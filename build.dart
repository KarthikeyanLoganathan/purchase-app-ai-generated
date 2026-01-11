// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) async {
  // Run the copy script
  print('Running pre-build script: Copying backend Google Script files...');

  final result = await Process.run(
    'dart',
    ['run', 'tool/copy_backend_google_script_code_as_assets.dart'],
  );

  if (result.exitCode != 0) {
    print('Error running copy script:');
    print(result.stderr);
    exit(result.exitCode);
  }

  print(result.stdout);
}
