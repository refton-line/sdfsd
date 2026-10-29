#include "Storage.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>

namespace Storage {
QString root() {
    const QSettings ini(QSettings::IniFormat, QSettings::UserScope, QCoreApplication::organizationName(),
                        QCoreApplication::applicationName());
    return QFileInfo(ini.fileName()).absolutePath();
}

QString profiles() { return root() + "/configs"; }

Copied migrate(QSettings &from, const QString &fromProfiles, QSettings &to, const QString &toProfiles) {
    Copied copied;
    for (const QString &key : from.allKeys()) {
        if (to.contains(key))
            continue;
        to.setValue(key, from.value(key));
        ++copied.keys;
    }
    to.sync();
    const QDir source(fromProfiles);
    if (!source.exists() || !QDir().mkpath(toProfiles))
        return copied;
    for (const QFileInfo &file : source.entryInfoList({"*.json"}, QDir::Files)) {
        const QString target = QDir(toProfiles).filePath(file.fileName());
        if (file.isSymLink() || file.size() > 65536 || QFileInfo::exists(target))
            continue;
        if (QFile::copy(file.absoluteFilePath(), target))
            ++copied.profiles;
    }
    return copied;
}

void install() {
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings fresh;
    if (QFileInfo::exists(fresh.fileName()))
        return;
    // Light clicker and earlier Fake Clicker builds used "ObsidianClick": the registry on Windows
    // and AppData\Local\ObsidianClick\ObsidianClick\configs for profiles.
    QSettings legacy(QSettings::NativeFormat, QSettings::UserScope, "ObsidianClick", "ObsidianClick");
    legacy.setFallbacksEnabled(false);
    const QString legacyProfiles = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) +
                                   "/ObsidianClick/ObsidianClick/configs";
    if (legacy.allKeys().isEmpty() && !QDir(legacyProfiles).exists())
        return;
    migrate(legacy, legacyProfiles, fresh, profiles());
    // Creates the INI file, so a profile deleted later is not copied back on the next start.
    fresh.setValue("storage/importedFrom", "ObsidianClick");
    fresh.sync();
}
} // namespace Storage
