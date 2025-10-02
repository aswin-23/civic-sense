class AppConfig {
  // Backend API configuration
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Android emulator
  // static const String baseUrl = "http://localhost:8000/api"; // iOS simulator
  // static const String baseUrl = "http://YOUR_IP:8000/api"; // Physical device

  // Gemini AI configuration
  static const String geminiApiKey = "AIzaSyC0F-AqD-NYfaqARX625upXlyvHjZI1xfI";

  // App configuration
  static const String appName = "Civic Sense";
  static const String appVersion = "1.0.0";

  // Image configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;

  // Location configuration
  static const double defaultLocationAccuracy = 10.0; // meters
  static const int locationTimeout = 10; // seconds

  // UI configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 4.0;

  // API timeout configuration
  static const int apiTimeout = 30; // seconds

  // Pagination configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation configuration
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 1000;
  static const int minDescriptionLength = 10;

  // Notification configuration
  static const String notificationChannelId = "civic_sense_notifications";
  static const String notificationChannelName = "Civic Sense Notifications";
  static const String notificationChannelDescription = "Notifications for civic issue updates";

  // Storage configuration
  static const String userDataKey = "user_data";
  static const String authTokenKey = "auth_token";
  static const String settingsKey = "app_settings";

  // Error messages
  static const String networkErrorMessage = "Network error. Please check your connection.";
  static const String serverErrorMessage = "Server error. Please try again later.";
  static const String unknownErrorMessage = "An unknown error occurred.";

  // Success messages
  static const String reportSubmittedMessage = "Report submitted successfully!";
  static const String accountCreatedMessage = "Account created successfully!";
  static const String loginSuccessMessage = "Welcome back!";

  // Categories
  static const List<String> issueCategories = [
    'pothole',
    'trash',
    'electric',
    'water',
    'traffic',
    'streetlight',
    'sidewalk',
    'other',
  ];

  // Status options
  static const List<String> complaintStatuses = [
    'submitted',
    'forwarded',
    'acknowledged',
    'in_progress',
    'resolved',
    'rejected',
  ];

  // Priority levels
  static const List<String> priorityLevels = [
    'low',
    'medium',
    'high',
  ];

  // User roles
  static const List<String> userRoles = [
    'citizen',
    'staff',
    'admin',
  ];

  // Department suggestions
  static const List<String> departments = [
    'Public Works Department',
    'Environmental Services',
    'Traffic Management',
    'Parks and Recreation',
    'Public Safety',
    'Utilities Department',
    'General Department',
  ];
}