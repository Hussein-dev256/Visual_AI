#ifndef FAST_PROCESSOR_H
#define FAST_PROCESSOR_H

#include <string>
#include <vector>

class FastProcessor {
public:
    FastProcessor();
    ~FastProcessor();

    // Preprocess image for TFLite inference
    bool preprocessImage(const std::string& input_path, std::vector<float>& output_buffer, int target_width, int target_height);

private:
    // Internal methods for image processing
    bool resizeImage(const std::string& input_path, std::vector<float>& output, int width, int height);
    bool normalizeImage(std::vector<float>& image_data);
};

#endif // FAST_PROCESSOR_H