#pragma once
#include <QFuture>
#include <QObject>
class StartupController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(int progress READ progress NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool done READ done NOTIFY changed)
  public:
    explicit StartupController(QObject *parent = nullptr);
    ~StartupController() override;
    int progress() const { return m_progress; }
    QString error() const { return m_error; }
    bool done() const { return m_done; }
    Q_INVOKABLE void start();
  signals:
    void changed();

  private:
    QFuture<void> m_task;
    int m_progress = 0;
    QString m_error;
    bool m_done = false, m_running = false;
};
