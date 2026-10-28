#include "CaptureHarness.h"
#include "ClickController.h"
#include "ConfigStore.h"
#include <QDir>
#include <QGuiApplication>
#include <QImage>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTimer>
#include <functional>
#include <memory>
#include <vector>
namespace {
QQuickItem *find(QQuickItem *item, const QString &name) {
    if (item->objectName() == name)
        return item;
    for (auto *child : item->childItems())
        if (auto *found = find(child, name))
            return found;
    return nullptr;
}
QObject *findObject(QQuickWindow *win, const QString &name) {
    if (auto *item = find(win->contentItem(), name))
        return item;
    return win->findChild<QObject *>(name);
}
} // namespace
// Deterministic UI tour for screenshots: --capture <dir>. Engine states are presented through
// presentForCapture because SendInput is Windows-only.
void runCaptureHarness(QQuickWindow *win, const QString &output, ClickController *engine,
                       ConfigStore *configs) {
    QDir().mkpath(output);
    struct Step { int at; std::function<void()> run; };
    auto steps = std::make_shared<std::vector<Step>>();
    auto shot = [win, output](const QString &name) {
        if (!win->isVisible() || !win->isExposed())
            return;
        if (!win->grabWindow().save(output + "/" + name + ".png"))
            qFatal("capture failed: %s", qPrintable(name));
    };
    auto page = [win](int index) { win->setProperty("currentPage", index); };
    auto call = [win](const char *method, const QVariant &arg) {
        QMetaObject::invokeMethod(win, method, Q_ARG(QVariant, arg));
    };
    auto add = [steps](int at, std::function<void()> run) { steps->push_back({at, std::move(run)}); };

    engine->enableForCapture();
    auto island = [win](bool pinned) {
        if (auto *item = findObject(win, "island"))
            item->setProperty("pinned", pinned);
    };
    auto popup = [win](const char *name, const char *method) {
        if (auto *object = findObject(win, name))
            QMetaObject::invokeMethod(object, method);
    };
    auto material = [=](const QString &value, int x, int y, const QString &midShot) {
        QMetaObject::invokeMethod(win, "setMaterial", Q_ARG(QVariant, value), Q_ARG(QVariant, x), Q_ARG(QVariant, y));
        // Real-time, not paced: catch the wave halfway.
        if (!midShot.isEmpty())
            for (int ms : {350, 650, 950})
                QTimer::singleShot(ms, win, [=] { shot(midShot + "-" + QString::number(ms)); });
    };
    add(260, [=] { shot("01-boot"); });
    add(1350, [=] { shot("02-launch"); });
    add(2600, [=] { shot("03-glass-clicker"); });
    add(2700, [=] { island(true); });
    add(3500, [=] { shot("04-glass-island-expanded"); });
    add(3600, [=] { island(false); engine->setMode(1); });
    add(3950, [=] { shot("05-island-notice"); });
    add(5400, [=] { engine->setCps(2500); });
    add(6200, [=] { shot("06-glass-blatant"); });
    add(6300, [=] { engine->presentForCapture("arming", 0, -1, 3); });
    add(7300, [=] { shot("07-arming"); });
    add(7400, [=] { engine->presentForCapture("running", 18420, 2493.7, 0); });
    for (int i = 0; i < 20; ++i)
        add(7500 + i * 100, [=] { engine->presentForCapture("running", 18420 + i * 250, 2440 + (i * 37 % 110), 0); });
    add(9600, [=] { shot("08-running"); });
    add(9700, [=] { island(true); });
    add(10500, [=] { shot("09-island-expanded-running"); });
    add(10600, [=] { island(false); engine->presentForCapture("idle", 24420, 2488.2, 0); });
    add(11300, [=] { shot("10-island-summary"); });
    add(13800, [=] { engine->presentForCapture("idle", 24420, 2488.2, 0, "focusLost"); });
    add(14400, [=] { shot("11-error"); });
    add(14500, [=] { engine->dismissError(); page(1); });
    add(15400, [=] { shot("12-glass-hotkeys"); });
    add(15500, [=] {
        if (auto *picker = findObject(win, "keyboardPicker"))
            QMetaObject::invokeMethod(picker, "edit", Q_ARG(QVariant, 0), Q_ARG(QVariant, 0));
    });
    add(16500, [=] { shot("13-glass-keyboard"); });
    add(16600, [=] { popup("keyboardPicker", "close"); });
    add(17100, [=] {
        engine->setMode(0);
        engine->setCps(12);
        configs->saveNew("Bedwars legit");
        engine->setMode(1);
        engine->setCps(500);
        configs->saveNew("Rage 500");
        engine->setCps(20);
        configs->saveNew("Blatant 20");
        page(2);
    });
    add(18300, [=] { shot("14-glass-profiles"); });
    add(18400, [=] { page(3); });
    add(19300, [=] { shot("15-glass-appearance"); });
    add(19400, [=] { material("solid", 700, 260, "16-material-switch"); });
    add(21000, [=] { shot("17-solid-appearance"); });
    add(21100, [=] { page(0); });
    add(22000, [=] { shot("18-solid-clicker"); });
    add(22100, [=] { island(true); });
    add(22900, [=] { shot("19-solid-island-expanded"); });
    add(23000, [=] { island(false); page(1); });
    add(23900, [=] { shot("20-solid-hotkeys"); });
    add(24000, [=] {
        if (auto *picker = findObject(win, "keyboardPicker"))
            QMetaObject::invokeMethod(picker, "edit", Q_ARG(QVariant, 1), Q_ARG(QVariant, 0));
    });
    add(25000, [=] { shot("21-solid-keyboard"); });
    add(25100, [=] { popup("keyboardPicker", "close"); page(2); });
    add(26000, [=] { shot("22-solid-profiles"); });
    add(26100, [=] { popup("configNameDialog", "open"); });
    add(27000, [=] { shot("23-solid-sheet"); });
    add(27100, [=] { popup("configNameDialog", "close"); page(4); });
    add(28000, [=] { call("setLanguage", "ru"); });
    add(29000, [=] { shot("24-solid-language-ru"); });
    add(29100, [=] { page(0); });
    add(29250, [=] { shot("25-solid-page-transition"); });
    add(30100, [=] { shot("26-solid-clicker-ru"); });
    add(30200, [=] { material("glass", 540, 360, "27-material-switch-back"); });
    add(31800, [=] { shot("28-glass-clicker-ru"); });
    add(31900, [=] { page(1); });
    add(32800, [=] { shot("29-glass-hotkeys-ru"); });
    add(32900, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>()) {
            engine->presentForCapture("running", 3120, 14.6, 0);
            overlay->setProperty("wanted", true);
        }
    });
    add(34000, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>())
            overlay->grabWindow().save(output + "/30-overlay-island.png");
    });
    add(34100, [=] {
        engine->presentForCapture("idle", 3120, 14.6, 0);
        call("setLanguage", "en");
    });
    add(35100, [=] { win->close(); });
    add(35160, [=] { shot("31-closing"); });

    // Relative scheduling: a slow grab on software GL must not bunch later steps together.
    const int pace = qEnvironmentVariableIntValue("CAPTURE_PACE") > 0 ? qEnvironmentVariableIntValue("CAPTURE_PACE") : 1;
    auto runner = std::make_shared<std::function<void(size_t, int)>>();
    std::weak_ptr<std::function<void(size_t, int)>> weak = runner;
    *runner = [=](size_t i, int previous) {
        if (i >= steps->size()) {
            QTimer::singleShot(1500 * pace, qApp, [] { QCoreApplication::exit(0); });
            return;
        }
        const auto step = steps->at(i);
        QTimer::singleShot(qMax(1, (step.at - previous) * pace), win, [=] {
            step.run();
            if (auto next = weak.lock())
                (*next)(i + 1, step.at);
        });
    };
    static std::shared_ptr<std::function<void(size_t, int)>> keepAlive;
    keepAlive = runner;
    (*runner)(0, 0);
}
