#pragma once
#include <QQuickImageProvider>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPainter>
#include <QSvgRenderer>
#include <QUrl>
#include <QUrlQuery>

// SVG arcs/strokes are rasterised by QPainter, not the GPU CurveRenderer.
// Fourfold coverage is reduced on the CPU to the exact requested physical size.
class CrispIconProvider final : public QQuickImageProvider {
public:
    CrispIconProvider(const QString &sourcePath = ":/qt/qml/FakeClicker/assets/icons.json") : QQuickImageProvider(QQuickImageProvider::Image) {
        QFile source(sourcePath);
        if (!source.open(QIODevice::ReadOnly)) qFatal("Icon source is missing");
        icons = QJsonDocument::fromJson(source.readAll()).object();
        if (icons.isEmpty()) qFatal("Icon source is empty");
    }
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override {
        const QUrl url("image://crispicons/" + id);
        const QString name = url.path().mid(1);
        const QUrlQuery query(url);
        QColor color(query.queryItemValue("color", QUrl::FullyDecoded));
        if (!color.isValid()) color = Qt::black;
        bool valid = false;
        const double requestedStroke = query.queryItemValue("stroke").toDouble(&valid);
        const double stroke = valid ? qBound(0.1, requestedStroke, 8.0) : 1.8;
        const QSize physical(qBound(1, requested.width() > 0 ? requested.width() : 20, 512),
                             qBound(1, requested.height() > 0 ? requested.height() : 20, 512));
        if (size) *size = physical;
        const auto glyph = icons.value(name).toObject();
        QImage high(physical * 4, QImage::Format_ARGB32_Premultiplied);
        high.fill(Qt::transparent);
        if (glyph.isEmpty()) return high.scaled(physical);
        const QString rgba = QString("rgb(%1,%2,%3)").arg(color.red()).arg(color.green()).arg(color.blue());
        QString svg = "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'><g opacity='"
            + QString::number(color.alphaF(), 'f', 6) + "'>";
        // QSvgRenderer can cap a zero-length/empty stroked path at (0,0).
        // Never submit an empty path: filled-only icons must not acquire a corner speck.
        const QString outline = glyph.value("d").toString();
        const QString filled = glyph.value("f").toString();
        if (!outline.isEmpty())
            svg += QString("<path d='%1' fill='none' stroke='%2' stroke-width='%3' stroke-linecap='round' stroke-linejoin='round'/>")
                .arg(outline, rgba, QString::number(stroke, 'f', 4));
        if (!filled.isEmpty())
            svg += QString("<path d='%1' fill='%2' stroke='none'/>").arg(filled, rgba);
        svg += "</g></svg>";
        QSvgRenderer renderer(svg.toUtf8());
        if (!renderer.isValid()) qFatal("Invalid icon SVG: %s", qPrintable(name));
        QPainter painter(&high);
        painter.setRenderHint(QPainter::Antialiasing, true);
        renderer.render(&painter, QRectF(QPointF(0, 0), QSizeF(high.size())));
        painter.end();
        return high.scaled(physical, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    }
private:
    QJsonObject icons;
};
