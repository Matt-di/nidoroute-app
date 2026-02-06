# NitoRoute

A  Flutter mobile application for school transport management with real-time GPS tracking, route optimization, and multi-role user support.

##  Overview

NitoRoute is a modern, feature-rich school transportation management system designed to streamline daily operations for schools, transport companies, and parents. The application provides real-time tracking, efficient route management, and seamless communication between drivers, guardians, and administrators.

##  Key Features

###  Core Functionality
- **Multi-Role Authentication**: Secure login system for Drivers, Guardians, and Administrators
- **Real-Time GPS Tracking**: Live vehicle tracking with accurate location updates
- **Route Management**: Optimized routes with dynamic stop management
- **Passenger Management**: Digital pickup/dropoff confirmation system
- **Push Notifications**: Real-time alerts for delays, arrivals, and important updates

###  User Experience
- **Modern Material 3 Design**: Clean, intuitive interface following Google's design principles
- **Responsive Layout**: Optimized for various screen sizes and device types
- **Offline Support**: Core functionality available without internet connectivity
- **Multi-Language Support**: Localization ready for global deployment

### � Technical Excellence
- **Bloc State Management**: Scalable and maintainable state architecture
- **Real-Time Communication**: WebSocket integration for instant updates
- **Secure Storage**: Encrypted local storage for sensitive data
- **API Integration**: RESTful backend integration with comprehensive error handling

##  Architecture

### Project Structure
```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Main app widget with Bloc providers
├── core/                     # Core business logic and utilities
│   ├── config/              # Configuration and constants
│   ├── theme/               # App theming and styling
│   ├── services/            # Business services and API clients
│   ├── bloc/                # Base bloc classes and utilities
│   └── widgets/             # Reusable UI components
├── features/                # Feature-based modules
│   ├── auth/               # Authentication flow
│   ├── trips/              # Trip management and tracking
│   ├── notifications/      # Push notifications management
│   └── settings/           # User settings and preferences
└── models/                  # Data models and entities
```

### Technology Stack
- **Framework**: Flutter 3.19.0+
- **State Management**: Bloc Pattern with Hydrated Bloc
- **Networking**: Dio HTTP Client
- **Maps**: Google Maps Flutter
- **Location Services**: Geolocator
- **Real-Time**: WebSocket Channel
- **Storage**: Flutter Secure Storage
- **Notifications**: Firebase Messaging
- **Navigation**: Go Router

##  Getting Started

### Prerequisites
- **Flutter SDK**: 3.19.0 or higher
- **Dart SDK**: 3.9.2 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Backend API**: Compatible Laravel/Node.js backend

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/nitoroute.git
   cd nitoroute
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Platform Setup**
   
   **Android:**
   - Update `android/app/src/main/AndroidManifest.xml` with required permissions
   - Add Google Maps API key
   
   **iOS:**
   - Update `ios/Runner/Info.plist` with location permissions
   - Configure Google Maps API key in `AppDelegate.swift`

### Configuration

#### Backend API
Update `lib/core/config/app_config.dart`:
```dart
static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.yourapp.com/v1';
```

#### Google Maps API
1. Obtain API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Add to `.env` file:
   ```
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

#### Firebase Configuration
1. Create Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
3. Place files in respective platform directories

## 🏃‍♂️ Running the Application

### Development Mode
```bash
flutter run
```

### Release Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

##  Authentication System

The application supports three distinct user roles:

### Driver Role
- **Dashboard**: Active trip management and navigation
- **Features**: Start/complete trips, passenger pickup confirmation, real-time location sharing
- **Permissions**: Location services, camera (for documentation), notifications

### Guardian Role
- **Dashboard**: Children tracking and trip monitoring
- **Features**: Real-time bus tracking, arrival notifications, pickup/dropoff confirmations
- **Permissions**: Location services, notifications

### Administrator Role
- **Dashboard**: System oversight and management
- **Features**: Route management, user administration, analytics and reporting
- **Permissions**: Full system access

##  API Integration

### Core Endpoints
```dart
// Authentication
POST /auth/login          // User authentication
POST /auth/logout         // User logout
GET  /user               // Current user profile

// Trip Management
GET  /trips              // List trips
GET  /trips/active       // Active trips
POST /trips/{id}/start   // Start trip
POST /trips/{id}/complete // Complete trip

// Passenger Management
GET  /deliveries         // Passenger deliveries
POST /deliveries/{id}/pickup   // Mark pickup
POST /deliveries/{id}/deliver  // Mark dropoff
```

### Real-Time Events
```dart
// WebSocket Events
'trip.started'           // Trip has begun
'trip.completed'         // Trip finished
'passenger.picked_up'    // Passenger boarded
'passenger.dropped_off'  // Passenger arrived
'location.updated'       // Vehicle location update
```

## 🧪 Development Guidelines

### Code Quality
- **Linting**: Follow `flutter_lints` rules
- **Testing**: Maintain >80% code coverage
- **Documentation**: Public APIs must be documented
- **State Management**: Use Bloc pattern consistently

### Git Workflow
```bash
# Feature branch
git checkout -b feature/new-feature
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Create pull request for review
```

### Code Generation
```bash
# Generate JSON serialization
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

## 📊 Performance Optimization

### Best Practices
- **Widget Rebuilding**: Minimize unnecessary rebuilds with `const` constructors
- **Image Optimization**: Use `cached_network_image` for remote images
- **Memory Management**: Proper disposal of controllers and listeners
- **Bundle Size**: Tree shaking and lazy loading for large assets

### Monitoring
- **Analytics**: Firebase Analytics for user behavior
- **Crash Reporting**: Firebase Crashlytics for error tracking
- **Performance**: Flutter DevTools for profiling

## 🔧 Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Location Permission Issues**
- Ensure permissions are properly configured in platform files
- Check location services are enabled on device
- Verify API key configuration

**Firebase Integration**
- Confirm configuration files are correctly placed
- Check Firebase project settings and bundle identifiers
- Verify internet connectivity

## 📱 Platform Support

| Platform | Minimum Version | Status |
|----------|-----------------|---------|
| Android  | API Level 21    | ✅ Supported |
| iOS      | iOS 12.0        | ✅ Supported |
| Web      | Chrome 84+      | 🚧 In Development |
| macOS    | macOS 10.14+    | 🚧 Planned |
| Windows  | Windows 10+     | 🚧 Planned |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Fork the repository
# Clone your fork
git clone https://github.com/your-username/nitoroute.git

# Add upstream remote
git remote add upstream https://github.com/your-org/nitoroute.git

# Create feature branch
git checkout -b feature/your-feature-name
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Documentation**: [https://docs.nitoroute.com](https://docs.nitoroute.com)
- **Issues**: [GitHub Issues](https://github.com/your-org/nitoroute/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/nitoroute/discussions)
- **Email**: support@nitoroute.com

## 🗺️ Roadmap

### Version 1.1 (Q2 2024)
- [ ] Web platform support
- [ ] Enhanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode theme

### Version 1.2 (Q3 2024)
- [ ] AI-powered route optimization
- [ ] Advanced reporting features
- [ ] Parent-teacher communication module
- [ ] Emergency alert system

### Version 2.0 (Q4 2024)
- [ ] Desktop applications (Windows, macOS)
- [ ] School bus fleet management
- [ ] Payment processing integration
- [ ] Advanced scheduling system

---

**Built with ❤️ using Flutter**
