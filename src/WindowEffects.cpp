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
    // Qt creates this window with WindowTransparentForInput (including the appropriate
    // layered/composition handling). Reinforce passivity after every native show.
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    EnableWindow(hwnd, FALSE);
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE,
                      GetWindowLongPtrW(hwnd, GWL_EXSTYLE) | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW | WS_EX_TRANSPARENT);
#else
    window->setFlag(Qt::WindowTransparentForInput, true);
#endif
}
void WindowEffects::roundCorners(QWindow *window) {
#ifdef Q_OS_WIN
    if (!window)
        return;
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    // DWMWA_WINDOW_CORNER_PREFERENCE / DWMWCP_ROUND; ignored before Windows 11.
    const DWORD cornerAttribute = 33, round = 2;
    DwmSetWindowAttribute(hwnd, cornerAttribute, &round, sizeof(round));
    // DWMWA_USE_IMMERSIVE_DARK_MODE and DWMWA_BORDER_COLOR: a dark system frame with a graphite
    // hairline that matches the interface. Unsupported attributes are ignored on older builds.
    const BOOL dark = TRUE;
    DwmSetWindowAttribute(hwnd, 20, &dark, sizeof(dark));
    const COLORREF border = RGB(0x24, 0x24, 0x24);
    DwmSetWindowAttribute(hwnd, 34, &border, sizeof(border));
#else
    Q_UNUSED(window)
#endif
}
#ifdef Q_OS_WIN
namespace {
// Custom frame only: the caption and thick frame exist for the window manager alone, so
// WM_NCCALCSIZE gives the whole window to the client, and a maximized window is fitted to the work
// area (Windows would otherwise push the invisible frame off-screen and the content with it).
class FrameFilter final : public QAbstractNativeEventFilter {
  public:
    HWND hwnd = nullptr;
    bool enabled = false;
    bool nativeEventFilter(const QByteArray &type, void *message, qintptr *result) override {
        if (!enabled || type != "windows_generic_MSG")
            return false;
        auto *msg = static_cast<MSG *>(message);
        if (msg->hwnd != hwnd || msg->message != WM_NCCALCSIZE)
            return false;
        if (msg->wParam && IsZoomed(hwnd)) {
            auto *params = reinterpret_cast<NCCALCSIZE_PARAMS *>(msg->lParam);
            MONITORINFO info{};
            info.cbSize = sizeof(info);
            if (GetMonitorInfoW(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &info))
                params->rgrc[0] = info.rcWork;
        }
        *result = 0;
        return true;
    }
};
FrameFilter &frameFilter() {
    static FrameFilter *filter = [] {
        auto *created = new FrameFilter;
        qApp->installNativeEventFilter(created);
        return created;
    }();
    return *filter;
}
} // namespace
#endif
void WindowEffects::setCustomFrame(QWindow *window, bool custom) {
    if (!window)
        return;
    const QSize client = window->size();
    const bool maximized = window->windowStates() & (Qt::WindowMaximized | Qt::WindowFullScreen);
#ifdef Q_OS_WIN
    FrameFilter &filter = frameFilter();
    filter.hwnd = reinterpret_cast<HWND>(window->winId());
    // Set before the flags change, so a standard frame is never computed away.
    filter.enabled = custom;
#endif
    window->setFlags(custom ? Qt::Window | Qt::FramelessWindowHint | Qt::WindowMinMaxButtonsHint | Qt::WindowSystemMenuHint
                            : Qt::Window);
#ifdef Q_OS_WIN
    if (custom) {
        const LONG_PTR style = GetWindowLongPtrW(filter.hwnd, GWL_STYLE);
        SetWindowLongPtrW(filter.hwnd, GWL_STYLE,
                          style | WS_CAPTION | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
    }
    SetWindowPos(filter.hwnd, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
#endif
    if (!maximized && window->size() != client)
        window->resize(client);
    m_nativeFrame = custom;
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
