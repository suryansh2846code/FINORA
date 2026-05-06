# 🐠 Fish Identifier

A professional, production-ready Flutter app for identifying aquatic species using YOLOv8n deep learning model with optimized TFLite inference.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

- 📸 **Camera & Gallery Support** - Capture or select images
- 🎯 **Real-time Detection** - Fast YOLOv8n inference (<500ms)
- 🎨 **Beautiful UI** - Material 3 design with smooth animations
- 🏗️ **Clean Architecture** - Domain/Data/Presentation layers
- 🔄 **BLoC State Management** - Reactive programming patterns
- 💾 **Memory Optimized** - Efficient image processing
- 📱 **Cross-Platform** - iOS & Android support

## 🐟 Detectable Species

- Fish 🐟
- Jellyfish 🪼
- Penguin 🐧
- Puffin 🦜
- Shark 🦈
- Starfish ⭐
- Stingray 🐠

## 🏛️ Architecture

```
lib/
├── config/
│   └── di/              # Dependency injection (GetIt)
├── core/
│   ├── constants/       # Model config, class labels
│   ├── utils/           # Image preprocessing utilities
│   └── errors/          # Error handling
└── features/detection/
    ├── domain/          # Business logic layer
    │   ├── entities/    # Core data models
    │   ├── repositories/# Abstract interfaces
    │   └── usecases/    # Business use cases
    ├── data/            # Data layer
    │   ├── datasources/ # TFLite inference service
    │   ├── models/      # Data models
    │   └── repositories/# Repository implementations
    └── presentation/    # UI layer
        ├── bloc/        # BLoC state management
        ├── pages/       # UI screens
        └── widgets/     # Reusable components
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Android Studio / Xcode
- Android device/emulator running Android 5.0+
- iOS device/simulator running iOS 12.0+

### Installation

1. **Clone the repository**
   ```bash
   cd fish_identifier
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### TFLite Model

The app uses a YOLOv8n model optimized for mobile:
- **Model**: `best_float16.tflite` (FP16 precision)
- **Input Size**: 640x640x3
- **Speed**: ~200-400ms on mid-range devices
- **Accuracy**: High precision with minimal degradation

### Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Camera access
- Storage read/write

**iOS** (`ios/Runner/Info.plist`):
- Camera usage description
- Photo library usage description

## 🎨 UI/UX Features

- **Gradient Backgrounds** - Eye-catching visual design
- **Custom Painters** - Precise bounding box rendering
- **Progress Indicators** - Confidence score visualizations
- **Smooth Transitions** - Polished user experience
- **Error Handling** - User-friendly error messages
- **Loading States** - Clear feedback during processing

## ⚙️ Technical Details

### Key Technologies

- **State Management**: BLoC (flutter_bloc)
- **ML Framework**: TFLite Flutter
- **Image Processing**: image package
- **DI**: get_it
- **UI**: Material 3 with Google Fonts

### Performance Optimizations

- ✅ Pre-allocated memory buffers
- ✅ Efficient image preprocessing
- ✅ Non-Maximum Suppression (NMS)
- ✅ Lazy model loading
- ✅ Proper resource disposal
- ✅ Memory-efficient bounding box calculations

### Memory Management

- Model singleton pattern
- Explicit garbage collection triggers
- Resource cleanup on dispose
- Optimized image compression
- Controlled concurrent operations

## 📱 Screenshots

### Home Screen
- Beautiful gradient background
- Camera and gallery options
- Loading states

### Detection Results
- Image with bounding boxes
- Detection statistics
- List of identified species
- Confidence scores

## 🧪 Testing

```bash
# Run analyzer
flutter analyze

# Run tests
flutter test

# Check for outdated packages
flutter pub outdated
```

## 📦 Build

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## 🛠️ Development

### Code Structure Principles

1. **Separation of Concerns** - Each layer has a single responsibility
2. **Dependency Inversion** - Abstractions, not concretions
3. **Single Responsibility** - Each class does one thing well
4. **Open/Closed** - Open for extension, closed for modification

### Adding New Features

1. **Domain Layer** - Define entities and use cases
2. **Data Layer** - Implement data sources and repositories
3. **Presentation Layer** - Create BLoCs and UI components

## 🐛 Troubleshooting

### Model Loading Issues
- Ensure TFLite model is in `assets/models/`
- Check `pubspec.yaml` assets configuration
- Verify model compatibility

### Performance Issues
- Test on physical device, not emulator
- Check memory usage in DevTools
- Optimize image sizes before processing

### Permission Errors
- Verify AndroidManifest.xml permissions
- Check Info.plist usage descriptions
- Request runtime permissions

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests.

## 📧 Contact

For questions or support, please open an issue in the repository.

---

**Built with ❤️ using Flutter and YOLOv8**
