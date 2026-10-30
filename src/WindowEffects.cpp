#include "WindowEffects.h"
#include <QGuiApplication>
#include <QPainterPath>
#include <QRegion>
#include <QAbstractNativeEventFilter>
#include <QWindow>
#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <dwmapi.h>
#include <windows.h>
#endif
void WindowEffects::setRoundedMask(QWindow *window, qreal x, qreal y, qreal width, qreal height,
                                   qreal radius) {
    if (!window || QGuiApplication::platformName() == "offscreen")
        return;
    if (width <= 0 || height <= 0) {
        window->setMask(QRegion(0, 0, 1, 1));
        return;
    }
    QPainterPath path;
    path.addRoundedRect(QRectF(x, y, width, height), radius, radius);
    window->setMask(QRegion(path.toFillPolygon().toPolygon()));
}
void WindowEffects::makePassive(QWindow *window) {
    if (!window)
        return;
#ifdef Q_OS_WIN
    // A disabled window is skipped by WindowFromPoint and never activates. WS_EX_TRANSPARENT
    // would require a layered window, which Direct3D flip-model swap chains do not present.
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    EnableWindow(hwnd, FALSE);
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE,
                      GetWindowLongPtrW(hwnd, GWL_EXSTYLE) | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW);
#else
    window->setFlag(Qt::WindowTransparentForInput, true);
#endif
}
void WindowEffects::roundCorners(QWindow *window) {
#ifdef Q_OS_WIN
    if (!window)
        return;
    // DWMWA_WINDOW_CORNER_PREFERENCE / DWMWCP_ROUND; ignored before Windows 11.
    const DWORD attribute = 33, round = 2;
    DwmSetWindowAttribute(reinterpret_cast<HWND>(window->winId()), attribute, &round, sizeof(round));
#else
    Q_UNUSED(window)
#endif
}
#ifdef Q_OS_WIN
namespace {
// The caption and thick frame exist only for the window manager: WM_NCCALCSIZE gives the whole
// window to the client, and a maximized window is fitted to the work area (Windows would otherwise
// push the invisible frame off-screen and the content with it).
class FrameFilter final : public QAbstractNativeEventFilter {
  public:
    explicit FrameFilter(HWND hwnd) : m_hwnd(hwnd) {}
    bool nativeEventFilter(const QByteArray &type, void *message, qintptr *result) override {
        if (type != "windows_generic_MSG")
            return false;
        auto *msg = static_cast<MSG *>(message);
        if (msg->hwnd != m_hwnd || msg->message != WM_NCCALCSIZE)
            return false;
        if (msg->wParam && IsZoomed(m_hwnd)) {
            auto *params = reinterpret_cast<NCCALCSIZE_PARAMS *>(msg->lParam);
            MONITORINFO info{};
            info.cbSize = sizeof(info);
            if (GetMonitorInfoW(MonitorFromWindow(m_hwnd, MONITOR_DEFAULTTONEAREST), &info))
                params->rgrc[0] = info.rcWork;
        }
        *result = 0;
        return true;
    }

  private:
    HWND m_hwnd;
};
} // namespace
#endif
void WindowEffects::enableNativeFrame(QWindow *window) {
#ifdef Q_OS_WIN
    if (!window)
        return;
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    static FrameFilter *filter = nullptr;
    if (!filter) {
        filter = new FrameFilter(hwnd);
        qApp->installNativeEventFilter(filter);
    }
    const LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
    SetWindowLongPtrW(hwnd, GWL_STYLE,
                      style | WS_CAPTION | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    m_nativeFrame = true;
#else
    Q_UNUSED(window)
#endif
}
bool WindowEffects::minimize(QWindow *window) {
#ifdef Q_OS_WIN
    if (!window || !m_nativeFrame)
        return false;
    ShowWindow(reinterpret_cast<HWND>(window->winId()), SW_MINIMIZE);
    return true;
#else
    Q_UNUSED(window)
    return false;
#endif
}
bool WindowEffects::toggleMaximize(QWindow *window) {
#ifdef Q_OS_WIN
    if (!window || !m_nativeFrame)
        return false;
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    ShowWindow(hwnd, IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE);
    return true;
#else
    Q_UNUSED(window)
    return false;
#endif
}
