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
};
