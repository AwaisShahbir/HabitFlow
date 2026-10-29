# HabitFlow Technical Architecture & Engineering Decisions

## 1. Architectural Philosophy
HabitFlow is structured using a **Clean, Modular Feature-Based Architecture**, designed specifically for high maintainability, testability, and offline reliability.

```
lib/
├── app/                  # Application bootstrap, routing & global theming
├── core/                 # Shared foundation (SQLite DB, themes, date utils, notifications)
├── habits/               # Habit models, SQLite repo, streak engine, UI & widgets
│   └── widgets/          # Hero progress, bottom sheets, badges, plant data
├── history/              # Monthly calendar visualization & retroactive day inspection
├── statistics/           # Trends, completion rates & performance analytics (fl_chart)
├── onboarding/           # Walkthrough screens, animated splash & asset buffers
├── settings/             # Theme toggling, reminder toggles, data reset & export
└── main.dart             # Application entry point
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
The streak engine is implemented in `lib/habits/streak_engine.dart` as an isolated pure Dart service without any UI or Flutter framework dependencies.
