# Widget Previews - Quick Start Guide

## ✅ VS Code Preview Detection

Your Flutter app now has **Preview Gallery** - an interactive browser for all your screens!

## 🚀 Quick Start

### Option 1: Use VS Code Launch Configuration (Easiest!)

1. Open VS Code
2. Press `F5` or go to Run → Start Debugging
3. Select **"Launch Preview Gallery"** from the dropdown
4. Browse all your 32 widgets in an interactive UI!

### Option 2: Command Line

```bash
# Run Preview Gallery
flutter run -t lib/preview_gallery.dart

# Or run on Chrome for web preview
flutter run -d chrome -t lib/preview_gallery.dart
```

## 📱 What You Get

- **32 Screen Previews** - All screens available for preview
- **Organized Categories**:
  - Main Screens (Home, Login, Settings)
  - Master Data Lists (Materials, Vendors, Manufacturers, etc.)
  - Transactions (Baskets, Quotations, Purchase Orders)
  - Utilities (Import Data, Sync Debug)
  - Detail Screens (with sample data)
- **Hot Reload Support** - Changes reflect immediately
- **Cross-Platform** - Works on iOS, Android, Web, Desktop

## 📚 Available Launch Configurations

In VS Code's Run menu (F5), you now have:

1. **Launch App** - Run the main purchase application
2. **Launch Preview Gallery** - Browse all widget previews

## 💡 Tips

- Use Preview Gallery for quick widget browsing and development
- All screens include preview classes at the end of each file
- Preview Gallery provides sample data for all detail screens
- Changes to widgets will hot-reload in preview mode
- Each screen file has a `[ScreenName]Preview` class for standalone testing

## 🎨 Individual Widget Previews

Each screen file (e.g., `materials_screen.dart`) has a preview class that can be run independently:

```dart
// Widget Preview for VS Code
class MaterialsScreenPreview extends StatelessWidget {
  const MaterialsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MaterialsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

You can copy any preview class to a test file or temporarily to `main.dart` to preview that specific widget.

## 📖 More Information

See [WIDGET_PREVIEWS.md](WIDGET_PREVIEWS.md) for detailed documentation.

## 🔍 Quick Test

Try it now:
```bash
flutter run -t lib/preview_gallery.dart
```

Or press `F5` in VS Code and select "Launch Preview Gallery"!
