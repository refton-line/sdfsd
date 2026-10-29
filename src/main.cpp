#include "CaptureHarness.h"
#include "CrispIconProvider.h"
#include <QTimer>
#include "ClickController.h"
#include "ConfigStore.h"
#include "SoundEngine.h"
#include "Storage.h"
#include "StartupController.h"
#include "WindowEffects.h"
#include "WindowPicker.h"
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScreen>
#include <QStyleHints>
#ifdef Q_OS_WIN
#include <windows.h>
#include <shobjidl.h>
#endif
int main(int argc, char *argv[]) {
#ifdef Q_OS_WIN
    // Stable shell identity for taskbar grouping and pinned shortcuts.
    SetCurrentProcessExplicitAppUserModelID(L"FakeClicker.Desktop");
#endif
    QQuickWindow::setDefaultAlphaBuffer(true);
    QGuiApplication app(argc, argv);
    const bool captureUi = app.arguments().contains("--capture") || app.arguments().contains("--capture-ui-regression") || app.arguments().contains("--capture-text-regression");
    app.setApplicationDisplayName("Fake Clicker");
    app.setOrganizationName("FakeClicker");
    app.setApplicationName("FakeClicker");
    app.setApplicationVersion("0.8.0");
    // One FakeClicker folder for settings and profiles; data of ObsidianClick builds is copied once.
    Storage::install();
    QFont grayscale = app.font();
    grayscale.setStyleStrategy(QFont::StyleStrategy(QFont::PreferAntialias | QFont::NoSubpixelAntialias));
    grayscale.setHintingPreference(QFont::PreferFullHinting);
    app.setWindowIcon(QIcon(":/qt/qml/FakeClicker/assets/app-icon.png"));
    for (const char *face : {"Geist-Regular", "Geist-Medium", "Geist-SemiBold", "Geist-Bold", "Geist-ExtraBold",
                             "Geist-Black", "GeistMono-Regular", "GeistMono-Medium", "GeistMono-SemiBold"})
        QFontDatabase::addApplicationFont(QString(":/qt/qml/FakeClicker/assets/fonts/%1.ttf").arg(face));
    grayscale.setFamily("Geist");
    app.setFont(grayscale);
    QQuickStyle::setStyle("Basic");
    // The app is always dark. Without this Qt follows a light Windows theme and paints the standard
    // title bar white, overriding the dark DWM attribute.
    app.styleHints()->setColorScheme(Qt::ColorScheme::Dark);
    StartupController startup;
    ClickController clicks;
    ConfigStore configs(&clicks);
    SoundEngine sounds;
    sounds.follow(&clicks);
    WindowEffects effects;
    WindowPicker picker;
    if (captureUi)
        picker.presentForCapture();
    QQmlApplicationEngine engine;
    engine.addImageProvider("crispicons", new CrispIconProvider);
    engine.addImageProvider("windows", new WindowThumbnails(&picker));
    engine.rootContext()->setContextProperty("windowPicker", &picker);
    engine.rootContext()->setContextProperty("startup", &startup);
    engine.rootContext()->setContextProperty("configs", &configs);
    engine.rootContext()->setContextProperty("clickEngine", &clicks);
    engine.rootContext()->setContextProperty("sounds", &sounds);
    engine.rootContext()->setContextProperty("windowEffects", &effects);
    engine.rootContext()->setContextProperty("uiCapture", captureUi);
    // Screenshot tours on slow software GL can stretch window animations to catch them part-way.
    const int motionScale = captureUi
                                ? qMax(1, qEnvironmentVariableIntValue("FAKECLICKER_MOTION_SCALE"))
                                : 1;
    engine.rootContext()->setContextProperty("motionScale", motionScale);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    const int renderIndex = app.arguments().indexOf("--capture-render-regression");
    if (renderIndex >= 0 && renderIndex + 1 < app.arguments().size()) {
        engine.loadFromModule("FakeClicker", "RenderDiagnostics");
        if (engine.rootObjects().isEmpty()) return 1;
        auto *diagnostic = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        const QString output = app.arguments()[renderIndex + 1];
        QTimer::singleShot(1200, diagnostic, [diagnostic, output] {
            if (!diagnostic->grabWindow().save(output)) qFatal("Render diagnostic save failed");
            QCoreApplication::exit(0);
        });
        return app.exec();
    }
    engine.loadFromModule("FakeClicker", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    effects.roundCorners(win);
    // Center once within this monitor's work area, title bar included; never bind x/y to changing
    // window dimensions.
    const QRect workArea = win->screen()->availableGeometry();
    const QSize outer = win->size().grownBy(win->frameMargins());
    win->setFramePosition(workArea.topLeft() + QPoint((workArea.width() - outer.width()) / 2,
                                                     qMax(0, (workArea.height() - outer.height()) / 2)));
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &clicks, &ClickController::stop);
    const int captureIndex = app.arguments().indexOf("--capture");
    if (captureIndex >= 0 && captureIndex + 1 < app.arguments().size())
        runCaptureHarness(win, app.arguments()[captureIndex + 1], &clicks, &configs);
    const int regressionIndex = app.arguments().indexOf("--capture-ui-regression");
    if (regressionIndex >= 0 && regressionIndex + 1 < app.arguments().size())
        runUiRegressionHarness(win, app.arguments()[regressionIndex + 1], &clicks);
    const int textIndex = app.arguments().indexOf("--capture-text-regression");
    if (textIndex >= 0 && textIndex + 1 < app.arguments().size())
        runTextRegressionHarness(win, app.arguments()[textIndex + 1], &clicks);
    return app.exec();
}
