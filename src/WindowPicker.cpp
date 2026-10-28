#include "WindowPicker.h"
#include <QFileInfo>
#include <QGuiApplication>
#include <QLinearGradient>
#include <QPainter>
#include <QScreen>
#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <dwmapi.h>
#include <windows.h>
#endif
namespace {
struct Sample { const char *title, *app; QColor top, bottom; };
const Sample samples[] = {
    {"Minecraft 1.21", "javaw.exe", QColor("#5b8c3a"), QColor("#2f4a1f")},
    {"osu!", "osu!.exe", QColor("#ff66aa"), QColor("#43284f")},
    {"Roblox", "RobloxPlayerBeta.exe", QColor("#3b82f6"), QColor("#1e293b")},
    {"Cookie Clicker - Google Chrome", "chrome.exe", QColor("#c8a26b"), QColor("#5a3d22")},
    {"Notepad", "notepad.exe", QColor("#f4f4f5"), QColor("#d4d4d8")},
    {"Discord", "Discord.exe", QColor("#5865f2"), QColor("#2b2d31")},
};
QImage sampleImage(int index, const QSize &bound) {
    const Sample &s = samples[index % std::size(samples)];
    QImage image(bound.isValid() ? bound : QSize(480, 270), QImage::Format_RGB32);
    QPainter p(&image);
    p.setRenderHint(QPainter::Antialiasing);
    QLinearGradient g(0, 0, 0, image.height());
    g.setColorAt(0, s.top);
    g.setColorAt(1, s.bottom);
    p.fillRect(image.rect(), g);
    p.fillRect(QRect(0, 0, image.width(), image.height() / 12), QColor(0, 0, 0, 60));
    p.setPen(Qt::NoPen);
    p.setBrush(QColor(255, 255, 255, 50));
    p.drawRoundedRect(QRectF(image.width() * 0.08, image.height() * 0.25, image.width() * 0.5,
                             image.height() * 0.5), 10, 10);
    return image;
}
#ifdef Q_OS_WIN
HWND toHwnd(const QString &id) { return reinterpret_cast<HWND>(quintptr(id.toULongLong())); }
bool pickable(HWND w) {
    if (!IsWindowVisible(w) || GetWindow(w, GW_OWNER) || GetWindowTextLengthW(w) == 0)
        return false;
    if (GetWindowLongPtrW(w, GWL_EXSTYLE) & WS_EX_TOOLWINDOW)
        return false;
    DWORD pid = 0;
    GetWindowThreadProcessId(w, &pid);
    if (pid == GetCurrentProcessId())
        return false;
    // Cloaked: suspended UWP frames and windows on other virtual desktops.
    int cloaked = 0;
    if (SUCCEEDED(DwmGetWindowAttribute(w, DWMWA_CLOAKED, &cloaked, sizeof(cloaked))) && cloaked)
        return false;
    RECT r{};
    GetWindowRect(w, &r);
    return IsIconic(w) || (r.right - r.left > 40 && r.bottom - r.top > 40);
}
QString processName(HWND w) {
    DWORD pid = 0;
    GetWindowThreadProcessId(w, &pid);
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!process)
        return {};
    wchar_t path[MAX_PATH];
    DWORD size = MAX_PATH;
    QString name;
    if (QueryFullProcessImageNameW(process, 0, path, &size))
        name = QFileInfo(QString::fromWCharArray(path, int(size))).fileName();
    CloseHandle(process);
    return name;
}
// Physical pixels to Qt's device-independent pixels: Qt keeps each screen's native origin and
// divides the extent by that screen's scale.
QRect logicalRect(HWND w, const RECT &r) {
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    GetMonitorInfoW(MonitorFromWindow(w, MONITOR_DEFAULTTONEAREST), &info);
    const QPoint origin(info.rcMonitor.left, info.rcMonitor.top);
    qreal ratio = 1;
    for (QScreen *s : QGuiApplication::screens())
        if (s->geometry().topLeft() == origin)
            ratio = s->devicePixelRatio();
    const auto map = [&](LONG x, LONG y) {
        return origin + QPointF((x - origin.x()) / ratio, (y - origin.y()) / ratio).toPoint();
    };
    return QRect(map(r.left, r.top), map(r.right, r.bottom));
}
#endif
} // namespace

void WindowPicker::refresh() {
    QVariantList list;
    if (m_fake) {
        for (int i = 0; i < int(std::size(samples)); ++i)
            list.append(QVariantMap{{"id", QString::number(1000 + i)}, {"title", samples[i].title},
                                    {"app", samples[i].app}, {"minimized", i == 4}});
    }
#ifdef Q_OS_WIN
    else {
        EnumWindows(
            [](HWND w, LPARAM out) -> BOOL {
                if (!pickable(w))
                    return TRUE;
                wchar_t title[512];
                const int n = GetWindowTextW(w, title, 512);
                reinterpret_cast<QVariantList *>(out)->append(QVariantMap{
                    {"id", QString::number(quintptr(w))},
                    {"title", QString::fromWCharArray(title, n)},
                    {"app", processName(w)},
                    {"minimized", bool(IsIconic(w))}});
                return TRUE;
            },
            reinterpret_cast<LPARAM>(&list));
    }
#endif
    m_windows = list;
    emit windowsChanged();
}
bool WindowPicker::alive(const QString &id) const {
    if (id.isEmpty())
        return false;
#ifdef Q_OS_WIN
    if (!m_fake)
        return IsWindow(toHwnd(id));
#endif
    return m_fake;
}
QRect WindowPicker::windowRect(const QString &id) const {
#ifdef Q_OS_WIN
    if (!m_fake) {
        const HWND w = toHwnd(id);
        RECT r{};
        if (!IsWindow(w) || IsIconic(w))
            return {};
        // The visible frame, without the invisible resize borders.
        if (FAILED(DwmGetWindowAttribute(w, DWMWA_EXTENDED_FRAME_BOUNDS, &r, sizeof(r))))
            GetWindowRect(w, &r);
        return logicalRect(w, r);
    }
#endif
    Q_UNUSED(id)
    return {};
}
QImage WindowPicker::thumbnail(const QString &id, const QSize &bound) const {
    if (m_fake) {
        const int index = id.toInt() - 1000;
        return index == 4 ? QImage() : sampleImage(index, bound);
    }
#ifdef Q_OS_WIN
    const HWND w = toHwnd(id);
    RECT r{};
    if (!IsWindow(w) || IsIconic(w) || !GetWindowRect(w, &r))
        return {};
    const int width = r.right - r.left, height = r.bottom - r.top;
    if (width <= 0 || height <= 0 || width > 16384 || height > 16384)
        return {};
    HDC screen = GetDC(nullptr);
    HDC memory = CreateCompatibleDC(screen);
    HBITMAP bitmap = CreateCompatibleBitmap(screen, width, height);
    HGDIOBJ old = SelectObject(memory, bitmap);
    // PW_RENDERFULLCONTENT (2) also captures DirectX and browser content on Windows 8.1+.
    const bool ok = PrintWindow(w, memory, 2);
    SelectObject(memory, old);
    QImage image = ok ? QImage::fromHBITMAP(bitmap).convertToFormat(QImage::Format_RGB32) : QImage();
    DeleteObject(bitmap);
    DeleteDC(memory);
    ReleaseDC(nullptr, screen);
    if (!image.isNull() && bound.isValid())
        image = image.scaled(bound, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    return image;
#else
    Q_UNUSED(id)
    Q_UNUSED(bound)
    return {};
#endif
}
QImage WindowThumbnails::requestImage(const QString &id, QSize *size, const QSize &requested) {
    const QSize bound = requested.isValid() ? requested : QSize(480, 300);
    QImage image = m_picker->thumbnail(id.section('/', 0, 0), bound);
    if (image.isNull()) {
        image = QImage(1, 1, QImage::Format_ARGB32);
        image.fill(Qt::transparent);
    }
    if (size)
        *size = image.size();
    return image;
}
