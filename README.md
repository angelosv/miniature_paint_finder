# Miniature Paint Finder

A Flutter application for finding and organizing miniature paints for hobbyists. This app helps you keep track of your paint collection and find equivalent colors across different paint brands.

## Features (Planned)

- Cross-platform support for iOS and Android
- Firebase authentication for user accounts
- Cloud storage for saving paint collections
- Search for similar paints across brands
- Barcode scanning for quick paint identification
- Color matching using camera

## Setup

### Prerequisites

- Flutter SDK
- Android Studio (for Android development)
- Xcode (for iOS development)
- Firebase account

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Set up Firebase for your project following the instructions at [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
4. Configure environment variables (see Environment Configuration below)
5. Run on your device or emulator using `flutter run`

## Environment Configuration

This app uses automatic environment detection based on Git branches and supports multiple configuration methods:

### Automatic Branch Detection

The app automatically detects the environment based on your current Git branch:

- **Production**: `main`, `master`, or branches containing `prod`
- **Staging**: branches containing `staging` or `stage`  
- **QA**: branches containing `qa` or `test`
- **Development**: all other branches (default)

### Configuration Methods

#### 1. Automatic Setup (Recommended)

Run the setup script to automatically configure based on your current branch:

```bash
./scripts/setup_env.sh
```

#### 2. Manual Configuration

Copy the appropriate environment file:

```bash
# For QA environment
cp config/qa.env .env

# For production
cp config/production.env .env

# For staging  
cp config/staging.env .env

# For development
cp config/development.env .env
```

#### 3. Quick Switch to QA

Use the dedicated QA script:

```bash
./scripts/switch_to_qa.sh
```

### Environment Variables

The app supports the following environment variables (in order of priority):

1. **Build-time defines** (highest priority)
2. **`.env` file variables**
3. **Environment-specific variables** (e.g., `QA_API_URL`)
4. **Default values** (lowest priority)

Available variables:

- `ENVIRONMENT`: `development`, `qa`, `staging`, `production`
- `API_BASE_URL`: Base URL for API calls
- `DEBUG_MODE`: Enable/disable debug mode
- `CACHE_TTL`: Cache time-to-live in seconds
- `SYNC_INTERVAL`: Background sync interval in seconds
- `SESSION_REPLAY_ENABLED`: Enable session replay
- `SESSION_REPLAY_SAMPLING_RATE`: Sampling rate percentage

### Current Configuration

To see the current configuration, check the app logs during startup. The configuration will be printed automatically.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
