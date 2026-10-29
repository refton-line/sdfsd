#include "CaptureHarness.h"
#include "ClickController.h"
#include "ConfigStore.h"
#include <QDir>
#include <QDebug>
#include <QGuiApplication>
#include <QImage>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QQuickWindow>
#include <QTimer>
#include <QQmlProperty>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QColor>
#include <cmath>
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
    // Real-time bursts (not paced) catch the loading bite part-way.
    const int motion = qMax(1, qEnvironmentVariableIntValue("FAKECLICKER_MOTION_SCALE"));
    auto burst = [=](const QString &name, std::initializer_list<int> times) {
        for (int ms : times)
            QTimer::singleShot(ms * motion, win, [=] { shot(name + "-" + QString::number(ms)); });
    };
    // Xvfb has no window manager, so the main window never becomes active and the passive
    // overlay would take the island over during runs. Pin it off; the overlay step shows it.
    if (auto *overlay = win->findChild<QQuickWindow *>("islandOverlay"))
        QQmlProperty::write(overlay, "wanted", false);
    // Grabs block the GUI thread on software GL: only burst the launch when it is slowed down.
    if (motion > 1) {
        add(1, [=] { burst("01-splash", {60, 160, 230, 290, 340, 420, 500, 560, 640, 760, 900, 1100, 1300}); });
    } else {
        add(150, [=] { shot("01-splash"); });
        add(330, [=] { shot("02-splash-loading"); });
    }
    add(2400, [=] { shot("03-clicker"); });
    add(2500, [=] { island(true); });
    add(3300, [=] { shot("04-island-expanded"); });
    add(3400, [=] { island(false); engine->setMode(1); });
    add(3750, [=] { shot("05-island-mode-notice"); });
    add(5700, [=] { engine->setCps(2500); });
    add(6050, [=] { shot("06-island-rate-notice"); });
    add(8000, [=] { shot("07-clicker-blatant"); });
    add(8100, [=] { engine->presentForCapture("arming", 0, -1, 3); });
    add(9000, [=] { shot("08-arming"); });
    add(9100, [=] { engine->presentForCapture("running", 18420, 2493.7, 0); });
    for (int i = 0; i < 20; ++i)
        add(9200 + i * 100, [=] { engine->presentForCapture("running", 18420 + i * 250, 2440 + (i * 37 % 110), 0); });
    add(11300, [=] { shot("09-running"); });
    add(11400, [=] { island(true); });
    add(12200, [=] { shot("10-island-expanded-running"); });
    add(12300, [=] { island(false); engine->presentForCapture("idle", 24420, 2488.2, 0); });
    add(12900, [=] { shot("11-island-summary"); });
    add(15600, [=] { engine->presentForCapture("idle", 24420, 2488.2, 0, "focusLost"); });
    add(16200, [=] { shot("12-error"); });
    add(16300, [=] { engine->dismissError(); page(1); });
    add(17200, [=] { shot("13-hotkeys"); });
    add(17300, [=] {
        if (auto *picker = findObject(win, "keyboardPicker"))
            QMetaObject::invokeMethod(picker, "edit", Q_ARG(QVariant, 0), Q_ARG(QVariant, 0));
    });
    add(18300, [=] { shot("14-keyboard"); });
    add(18400, [=] { popup("keyboardPicker", "close"); });
    add(18900, [=] {
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
    add(21200, [=] { shot("15-profiles"); });
    add(21300, [=] { popup("configNameDialog", "open"); });
    add(22100, [=] { shot("16-profile-sheet"); });
    add(22200, [=] { popup("configNameDialog", "close"); page(3); });
    add(23100, [=] { shot("17-settings"); });
    add(23200, [=] { call("setIslandOverlay", false); });
    add(23550, [=] { shot("18-island-overlay-off"); });
    add(25500, [=] { call("setIslandOverlay", true); });
    add(25850, [=] { shot("19-island-overlay-on"); });
    add(27800, [=] { call("setLanguage", "ru"); });
    add(28800, [=] { shot("20-settings-ru"); });
    add(28900, [=] { page(0); });
    add(29800, [=] { shot("21-clicker-ru"); });
    add(29900, [=] { page(1); });
    add(30800, [=] { shot("22-hotkeys-ru"); });
    add(30900, [=] { page(2); });
    add(31800, [=] { shot("23-profiles-ru"); });
    add(31900, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>()) {
            engine->presentForCapture("running", 3120, 14.6, 0);
            QQmlProperty::write(overlay, "wanted", true);
        }
    });
    add(33000, [=] {
        if (auto *overlay = win->findChild<QQuickWindow *>()) {
            overlay->grabWindow().save(output + "/24-overlay-island.png");
            QQmlProperty::write(overlay, "wanted", false);
        }
    });
    add(33100, [=] {
        engine->presentForCapture("idle", 3120, 14.6, 0);
        call("setLanguage", "en");
    });
    add(34000, [=] {
        page(0);
        if (auto *sheet = findObject(win, "windowSheet"))
            QMetaObject::invokeMethod(sheet, "choose");
    });
    add(35200, [=] { shot("25-window-picker"); });
    add(35300, [=] {
        engine->setTarget("1001", "osu!");
        if (auto *sheet = findObject(win, "windowSheet"))
            QMetaObject::invokeMethod(sheet, "close");
    });
    add(35700, [=] { shot("26-island-target-notice"); });
    add(37600, [=] { shot("27-target-chosen"); });
    add(37700, [=] { island(true); });
    add(38500, [=] { shot("28-island-expanded"); });
    // Island notice gallery: every setting change shows what changed and its new value.
    add(38600, [=] { island(false); engine->setMouseButton(1); });
    add(38950, [=] { shot("29-notice-button"); });
    add(40900, [=] { engine->setDurationSec(60); });
    add(41250, [=] { shot("30-notice-time-limit"); });
    add(43200, [=] { engine->setCountLimit(5000); });
    add(43550, [=] { shot("31-notice-click-limit"); });
    add(45500, [=] { engine->setLaunchDelaySec(5); });
    add(45850, [=] { shot("32-notice-countdown"); });
    add(47800, [=] { engine->setHoldMs(12); });
    add(48150, [=] { shot("33-notice-hold"); });
    add(50100, [=] { engine->applyBindingSlot(false, 0, 118, 0); });
    add(50450, [=] { shot("34-notice-start-key"); });
    add(52400, [=] { engine->setMode(0); });
    add(52750, [=] { shot("35-notice-mode-legit"); });
    add(54700, [=] { configs->saveNew("Ranked 14"); });
    add(55050, [=] { shot("36-notice-profile-saved"); });
    add(57000, [=] { call("setSounds", false); });
    add(57350, [=] { shot("37-notice-sounds-off"); });
    add(59300, [=] { call("setSounds", true); });
    add(61200, [=] { call("setSoundVolume", 40); });
    add(61550, [=] { shot("38-notice-volume"); });
    add(63500, [=] {
        call("setSoundVolume", 70);
        engine->applyBindingSlot(false, 0, 117, 0);
        engine->setMouseButton(0);
        engine->setDurationSec(0);
        engine->setCountLimit(0);
        engine->resetLaunchDelay();
        engine->setTarget("", "");
    });
    add(66000, [=] {
        win->close();
        burst("99-closing", {40, 90, 140});
    });

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


// Deterministic UI-only regression tour: no SendInput, real event loop and real rendered frames.
// Each step is relative to the previous grab so a slow software GPU cannot bunch the checks.
void runUiRegressionHarness(QQuickWindow *win, const QString &output, ClickController *engine) {
    QDir().mkpath(output);
    engine->enableForCapture();
    auto *overlay = win->findChild<QQuickWindow *>("islandOverlay");
    auto *mainIsland = find(win->contentItem(), "island");
    auto *overlayIsland = overlay ? find(overlay->contentItem(), "overlayIsland") : nullptr;
    if (!overlay || !mainIsland || !overlayIsland)
        qFatal("UI_REGRESSION: island objects missing");
    QQmlProperty::write(overlay, "wanted", false);
    auto check = [](bool ok, const char *label) {
        if (!ok) qFatal("UI_REGRESSION_FAIL: %s", label);
        qInfo("UI_REGRESSION_PASS: %s", label);
    };
    auto shot = [=](QQuickWindow *window, const QString &name) {
        const auto image = window->grabWindow();
        if (image.isNull() || !image.save(output + "/" + name + ".png"))
            qFatal("UI_REGRESSION: screenshot failed: %s", qPrintable(name));
    };
    struct Task { int delay; std::function<void()> run; };
    auto tasks = std::make_shared<std::vector<Task>>();
    auto add = [=](int delay, std::function<void()> run) { tasks->push_back({delay, std::move(run)}); };
    add(3800, [=] {
        check(win->property("launched").toBool(), "launch completed");
        win->setProperty("currentPage", 1);
    });
    add(700, [=] {
        auto *glyph = find(win->contentItem(), "stopGlyph");
        check(glyph != nullptr, "Stop uses the CPU SVG raster, not GPU curve arcs");
        shot(win, "01-hotkeys-stop");
        mainIsland->setProperty("pinned", true);
    });
    add(450, [=] { shot(win, "02-expanded-start"); engine->presentForCapture("running", 120, 12, 0); });
    add(400, [=] { shot(win, "03-expanded-stop"); mainIsland->setProperty("pinned", false); });
    for (int i = 0; i < 4; ++i)
        add(i == 0 ? 25 : 55, [=] { shot(win, "04-collapse-" + QString::number(i)); });
    add(250, [=] {
        QQmlProperty::write(overlay, "wanted", true);
        check(!mainIsland->isVisible(), "only overlay island is visible during handoff");
        check(!mainIsland->property("presentsEvents").toBool(), "main island does not consume overlay events");
        check(overlayIsland->property("presentsEvents").toBool(), "overlay owns transient events");
    });
    add(300, [=] { shot(overlay, "05-overlay-live"); shot(win, "06-main-without-duplicate"); });
    add(80, [=] { engine->presentForCapture("idle", 120, 12, 0, "focusLost"); });
    for (int i = 0; i < 4; ++i)
        add(i == 0 ? 30 : 60, [=] { shot(overlay, "07-overlay-error-transition-" + QString::number(i)); });
    add(150, [=] {
        check(!overlayIsland->property("errorText").toString().isEmpty(), "error is delivered to overlay");
        check(mainIsland->property("errorText").toString().isEmpty(), "error is not duplicated in main island");
        shot(overlay, "08-overlay-error");
        QQmlProperty::write(overlay, "wanted", false);
    });
    add(250, [=] {
        check(!overlay->isVisible() && mainIsland->isVisible(), "handoff hides native overlay immediately");
        check(mainIsland->property("errorText").toString().isEmpty(), "restoring main does not replay an overlay error");
        check(overlayIsland->property("errorText").toString().isEmpty(), "inactive presenter clears transient state");
        shot(win, "09-return-no-stale-error");
        engine->presentForCapture("running", 150, 12, 0);
        QQmlProperty::write(overlay, "wanted", true);
        win->showMinimized();
    });
    auto clock = std::make_shared<double>(0);
    add(350, [=] { *clock = overlayIsland->property("clock").toDouble(); shot(overlay, "10-overlay-main-minimized"); });
    add(350, [=] {
        check(overlayIsland->property("clock").toDouble() > *clock + .1,
              "overlay animation keeps running with main minimized");
        shot(overlay, "11-overlay-independent-frame");
        win->showNormal();
        QQmlProperty::write(overlay, "wanted", false);
        engine->presentForCapture("idle", 150, 12, 0);
    });
    add(350, [=] { shot(win, "12-main-summary"); win->setProperty("currentPage", 0); });
    add(500, [=] { shot(win, "13-main-clicker"); });
    add(100, [=] {
        qInfo("UI_REGRESSION_ALL_PASS: Stop, transitions, exclusive presentation, error handoff, minimized animation");
        QCoreApplication::exit(0);
    });
    auto runner = std::make_shared<std::function<void(size_t)>>();
    std::weak_ptr<std::function<void(size_t)>> weak = runner;
    *runner = [=](size_t i) {
        if (i >= tasks->size()) return;
        const auto task = tasks->at(i);
        QTimer::singleShot(task.delay, win, [=] {
            task.run();
            if (auto next = weak.lock()) (*next)(i + 1);
        });
    };
    // Keep the runner alive only until the tour/application ends.
    QTimer::singleShot(0, win, [runner] { (*runner)(0); });
    QObject::connect(qApp, &QCoreApplication::aboutToQuit, qApp, [runner] {});
}


// Small-text stress tour at the caller's QT_SCALE_FACTOR. Never invokes the click worker.
void runTextRegressionHarness(QQuickWindow *win, const QString &output, ClickController *engine) {
    QDir().mkpath(output);
    engine->enableForCapture();
    auto *overlay = win->findChild<QQuickWindow *>("islandOverlay");
    auto *island = find(win->contentItem(), "island");
    auto *detached = overlay ? find(overlay->contentItem(), "overlayIsland") : nullptr;
    if (!overlay || !island || !detached) qFatal("TEXT_REGRESSION: missing islands");
    QQmlProperty::write(overlay, "wanted", false);
    auto check = [](bool ok, const char *label) {
        if (!ok) qFatal("TEXT_REGRESSION_FAIL: %s", label);
        qInfo("TEXT_REGRESSION_PASS: %s", label);
    };
    auto report = std::make_shared<QJsonArray>();
    auto clear = [](QObject *item) { QMetaObject::invokeMethod(item, "clearTransient"); };
    auto shot = [=](QQuickWindow *window, QQuickItem *root, const QString &name) {
        const auto image = window->grabWindow();
        if (image.isNull() || !image.save(output + "/" + name + ".png"))
            qFatal("TEXT_REGRESSION: grab failed");
        const double dpr = window->devicePixelRatio();
        check(std::abs(root->property("pixelRatio").toDouble() - dpr) < .001, "QML pixel ratio matches window");
        check(std::abs(root->width() * dpr - std::round(root->width() * dpr)) < .01, "capsule width snaps to physical pixels");
        check(std::abs(root->x() * dpr - std::round(root->x() * dpr)) < .01, "capsule origin snaps to physical pixels");
        QJsonArray labels;
        // Visual parenting can differ from QObject ownership for inline QML components.
        std::vector<QQuickItem *> visualItems;
        std::function<void(QQuickItem *)> collect = [&](QQuickItem *item) {
            for (auto *child : item->childItems()) { visualItems.push_back(child); collect(child); }
        };
        collect(root);
        for (auto *text : visualItems) {
            QObject *obj = text;
            if (!text || !text->isVisible() || !obj->property("renderType").isValid()
                    || obj->property("text").toString().isEmpty()) continue;
            check(obj->property("renderType").toInt() == 1, "visible text uses native grayscale rasterisation");
            const auto bounds = text->mapRectToItem(root, text->boundingRect());
            const bool contained = bounds.left() >= -1 && bounds.right() <= root->width() + 1 &&
                                   bounds.top() >= -1 && bounds.bottom() <= root->height() + 1;
            if (!contained) qWarning() << "TEXT_BOUNDS" << name << obj->property("text").toString() << bounds << root->size();
            check(contained, "text geometry stays inside capsule");
            const auto scene = text->mapRectToScene(text->boundingRect());
            const QColor color = obj->property("color").value<QColor>();
            labels.append(QJsonObject{{"text", obj->property("text").toString()},
                {"x",scene.x()*dpr},{"y",scene.y()*dpr},{"width",scene.width()*dpr},{"height",scene.height()*dpr},
                {"neutral",std::abs(color.red()-color.green())<=3 && std::abs(color.red()-color.blue())<=3}});
        }
        report->append(QJsonObject{{"file",name+".png"},{"dpr",dpr},{"overlay",window==overlay},{"labels",labels}});
        qInfo("TEXT_CAPTURE: %s",qPrintable(name));
    };
    struct Step { int delay; std::function<void()> run; };
    auto steps=std::make_shared<std::vector<Step>>();
    auto add=[=](int delay,std::function<void()> run) { steps->push_back({delay,std::move(run)}); };
    add(3800,[=] { clear(island); engine->presentForCapture("idle",0,-1,0); });
    add(350,[=] { shot(win,island,"01-idle-en"); engine->presentForCapture("arming",0,-1,3); });
    add(350,[=] { shot(win,island,"02-arming-en"); engine->presentForCapture("running",120,12.34,0); });
    add(350,[=] { shot(win,island,"03-live-decimals"); engine->presentForCapture("running",125,12.35,0); });
    add(200,[=] { shot(win,island,"04-live-next-sample"); island->setProperty("pinned",true); engine->presentForCapture("running",1000000000000ULL,987654321.23,0); });
    add(450,[=] {
        auto *value=find(win->contentItem(),"islandBigValue");
        check(value && value->property("contentWidth").toReal() <= value->width()+1,"huge CPS fits before waveform/action");
        shot(win,island,"05-expanded-huge-rate");
        island->setProperty("pinned",false);
        engine->presentForCapture("idle",1000000000000ULL,987654321.23,0);
    });
    add(450,[=] { shot(win,island,"06-summary-huge-count"); clear(island);
        QMetaObject::invokeMethod(island,"showError",Q_ARG(QVariant,QString("Stopped: a long diagnostic message checks wrapping without text outside the capsule"))); });
    add(350,[=] { shot(win,island,"07-long-error-en"); clear(island);
        QMetaObject::invokeMethod(island,"notify",Q_ARG(QVariant,QString("check")),Q_ARG(QVariant,QString("Long profile name — 0123456789 — without overlapping the capsule edge")),Q_ARG(QVariant,QColor("#f5f5f7"))); });
    add(350,[=] { shot(win,island,"08-long-notice-en"); clear(island);
        QMetaObject::invokeMethod(win,"setLanguage",Q_ARG(QVariant,QString("ru"))); });
    add(850,[=] { clear(island); engine->presentForCapture("running",120,12.34,0); });
    add(350,[=] { shot(win,island,"09-live-ru"); QQmlProperty::write(overlay,"wanted",true); });
    add(350,[=] { shot(overlay,detached,"10-overlay-ru-a"); });
    add(350,[=] { shot(overlay,detached,"11-overlay-ru-b"); engine->presentForCapture("idle",120,12.34,0,"focusLost"); });
    add(650,[=] { shot(overlay,detached,"12-overlay-error-ru"); QQmlProperty::write(overlay,"wanted",false); clear(island);
        engine->presentForCapture("idle",0,-1,0);
        win->setProperty("currentPage",3); });
    add(900,[=] { clear(island); shot(win,island,"13-idle-ru"); island->setProperty("pinned",true); });
    add(450,[=] { shot(win,island,"14-expanded-ru"); island->setProperty("pinned",false); clear(island);
        QMetaObject::invokeMethod(island,"inform",Q_ARG(QVariant,QString("play")),Q_ARG(QVariant,QString("Запуск")),
                                  Q_ARG(QVariant,QString("Ctrl + Shift + F6")),Q_ARG(QVariant,QString("key"))); });
    add(400,[=] { shot(win,island,"15-notice-key-ru"); clear(island);
        QMetaObject::invokeMethod(island,"inform",Q_ARG(QVariant,QString("overlayOff")),Q_ARG(QVariant,QString("Остров поверх окон")),
                                  Q_ARG(QVariant,QString("Выкл")),Q_ARG(QVariant,QString("off"))); });
    add(400,[=] { shot(win,island,"16-notice-off-ru");
        QFile file(output+"/text-bounds.json");
        if (!file.open(QIODevice::WriteOnly)) qFatal("TEXT_REGRESSION: report write failed");
        file.write(QJsonDocument(*report).toJson()); file.close();
        qInfo("TEXT_REGRESSION_ALL_PASS"); QCoreApplication::exit(0);
    });
    auto runner=std::make_shared<std::function<void(size_t)>>();
    std::weak_ptr<std::function<void(size_t)>> weak=runner;
    *runner=[=](size_t i) { if(i>=steps->size())return;const auto step=steps->at(i);
        QTimer::singleShot(step.delay,win,[=] { step.run();if(auto next=weak.lock())(*next)(i+1); }); };
    QTimer::singleShot(0,win,[runner] {(*runner)(0);});
    QObject::connect(qApp,&QCoreApplication::aboutToQuit,qApp,[runner]{});
}
