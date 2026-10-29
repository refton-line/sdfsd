#pragma once
#include <QString>
class QSettings;

// Where Fake Clicker keeps its data: one folder holding FakeClicker.ini (all settings, plain INI)
// and configs/ (profiles as JSON) — %APPDATA%\FakeClicker on Windows, ~/.config/FakeClicker on Linux.
namespace Storage {
QString root();
QString profiles();
// Points every default QSettings (C++ and QML Settings) at the INI file in root(), and on the
// first start copies the data of builds that stored it as "ObsidianClick". Call after the
// application name is set and before any QSettings is used.
void install();
struct Copied {
    int keys = 0;
    int profiles = 0;
};
// Copies the keys `to` does not have yet and every *.json profile not already present; the
// source is never changed.
Copied migrate(QSettings &from, const QString &fromProfiles, QSettings &to, const QString &toProfiles);
} // namespace Storage
