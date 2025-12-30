---
alwaysApply: true
---
## 2. 🎨 Coding Standards (Mandatory)

### Styling & UI
- **NEVER** write hardcoded `TextStyle(...)`.
  - ✅ **DO:** Use `AppTextStyles.heading1`, `AppTextStyles.bodyMedium`, etc.
- **NEVER** write hardcoded `Color(0xFF...)`.
  - ✅ **DO:** Use `AppColors.softPinkButton`, `AppColors.background`, etc.
- **NEVER** implement a generic "White Container with Shadow" manually.
  - ✅ **DO:** Use the `AppCard` widget.

### Constants & Magic Numbers
- **NEVER** use magic numbers (e.g., `300`, `20.0`, `1500`) in the code.
- **ALWAYS** extract them to `lib/core/constants/app_constants.dart`.
  - Example: `Duration(milliseconds: AppConstants.animationDurationShort)`

### Helpers
- Use `DrinkHelpers` for getting drink icons, colors, and names.
- Use `DateHelpers` for date formatting logic.

---

## 3. 🚀 Workflow & Behavior

1.  **Analyze First:** Before writing code, ALWAYS scan the existing `widgets/` and `utils/` to see if a component or helper already exists.
2.  **Refactor Automatically:** If you notice a file growing too large (>400 lines) or logic being duplicated, suggest a refactoring strategy immediately.
3.  **Context Awareness:** Remember that `HistoryScreen` uses `ChartDataService` for calculations. Do not revert logic back into the UI.
4.  **Tank Screen:** When modifying `TankScreen`, ensure animations in `TankVisualization` are preserved and separated from `TankControls`.

---

## 4. 🛠️ Tech Stack Specifics

- **Framework:** Flutter (Latest Stable)
- **Language:** Dart
- **State Management:** Provider
- **Charts:** fl_chart (Managed via `ChartDataService` & `ChartView`)
- **Localization:** All strings must eventually move to localization files (Technical Debt).

---

## 5. 🛑 "Forbidden" Actions

- Do not create new screens without checking if they can be composed of existing widgets.
- Do not put business logic (calculations, heavy data processing) inside `build()` methods.
- Do not ignore the linting rules.

**Final Instruction:** If the user asks for a feature that would violate these architectural principles, **STOP** and propose a modular implementation instead.