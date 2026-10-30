#include "ClickController.h"
#include "ClickPlanner.h"
#include "Timing.h"
#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <algorithm>
#include <windows.h>
namespace {
using Planner::MaxBatch;
struct TimerHandle {
    HANDLE value =
        CreateWaitableTimerExW(nullptr, nullptr, 0x00000002, TIMER_MODIFY_STATE | SYNCHRONIZE);
    TimerHandle() {
        if (!value)
            value = CreateWaitableTimerW(nullptr, TRUE, nullptr);
    }
    ~TimerHandle() {
        if (value)
            CloseHandle(value);
    }
};
qint64 tick() {
    LARGE_INTEGER q;
    QueryPerformanceCounter(&q);
    return q.QuadPart;
}
bool ours(HWND w) {
    DWORD pid = 0;
    GetWindowThreadProcessId(w, &pid);
    return pid == GetCurrentProcessId();
}
// 0=deadline reached, 1=cancel, 2=error. Recheck QPC after waking: no early sends.
int waitUntil(qint64 deadline, qint64 freq, HANDLE stop, HANDLE timer) {
    HANDLE h[]{stop, timer};
    for (;;) {
        if (WaitForSingleObject(stop, 0) == WAIT_OBJECT_0)
            return 1;
        auto now = tick();
        if (now >= deadline)
            return 0;
        // Relative due time in 100 ns units, in double and capped at 1 s (the loop re-arms), so a
        // long Legit gap cannot overflow with a GHz-range QPC frequency.
        LARGE_INTEGER due;
        due.QuadPart = -std::max<qint64>(1, qint64(std::min(double(deadline - now) * 1e7 / double(freq), 1e7)));
        if (!SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE))
            return 2;
        DWORD r = WaitForMultipleObjects(2, h, FALSE, INFINITE);
        if (r == WAIT_OBJECT_0)
            return 1;
        if (r != WAIT_OBJECT_0 + 1)
            return 2;
    }
}
struct LoopState {
    HANDLE stop;
    HWND chosen;
    std::atomic_bool &cancel;
    std::atomic<qulonglong> &count, &skips;
    std::atomic<qint64> &maxLate;
};
QString loop(const ClickConfig &c, LoopState &state) {
    auto &[stop, chosen, cancel, count, skips, maxLate] = state;
    HWND target = GetForegroundWindow();
    if (chosen) {
        if (!IsWindow(chosen))
            return "targetGone";
        if (target != chosen)
            return "targetNotFront";
    }
    if (!target || ours(target))
        return "noTarget";
    LARGE_INTEGER f;
    if (!QueryPerformanceFrequency(&f) || f.QuadPart <= 0)
        return "noCounter";
    TimerHandle timer;
    if (!timer.value)
        return "noTimer";
    const qint64 freq = f.QuadPart;
    auto ticksFromNs = [freq](double ns) { return qint64(ns * double(freq) / 1e9); };
    auto nsFromTicks = [freq](qint64 ticks) { return qint64(double(ticks) * 1e9 / double(freq)); };
    const qint64 begin = tick(), limit = c.duration ? begin + freq * c.duration : 0;
    const bool blatant = c.mode == int(ClickMode::Blatant);
    const Planner::Grid grid(c.cps);
    Planner::Humanizer human(c.cps, c.variance,
                             quint64(begin) ^ (quint64(GetCurrentProcessId()) << 32));
    Planner::Step step = blatant ? Planner::Step{0, qint64(c.hold) * 1000000} : human.next();
    quint64 slot = 0;
    qint64 deadline = begin;
    DWORD targetPid = 0;
    const DWORD targetThread = GetWindowThreadProcessId(target, &targetPid);
    const DWORD down[]{MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_MIDDLEDOWN};
    const DWORD up[]{MOUSEEVENTF_LEFTUP, MOUSEEVENTF_RIGHTUP, MOUSEEVENTF_MIDDLEUP};
    INPUT batch[MaxBatch * 2];
    for (quint64 i = 0; i < MaxBatch * 2; ++i) {
        batch[i] = {};
        batch[i].type = INPUT_MOUSE;
        batch[i].mi.dwExtraInfo = 0x43434c4b;
        batch[i].mi.dwFlags = i % 2 ? up[c.button] : down[c.button];
    }
    INPUT *press = batch, *release = batch + 1;
    while (!cancel.load()) {
        int waited = waitUntil(limit ? std::min(deadline, limit) : deadline, freq, stop, timer.value);
        if (waited == 1)
            return {};
        if (waited == 2)
            return "timerFailed";
        qint64 now = tick();
        if (limit && now >= limit)
            return {};
        DWORD pid = 0;
        const auto thread = GetWindowThreadProcessId(target, &pid);
        if (!IsWindow(target) || GetForegroundWindow() != target || pid != targetPid ||
            thread != targetThread)
            return "focusLost";
        POINT point;
        if (!GetCursorPos(&point))
            return "noCursor";
        HWND under = WindowFromPoint(point);
        if (!under || GetAncestor(under, GA_ROOT) != target)
            return "cursorOutside";
        // Reject an already-held button at start. Do not confuse our own injected
        // async button state with a new physical press during subsequent clicks.
        const int vk[]{VK_LBUTTON, VK_RBUTTON, VK_MBUTTON};
        if (count.load() == 0 && (GetAsyncKeyState(vk[c.button]) & 0x8000))
            return "buttonHeld";
        if (cancel.load())
            return {};
        maxLate.store(std::max(maxLate.load(), nsFromTicks(now - deadline)));
        quint64 pairs = 1;
        if (blatant) {
            const quint64 due = grid.dueThrough(nsFromTicks(now - begin));
            const auto batch = Planner::blatantBatch(due > slot ? due - slot : 1, grid.periodNs(),
                                                     step.holdNs == 0,
                                                     c.countLimit ? c.countLimit - count.load() : 0);
            pairs = batch.pairs;
            skips.fetch_add(batch.skipped);
            slot = std::max(due, slot + 1);
        }
        bool cancelled = false;
        if (step.holdNs == 0) {
            const UINT wanted = UINT(pairs * 2);
            const UINT sent = SendInput(wanted, batch, sizeof(INPUT));
            if (sent != wanted) {
                // Never leave a press without its release; count only completed pairs.
                if (sent % 2 && SendInput(1, release, sizeof(INPUT)) == 1)
                    count.fetch_add(sent / 2 + 1);
                else
                    count.fetch_add(sent / 2);
                return "inputRejected";
            }
        } else {
            if (SendInput(1, press, sizeof(INPUT)) != 1)
                return "pressRejected";
            qint64 holdEnd = tick() + ticksFromNs(double(step.holdNs));
            if (limit)
                holdEnd = std::min(holdEnd, limit);
            const int held = waitUntil(holdEnd, freq, stop, timer.value);
            // Release even on cancellation or loss of focus; never count a press without release.
            if (SendInput(1, release, sizeof(INPUT)) != 1) {
                if (SendInput(1, release, sizeof(INPUT)) == 1)
                    count.fetch_add(1);
                return "releaseRejected";
            }
            cancelled = held == 1;
            if (held == 2) {
                count.fetch_add(1);
                return "holdTimerFailed";
            }
        }
        const auto accepted = count.fetch_add(pairs) + pairs;
        if (cancelled || cancel.load() || (c.countLimit && accepted >= c.countLimit))
            return {};
        if (blatant) {
            deadline = begin + ticksFromNs(double(grid.at(slot)));
        } else {
            deadline += ticksFromNs(double(step.gapNs));
            step = human.next();
            // After a stall (sleep, heavy load) resume with a normal gap instead of bursting to
            // catch up; the lost beats are reported as skipped.
            const qint64 current = tick();
            const qint64 gapTicks = std::max<qint64>(1, ticksFromNs(double(step.gapNs)));
            if (deadline < current - gapTicks) {
                skips.fetch_add(quint64((current - deadline) / gapTicks));
                deadline = current + gapTicks;
            }
        }
    }
    return {};
}
} // namespace
#endif
void ClickController::runWorker() {
    m_beginNs = Timing::nowNs();
    QString reason;
#ifdef Q_OS_WIN
    LoopState state{static_cast<HANDLE>(m_stopEvent), reinterpret_cast<HWND>(m_targetHandle.load()),
                    m_cancel, m_clicks, m_skipped, m_maxLateNs};
    reason = loop(m_config, state);
#else
    reason = "windowsOnly";
#endif
    m_endNs = Timing::nowNs();
    QMetaObject::invokeMethod(this, [this, reason] { complete(reason); }, Qt::QueuedConnection);
}
