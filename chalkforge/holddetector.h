#pragma once

#include <QObject>
#include <QVariantList>

class HoldDetector : public QObject
{
    Q_OBJECT

public:
    explicit HoldDetector(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList detectHold(
        const QString &imagePath,
        int startX,
        int startY
        );
};
