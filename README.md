# NitoRoute

A Flutter mobile application for school transport management with real-time GPS tracking and multi-role user support.

## Features

- **Multi-Role Authentication**: Drivers, Guardians, and Administrators
- **Real-Time GPS Tracking**: Live vehicle tracking with location updates
- **Route Management**: Optimized routes with dynamic stop management
- **Push Notifications**: Real-time alerts for delays and arrivals
- **Modern UI**: Material 3 design with responsive layout

## Quick Start

### Prerequisites
- Flutter SDK 3.19.0+
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone and install dependencies:
```bash
git clone https://github.com/Matt-di/nidoroute-app.git
cd nitoroute
flutter pub get
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

3. Add Google Maps API key:
```bash
# Get API key from https://console.cloud.google.com/
# Add to .env: GOOGLE_MAPS_API_KEY=your_api_key_here
```

4. Run the app:
```bash
flutter run
```

## User Roles

- **Driver**: Start/complete trips, passenger pickup confirmation, real-time location sharing
- **Guardian**: Track children's buses, receive arrival notifications
- **Administrator**: Manage routes, users, and system settings

## Technology Stack

- **Framework**: Flutter 3.19.0+
- **State Management**: Bloc Pattern
- **Maps**: Google Maps Flutter
- **Backend**: RESTful API integration
- **Real-Time**: WebSocket communication

## Platform Support

| Platform | Status |
|----------|---------|
| Android  | Supported |
| iOS      | Supported |
| Web      | In Development |

## Build for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

