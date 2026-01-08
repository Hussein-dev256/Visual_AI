#include "image_processor.h"
#include <opencv2/opencv.hpp>

bool ImagePreprocessor::preprocessImage(const std::string& inputPath, const std::string& outputPath, int width, int height) {
    try {
        cv::Mat image = cv2::imread(inputPath);
        if (image.empty()) {
            return false;
        }

        cv::resize(image, image, cv::Size(width, height), 0, 0, cv::INTER_AREA);
        image.convertTo(image, CV_32F, 1.0 / 255.0);

        cv::imwrite(outputPath, image);
        return true;
    } catch (const std::exception& e) {
        return false;
    }
}