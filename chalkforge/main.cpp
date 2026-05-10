#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "holddetector.h"
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<HoldDetector>(
        "HoldDetector",
        1,
        0,
        "HoldDetector"
        );

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("chalkforge", "Main");
    return app.exec();
}
