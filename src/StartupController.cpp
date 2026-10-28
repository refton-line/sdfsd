#include "StartupController.h"
#include <QDir>
#include <QElapsedTimer>
#include <QStandardPaths>
#include <QtConcurrent>
#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif
StartupController::StartupController(QObject *p) : QObject(p) {}
StartupController::~StartupController() { m_task.waitForFinished(); }
void StartupController::start() {
    if (m_running || m_done)
        return;
    m_running = true;
    m_error.clear();
    m_progress = 0;
    emit changed();
    m_task = QtConcurrent::run([this] {
        // Errors are message codes; the UI owns the wording in both languages.
        auto report = [this](int percent, const QString &error = {}, bool final = false) {
            QMetaObject::invokeMethod(
                this,
                [this, percent, error, final] {
                    m_progress = percent;
                    m_error = error;
                    if (final || !error.isEmpty())
                        m_running = false;
                    m_done = final;
                    emit changed();
                },
                Qt::QueuedConnection);
        };
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
        if (dir.isEmpty() || !QDir().mkpath(dir) || !QDir().mkpath(dir + "/configs")) {
            report(0, "settingsFolder");
            return;
        }
        report(50);
#ifdef Q_OS_WIN
        LARGE_INTEGER frequency;
        if (!QueryPerformanceFrequency(&frequency) || frequency.QuadPart <= 0) {
            report(50, "noCounter");
            return;
        }
#else
        if (!QElapsedTimer::isMonotonic()) {
            report(50, "noCounter");
            return;
        }
#endif
        report(100, {}, true);
    });
}
