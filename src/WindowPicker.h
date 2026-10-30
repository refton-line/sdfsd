#pragma once
#include <QImage>
#include <QObject>
#include <QQuickImageProvider>
#include <QRect>
#include <QVariantList>
// Lists top-level windows for the target picker (like a screen-share window picker) and renders
// their thumbnails. Ids are HWND values as decimal strings, safe in JavaScript.
class WindowPicker final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
  public:
    using QObject::QObject;
    QVariantList windows() const { return m_windows; }
    Q_INVOKABLE void refresh();
    // Window rect in device-independent pixels, empty when the window is gone or minimized.
    Q_INVOKABLE QRect windowRect(const QString &id) const;
    Q_INVOKABLE bool alive(const QString &id) const;
    QImage thumbnail(const QString &id, const QSize &bound) const;
    // Screenshot tours on Linux: a fixed set of sample windows.
    void presentForCapture() { m_fake = true; refresh(); }

  signals:
    void windowsChanged();

  private:
    QVariantList m_windows;
    bool m_fake = false;
};
class WindowThumbnails final : public QQuickImageProvider {
  public:
    explicit WindowThumbnails(WindowPicker *picker)
        : QQuickImageProvider(QQuickImageProvider::Image), m_picker(picker) {}
    // id: "<hwnd>/<refresh serial>"; the serial only defeats the image cache.
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;

  private:
    WindowPicker *m_picker;
};
