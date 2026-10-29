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
