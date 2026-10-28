# HabitFlow — Premium Habit Tracker Mobile Application

> **Build Better Habits, A Better You.**  
> A production-grade, offline-first Flutter application engineered with clean layered architecture, robust SQLite persistence, an isolated mathematical streak engine, and modern emerald UI.

---

## 🌟 Key Features

* **Intelligent Habit Management:** Create, edit, archive, and delete habits with flexible schedules (Every day, Weekdays, Custom Mon–Sun).
* **Multi-Modal Tracking:** Supports **Binary** (Done/Undo), **Numeric** (e.g. 2,000 ml water), and **Duration** (e.g. 20 min meditation) with aggregate daily logging.
* **Deterministic Streak Engine:** Isolated pure-Dart calculation engine respecting scheduled days, pending today states, and historical maximums.
* **Monthly Calendar Visualizer:** Month-by-month history with color-coded completed, missed, and unscheduled indicators.
* **Rich Analytics & Trends:** Weekly and monthly completion percentage trends and individual habit performance breakdown.
* **Modern Minimal Design:** Clean Emerald palette (`#16A34A`, `#22C55E`, `#F0FDF4`, `#111827`), rounded surfaces, bottom sheets, and full Light & Dark mode support.
* **Data Safety & Portability:** On-device SQLite database with composite unique constraints `(habit_id, local_date)`, JSON export/import capability, and safe data wiping.

---

## 🏗️ Technical Architecture

HabitFlow adheres strictly to **Feature-First Clean Architecture**:

```
lib/
├── app/                  # Application bootstrap, GoRouter, themes
├── core/                 # Database helpers, date utilities, design tokens
└── features/
    ├── habits/           # Habit domain entities, SQLite models, streak service
    ├── history/          # Calendar grid & date inspection
    ├── statistics/       # Trends & performance metrics
    ├── onboarding/       # Multi-step introduction walkthrough
    └── settings/         # Theme toggling, notifications & data management
```

### Core Technologies
* **Framework:** Flutter 3.x / Dart 3.x
* **State Management:** Riverpod (`flutter_riverpod`)
* **Routing:** GoRouter (`go_router`)
* **Local Persistence:** SQLite (`sqflite`) + `shared_preferences`
* **Typography & Charts:** Google Fonts (`Inter`) & `fl_chart`
* **Notifications:** `flutter_local_notifications`

---

## 🧮 Streak Calculation Engine Policy

The streak engine (`lib/features/habits/domain/services/streak_engine.dart`) adheres to strict deterministic rules:

1. **Unscheduled Days:** Unscheduled days do not break a streak (e.g., a Monday/Wednesday/Friday habit completed on Monday and Wednesday has a current streak of 2).
2. **Current Day Policy:** When a habit is scheduled for today but incomplete, it is marked as **pending**. It does **not** reset the active streak before midnight.
3. **Missed Occurrence:** Any past scheduled date without a completed target breaks the streak sequence.
4. **All-Time Best Streak:** Chronologically computed peak sequence across the entire habit history.
5. **Safe Division:** Returns `null` (displaying "No scheduled habits") rather than `NaN` or invalid percentages when there are zero eligible occurrences.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.10.0 or higher)
* Dart SDK (3.0.0 or higher)
* Android Studio / VS Code with Flutter extension
* Android SDK & Gradle

### Installation & Run

1. Clone or navigate to the repository:
   ```bash
   cd HabitFlow
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run automated unit tests:
   ```bash
   flutter test
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

5. Build Android APK:
   ```bash
   flutter build apk --debug
   ```

---

## 🧪 Automated Testing

Unit tests for streak computations, schedule eligibility, and boundary conditions are located in `test/unit/streak_engine_test.dart`.

```bash
flutter test test/unit/streak_engine_test.dart
```

---

## 📋 Evaluation Checklist & Deliverables

- [x] Feature-based Clean Architecture scaffold
- [x] Pure Dart Streak Calculation Engine
- [x] SQLite database schema with `(habit_id, local_date)` unique constraint
- [x] Full UI design system tokens (Light & Dark mode)
- [x] GoRouter navigation shell with bottom navigation bar
- [x] Comprehensive unit test suite for business logic
- [x] Complete technical documentation & README
