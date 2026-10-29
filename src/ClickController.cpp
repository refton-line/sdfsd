#include "ClickController.h"
#include "Timing.h"
#include <QGuiApplication>
#include <QSettings>
#include <QWindow>
#include <QtConcurrent>
#include <cmath>
#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif
ClickController::ClickController(QObject *parent) : QObject(parent) {
    qGuiApp->installEventFilter(this);
    QSettings s;
    QString error;
    ClickConfig loaded;
    if (s.contains("click/config")) {
        if (Configuration::decode(s.value("click/config").toJsonObject(), loaded, error))
            m_config = loaded;
        else
            m_error = "savedRejected:" + error;
    } else if (s.contains("click/interval")) {
        // Pre-profile releases stored a fixed interval; that behaviour is Blatant mode now.
        m_config.mode = int(ClickMode::Blatant);
        m_config.cps = 1000.0 / qBound(5, s.value("click/interval", 100).toInt(), 10000);
        m_config.hold = 1; // the fixed-interval engine always held for 1 ms
        m_config.duration = qBound(0, s.value("click/duration", 0).toInt(), 3600);
        m_config.button = qBound(0, s.value("click/button", 0).toInt(), 1);
        int f = s.value("click/key", 6).toInt();
        if (QList<int>{6, 7, 9, 10}.contains(f))
            m_config.startKey = 0x6f + f;
    }
#ifdef Q_OS_WIN
    m_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    m_available = m_stopEvent && registerBindings(m_config);
    if (!m_available)
        m_error = "keyboardUnavailable";
    qGuiApp->installNativeEventFilter(this);
#endif
    m_countdownTimer.setInterval(1000);
    connect(&m_countdownTimer, &QTimer::timeout, this, [this] {
        --m_countdown;
        if (m_countdown == 0) {
            m_countdownTimer.stop();
            launch();
        }
        emit changed();
    });
    m_poll.setInterval(100);
    connect(&m_poll, &QTimer::timeout, this, &ClickController::sample);
}
ClickController::~ClickController() {
    qGuiApp->removeEventFilter(this);
    stop();
    m_task.waitForFinished();
#ifdef Q_OS_WIN
    qGuiApp->removeNativeEventFilter(this);
    unregisterBindings();
    delete m_inputWindow;
    if (m_stopEvent)
        CloseHandle(m_stopEvent);
#endif
}
void ClickController::persist() {
    QSettings().setValue("click/config", QVariant::fromValue(Configuration::encode(m_config)));
}
bool ClickController::applyConfig(const ClickConfig &c) {
    if (m_active) {
        m_error = "stopFirst";
        emit changed();
        return false;
    }
    auto error = Configuration::validate(c);
    if (!error.isEmpty()) {
        m_error = error;
        emit changed();
        return false;
    }
    const bool changedKeys = c.startKey != startKey() || c.stopKey != stopKey() ||
                             c.startMods != startMods() || c.stopMods != stopMods() ||
                             c.startChord != m_config.startChord || c.stopChord != m_config.stopChord ||
                             c.startExtra != m_config.startExtra ||
                             c.stopExtra != m_config.stopExtra;
#ifdef Q_OS_WIN
    if (changedKeys || m_editing || !m_available) {
        unregisterBindings();
        if (!m_stopEvent || !registerBindings(c)) {
            unregisterBindings();
            m_available = !m_editing && m_stopEvent && registerBindings(m_config);
            m_error = "keyboardUnavailable";
            emit changed();
            return false;
        }
        m_available = true;
    }
#else
    Q_UNUSED(changedKeys)
#endif
    m_config = c;
    m_draftError.clear();
    m_editing = false;
    m_pressedKeys.clear();
    emit keyboardStateChanged();
    m_error.clear();
    persist();
    emit changed();
    return true;
}
void ClickController::setLaunchDelaySec(int v) {
    auto c = m_config;
    c.launchDelay = v;
    applyConfig(c);
}
void ClickController::fitHold(ClickConfig &c) {
    if (c.mode != int(ClickMode::Blatant) || !Configuration::validCps(c.cps))
        return;
    const double periodMs = 1000.0 / c.cps;
    if (c.hold >= periodMs)
        c.hold = qMax(0, int(std::ceil(periodMs)) - 1);
}
void ClickController::setMode(int v) {
    auto c = m_config;
    c.mode = v;
    fitHold(c);
    applyConfig(c);
}
void ClickController::setCps(double v) {
    auto c = m_config;
    c.cps = v;
    fitHold(c);
    applyConfig(c);
}
void ClickController::setVariance(int v) {
    auto c = m_config;
    c.variance = v;
    applyConfig(c);
}
void ClickController::setDurationSec(int v) {
    auto c = m_config;
    c.duration = v;
    applyConfig(c);
}
void ClickController::setMouseButton(int v) {
    auto c = m_config;
    c.button = v;
    applyConfig(c);
}
void ClickController::setHoldMs(int v) {
    auto c = m_config;
    c.hold = v;
    applyConfig(c);
}
void ClickController::setCountLimit(qulonglong v) {
    auto c = m_config;
    c.countLimit = v;
    applyConfig(c);
}
double ClickController::elapsedSec() const {
    const auto b = m_beginNs.load();
    if (!b)
        return 0;
    const auto e = m_endNs.load();
    return qMax<qint64>(0, (e ? e : Timing::nowNs()) - b) / 1e9;
}
double ClickController::averageCps() const {
    auto seconds = elapsedSec();
    return seconds >= 0.25 ? double(clicks()) / seconds : -1;
}
void ClickController::sample() {
    const qint64 b = m_beginNs.load();
    if (!b) {
        emit changed();
        return;
    }
    const qint64 now = m_endNs.load() ? m_endNs.load() : Timing::nowNs();
    const quint64 count = clicks();
    if (m_samples.isEmpty())
        m_samples.enqueue({b, 0});
    m_samples.enqueue({now, count});
    while (m_samples.size() > 2 && m_samples.at(1).first <= now - 1000000000LL)
        m_samples.dequeue();
    m_recentCps = Timing::rate(count - m_samples.head().second, now - m_samples.head().first);
    emit changed();
}
void ClickController::setReady(bool v) {
    m_ready = v;
    emit changed();
}
void ClickController::toggle() {
    if (m_active)
        stop();
    else
        start();
}
void ClickController::start() {
    if (m_active || !available())
        return;
    m_error.clear();
    m_clicks = 0;
    m_skipped = 0;
    m_maxLateNs = 0;
    m_beginNs = 0;
    m_endNs = 0;
    m_recentCps = -1;
    m_samples.clear();
    m_active = true;
    m_countdown = m_config.launchDelay;
    m_state = "arming";
    activateTarget();
    m_cancel = false;
#ifdef Q_OS_WIN
    ResetEvent(m_stopEvent);
#endif
    m_countdownTimer.start();
    emit changed();
}
void ClickController::setTarget(const QString &id, const QString &title) {
    if (m_active)
        return;
    m_targetWindow = id;
    m_targetTitle = id.isEmpty() ? QString() : title;
    m_targetHandle = quintptr(id.toULongLong());
    emit changed();
}
// Bring the chosen window forward: at Start (this app is in front, so Windows allows it) and again
// when the countdown ends.
void ClickController::activateTarget() {
#ifdef Q_OS_WIN
    const HWND w = reinterpret_cast<HWND>(m_targetHandle.load());
    if (!w || !IsWindow(w))
        return;
    if (IsIconic(w))
        ShowWindow(w, SW_RESTORE);
    SetForegroundWindow(w);
#endif
}
void ClickController::launch() {
    if (!m_active)
        return;
    activateTarget();
    m_state = "running";
    m_poll.start();
    m_task = QtConcurrent::run([this] { runWorker(); });
}
void ClickController::stop() {
    if (!m_active)
        return;
    m_countdownTimer.stop();
    m_cancel = true;
#ifdef Q_OS_WIN
    if (m_stopEvent)
        SetEvent(m_stopEvent);
#endif
    if (m_countdown > 0) {
        m_countdown = 0;
        complete("cancelled");
        return;
    }
    m_state = "stopping";
    emit changed();
}
void ClickController::complete(const QString &reason) {
    m_poll.stop();
    sample();
    m_active = false;
    m_state = "idle";
    if (!reason.isEmpty() && reason != "cancelled")
        m_error = reason;
    emit changed();
}
void ClickController::presentForCapture(const QString &state, qulonglong clicks, double measured,
                                        int countdown, const QString &error) {
    m_state = state;
    m_active = state != "idle";
    m_clicks = clicks;
    m_recentCps = measured;
    m_countdown = countdown;
    m_error = error;
    if (state == "running" && !m_beginNs)
        m_beginNs = Timing::nowNs() - qint64(clicks / qMax(1.0, measured) * 1e9);
    m_endNs = state == "idle" ? Timing::nowNs() : 0;
    emit changed();
}
