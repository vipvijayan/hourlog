# HourLog ⏱️

A compact, delightful time-tracking Flutter app for quick check-ins and history review.

Whether you want a minimal personal time logger or a clean example of Provider + Sqflite usage, HourLog is compact, readable, and easy-to-extend.

---

## ✨ Highlights

- Lightweight offline-first time tracking using `sqflite`.
- Simple check-in / check-out flow with history, editing, and per-day/week/month totals.
- Dependency-free UI widgets where possible; provider-based state management.
- Focused on clarity — easy to read and extend for new features.
- Includes seeded sample records for a ready-to-run demo experience on fresh installs.

---

## 📸 Screenshot

![HourLog sample view](screenshots/hourlog-sample.png)

---

## 🚀 Quick Start

Prerequisites:

- Flutter SDK (stable)
- A connected device or simulator

Run locally:

```bash
flutter pub get
flutter run
```

> On an untouched install, the app seeds a few sample time records automatically so you can explore the UI without manual data entry.

Run static analysis:

```bash
flutter analyze
```

Run tests (if any):

```bash
flutter test
```

---

## 🔍 Project Structure (high level)

- `lib/main.dart` — app entry and theme setup. ([lib/main.dart](lib/main.dart))
- `lib/screens/home_screen.dart` — main UI, app lifecycle, and animation controller. ([lib/screens/home_screen.dart](lib/screens/home_screen.dart))
- `lib/screens/components/home_screen_components.dart` — extracted stateless UI components used by the home screen (AppBar, status card, action button, summary widgets). ([lib/screens/components/home_screen_components.dart](lib/screens/components/home_screen_components.dart))
- `lib/widgets/weekly_bar_chart.dart` — small dependency-free bar chart for Mon–Fri. ([lib/widgets/weekly_bar_chart.dart](lib/widgets/weekly_bar_chart.dart))
- `lib/widgets/edit_record_dialog.dart` — dialog used to edit a time entry. ([lib/widgets/edit_record_dialog.dart](lib/widgets/edit_record_dialog.dart))
- `lib/providers/time_provider.dart` — app state, persistence orchestration and helpers. ([lib/providers/time_provider.dart](lib/providers/time_provider.dart))
- `lib/models/time_record.dart` — data model for time records. ([lib/models/time_record.dart](lib/models/time_record.dart))
- `lib/database/database_helper.dart` — small `sqflite` wrapper for persistence. ([lib/database/database_helper.dart](lib/database/database_helper.dart))
- `lib/utils/duration_formatter.dart` — human-friendly duration formatting helpers. ([lib/utils/duration_formatter.dart](lib/utils/duration_formatter.dart))

---

## 🧭 How it works (overview)

- The UI reads and updates data through `TimeProvider` (a `ChangeNotifier`) which wraps a tiny `DatabaseHelper` built on `sqflite`.
- Checking in inserts a `TimeRecord` with a `check_in` timestamp; checking out writes `check_out` and recomputes totals.
- The History screen groups records by day and shows a compact list with editing and deletion support.

Key implementation notes:

- Stateless components: the home screen's visual parts were extracted to `lib/screens/components/home_screen_components.dart` to keep `HomeScreen` focused on lifecycle and animation concerns.
- Chart sizing: `weekly_bar_chart.dart` uses a bounded `SizedBox` to prevent RenderFlex unbounded-height errors when embedded in scrollable content.

---

## 🛠️ Development notes & tips

- If you see a RenderFlex error mentioning "incoming height constraints are unbounded", check the chart widget and ensure its vertical size is bounded (the project already adds a `SizedBox` to the chart).
- Use `flutter analyze` frequently — the project is configured for clean analyzer output.
- To add features, start by updating `TimeProvider` and then surface actions in the UI via the provider.

---

## 🎯 Contributing

Contributions are welcome — open an issue or create a PR. Keep changes small and focused; add tests where appropriate.

Suggested workflow:

1. Create a feature branch.
2. Run `flutter analyze` and `flutter test`.
3. Open a PR with a short description of the intent.

---

## ⚖️ License

No license file is included by default. Add a `LICENSE` file to clarify usage and contribution terms.

---

## 📬 Contact

If you'd like help extending the project or integrating it with a backend, open an issue or reach out in the repo.

Happy hacking! 🧡

