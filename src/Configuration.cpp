#include "Configuration.h"
#include <QJsonArray>
#include <QJsonValue>
#include <QMap>
#include <QSet>
#include <cmath>
namespace Configuration {
bool validKey(int k) {
    return (k >= 0x30 && k <= 0x39) || (k >= 0x41 && k <= 0x5a) || (k >= 0x60 && k <= 0x6f) ||
           (k >= 0x70 && k <= 0x87 && k != 0x7b) || (k >= 0xba && k <= 0xc0) ||
           (k >= 0xdb && k <= 0xde) || (k >= 160 && k <= 165) ||
           QList<int>{8, 9, 13, 19, 20, 27, 32, 33, 34, 35, 36, 37, 38, 39, 40, 44, 45, 46, 144, 145}
               .contains(k);
}
bool validCps(double cps) { return std::isfinite(cps) && cps >= MinCps && cps <= MaxCps; }
QString bindingError(int k, int m, int t, int n) {
    if (!validKey(k) || !validKey(t) || m < 0 || m > 7 || n < 0 || n > 7)
        return "unsupportedKey";
    if (k == t && m == n)
        return "sameStartStop";
    for (auto b : {qMakePair(k, m), qMakePair(t, n)}) {
        if ((b.first == 46 && (b.second & 3) == 3) || (b.first == 9 && (b.second & 2)) ||
            (b.first == 27 && (b.second & 3)))
            return "reserved";
    }
    return {};
}
QList<KeyBinding> bindings(const ClickConfig &c, bool stop) {
    auto list = stop ? c.stopExtra : c.startExtra;
    list.prepend(stop ? KeyBinding{c.stopKey, c.stopMods, c.stopChord} : KeyBinding{c.startKey, c.startMods, c.startChord});
    return list;
}
QString validate(const ClickConfig &c) {
    if (c.mode < 0 || c.mode > 1 || c.variance < 0 || c.variance > 2 || !validCps(c.cps) ||
        c.duration < 0 || c.duration > MaxDurationSec || c.button < 0 || c.button > 2 ||
        c.hold < 0 || c.hold > MaxHoldMs || c.countLimit > MaxCountLimit || c.launchDelay < 1 ||
        c.launchDelay > 10)
        return "outOfRange";
    // A Blatant press must be released before the next slot; Legit derives hold per click.
    if (c.mode == int(ClickMode::Blatant) && c.hold > 0 && double(c.hold) * 1e6 >= 1e9 / c.cps)
        return "holdTooLong";
    if (c.startExtra.size() > 7 || c.stopExtra.size() > 7)
        return "tooManyBindings";
    QList<KeyBinding> used;
    for (bool stop : {false, true})
        for (const auto &binding : bindings(c, stop)) {
            const auto keys = chordKeys(binding);
            if (binding.keys.isEmpty()) {
                auto error = bindingError(binding.key, binding.mods, stop ? c.startKey : c.stopKey,
                                          stop ? c.startMods : c.stopMods);
                // Explicit opposite chords are validated independently below.
                if (!error.isEmpty() && (stop ? c.startChord : c.stopChord).isEmpty()) return error;
                if (!validKey(binding.key) || binding.mods < 0 || binding.mods > 7)
                    return "legacyBinding";
            } else if (keys.size() < 1 || keys.size() > 3) {
                return "chordSize";
            }
            QSet<int> unique;
            bool ctrl = false, alt = false, shift = false;
            for (int key : keys) {
                if ((!validChordKey(key) && !(binding.keys.isEmpty() && key >= 16 && key <= 18)) || unique.contains(key))
                    return "badKey";
                unique.insert(key);
                ctrl |= key == 17 || key == 162 || key == 163;
                alt |= key == 18 || key == 164 || key == 165;
                shift |= key == 16 || key == 160 || key == 161;
            }
            if ((ctrl && alt && unique.contains(46)) || (alt && unique.contains(9)) ||
                ((ctrl || alt) && unique.contains(27)) || (alt && unique.contains(115)) ||
                (ctrl && shift && unique.contains(27)))
                return "reserved";
            // Reject subset/side-generic overlaps: a smaller chord would fire before the larger one.
            auto covers = [](const QList<int> &a, const QList<int> &b) {
                for (int k : a) {
                    bool found = false;
                    for (int v : b)
                        found |= k == v || (k == 17 && (v == 162 || v == 163)) ||
                            (k == 18 && (v == 164 || v == 165)) || (k == 16 && (v == 160 || v == 161));
                    if (!found) return false;
                }
                return true;
            };
            for (const auto &other : used) {
                const auto previous = chordKeys(other);
                if (covers(keys, previous) || covers(previous, keys))
                    return "overlap";
            }
            used.append(binding);
        }
    return {};
}
namespace {
QJsonArray bindingArray(const QList<KeyBinding> &list) {
    QJsonArray a;
    for (const auto &b : list) {
        QJsonObject item{{"key", b.key}, {"mods", b.mods}};
        if (!b.keys.isEmpty()) {
            QJsonArray keys;
            for (int key : b.keys) keys.append(key);
            item["keys"] = keys;
        }
        a.append(item);
    }
    return a;
}
bool wholeNumber(const QJsonValue &v, double max) {
    return v.isDouble() && std::isfinite(v.toDouble()) && std::floor(v.toDouble()) == v.toDouble() &&
           v.toDouble() >= 0 && v.toDouble() <= max;
}
bool readKeys(const QJsonValue &value, QList<int> &keys, bool emptyAllowed) {
    if (!value.isArray() || value.toArray().size() > 3 || (!emptyAllowed && value.toArray().isEmpty())) return false;
    for (const auto &v : value.toArray()) {
        if (!v.isDouble() || v.toDouble() != v.toInt() || !validChordKey(v.toInt()) || keys.contains(v.toInt())) return false;
        keys.append(v.toInt());
    }
    return true;
}
// Shared by v2/v3 (legacy) and v4: launch delay, alternative bindings and optional explicit chords.
bool readBindings(const QJsonObject &o, bool chords, ClickConfig &c, QString &error) {
    const auto d = o["launchDelaySec"];
    if (!d.isDouble() || d.toDouble() != d.toInt() || d.toInt() < 1 || d.toInt() > 10) {
        error = "badDelay";
        return false;
    }
    c.launchDelay = d.toInt();
    for (bool stop : {false, true}) {
        const auto value = o[stop ? "stopExtra" : "startExtra"];
        if (!value.isArray() || value.toArray().size() > 7) {
            error = "badBindingList";
            return false;
        }
        auto &list = stop ? c.stopExtra : c.startExtra;
        for (auto entry : value.toArray()) {
            const auto b = entry.toObject();
            if (!entry.isObject() || (b.size() != 2 && b.size() != 3) || !b["key"].isDouble() ||
                !b["mods"].isDouble() || b["key"].toDouble() != b["key"].toInt() ||
                b["mods"].toDouble() != b["mods"].toInt()) {
                error = "badBinding";
                return false;
            }
            KeyBinding binding{b["key"].toInt(), b["mods"].toInt()};
            if (b.size() == 3 && (!chords || !readKeys(b["keys"], binding.keys, false))) {
                error = "badKeySet";
                return false;
            }
            list.append(binding);
        }
    }
    if (chords && (!readKeys(o["startChord"], c.startChord, true) || !readKeys(o["stopChord"], c.stopChord, true))) {
        error = "badKeySet";
        return false;
    }
    return true;
}
bool decodeLegacy(const QJsonObject &o, ClickConfig &c, QString &error) {
    const QStringList fields = {"intervalMs", "durationSec", "mouseButton", "holdMs",  "countLimit",
                                "startKey",   "startMods",   "stopKey",     "stopMods"};
    if (o.size() != fields.size() && o.size() != fields.size() + 3 && o.size() != fields.size() + 5) {
        error = "schema";
        return false;
    }
    QStringList allowed = fields;
    if (o.size() >= 12) allowed << "launchDelaySec" << "startExtra" << "stopExtra";
    if (o.size() == 14) allowed << "startChord" << "stopChord";
    for (const auto &key : o.keys())
        if (!allowed.contains(key)) {
            error = "unknownField:" + key;
            return false;
        }
    for (const auto &k : fields)
        if (!wholeNumber(o[k], 1000000000)) {
            error = "notInteger:" + k;
            return false;
        }
    const int interval = o["intervalMs"].toInt(), hold = o["holdMs"].toInt();
    // Earlier releases accepted 5–10000 ms with hold 0–100 ms shorter than the interval.
    if (interval < 5 || interval > 10000 || hold > 100 || hold >= interval) {
        error = "outOfRange";
        return false;
    }
    // Legacy profiles always clicked on an exact grid, which is Blatant mode now.
    c.mode = int(ClickMode::Blatant);
    c.cps = 1000.0 / interval;
    c.hold = hold;
    c.duration = o["durationSec"].toInt();
    c.button = o["mouseButton"].toInt();
    c.countLimit = quint64(o["countLimit"].toDouble());
    c.startKey = o["startKey"].toInt();
    c.startMods = o["startMods"].toInt();
    c.stopKey = o["stopKey"].toInt();
    c.stopMods = o["stopMods"].toInt();
    return o.size() < 12 || readBindings(o, o.size() == 14, c, error);
}
} // namespace
QJsonObject encode(const ClickConfig &c) {
    QJsonObject result{{"mode", c.mode == int(ClickMode::Blatant) ? "blatant" : "legit"},
                       {"cps", c.cps},
                       {"variance", c.variance},
                       {"holdMs", c.hold},
                       {"durationSec", c.duration},
                       {"mouseButton", c.button},
                       {"countLimit", double(c.countLimit)},
                       {"startKey", c.startKey},
                       {"startMods", c.startMods},
                       {"stopKey", c.stopKey},
                       {"stopMods", c.stopMods},
                       {"launchDelaySec", c.launchDelay},
                       {"startExtra", bindingArray(c.startExtra)},
                       {"stopExtra", bindingArray(c.stopExtra)}};
    bool explicitChord = !c.startChord.isEmpty() || !c.stopChord.isEmpty();
    for (const auto &b : c.startExtra + c.stopExtra) explicitChord |= !b.keys.isEmpty();
    if (explicitChord) {
        QJsonArray start, stop;
        for (int k : c.startChord) start.append(k);
        for (int k : c.stopChord) stop.append(k);
        result["startChord"] = start;
        result["stopChord"] = stop;
    }
    return result;
}
bool decode(const QJsonObject &o, ClickConfig &out, QString &error) {
    ClickConfig c;
    c.startExtra.clear();
    c.stopExtra.clear();
    if (o.contains("intervalMs")) {
        if (!decodeLegacy(o, c, error))
            return false;
    } else {
        static const QStringList fields = {"mode",       "cps",         "variance",  "holdMs",
                                           "durationSec", "mouseButton", "countLimit", "startKey",
                                           "startMods",  "stopKey",     "stopMods",  "launchDelaySec",
                                           "startExtra", "stopExtra"};
        const bool chords = o.contains("startChord") || o.contains("stopChord");
        if (o.size() != fields.size() + (chords ? 2 : 0)) {
            error = "schema";
            return false;
        }
        for (const auto &key : o.keys())
            if (!fields.contains(key) && key != "startChord" && key != "stopChord") {
                error = "unknownField:" + key;
                return false;
            }
        const auto mode = o["mode"].toString();
        if (!o["mode"].isString() || (mode != "legit" && mode != "blatant")) {
            error = "notInteger:mode";
            return false;
        }
        if (!o["cps"].isDouble() || !validCps(o["cps"].toDouble())) {
            error = "notNumber:cps";
            return false;
        }
        for (const auto &k : {"variance", "holdMs", "durationSec", "mouseButton", "countLimit",
                              "startKey", "startMods", "stopKey", "stopMods"})
            if (!wholeNumber(o[k], double(MaxCountLimit))) {
                error = QString("notInteger:") + k;
                return false;
            }
        c.mode = mode == "blatant" ? int(ClickMode::Blatant) : int(ClickMode::Legit);
        c.cps = o["cps"].toDouble();
        c.variance = qMin(o["variance"].toDouble(), 100.0);
        c.hold = qMin(o["holdMs"].toDouble(), 1e6);
        c.duration = qMin(o["durationSec"].toDouble(), 1e7);
        c.button = qMin(o["mouseButton"].toDouble(), 100.0);
        c.countLimit = quint64(o["countLimit"].toDouble());
        c.startKey = qMin(o["startKey"].toDouble(), 1e6);
        c.startMods = qMin(o["startMods"].toDouble(), 100.0);
        c.stopKey = qMin(o["stopKey"].toDouble(), 1e6);
        c.stopMods = qMin(o["stopMods"].toDouble(), 100.0);
        if (!readBindings(o, chords, c, error))
            return false;
    }
    error = validate(c);
    if (!error.isEmpty())
        return false;
    out = c;
    return true;
}
QString keyName(int k) {
    if (k >= 0x70 && k <= 0x87)
        return "F" + QString::number(k - 0x6f);
    if (k >= 0x30 && k <= 0x5a)
        return QString(QChar(k));
    if (k >= 0x60 && k <= 0x69)
        return "Num " + QString::number(k - 0x60);
    const QMap<int, QString> names = {{16, "Shift"}, {17, "Ctrl"}, {18, "Alt"},
                                      {160, "Shift L"}, {161, "Shift R"}, {162, "Ctrl L"}, {163, "Ctrl R"},
                                      {164, "Alt L"}, {165, "Alt R"}, {269, "Num Enter"}, {226, "ISO"},
                                      {8, "Backspace"},
                                      {9, "Tab"},
                                      {13, "Enter"},
                                      {19, "Pause"},
                                      {20, "Caps Lock"},
                                      {27, "Esc"},
                                      {32, "Space"},
                                      {33, "Page Up"},
                                      {34, "Page Down"},
                                      {35, "End"},
                                      {36, "Home"},
                                      {37, "←"},
                                      {38, "↑"},
                                      {39, "→"},
                                      {40, "↓"},
                                      {44, "PrintScreen"},
                                      {45, "Insert"},
                                      {46, "Delete"},
                                      {106, "Num *"},
                                      {107, "Num +"},
                                      {109, "Num −"},
                                      {108, "Num Separator"},
                                      {110, "Num ."},
                                      {111, "Num /"},
                                      {144, "Num Lock"},
                                      {145, "Scroll Lock"},
                                      {186, ";"},
                                      {187, "="},
                                      {188, ","},
                                      {189, "−"},
                                      {190, "."},
                                      {191, "/"},
                                      {192, "`"},
                                      {219, "["},
                                      {220, "\\"},
                                      {221, "]"},
                                      {222, "'"}};
    return names.value(k, "?");
}
bool validChordKey(int key) {
    return (validKey(key) && key != 144) || (key >= 160 && key <= 165) || key == 269 || key == 226 || key == 44;
}
QList<int> chordKeys(const KeyBinding &b) {
    if (!b.keys.isEmpty()) return b.keys;
    QList<int> keys;
    if (b.mods & 1) keys.append(17);
    if (b.mods & 2) keys.append(18);
    if (b.mods & 4) keys.append(16);
    keys.append(b.key);
    return keys;
}
bool chordMatches(const KeyBinding &b, const QSet<int> &held) {
    for (int key : chordKeys(b)) {
        if (held.contains(key)) continue;
        if (key == 17 && (held.contains(162) || held.contains(163))) continue;
        if (key == 18 && (held.contains(164) || held.contains(165))) continue;
        if (key == 16 && (held.contains(160) || held.contains(161))) continue;
        return false;
    }
    return true;
}
QString chordName(const KeyBinding &b) {
    QStringList names;
    for (int key : chordKeys(b)) names.append(keyName(key));
    return names.join(" · ");
}
QString shortcutName(int k, int m) { return chordName({k, m}); }
} // namespace Configuration
