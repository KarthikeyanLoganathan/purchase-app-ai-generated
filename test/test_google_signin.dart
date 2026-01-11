// Run this standalone test: dart run test_google_signin.dart
// This tests if the google-services.json is properly configured

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== Google Sign-In Configuration Checker ===\n');

  // Check google-services.json
  final file = File('android/app/google-services.json');

  if (!file.existsSync()) {
    print('❌ ERROR: google-services.json not found!');
    return;
  }

  print('✓ google-services.json exists\n');

  final content = await file.readAsString();
  final json = jsonDecode(content);

  // Extract info
  final projectNumber = json['project_info']['project_number'];
  final projectId = json['project_info']['project_id'];
  final packageName =
      json['client'][0]['client_info']['android_client_info']['package_name'];
  final oauthClients = json['client'][0]['oauth_client'] as List;

  print('Project Info:');
  print('  Project Number: $projectNumber');
  print('  Project ID: $projectId');
  print('  Package Name: $packageName\n');

  if (oauthClients.isEmpty) {
    print('❌ ERROR: No OAuth clients found in google-services.json!');
    print(
        '   This means the SHA-1 fingerprint is not configured in Firebase.\n');
    print('Action Required:');
    print(
        '1. Go to: https://console.firebase.google.com/project/$projectId/settings/general');
    print('2. Under "Your apps" → Android app');
    print('3. Click "Add fingerprint"');
    print(
        '4. Add SHA-1: 07:5B:6B:7E:61:0E:B4:D9:25:B4:0C:BE:34:72:8A:DE:36:54:D2:FC');
    print('5. Re-download google-services.json');
    return;
  }

  print('OAuth Clients:');
  for (var i = 0; i < oauthClients.length; i++) {
    final client = oauthClients[i];
    print('  Client ${i + 1}:');
    print('    Client ID: ${client['client_id']}');
    print('    Type: ${client['client_type']}');
    if (client.containsKey('android_info')) {
      print('    Package: ${client['android_info']['package_name']}');
      print('    SHA-1: ${client['android_info']['certificate_hash']}');
    }
  }

  print('\n=== Verification ===');

  // Check package name match
  if (packageName != 'com.purchase.purchase_app') {
    print('❌ Package name mismatch!');
    print('   Expected: com.purchase.purchase_app');
    print('   Found: $packageName');
  } else {
    print('✓ Package name correct');
  }

  // Check SHA-1
  const expectedSha = '075b6b7e610eb4d925b40cbe34728ade3654d2fc';
  bool sha1Found = false;

  for (var client in oauthClients) {
    if (client.containsKey('android_info')) {
      final hash = client['android_info']['certificate_hash'] as String;
      if (hash.toLowerCase() == expectedSha) {
        sha1Found = true;
        break;
      }
    }
  }

  if (sha1Found) {
    print('✓ SHA-1 fingerprint correct');
  } else {
    print('❌ SHA-1 fingerprint mismatch or missing!');
    print('   Expected: $expectedSha');
  }

  print('\n=== Next Steps ===');
  print('1. Verify these URLs:');
  print(
      '   OAuth Consent: https://console.cloud.google.com/apis/credentials/consent?project=$projectId');
  print(
      '   Credentials: https://console.cloud.google.com/apis/credentials?project=$projectId');
  print('2. Make sure an Android OAuth client exists in Google Cloud Console');
  print('3. Add your email as a test user in OAuth consent screen');
  print('4. Enable required APIs (Sheets, Drive, Apps Script)');
}
