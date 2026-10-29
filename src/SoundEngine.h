#pragma once
#include <QByteArray>
#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QStringList>
#include <memory>
class ClickController;
class QFile;
class SoundOutput;

// Interface sounds: short WAV cues bundled in the QML module (assets/sounds, rendered by
// scripts/render-sounds.py). play() never blocks: Windows mixes the cues through XAudio2 on its
// own thread; other platforms stay silent, like the clicker itself.
class SoundEngine final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY changed)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY changed)
  public:
    // One clicker update, as far as sounds care.
    struct Session {
        QString state = "idle";
        int countdown = 0;
        QString error;
    };
    explicit SoundEngine(QObject *parent = nullptr);
    ~SoundEngine() override;
    static const QStringList &cues();
    // The samples of a 16-bit mono 48 kHz PCM WAV file; empty for anything else.
    static QByteArray pcm(const QByteArray &wav);
    // Cues for one clicker update: countdown ticks, start, stop, finish on a limit, errors.
    static QStringList sessionCues(const Session &before, const Session &now);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool on);
    int volume() const { return m_volume; }
    void setVolume(int percent);
    // preview() plays even while sounds are off, so the switch that turns them off still clicks.
    Q_INVOKABLE void play(const QString &cue);
    Q_INVOKABLE void preview(const QString &cue);
    void follow(ClickController *engine);
  signals:
    void changed();
    void played(const QString &cue);

  private:
    bool m_enabled = true;
    int m_volume = 70;
    QHash<QString, int> m_index;
    std::unique_ptr<SoundOutput> m_output;
    Session m_session;
    QElapsedTimer m_clock;
    QString m_lastCue;
    qint64 m_lastAt = -1000;
    std::unique_ptr<QFile> m_log;
};
