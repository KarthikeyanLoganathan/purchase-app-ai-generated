import 'dart:io';
// ignore_for_file: avoid_print

void main() {
  // Get the executable directory (where this script is located)
  final scriptUri = Platform.script;
  final scriptPath = scriptUri.toFilePath();
  final executableDir = Directory(scriptPath).parent;

  // Compute paths relative to executable directory
  final sourceDir =
      Directory('${executableDir.parent.path}/backend/google-app-script-code');
  final targetDir =
      Directory('${executableDir.parent.path}/backend-google-app-script-code');

  // Create target directory if it doesn't exist
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
    print('Created target directory: ${targetDir.path}');
  }

  // Check if source directory exists
  if (!sourceDir.existsSync()) {
    print('Error: Source directory not found: ${sourceDir.path}');
    print('This directory must exist and contain backend scripts.');
    exit(1);
  }

  // Copy all .js files
  var copiedCount = 0;
  for (var entity in sourceDir.listSync()) {
    if (entity is File &&
        (entity.path.toLowerCase().endsWith('.js') ||
            entity.path.toLowerCase().endsWith('.html') ||
            entity.path.toLowerCase().endsWith('appsscript.json'))) {
      final fileName = entity.uri.pathSegments.last;
      final targetPath = '${targetDir.path}/$fileName';
      entity.copySync(targetPath);
      print('Copied: $fileName');
      copiedCount++;
    }
  }

  if (copiedCount == 0) {
    print('Error: No .js files found in ${sourceDir.path}');
    exit(1);
  }

  print('Successfully copied $copiedCount Google Apps Script files to assets.');
}
