# Requirements Document

## Introduction

MazdoorLink supports English and Urdu through `AppLocalizations`, `AppController.locale`, and bilingual worker-facing screens. The worker services setup screen currently contains Urdu literals rendered as mojibake (for example, strings beginning with `Ø`, `Ù`, or `Ã`), including the services setup header and service names. The same encoding defect is visible in some comments and may explain garbled screenshot text. This feature defines the requirements for removing corrupted display text while preserving supported English and Urdu behavior. The implementation phase shall inspect and correct affected source strings; this document does not prescribe a particular code structure.

## Glossary

- **AppLocalizations**: The localization helper in `lib/l10n/app_localizations.dart` that maps localization keys to English and Urdu display values.
- **AppController**: The application state controller in `lib/app_state.dart` that stores the active `Locale` and toggles English and Urdu.
- **Mojibake**: Text produced when UTF-8 Urdu bytes are decoded or stored using an incompatible character encoding, commonly displayed with sequences such as `Ø`, `Ù`, `Ã`, `Â`, or `â`.
- **Worker Services Setup Screen**: The worker-facing screen in `lib/screens/worker_services_setup_screen.dart` that displays service names, rates, validation messages, and the services setup header.
- **Worker Settings Screen**: The shared settings screen in `lib/screens/mazdoor_flow.dart` reached through `/shared/settings` while the active role is worker.
- **Valid Urdu**: Intended Urdu Unicode text represented by Urdu/Arabic code points and rendered as meaningful Urdu words, not mojibake sequences.
- **Source Text**: Human-readable strings, comments, localization values, and persisted display labels stored in project files or data mappings.

## Requirements

### Requirement 1: Remove corrupted display text

**User Story:** As a worker, I want setup and settings screens to show readable labels, so that I can configure services without interpreting encoding artifacts.

#### Acceptance Criteria

1. WHEN the Worker Services Setup Screen renders in Urdu, THE Worker Services Setup Screen SHALL display Valid Urdu for the page title, language toggle, profession header, explanatory header text, service names, validation messages, duplicate-service dialog, save confirmation, and error messages.
2. WHEN the Worker Settings Screen renders in Urdu, THE Worker Settings Screen SHALL display Valid Urdu for every visible label, action, dialog, status, and feedback message supplied by bilingual helpers or direct literals.
3. IF a Source Text value contains a Mojibake marker in a user-visible string, THEN THE localization and worker-screen text SHALL replace the corrupted value with an intended English or Valid Urdu value before release.
4. WHEN the affected screens render in English, THE Worker Services Setup Screen and Worker Settings Screen SHALL preserve the existing valid English meaning for all corresponding labels and messages.

### Requirement 2: Preserve localization behavior

**User Story:** As a bilingual user, I want the language switch to remain predictable, so that correcting Urdu text does not break English or Urdu navigation.

#### Acceptance Criteria

1. WHEN AppController.locale has language code `en`, THE AppLocalizations SHALL resolve supported keys to English values.
2. WHEN AppController.locale has language code `ur`, THE AppLocalizations SHALL resolve supported keys to Valid Urdu values for the affected worker setup and settings content.
3. WHEN a worker toggles language on the Worker Services Setup Screen or Worker Settings Screen, THE AppController SHALL switch the displayed content between English and Urdu without changing the selected services, entered prices, worker role, or saved settings state.
4. IF a requested localization key has no value for the active language, THEN AppLocalizations SHALL use the defined fallback behavior and SHALL not display a Mojibake value.
5. WHEN Urdu is selected, THE Worker Services Setup Screen SHALL retain right-to-left layout behavior and THE Worker Settings Screen SHALL retain the existing bilingual layout behavior.

### Requirement 3: Establish encoding expectations

**User Story:** As a maintainer, I want a clear encoding contract for display strings, so that future edits cannot reintroduce mojibake.

#### Acceptance Criteria

1. THE Source Text SHALL be stored and reviewed as UTF-8, including Dart source files, localization values, worker service labels, and any checked-in display fixtures.
2. WHEN a developer adds or changes Urdu Source Text, THE developer SHALL store the intended Unicode characters directly or use a documented Unicode-safe localization representation that decodes to Valid Urdu at runtime.
3. IF a source scan finds Mojibake markers in user-visible strings or localization data, THEN the validation process SHALL report the file and string location as a failure.
4. WHEN non-user-facing comments contain encoding artifacts, THE affected comments SHALL be normalized or removed so that repository encoding scans do not conceal or confuse user-visible defects.

### Requirement 4: Cover the identified affected surface

**User Story:** As a product owner, I want the fix scoped to all known affected surfaces, so that the screenshot and related worker flows are corrected consistently.

#### Acceptance Criteria

1. WHEN the implementation is reviewed, THE review SHALL include `lib/screens/worker_services_setup_screen.dart`, including `_skillNamesUr`, `_servicesMap`, Urdu validation and dialog messages, completion messages, and the setup AppBar/header.
2. WHEN the implementation is reviewed, THE review SHALL include `lib/l10n/app_localizations.dart` and `lib/app_state.dart` to confirm that valid existing English/Urdu localization and locale toggling remain intact.
3. WHEN the implementation is reviewed, THE review SHALL include `lib/screens/mazdoor_flow.dart` for worker settings labels, direct bilingual strings, and the `/shared/settings` route.
4. WHEN repository-wide text validation runs, THE validation SHALL inspect other Dart source and checked-in display data for the same Mojibake patterns rather than limiting detection to the screenshot header.
5. IF the same corrupted value is persisted to or loaded from worker profile/service data, THEN the data mapping SHALL define how the display value is repaired or safely replaced without altering the corresponding valid English service identity.

### Requirement 5: Validate rendered output

**User Story:** As a tester, I want reproducible checks for both source and rendered text, so that the screenshot header and all affected strings are demonstrably fixed.

#### Acceptance Criteria

1. WHEN automated text validation runs, THE validation SHALL confirm that affected Urdu values contain no known Mojibake markers and contain intended Urdu characters where Urdu support is specified.
2. WHEN localization tests run for English and Urdu, THE tests SHALL verify that every affected key returns a non-empty value and that the English and Urdu values are not identical solely because of a missing translation.
3. WHEN widget tests or manual QA render the Worker Services Setup Screen in Urdu, THE rendered AppBar title and top information header SHALL be readable Urdu and SHALL not show `Ø`, `Ù`, `Ã`, `Â`, or `â` mojibake sequences.
4. WHEN widget tests or manual QA render the Worker Services Setup Screen in English, THE rendered AppBar title and top information header SHALL match the existing English meaning and SHALL remain readable.
5. WHEN widget tests or manual QA exercise the Worker Settings Screen in both locales, THE rendered visible labels and dialogs SHALL contain no Mojibake and SHALL preserve role switching, language switching, and settings navigation behavior.
6. WHEN Flutter analysis and the available test suite run after implementation, THE project SHALL complete those checks without new localization, encoding, or rendering failures attributable to this change.
