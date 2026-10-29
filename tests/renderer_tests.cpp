#include "CrispIconProvider.h"
#include <QGuiApplication>
#include <QJsonObject>
#include <QQueue>
#include <QSet>
#include <QDebug>
int main(int argc,char **argv) {
    QGuiApplication app(argc,argv);
    const QString path=QString(CCLICKER_SOURCE_DIR)+"/assets/icons.json";
    QFile file(path); if(!file.open(QIODevice::ReadOnly)) return 1;
    const auto icons=QJsonDocument::fromJson(file.readAll()).object();
    CrispIconProvider provider(path);
    int checks=0, renders=0;
    auto check=[&](bool ok,const QString &label) { ++checks; if(!ok) qFatal("RASTER_FAIL: %s",qPrintable(label)); };
    check(icons.size()==40,"40 distinct glyphs");
    for(const auto &name:icons.keys()) for(int logical:{12,16,20,24,32}) for(double dpr:{1.,1.25,1.5,2.}) for(const QString color:{QString("%23ffffff"),QString("%231d1d1f")}) {
        const int side=qRound(logical*dpr); QSize size;
        const auto image=provider.requestImage(name+"?color="+color+"&stroke=1.8",&size,QSize(side,side));
        const QString context=name+"/"+QString::number(side)+"/"+color;
        check(image.size()==QSize(side,side)&&size==image.size(),context+" exact physical size");
        for(const QPoint corner:{QPoint(0,0),QPoint(side-1,0),QPoint(0,side-1),QPoint(side-1,side-1)})
            check(image.pixelColor(corner).alpha()==0,context+" no stray corner pixels");
        int visible=0;
        for(int y=0;y<side;++y) for(int x=0;x<side;++x) if(image.pixelColor(x,y).alpha()>64) ++visible;
        check(visible>2,context+" nonempty glyph");
        if(name=="globe"||name=="search"||name=="stop"||name=="hash"||name=="winMax") {
            QSet<int> pixels;
            for(int y=0;y<side;++y) for(int x=0;x<side;++x) if(image.pixelColor(x,y).alpha()>64) pixels.insert(y*side+x);
            int components=0;
            while(!pixels.isEmpty()) {
                ++components;QQueue<int> queue;queue.enqueue(*pixels.begin());pixels.remove(queue.head());
                while(!queue.isEmpty()) { const int v=queue.dequeue(),x=v%side,y=v/side;
                    for(int dy=-1;dy<=1;++dy) for(int dx=-1;dx<=1;++dx) {const int nx=x+dx,ny=y+dy,k=ny*side+nx;
                        if(nx>=0&&nx<side&&ny>=0&&ny<side&&pixels.remove(k)) queue.enqueue(k);
                    }
                }
            }
            check(components==1,context+" continuous outline/shape");
        }
        ++renders;
    }
    qInfo("RASTER_ICONS_PASS %d checks; %d renders; 40 glyphs; 12–32 px; DPR 100/125/150/200%%; no corner specks; continuous key outlines",checks,renders);
}
