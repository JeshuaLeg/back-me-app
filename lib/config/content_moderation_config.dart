class ContentModerationConfig {
  // TODO: Replace with your actual Google Cloud Vision API key
  // Get your API key from: https://console.cloud.google.com/
  // Enable the Cloud Vision API and create credentials
  static const String apiKey = 'AIzaSyBAW5DXDp1miQ6OxPYlXc3_qPhecIaXqBs';
  
  // Set to false to disable content moderation entirely
  static const bool enableContentModeration = true;
  
  // Threshold for content moderation (1-5)
  // 1: VERY_UNLIKELY, 2: UNLIKELY, 3: POSSIBLE, 4: LIKELY, 5: VERY_LIKELY
  // Images with scores >= this threshold will be rejected
  static const int contentThreshold = 4; // LIKELY or VERY_LIKELY
} 