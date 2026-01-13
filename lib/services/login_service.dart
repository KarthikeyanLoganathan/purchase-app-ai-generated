import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import '../utils/settings_manager.dart';

/// Service to handle login/logout operations and login status
///
/// This service centralizes all login-related functionality:
/// - Saving credentials
/// - Clearing credentials (logout)
/// - Checking login status
/// - Clearing all data on logout
class LoginService {
  static final LoginService instance = LoginService._init();
  LoginService._init();

  final _dbHelper = DatabaseHelper.instance;

  /// Validate and save login credentials
  /// Returns true if credentials are valid and saved successfully
  Future<bool> login(String webAppUrl, String secretCode) async {
    // Validate credentials first
    final isValid = await _validateCredentials(webAppUrl, secretCode);

    if (isValid) {
      await SettingsManager.instance
          .setWebAppUrlAndSecretCode(webAppUrl, secretCode);
      await _dbHelper.clearAllData();
    }

    return isValid;
  }

  /// Logout: Clear all data and credentials
  Future<void> logout() async {
    // Clear all data from database
    await _dbHelper.clearAllData();

    // Clear credentials
    await SettingsManager.instance.setWebAppUrlAndSecretCode(null, null);
  }

  /// Validate credentials by making a test API call (private)
  Future<bool> _validateCredentials(String webAppUrl, String secretCode) async {
    try {
      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'secret': secretCode,
              'operation': 'login',
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Handle response with redirect support
      final data = await _handleResponse(response);

      // Check for error in response
      if (data['error'] != null) {
        return false;
      }

      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Handle HTTP response with redirect support
  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 302 || response.statusCode == 301) {
      final redirectMatch = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
      if (redirectMatch != null) {
        final redirectUrl = redirectMatch.group(1)!.replaceAll('&amp;', '&');
        final redirectResponse = await http.get(Uri.parse(redirectUrl));

        if (redirectResponse.statusCode != 200) {
          throw Exception(
              'HTTP ${redirectResponse.statusCode}: ${redirectResponse.body}');
        }

        return json.decode(redirectResponse.body);
      }
    } else if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}
