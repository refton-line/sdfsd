#pragma once
#include <QJsonObject>
#include <QList>
#include <QString>
#include <QSet>
struct KeyBinding {
    int key = 0, mods = 0;
    QList<int> keys = {};
    bool operator==(const KeyBinding &) const = default;
};
// Legit: humanised timing around the target rate. Blatant: exact fixed grid, batched when needed.
enum class ClickMode : int { Legit = 0, Blatant = 1 };
struct ClickConfig {
    int mode = int(ClickMode::Legit);
    double cps = 12;
    int variance = 1; // Legit only: 0 tight, 1 natural, 2 loose
    int duration = 0, button = 0, hold = 0; // hold: Blatant only, milliseconds
    int startKey = 0x75, startMods = 0, stopKey = 0x77, stopMods = 0;
    quint64 countLimit = 0;
    int launchDelay = 3;
    QList<KeyBinding> startExtra, stopExtra;
    QList<int> startChord, stopChord;
};
namespace Configuration {
// Highest accepted rate: one click per nanosecond. Anything slower is allowed; the engine
// batches when the requested rate outruns the system timer.
constexpr double MaxCps = 1e9;
constexpr double MinCps = 0.01;
constexpr int MaxDurationSec = 86400;
constexpr quint64 MaxCountLimit = 1000000000000ULL;
constexpr int MaxHoldMs = 1000;
QList<KeyBinding> bindings(const ClickConfig &, bool stop);
bool validKey(int key);
bool validChordKey(int key);
bool validCps(double cps);
QList<int> chordKeys(const KeyBinding &binding);
QString chordName(const KeyBinding &binding);
bool chordMatches(const KeyBinding &binding, const QSet<int> &held);
// Returned strings are message codes ("code" or "code:argument"), translated by the UI.
QString bindingError(int start, int sm, int stop, int tm);
QString validate(const ClickConfig &config);
QJsonObject encode(const ClickConfig &config);
bool decode(const QJsonObject &object, ClickConfig &out, QString &error);
QString keyName(int key);
QString shortcutName(int key, int mods);
} // namespace Configuration
