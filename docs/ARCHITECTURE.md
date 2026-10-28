# HabitFlow Technical Architecture & Engineering Decisions

## 1. Architectural Philosophy
HabitFlow is structured using **Feature-First Clean Architecture**, designed specifically for high maintainability, testability, and offline reliability.

```
lib/
├── app/                  # Application bootstrap, routing & global theming
│   ├── app.dart
│   ├── router.dart
│   └── ...
├── core/                 # Shared foundation across all features
│   ├── database/         # SQLite schema, migrations & db client
│   ├── theme/            # Design tokens, color system & Material 3 specs
│   ├── utils/            # Pure date normalization, formatting & math
│   └── widgets/          # Shared reusable UI atoms & molecules
└── features/             # Feature slices (Domain-Driven, Layered)
    ├── habits/           # Habit creation, editing, scheduling, streak engine
    │   ├── domain/       # Pure Dart entities, streak service, repository contracts
    │   ├── data/         # Models, local datasources & repository implementations
    │   └── presentation/ # Riverpod controllers, UI screens & bottom sheets
    ├── history/          # Monthly calendar visualization & day inspection
    ├── statistics/       # Trends, completion rates & performance analytics
    ├── onboarding/       # Walkthrough screens & first-launch persistence
    └── settings/         # Theme toggling, reminder toggles, data reset & export
```

---

## 2. State Management Strategy: Riverpod
### Why Riverpod over Vanilla Bloc or Provider?
1. **Compile-Time Safety:** Eliminates `ProviderNotFoundException` runtime errors.
2. **No `BuildContext` Leaks:** Business logic and data providers can be read and invalidated completely decoupled from the widget tree.
3. **Painless Unit Testing:** Providers can be easily overridden in tests without spinning up heavy mock widgets or context harnesses.
4. **Reactive Caching:** Easily auto-disposes listeners and streams when screens unmount.

---

## 3. Data Integrity & Storage Strategy
### SQLite with Foreign Key Cascades & Composite Constraints
- Local database engine: SQLite (`sqflite`).
- **Unique Constraint:** `(habit_id, local_date)` on `habit_completions`. This enforces idempotent updates—tapping a habit twice or updating progress on the same date updates the single aggregate row instead of generating duplicate entries.
- **Cascade Deletion:** Deleting a habit automatically purges all child completion records via `ON DELETE CASCADE`.
- **Soft Deletion / Archival:** Users can archive habits rather than deleting them, preserving historic completion statistics while suppressing them from future schedules.

---

## 4. Streak Calculation Engine Specification
The streak engine is implemented in `lib/features/habits/domain/services/streak_engine.dart` as an isolated pure Dart service without any UI or Flutter framework dependencies.

### Key Rules Implemented:
1. **Consecutive Scheduled Occurrences:** Only days matching the habit's configured schedule (Daily, Weekdays, or Custom Mon-Sun) count. Unscheduled days are strictly skipped and do not break streaks.
2. **Pending Today Policy:** If a habit is scheduled for today but is not yet marked done, it remains in a **pending** state. It does not break the active streak until the day has elapsed.
3. **Missed Scheduled Day:** If a scheduled date in the past has passed without satisfying the configured target, the current streak is interrupted and resets.
4. **Best Streak:** Computed by stepping forward chronologically from `startDate` through all scheduled occurrences and recording the peak sequence.
5. **Completion Rate Formula:**
   $$\text{Completion Rate} = \frac{\text{Completed Eligible Occurrences}}{\text{Total Eligible Occurrences}} \times 100$$
   Returns `null` instead of `NaN` or dividing by zero when there are no eligible occurrences.
