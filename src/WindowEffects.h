#pragma once
#include <QObject>
class QWindow;
// Native window touches QML cannot express: overlay shape/click-through and Windows 11 corners.
class WindowEffects final : public QObject {
    Q_OBJECT
  public:
    using QObject::QObject;
    // Clip the window to a rounded rectangle (device-independent pixels); empty clears the mask.
    Q_INVOKABLE void setRoundedMask(QWindow *window, qreal x, qreal y, qreal width, qreal height,
                                    qreal radius);
    // Never take focus or mouse input, so the click target keeps foreground and cursor.
    Q_INVOKABLE void makePassive(QWindow *window);
    Q_INVOKABLE void roundCorners(QWindow *window);
    // The standard Windows title bar, or the app's own (custom). The custom frame keeps an invisible
    // native frame so Windows still animates minimize, maximize, restore and Snap. Switching keeps the
    // client size.
    Q_INVOKABLE void setCustomFrame(QWindow *window, bool custom);
    // Standard window commands with the system animations; false when unavailable (not Windows).
    Q_INVOKABLE bool minimize(QWindow *window);
    Q_INVOKABLE bool toggleMaximize(QWindow *window);

  private:
    bool m_nativeFrame = false;
};
