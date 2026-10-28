#include "ConfigStore.h"
#include "ClickController.h"
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>
namespace {
bool validName(const QString &name) {
    if (name.trimmed().isEmpty() || name.size() > 64)
        return false;
    for (QChar c : name)
        if (c.category() == QChar::Other_Control || c.category() == QChar::Other_Format)
            return false;
    return true;
}
} // namespace
ConfigStore::ConfigStore(ClickController *engine, QObject *parent)
    : QObject(parent), m_engine(engine) {
    m_directory = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/configs";
    if (!QDir().mkpath(m_directory)) {
        m_failed = true;
        m_notice = "folderUnavailable";
    }
    connect(engine, &ClickController::changed, this, &ConfigStore::changed);
    refresh();
}
bool ConfigStore::modified() const {
    return !m_activeId.isEmpty() && Configuration::encode(m_engine->config()) != m_applied;
}
QString ConfigStore::safePath(const QString &id) const {
    if (id.isEmpty() || id.size() > 255 || QFileInfo(id).fileName() != id || id.contains(':') ||
        id.contains('/') || id.contains('\\') || !id.endsWith(".json", Qt::CaseInsensitive))
        return {};
    for (const auto c : id)
        if (c.category() == QChar::Other_Control || QString("<>\"|?*").contains(c))
            return {};
    const QString path = QDir(m_directory).filePath(id);
    QFileInfo f(path);
    if (f.isSymLink() || (f.exists() && f.canonicalPath() != QDir(m_directory).canonicalPath()))
        return {};
    return path;
}
bool ConfigStore::read(const QString &path, QJsonObject &doc, ClickConfig &cfg,
                       QString &error) const {
    QFile f(path);
    if (!QFileInfo(path).isFile() || QFileInfo(path).isSymLink() || !f.open(QIODevice::ReadOnly) ||
        f.size() > 65536) {
        error = "fileTooLarge";
        return false;
    }
    const auto bytes = f.read(65537);
    if (bytes.size() > 65536 || !f.atEnd()) {
        error = "fileTooLarge";
        return false;
    }
    QJsonParseError pe;
    const auto d = QJsonDocument::fromJson(bytes, &pe);
    if (pe.error != QJsonParseError::NoError || !d.isObject()) {
        error = "badJson";
        return false;
    }
    doc = d.object();
    if (doc.size() != 4 ||
        !((doc["format"] == "obsidian-click" && doc["version"].toDouble() == 1) ||
          (doc["format"] == "c-clicker" && (doc["version"].toDouble() == 2 || doc["version"].toDouble() == 3 ||
                                            doc["version"].toDouble() == 4)) ||
          (doc["format"] == "light-clicker" && doc["version"].toDouble() == 4)) ||
        !doc["version"].isDouble() || !doc["name"].isString() ||
        !validName(doc["name"].toString()) || !doc["settings"].isObject()) {
        error = "schema";
        return false;
    }
    return Configuration::decode(doc["settings"].toObject(), cfg, error);
}
bool ConfigStore::write(const QString &path, const QJsonObject &doc) {
    if (path.isEmpty() || QFileInfo(path).isSymLink())
        return false;
    QSaveFile f(path);
    auto bytes = QJsonDocument(doc).toJson(QJsonDocument::Indented);
    return f.open(QIODevice::WriteOnly) && f.write(bytes) == bytes.size() && f.commit();
}
bool ConfigStore::finish(bool ok, const QString &text) {
    m_failed = !ok;
    m_notice = text;
    refresh();
    emit noticed(text, ok);
    return ok;
}
void ConfigStore::refresh() {
    QVariantList list;
    const auto files =
        QDir(m_directory)
            .entryInfoList({"*.json", "*.JSON"}, QDir::Files | QDir::NoDotAndDotDot, QDir::Name);
    for (const auto &f : files.mid(0, 500)) {
        QJsonObject doc;
        ClickConfig cfg;
        QString error;
        bool valid =
            !safePath(f.fileName()).isEmpty() && read(f.absoluteFilePath(), doc, cfg, error);
        if (!m_query.isEmpty() &&
            !(valid ? doc["name"].toString() : f.fileName()).contains(m_query, Qt::CaseInsensitive))
            continue;
        list.append(QVariantMap{
            {"id", f.fileName()},
            {"name", valid ? doc["name"].toString() : f.fileName()},
            {"valid", valid},
            {"mode", valid ? QVariant(cfg.mode == int(ClickMode::Blatant) ? "blatant" : "legit") : QVariant()},
            {"cps", valid ? QVariant(cfg.cps) : QVariant()},
            {"error", valid ? QString() : error},
            {"active", m_activeId == f.fileName()}});
    }
    if (m_profiles != list) {
        m_profiles = list;
        emit profilesChanged();
    }
    emit changed();
}
bool ConfigStore::saveNew(const QString &name) {
    if (!validName(name))
        return finish(false, "badName");
    const auto id = QUuid::createUuid().toString(QUuid::WithoutBraces) + ".json";
    const auto settings = Configuration::encode(m_engine->config());
    if (!write(safePath(id), {{"format", "light-clicker"},
                              {"version", 4},
                              {"name", name.trimmed()},
                              {"settings", settings}}))
        return finish(false, "saveFailed");
    m_activeId = id;
    m_activeName = name.trimmed();
    m_applied = settings;
    return finish(true, "saved");
}
bool ConfigStore::duplicate(const QString &id) {
    QJsonObject doc;
    ClickConfig cfg;
    QString error;
    const auto path = safePath(id);
    if (path.isEmpty() || !read(path, doc, cfg, error))
        return finish(false, "readFailed");
    doc["name"] = doc["name"].toString().left(57) + " (2)";
    doc["format"] = "light-clicker";
    doc["version"] = 4;
    doc["settings"] = Configuration::encode(cfg);
    const auto fresh = QUuid::createUuid().toString(QUuid::WithoutBraces) + ".json";
    const bool ok = write(safePath(fresh), doc);
    return finish(ok, ok ? "duplicated" : "saveFailed");
}
bool ConfigStore::apply(const QString &id) {
    const auto path = safePath(id);
    QJsonObject doc;
    ClickConfig cfg;
    QString error;
    if (path.isEmpty() || !read(path, doc, cfg, error))
        return finish(false, error.isEmpty() ? "notFound" : error);
    if (!m_engine->applyConfig(cfg))
        return finish(false, m_engine->error());
    m_activeId = id;
    m_activeName = doc["name"].toString();
    m_applied = Configuration::encode(cfg);
    return finish(true, "applied:" + m_activeName);
}
bool ConfigStore::remove(const QString &id) {
    const auto path = safePath(id);
    if (path.isEmpty() || !QFile::remove(path))
        return finish(false, "deleteFailed");
    if (id == m_activeId) {
        m_activeId.clear();
        m_activeName.clear();
        m_applied = {};
    }
    return finish(true, "deleted");
}
bool ConfigStore::rename(const QString &id, const QString &name) {
    if (!validName(name))
        return finish(false, "badName");
    QJsonObject doc;
    ClickConfig cfg;
    QString error;
    const auto path = safePath(id);
    if (path.isEmpty() || !read(path, doc, cfg, error))
        return finish(false, "readFailed");
    doc["name"] = name.trimmed();
    if (!write(path, doc))
        return finish(false, "renameFailed");
    if (m_activeId == id)
        m_activeName = name.trimmed();
    return finish(true, "renamed");
}
bool ConfigStore::importFile(const QUrl &url) {
    if (!url.isLocalFile())
        return finish(false, "localJsonOnly");
    QJsonObject doc;
    ClickConfig cfg;
    QString error;
    if (!read(url.toLocalFile(), doc, cfg, error))
        return finish(false, error);
    const auto id = QUuid::createUuid().toString(QUuid::WithoutBraces) + ".json";
    doc["format"] = "light-clicker";
    doc["version"] = 4;
    doc["settings"] = Configuration::encode(cfg);
    const bool ok = write(safePath(id), doc);
    return finish(ok, ok ? "imported" : "saveFailed");
}
bool ConfigStore::exportFile(const QString &id, const QUrl &url) {
    if (!url.isLocalFile() || !url.toLocalFile().endsWith(".json", Qt::CaseInsensitive))
        return finish(false, "localJsonOnly");
    QJsonObject doc;
    ClickConfig cfg;
    QString error;
    const auto path = safePath(id);
    if (path.isEmpty() || !read(path, doc, cfg, error))
        return finish(false, "readFailed");
    const bool ok = write(url.toLocalFile(), doc);
    return finish(ok, ok ? "exported" : "exportFailed");
}
void ConfigStore::openFolder() {
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(m_directory)))
        finish(false, "folderUnavailable");
}
