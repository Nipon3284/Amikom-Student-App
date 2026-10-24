# Amikom Student

A modern mobile client application for the Universitas Amikom Purwokerto student portal, built with Flutter, Riverpod, and clean architectural principles.

---

## Overview

Amikom Student provides a streamlined, responsive, and secure mobile interface for Universitas Amikom Purwokerto students to access academic data directly from their smartphones. The application communicates with the university portal (`student.amikompurwokerto.ac.id`), parsing and presenting schedules, academic records, attendance, and study plans in an intuitive dashboard.

---

## Key Features

- **Authentication & Security**
  - Secure login with Student ID (NPM) and portal password.
  - Biometric authentication (Fingerprint and Face ID) via `local_auth`.
  - Encrypted local token and credential storage using `flutter_secure_storage`.
  - Automated session persistence and cookie lifecycle management.

- **Academic Dashboard**
  - High-level overview of academic progress: Cumulative GPA (IPK), total credit units (SKS), and active semester.
  - Quick action shortcuts and upcoming class indicators.

- **Class & Exam Schedules**
  - Daily and weekly lecture schedules with room numbers and lecturers.
  - Integrated exam schedule view with timeline tracking.

- **Attendance Management (Presensi)**
  - Real-time attendance monitoring per course.
  - Attendance threshold alerts to ensure compliance with exam eligibility.

- **Study Plan (KRS) & Academic Grades (KHS)**
  - View enrolled courses and credit weights in the current semester.
  - Semester-by-semester Grade Point Average (IPS) and cumulative transcript review.

- **User Experience & Personalization**
  - Adaptive Dark and Light themes.
  - Smooth loading states with Shimmer effects.
  - Offline-resilient state caching with Riverpod and SharedPreferences.

---

## Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.11.0)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Networking & Session**: [Dio](https://pub.dev/packages/dio), `dio_cookie_manager`, `cookie_jar`
- **Data Extraction**: `html` parser
- **Local Persistence & Security**: `flutter_secure_storage`, `shared_preferences`, `local_auth`
- **Typography & Icons**: `google_fonts`, `lucide_icons`

### Project Structure

```text
lib/
├── core/
│   ├── models/        # Data models (Student profile, Schedules, Grades, Attendance)
│   ├── network/       # HTTP client, Cookie manager, and Portal scraper
│   ├── providers/     # Global state and Riverpod providers
│   ├── storage/       # Secure storage and persistent preferences
│   ├── theme/         # Design tokens, color schemes, and typography
│   └── widgets/       # Shared UI components and layout helpers
├── features/
│   ├── dashboard_screen.dart
│   ├── jadwal/        # Schedule components and views
│   ├── presensi/      # Attendance records and views
│   ├── krs_screen.dart
│   ├── nilai_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   └── splash_screen.dart
└── main.dart          # Application entrypoint
```

---

## Getting Started

### Prerequisites

- Flutter SDK (version 3.19 or later recommended)
- Android Studio or VS Code with Flutter extension
- Android SDK (API level 21 minimum) or iOS development environment

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<username>/amikom-student.git
   cd amikom-student
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the development build:**
   ```bash
   flutter run
   ```

4. **Build APK for Android:**
   ```bash
   flutter build apk --release
   ```

---

## Disclaimer

This is an independent community project developed for Universitas Amikom Purwokerto students and is not officially affiliated with, maintained by, or endorsed by Universitas Amikom Purwokerto. All portal endpoints and data structures belong to their respective university systems.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
