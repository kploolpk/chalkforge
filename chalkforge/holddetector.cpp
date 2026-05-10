#include "holddetector.h"

#include <opencv2/opencv.hpp>

#include <QImage>
#include <QDebug>

#include <queue>
#include <cmath>

HoldDetector::HoldDetector(QObject *parent)
    : QObject(parent)
{
}

QVariantList HoldDetector::detectHold(
    const QString &imagePath,
    int startX,
    int startY)
{
    QVariantList points;

    // Load image using Qt
    // Works properly with Android content:// URIs
    QImage qimg(imagePath);

    if (qimg.isNull()) {
        qDebug() << "Failed to load image:" << imagePath;
        return points;
    }

    // Convert to RGB format
    QImage converted =
        qimg.convertToFormat(QImage::Format_RGB888);

    // Convert QImage -> OpenCV Mat
    cv::Mat image(
        converted.height(),
        converted.width(),
        CV_8UC3,
        converted.bits(),
        converted.bytesPerLine()
        );

    // Convert RGB -> BGR
    cv::cvtColor(image, image, cv::COLOR_RGB2BGR);

    // Smooth image slightly
    // Reduces noise and texture problems
    cv::GaussianBlur(
        image,
        image,
        cv::Size(5, 5),
        0
        );

    // Convert to HSV
    cv::Mat hsvImage;

    cv::cvtColor(
        image,
        hsvImage,
        cv::COLOR_BGR2HSV
        );

    // Edge detection
    // Helps stop flood fill leaking
    cv::Mat edges;

    cv::Canny(
        image,
        edges,
        80,
        160
        );

    // Safety check
    if (startX < 0 || startY < 0
        || startX >= image.cols
        || startY >= image.rows) {

        qDebug() << "Tap position outside image";
        return points;
    }

    // Starting colour
    cv::Vec3b targetColor =
        hsvImage.at<cv::Vec3b>(startY, startX);

    // Tracks visited pixels
    cv::Mat visited = cv::Mat::zeros(
        image.rows,
        image.cols,
        CV_8U
        );

    // Binary mask
    cv::Mat mask = cv::Mat::zeros(
        image.rows,
        image.cols,
        CV_8U
        );

    std::queue<cv::Point> q;
    q.push(cv::Point(startX, startY));

    // Much higher now because HSV weighting changed
    int threshold = 20;

    while (!q.empty()) {

        cv::Point p = q.front();
        q.pop();

        // Bounds check
        if (p.x < 0 || p.y < 0
            || p.x >= image.cols
            || p.y >= image.rows)
            continue;

        // Skip already visited
        if (visited.at<uchar>(p.y, p.x))
            continue;

        visited.at<uchar>(p.y, p.x) = 1;

        // Stop flood fill crossing strong edges
        if (edges.at<uchar>(p.y, p.x) > 0)
            continue;

        cv::Vec3b color =
            hsvImage.at<cv::Vec3b>(p.y, p.x);

        // HSV differences
        int hueDiff =
            abs(color[0] - targetColor[0]);

        int satDiff =
            abs(color[1] - targetColor[1]);

        int valDiff =
            abs(color[2] - targetColor[2]);

        // Hue wraparound fix
        hueDiff = std::min(
            hueDiff,
            180 - hueDiff
            );

        // Distance from tap point
        double distance =
            std::sqrt(
                (p.x - startX) * (p.x - startX)
                + (p.y - startY) * (p.y - startY)
                );

        // Weighted difference
        int diff =
            hueDiff * 5
            + satDiff * 2
            + valDiff
            + distance * 0.4;

        // Pixel accepted
        if (diff < threshold) {

            mask.at<uchar>(p.y, p.x) = 255;

            q.push(cv::Point(p.x + 1, p.y));
            q.push(cv::Point(p.x - 1, p.y));
            q.push(cv::Point(p.x, p.y + 1));
            q.push(cv::Point(p.x, p.y - 1));
        }
    }

    // Clean up mask slightly
    cv::morphologyEx(
        mask,
        mask,
        cv::MORPH_CLOSE,
        cv::Mat(),
        cv::Point(-1, -1),
        2
        );

    // Find contours
    std::vector<std::vector<cv::Point>> contours;

    cv::findContours(
        mask,
        contours,
        cv::RETR_EXTERNAL,
        cv::CHAIN_APPROX_SIMPLE
        );

    // Find largest contour
    double maxArea = 0;
    int largestIndex = -1;

    for (int i = 0; i < contours.size(); i++) {

        double area =
            cv::contourArea(contours[i]);

        // Ignore tiny noisy regions
        if (area < 100)
            continue;

        if (area > maxArea) {
            maxArea = area;
            largestIndex = i;
        }
    }

    // Simplify contour
    std::vector<cv::Point> simplified;

    if (largestIndex >= 0) {

        cv::approxPolyDP(
            contours[largestIndex],
            simplified,
            3,
            true
            );
    }

    // Convert contour -> QVariantList
    for (const cv::Point &p : simplified) {

        QVariantMap point;

        point["x"] = p.x;
        point["y"] = p.y;

        points.append(point);
    }

    qDebug() << "Contour points:" << points.size();
    qDebug() << "Largest contour area:" << maxArea;

    return points;
}
