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
* **Official Branding:** Custom high-resolution green squircle leaf logo and native Android launcher icons across all screen densities.

---

## 🏗️ Technical Architecture

HabitFlow adheres strictly to a clean, flat, modular architecture:

```
lib/
├── app/                  # Application bootstrap & GoRouter
├── core/                 # Database helpers, date utilities, design tokens, notifications
├── habits/               # Habit models, SQLite repo, streak engine, UI & widgets
│   └── widgets/          # Hero progress, bottom sheets, badges, plant data
├── history/              # Calendar grid & retroactive date inspection
├── statistics/           # Analytics, fl_chart visualizations, performance metrics
├── onboarding/           # Animated splash screen, onboarding carousel & assets
├── settings/             # Themes, notifications, backup & data management
└── main.dart             # Application entry point
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

The streak engine (`lib/habits/streak_engine.dart`) adheres to strict deterministic rules:

1. **Unscheduled Days:** Unscheduled days do not break a streak (e.g., a Monday/Wednesday/Friday habit completed on Monday and Wednesday has a current streak of 2).
2. **Current Day Tolerance:** An uncompleted habit for "Today" does not break an active streak until the day elapses.
3. **Missed Scheduled Day:** Missing a scheduled past day immediately resets the active streak counter to 0.
4. **Historical Peak:** Best streak tracks all-time historical peak accurately.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.10.0 or later)
* Android Studio / VS Code with Flutter extension
* An active Android emulator or physical device

### Installation
```bash
# Clone the repository
git clone https://github.com/AwaisShahbir/HabitFlow.git

# Navigate to project directory
cd HabitFlow

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Run application
flutter run
```
