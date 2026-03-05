const String API_BASE_URL = 'http://localhost:8000/api';

class ApiEndpoints {
  // Auth
  static const String login = '$API_BASE_URL/auth/login';
  static const String register = '$API_BASE_URL/auth/register';
  static const String logout = '$API_BASE_URL/auth/logout';
  
  // Users
  static const String userProfile = '$API_BASE_URL/users/profile';
  static const String updateProfile = '$API_BASE_URL/users/profile';
  
  // Food Logging
  static const String foodLogs = '$API_BASE_URL/food/logs';
  static const String foodLogsToday = '$API_BASE_URL/food/logs/today';
  static const String deleteFood = '$API_BASE_URL/food/logs';
  
  // Weight Tracking
  static const String weightEntries = '$API_BASE_URL/weight/entries';
  static const String recordWeight = '$API_BASE_URL/weight/entries';
  static const String weightTrend = '$API_BASE_URL/weight/trend';
  
  // Activities
  static const String activities = '$API_BASE_URL/activities';
  static const String activitiesToday = '$API_BASE_URL/activities/today';
  
  // Diary
  static const String diaryEntries = '$API_BASE_URL/diary';
  static const String diaryToday = '$API_BASE_URL/diary/today';
  
  // Dashboard
  static const String dashboardStats = '$API_BASE_URL/dashboard/stats';
  
  // External APIs
  static const String foodDatabase = '$API_BASE_URL/food/search';
  static const String calorieEstimate = '$API_BASE_URL/food/estimate-calories';
}
