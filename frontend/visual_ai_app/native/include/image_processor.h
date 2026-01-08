#ifndef IMAGE_PROCESSOR_H
#define IMAGE_PROCESSOR_H

#include <string>
#include <opencv2/opencv.hpp>

class ImagePreprocessor {
 public:
  static bool preprocessImage(const std::string& inputPath, const std::string& outputPath, int width, int height);
};

#endif