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
        if (!win->grabWindow().save(output + "/" + name + ".png"))
            qFatal("capture failed: %s", qPrintable(name));
    };
    auto page = [win](int index) { win->setProperty("currentPage", index); };
    auto call = [win](const char *method, const QVariant &arg) {
        QMetaObject::invokeMethod(win, method, Q_ARG(QVariant, arg));
    };
    auto add = [steps](int at, std::function<void()> run) { steps->push_back({at, std::move(run)}); };

    engine->enableForCapture();
    add(260, [=] { shot("01-boot"); });
    add(1350, [=] { shot("02-launch"); });
    add(2600, [=] { shot("03-clicker-legit"); });
    add(2700, [=] { engine->setMode(1); });
    add(3050, [=] { shot("04-island-mode-notice"); });
    add(4800, [=] { shot("05-clicker-blatant"); });
    add(4900, [=] { engine->setCps(2500); });
    add(5700, [=] { shot("06-custom-cps"); });
    add(5800, [=] { engine->presentForCapture("arming", 0, -1, 3); });
    add(6500, [=] { shot("07-arming"); });
    add(6600, [=] { engine->presentForCapture("running", 18420, 2493.7, 0); });
    for (int i = 0; i < 24; ++i)
        add(6700 + i * 100, [=] { engine->presentForCapture("running", 18420 + i * 250, 2440 + (i * 37 % 110), 0); });
    add(9300, [=] { shot("08-running"); });
    add(9400, [=] {
        if (auto *island = findObject(win, "island"))
            island->setProperty("pinned", true);
    });
    add(10200, [=] { shot("09-island-expanded"); });
    add(10300, [=] { engine->presentForCapture("idle", 24420, 2488.2, 0); });
    add(11000, [=] { shot("10-island-summary"); });
    add(13600, [=] { engine->presentForCapture("idle", 24420, 2488.2, 0, "focusLost"); });
    add(14200, [=] { shot("11-error"); });
    add(14300, [=] { engine->dismissError(); page(1); });
    add(15200, [=] { shot("12-hotkeys"); });
    add(15300, [=] {
        if (auto *picker = findObject(win, "keyboardPicker"))
            QMetaObject::invokeMethod(picker, "edit", Q_ARG(QVariant, 0), Q_ARG(QVariant, 0));
    });
    add(16300, [=] { shot("13-keyboard"); });
    add(16400, [=] {
        if (auto *picker = findObject(win, "keyboardPicker"))
            QMetaObject::invokeMethod(picker, "close");
    });
    add(16900, [=] {
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
    add(18000, [=] { shot("14-profiles"); });
    add(18100, [=] { page(3); });
    add(19000, [=] { shot("15-appearance"); });
    add(19100, [=] { call("setMaterial", "solid"); });
    add(20200, [=] { shot("16-appearance-solid"); });
    add(20300, [=] { page(0); });
    add(21200, [=] { shot("17-clicker-solid"); });
    add(21300, [=] { call("setMaterial", "glass"); page(4); });
    add(22300, [=] { call("setLanguage", "ru"); });
    add(23300, [=] { shot("18-language-ru"); });
    add(23400, [=] { page(0); });
    add(23520, [=] { shot("19-page-transition"); });
    add(24400, [=] { shot("20-clicker-ru"); });
    add(24500, [=] { page(1); });
    add(25400, [=] { shot("21-hotkeys-ru"); });
    add(25500, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>()) {
            engine->presentForCapture("running", 3120, 14.6, 0);
            overlay->setProperty("wanted", true);
        }
    });
    add(26600, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>())
            overlay->grabWindow().save(output + "/22-overlay-island.png");
    });
    add(26700, [=] {
        engine->presentForCapture("idle", 3120, 14.6, 0);
        call("setLanguage", "en");
    });
    add(27700, [=] { win->close(); });
    add(27900, [=] { shot("23-closing"); });

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
