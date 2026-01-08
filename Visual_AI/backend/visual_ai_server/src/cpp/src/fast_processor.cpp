#include "fast_processor.h"
#include <opencv2/opencv.hpp>
#include <stdexcept>

FastProcessor::FastProcessor() {}

FastProcessor::~FastProcessor() {}

bool FastProcessor::preprocessImage(const std::string& input_path, std::vector<float>& output_buffer, int target_width, int target_height) {
    try {
        // Resize image
        if (!resizeImage(input_path, output_buffer, target_width, target_height)) {
            return false;
        }

        // Normalize image
        if (!normalizeImage(output_buffer)) {
            return false;
        }

        return true;
    } catch (const std::exception& e) {
        return false;
    }
}

bool FastProcessor::resizeImage(const std::string& input_path, std::vector<float>& output, int width, int height) {
    cv::Mat image = cv::imread(input_path);
    if (image.empty()) {
        return false;
    }

    cv::Mat resized;
    cv::resize(image, resized, cv::Size(width, height));

    // Convert to RGB float values
    output.resize(width * height * 3);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            cv::Vec3b pixel = resized.at<cv::Vec3b>(y, x);
            output[(y * width + x) * 3 + 0] = pixel[2]; // R
            output[(y * width + x) * 3 + 1] = pixel[1]; // G
            output[(y * width + x) * 3 + 2] = pixel[0]; // B
        }
    }

    return true;
}

bool FastProcessor::normalizeImage(std::vector<float>& image_data) {
    // Normalize to [0, 1]
    for (float& value : image_data) {
        value /= 255.0f;
    }
    return true;
}