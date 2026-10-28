#include "WindowEffects.h"
#include <QGuiApplication>
#include <QPainterPath>
#include <QRegion>
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
