---
description: Repository Information Overview
alwaysApply: true
---

# LIVE BOT Information

## Summary
LIVE BOT is a Flutter mobile application for monitoring football matches and sending notifications based on specific game conditions. The app integrates with football data APIs and web scraping from SofaScore to fetch live match data, with a fallback mechanism to use sample data when API access is unavailable. It specifically targets matches that remain 0-0 after 8 minutes of play, suggesting a potential betting opportunity for over 2.5 goals.

## Structure
- **lib/**: Core application code organized in MVC pattern
  - **controllers/**: Business logic for match monitoring
  - **models/**: Data models for football fixtures
  - **screens/**: UI components and screens
  - **services/**: API integration, web scraping, and notification services
- **android/**, **ios/**, **web/**, **windows/**, **macos/**, **linux/**: Platform-specific code
- **test/**: Test files
- **test_*.dart**: Various test scripts for API integration testing

## Language & Runtime
**Language**: Dart
**Version**: SDK >=3.5.0 <4.0.0
**Framework**: Flutter
**Package Manager**: pub (Dart package manager)

## Dependencies
**Main Dependencies**:
- flutter: Flutter SDK
- http: ^1.2.2 (HTTP client for API requests and web scraping)
- html: ^0.15.4 (HTML parsing for web scraping)
- shared_preferences: ^2.3.2 (Local storage)
- flutter_local_notifications: ^17.2.2 (Push notifications)
- intl: ^0.19.0 (Date formatting)

**Development Dependencies**:
- flutter_test: Flutter testing framework
- flutter_lints: ^4.0.0 (Linting rules)

## Build & Installation
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios
```

## Data Sources
**API Integration**: API-Football via RapidAPI
- Requires RapidAPI key with API-Football subscription
- Default key: 239a1e02def2d210a0829a958348c5f5
- Endpoints: fixtures, live matches, timezone

**Web Scraping**: SofaScore
- Implemented in `sofascore_scraper_service.dart`
- Uses multiple user agents and referrers to avoid detection
- Supports both HTML parsing and direct JSON API access
- Multiple fallback mechanisms for robust data retrieval

**Fallback Mechanism**:
- Sample data mode for development/testing
- Automatic fallback to sample data on API/scraping errors

## Key Components

### SofaScore Scraper Service
**File**: `lib/services/sofascore_scraper_service.dart`
**Features**:
- User agent rotation with 10 different browser signatures
- Random referrer selection from 10 different sources
- Multiple URL sources for redundancy (with/without www, different domains)
- JSON and HTML parsing capabilities
- Comprehensive CSS selector system with 100+ selectors for robust scraping
- Multiple fallback mechanisms including pattern matching and common team detection
- Progressive retry system with increasing delays
- Random delays between requests to avoid rate limiting
- Detailed logging for troubleshooting
- Fallback to sample data when scraping fails

### Hybrid Football Service
**File**: `lib/services/hybrid_football_service.dart`
**Purpose**: Coordinates between different data sources
**Features**:
- Attempts to fetch real data from SofaScore
- Multiple retry attempts for reliability
- Falls back to sample data when real data is unavailable

### Monitor Controller
**File**: `lib/controllers/monitor_controller.dart`
**Features**:
- Periodically checks match status (configurable interval)
- Identifies matches meeting alert criteria (0-0 after 8 minutes)
- Triggers notifications for qualifying matches
- Prevents duplicate notifications with tracking system

### Error Handling
- Global error handling with detailed logging
- Comprehensive try-catch blocks throughout the app
- Multiple retry mechanisms for data fetching
- Automatic fallback to sample data on API/scraping failures
- Robust model parsing for malformed responses