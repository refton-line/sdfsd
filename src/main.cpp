#include "CaptureHarness.h"
#include "ClickController.h"
#include "ConfigStore.h"
#include "StartupController.h"
#include "WindowEffects.h"
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScreen>
#ifdef Q_OS_WIN
#include <windows.h>
#include <shobjidl.h>
#endif
int main(int argc, char *argv[]) {
#ifdef Q_OS_WIN
    // Stable shell identity for taskbar grouping and pinned shortcuts.
    SetCurrentProcessExplicitAppUserModelID(L"LightClicker.Desktop");
#endif
    QGuiApplication app(argc, argv);
    // Keep the established storage identity: an upgrade does not move or delete user data.
    app.setApplicationDisplayName("Light clicker");
    app.setOrganizationName("ObsidianClick");
    app.setApplicationName("ObsidianClick");
    app.setApplicationVersion("0.7.0");
    app.setWindowIcon(QIcon(":/qt/qml/LightClicker/assets/app-icon.png"));
    for (const char *face : {"Regular", "Medium", "SemiBold", "Bold"})
        QFontDatabase::addApplicationFont(QString(":/qt/qml/LightClicker/assets/fonts/Inter-%1.ttf").arg(face));
    QQuickStyle::setStyle("Basic");
    StartupController startup;
    ClickController clicks;
    ConfigStore configs(&clicks);
    WindowEffects effects;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("startup", &startup);
    engine.rootContext()->setContextProperty("configs", &configs);
    engine.rootContext()->setContextProperty("clickEngine", &clicks);
    engine.rootContext()->setContextProperty("windowEffects", &effects);
    engine.rootContext()->setContextProperty("uiCapture", app.arguments().contains("--capture"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("LightClicker", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    // Center once within this monitor's work area, never bind x/y to changing window dimensions.
    const QRect workArea = win->screen()->availableGeometry();
    win->setPosition(workArea.topLeft() + QPoint((workArea.width() - win->width()) / 2,
                                                (workArea.height() - win->height()) / 2));
    effects.roundCorners(win);
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &clicks, &ClickController::stop);
    const int captureIndex = app.arguments().indexOf("--capture");
    if (captureIndex >= 0 && captureIndex + 1 < app.arguments().size())
        runCaptureHarness(win, app.arguments()[captureIndex + 1], &clicks, &configs);
    return app.exec();
}
