#include "SoundEngine.h"
#include "ClickController.h"
#include <QFile>
#include <QtEndian>
#include <cmath>
#include <vector>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <xaudio2.h>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

// XAudio2 lives on one thread for its whole life: setup, every play and teardown. The UI thread
// only queues requests, so a slow or missing audio device never stalls the interface.
class SoundOutput final : public IXAudio2EngineCallback {
  public:
    explicit SoundOutput(std::vector<QByteArray> clips) : m_clips(std::move(clips)) {
        m_thread = std::thread([this] { run(); });
    }
    ~SoundOutput() {
        {
            std::lock_guard lock(m_mutex);
            m_quit = true;
        }
        m_wake.notify_one();
        m_thread.join();
    }
    void play(int clip, float gain) {
        {
            std::lock_guard lock(m_mutex);
            m_queue.push_back({clip, gain, Clock::now()});
        }
        m_wake.notify_one();
    }
    // Called on the XAudio2 thread. A lost or switched device is reopened on the next cue.
    void STDMETHODCALLTYPE OnProcessingPassStart() override {}
    void STDMETHODCALLTYPE OnProcessingPassEnd() override {}
    void STDMETHODCALLTYPE OnCriticalError(HRESULT) override { m_lost = true; }

  private:
    using Clock = std::chrono::steady_clock;
    struct Request {
        int clip;
        float gain;
        Clock::time_point at;
    };
    static constexpr int Voices = 8;
    // A late sound is worse than none: requests that waited this long are dropped.
    static constexpr auto Stale = std::chrono::milliseconds(150);

    void run() {
        const HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
        open();
        std::unique_lock lock(m_mutex);
        for (;;) {
            m_wake.wait(lock, [this] { return m_quit || !m_queue.empty(); });
            if (m_quit)
                break;
            std::deque<Request> batch;
            batch.swap(m_queue);
            lock.unlock();
            for (const Request &request : batch) {
                if (Clock::now() - request.at > Stale)
                    continue;
                if ((!m_xaudio || m_lost) && Clock::now() - m_opened > std::chrono::seconds(2)) {
                    close();
                    open();
                }
                if (m_xaudio && !m_lost && Clock::now() - request.at <= Stale)
                    start(request);
            }
            lock.lock();
        }
        lock.unlock();
        close();
        if (m_dll)
            FreeLibrary(m_dll);
        if (SUCCEEDED(com))
            CoUninitialize();
    }
    // With no output device Windows fails CreateMasteringVoice, but Wine's XAudio2 crashes in it
    // (divide by zero), so ask MMDevAPI first.
    static bool hasOutputDevice() {
        static const CLSID enumeratorClass = {0xBCDE0395, 0xE52F, 0x467C, {0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E}};
        static const IID enumeratorInterface = {0xA95664D2, 0x9614, 0x4F35, {0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6}};
        IMMDeviceEnumerator *devices = nullptr;
        if (FAILED(CoCreateInstance(enumeratorClass, nullptr, CLSCTX_ALL, enumeratorInterface,
                                    reinterpret_cast<void **>(&devices))))
            return false;
        IMMDevice *device = nullptr;
        const bool found = SUCCEEDED(devices->GetDefaultAudioEndpoint(eRender, eConsole, &device)) && device;
        if (device)
            device->Release();
        devices->Release();
        return found;
    }
    bool open() {
        m_opened = Clock::now();
        m_lost = false;
        if (!hasOutputDevice())
            return false;
        // xaudio2_9 ships with Windows 10 and 11; load it from System32 only.
        if (!m_dll)
            m_dll = LoadLibraryExW(L"xaudio2_9.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
        if (!m_dll)
            return false;
        using Create = HRESULT(WINAPI *)(IXAudio2 **, UINT32, XAUDIO2_PROCESSOR);
        const auto create = reinterpret_cast<Create>(reinterpret_cast<void *>(GetProcAddress(m_dll, "XAudio2Create")));
        if (!create || FAILED(create(&m_xaudio, 0, XAUDIO2_DEFAULT_PROCESSOR))) {
            m_xaudio = nullptr;
            return false;
        }
        m_xaudio->RegisterForCallbacks(this);
        if (FAILED(m_xaudio->CreateMasteringVoice(&m_master, XAUDIO2_DEFAULT_CHANNELS, XAUDIO2_DEFAULT_SAMPLERATE, 0,
                                                  nullptr, nullptr, AudioCategory_SoundEffects))) {
            close();
            return false;
        }
        WAVEFORMATEX format{};
        format.wFormatTag = WAVE_FORMAT_PCM;
        format.nChannels = 1;
        format.nSamplesPerSec = 48000;
        format.wBitsPerSample = 16;
        format.nBlockAlign = 2;
        format.nAvgBytesPerSec = 96000;
        // Voices start once and idle on an empty queue; a submitted buffer plays at once.
        for (auto &voice : m_voices) {
            if (FAILED(m_xaudio->CreateSourceVoice(&voice, &format, XAUDIO2_VOICE_NOPITCH)) || FAILED(voice->Start(0))) {
                close();
                return false;
            }
        }
        return true;
    }
    void close() {
        for (auto &voice : m_voices) {
            if (voice)
                voice->DestroyVoice();
            voice = nullptr;
        }
        if (m_master)
            m_master->DestroyVoice();
        m_master = nullptr;
        if (m_xaudio) {
            m_xaudio->UnregisterForCallbacks(this);
            m_xaudio->Release();
        }
        m_xaudio = nullptr;
    }
    void start(const Request &request) {
        if (request.clip < 0 || request.clip >= int(m_clips.size()) || m_clips[request.clip].isEmpty())
            return;
        const QByteArray &clip = m_clips[request.clip];
        for (auto *voice : m_voices) {
            XAUDIO2_VOICE_STATE state{};
            voice->GetState(&state, XAUDIO2_VOICE_NOSAMPLESPLAYED);
            if (state.BuffersQueued)
                continue;
            XAUDIO2_BUFFER buffer{};
            buffer.Flags = XAUDIO2_END_OF_STREAM;
            buffer.AudioBytes = UINT32(clip.size());
            buffer.pAudioData = reinterpret_cast<const BYTE *>(clip.constData());
            voice->SetVolume(request.gain);
            voice->SubmitSourceBuffer(&buffer);
            return;
        }
    }

    const std::vector<QByteArray> m_clips;
    std::thread m_thread;
    std::mutex m_mutex;
    std::condition_variable m_wake;
    std::deque<Request> m_queue;
    bool m_quit = false;
    std::atomic<bool> m_lost{false};
    Clock::time_point m_opened{};
    HMODULE m_dll = nullptr;
    IXAudio2 *m_xaudio = nullptr;
    IXAudio2MasteringVoice *m_master = nullptr;
    IXAudio2SourceVoice *m_voices[Voices] = {};
};
#else
class SoundOutput {
  public:
    void play(int, float) {}
};
#endif

SoundEngine::SoundEngine(QObject *parent) : QObject(parent) {
    m_clock.start();
    std::vector<QByteArray> clips;
    for (const QString &cue : cues()) {
        m_index.insert(cue, int(clips.size()));
        QFile file(":/qt/qml/FakeClicker/assets/sounds/" + cue + ".wav");
        clips.push_back(file.open(QIODevice::ReadOnly) ? pcm(file.readAll()) : QByteArray());
    }
    // QA: FAKECLICKER_SOUND_LOG=<file> records every cue with its time since start.
    if (const QString path = qEnvironmentVariable("FAKECLICKER_SOUND_LOG"); !path.isEmpty()) {
        m_log = std::make_unique<QFile>(path);
        if (!m_log->open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
            m_log.reset();
    }
#ifdef Q_OS_WIN
    m_output = std::make_unique<SoundOutput>(std::move(clips));
#endif
}

SoundEngine::~SoundEngine() = default;

const QStringList &SoundEngine::cues() {
    static const QStringList list = {"tap",  "select", "switchOn", "switchOff", "step",   "count", "start",
                                     "stop", "done",   "confirm",  "remove",    "error",  "jaw",   "jaw2"};
    return list;
}

QByteArray SoundEngine::pcm(const QByteArray &wav) {
    if (wav.size() < 12 || !wav.startsWith("RIFF") || wav.mid(8, 4) != "WAVE")
        return {};
    bool supported = false;
    for (qsizetype at = 12; at + 8 <= wav.size();) {
        const QByteArray id = wav.mid(at, 4);
        const quint32 size = qFromLittleEndian<quint32>(wav.constData() + at + 4);
        const qsizetype body = at + 8;
        if (body + qsizetype(size) > wav.size())
            return {};
        if (id == "fmt ") {
            const char *f = wav.constData() + body;
            supported = size >= 16 && qFromLittleEndian<quint16>(f) == 1 && qFromLittleEndian<quint16>(f + 2) == 1 &&
                        qFromLittleEndian<quint32>(f + 4) == 48000 && qFromLittleEndian<quint16>(f + 14) == 16;
        } else if (id == "data") {
            return supported && size % 2 == 0 ? wav.mid(body, size) : QByteArray();
        }
        at = body + size + (size & 1);
    }
    return {};
}

QStringList SoundEngine::sessionCues(const Session &before, const Session &now) {
    if (!now.error.isEmpty() && now.error != before.error)
        return {"error"};
    if (now.state == "arming") {
        const bool tick = before.state != "arming" || now.countdown < before.countdown;
        return tick && now.countdown > 0 ? QStringList{"count"} : QStringList{};
    }
    if (now.state == "running" && before.state != "running" && before.state != "stopping")
        return {"start"};
    if (now.state == "stopping" && before.state != "stopping")
        return {"stop"};
    if (now.state == "idle" && before.state == "arming")
        return {"stop"}; // cancelled during the countdown
    if (now.state == "idle" && before.state == "running")
        return {"done"}; // ended on its own: a time or click limit
    return {};
}

void SoundEngine::setEnabled(bool on) {
    if (m_enabled == on)
        return;
    m_enabled = on;
    emit changed();
}

void SoundEngine::setVolume(int percent) {
    percent = qBound(0, percent, 100);
    if (m_volume == percent)
        return;
    m_volume = percent;
    emit changed();
}

void SoundEngine::play(const QString &cue) {
    if (m_enabled)
        preview(cue);
}

void SoundEngine::preview(const QString &cue) {
    const auto it = m_index.constFind(cue);
    if (it == m_index.cend() || m_volume <= 0)
        return;
    const qint64 now = m_clock.elapsed();
    // One gesture, one sound: the same cue again within 80 ms is the same event (a held stepper
    // repeats every 100 ms and still ticks).
    if (cue == m_lastCue && now - m_lastAt < 80)
        return;
    m_lastCue = cue;
    m_lastAt = now;
    if (m_log) {
        m_log->write(QByteArray::number(now) + '\t' + cue.toUtf8() + '\n');
        m_log->flush();
    }
    if (m_output)
        m_output->play(*it, float(std::pow(m_volume / 100.0, 1.5)));
    emit played(cue);
}

void SoundEngine::follow(ClickController *engine) {
    m_session = {engine->state(), engine->countdown(), engine->error()};
    connect(engine, &ClickController::changed, this, [this, engine] {
        const Session now{engine->state(), engine->countdown(), engine->error()};
        for (const QString &cue : sessionCues(m_session, now))
            play(cue);
        m_session = now;
    });
}
