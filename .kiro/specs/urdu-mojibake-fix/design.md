# Design Document: Urdu Mojibake Fix

## Overview

This change repairs corrupted Urdu display text in the worker services setup flow and worker settings flow while preserving the existing English copy, `AppController` locale switching, and right-to-left layout behavior. The implementation is intentionally narrow: replace mojibake literals with verified UTF-8 Urdu in the existing bilingual fields and helpers, add only the localization entries or small normalization helper needed to make the affected surface consistent, and avoid a broad UI rewrite.

The affected runtime path is:

```text
AppController.locale / isUrdu
        |
        +--> WorkerServicesSetupScreen
        |      - _skillNamesEn / _skillNamesUr
        |      - _servicesMap ServiceItem titleEn/titleUr
        |      - setup labels, validation, dialogs, feedback
        |
        +--> mazdoor_flow.dart
               - bilingual(en, ur) helper
               - MzScaffold / RoleBottomNav
               - SettingsScreen at /shared/settings

AppLocalizations.t(key) --> locale-specific map --> visible text
```

## Goals and Non-Goals

### Goals

- Replace all known mojibake in the worker setup title, language toggle, profession header, explanatory text, service names, prices, custom-service controls, validation, duplicate-service dialog, save confirmation, and error feedback.
- Review and repair the worker settings surface reached through `/shared/settings` when the active role is worker.
- Preserve every existing valid English meaning and the current `AppController.toggleLanguage`, `setLocale`, role, navigation, and RTL behavior.
- Define a repeatable repository scan that catches mojibake markers in Dart source, localization data, and checked-in display fixtures.
- Safely handle legacy persisted service labels without changing the canonical English service identity or unrelated profile data.

### Non-Goals

- Replacing the project’s hand-written localization system with Flutter ARB generation or a new localization package.
- Translating unrelated screens that do not contain the identified defect.
- Changing Firestore schema, service prices, role semantics, navigation routes, or authentication behavior.
- Automatically rewriting arbitrary user-entered custom service names when their intended meaning cannot be established.

## Implementation Approach

### 1. Use minimal repair with a small shared boundary, not a wholesale centralization

The existing code already separates paired values in `ServiceItem(titleEn, titleUr)` and uses `bilingual(context, en, ur)` in `mazdoor_flow.dart`. Preserve those interfaces because they are stable and keep the diff low-risk. Replace corrupted Urdu literals in place with direct UTF-8 Unicode literals, keeping their English counterparts byte-for-byte and semantically unchanged.

For strings repeated across multiple worker surfaces or likely to be tested as localization keys, add explicit entries to `AppLocalizations` and resolve them through `AppLocalizations.t`. Do not move every existing literal into a new abstraction during this fix. This hybrid approach gives the affected shared labels one source of truth while avoiding a broad refactor of `mazdoor_flow.dart` and reducing the chance of changing layout or behavior.

The implementation should establish an affected-string inventory, including stable identifiers for:

- setup app bar title, language toggle, profession label, explanatory header, currency label, custom-service labels, hint text, checking/add/complete actions;
- setup validation, duplicate-service, save-success, and save-error feedback;
- plumber/electrician category names and every predefined service’s English/Urdu pair;
- worker settings labels, actions, dialogs, status messages, and feedback that are direct bilingual literals or localization values;
- any profile/service mapping labels read from Firestore.

### 2. Repair setup screen literals

In `worker_services_setup_screen.dart`:

- Replace `_skillNamesUr` with readable Urdu category names while leaving `_skillNamesEn` unchanged.
- Replace every `ServiceItem.titleUr` in `_servicesMap` with the intended Urdu service label. Keep each item’s `titleEn`, price, selection default, and list identity unchanged.
- Replace Urdu branches in `_addCustomService`, duplicate detection dialog, `_completeSetup`, and the success modal with valid Urdu. Keep interpolation placeholders such as `$title`, `$duplicate`, and `$e` intact and preserve the existing English branch.
- Replace the setup `AppBar`, language toggle label, top information card, currency label, custom-service form, loading text, and complete button Urdu branches.
- Keep `Directionality(textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr)`, arrow choices, controller toggling, and all state mutations unchanged.

Where a string is moved to `AppLocalizations`, use stable keys and a single interpolation mechanism rather than concatenating translated fragments. If a dynamic error contains an exception, retain the existing error detail after a translated prefix and ensure the prefix itself is clean.

### 3. Review and repair worker settings

In `mazdoor_flow.dart`, inspect `SettingsScreen` and all worker-only settings widgets, not only the route declaration. Repair direct bilingual Urdu values and replace any corrupted localization values with valid Urdu. Continue using `bilingual(context, en, ur)` where it is already the local convention unless the same label is shared elsewhere and should use an `AppLocalizations` key.

Do not change the route constant `/shared/settings`, role detection, bottom navigation labels, settings action callbacks, or `AppController` calls. The screen must still render under the active role and preserve the current layout direction after toggling.

### 4. Preserve localization and locale state

`app_localizations.dart` remains the lookup source for its existing keys. Add only affected missing keys when centralization is beneficial. `AppLocalizations.t` must retain its current language selection and fallback behavior; if fallback behavior is strengthened, it must return a clean documented fallback and never a known mojibake value.

`app_state.dart` should not require behavioral changes. Tests must demonstrate that:

- `Locale('en')` selects English values;
- `Locale('ur')` selects valid Urdu values;
- `toggleLanguage()` changes only locale-dependent display output;
- selected services, edited prices, worker role, and settings state remain unchanged across a toggle;
- Urdu still supplies RTL directionality.

### 5. Safely handle persisted labels

Firestore documents currently store both `titleEn` and `titleUr` in `skills`, plus `categoryNameEn` and `categoryNameUr`. The canonical identity for matching predefined services is `titleEn`; therefore repair logic must never use corrupted Urdu text as the identity key.

At the persistence boundary, use this precedence:

1. Match predefined services by canonical `titleEn` (case-insensitive only where the existing code already does so).
2. For a recognized predefined English identity, display and, on the next successful save, write the canonical valid Urdu pair from `_servicesMap`.
3. If a legacy record has a corrupted/missing Urdu value but a recognized English identity, repair only the Urdu display value.
4. For custom services, preserve the user’s valid English identity and do not invent a translation. If the custom Urdu value is corrupted, use the safe documented fallback (the custom English label) rather than silently changing the service identity.
5. Preserve price, selection, category identity, timestamps, and unrelated profile fields. Do not perform a repository-wide or account-wide migration as part of screen rendering.

A normalization helper may be introduced in the service mapping layer if it can be pure and independently tested. It should return a copied normalized model, not mutate the Firestore map in place, and should be applied before rendering and before writing a selected service back.

## Components and Interfaces

### Existing components retained

- `AppController`: owns `Locale`, `isUrdu`, `toggleLanguage`, and role state.
- `AppScope`: exposes the controller to worker screens.
- `AppLocalizations`: maps localization keys to English/Urdu values.
- `WorkerServicesSetupScreen`: owns category/service definitions, editable prices, validation, persistence, and setup UI.
- `SettingsScreen` in `mazdoor_flow.dart`: worker settings route and bilingual UI.

### Optional pure normalization interface

If persisted repair cannot remain simple inline mapping, define a small pure boundary similar to:

```dart
ServiceItem normalizePersistedService({
  required Map<String, dynamic> data,
  required List<ServiceItem> predefined,
});
```

The function must preserve `titleEn`, price, and selection semantics, select the canonical Urdu title for known predefined English identities, and fall back safely for unknown custom values. It must not perform Firestore I/O.

### Scan interface

Provide a repository test or validation script that accepts the relevant source roots and reports:

```text
file:line:column: matched marker and surrounding string
```

The scan covers Dart source and checked-in display data, excludes `.dart_tool`, build outputs, generated binaries, and test fixtures intentionally containing bad examples, and checks both user-visible literals and comments. A fixture-based test should verify a bad marker fails with a location and clean files pass.

## Data Model and Invariants

`ServiceItem` remains the runtime model:

```text
(titleEn: canonical identity, titleUr: display translation, price, isSelected)
```

Invariants:

- `titleEn` is unchanged for every predefined service.
- Every predefined `titleUr` is UTF-8, non-empty, contains intended Urdu/Arabic-script code points, and contains none of `Ø`, `Ù`, `Ã`, `Â`, or `â`.
- English and Urdu branches are both non-empty for every affected label.
- Locale changes do not alter service list membership, selection, price, role, or persisted English identity.
- Known legacy records normalize to the same canonical `titleEn` and valid Urdu display value.
- Unknown custom records are not destructively translated or renamed.

## Error Handling

- Missing localization keys retain the existing fallback contract unless a clean fallback is explicitly defined; a fallback must never expose a mojibake literal.
- Invalid or missing persisted `titleUr` values must not prevent the worker setup screen from loading. Use the canonical predefined translation or the custom English label fallback.
- Malformed persisted service maps continue to be skipped or defaulted according to current behavior; normalization must not introduce a new crash path.
- Firestore read/write failures retain the current user-facing error flow, with only the Urdu prefix repaired.
- A scan failure is a release-blocking validation failure and must identify the exact file and location.
- If Urdu font/rendering is unavailable, text should remain valid Unicode and readable according to the existing Flutter font fallback; this design does not introduce a font dependency.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system. These properties bridge the requirements to executable tests; bounded UI examples and smoke checks complement them where universal generation is not appropriate.*

### Property 1: Affected localization values are clean and complete

For all affected localization keys and all supported locales, the resolved value is non-empty, contains no known mojibake marker, and contains intended Urdu/Arabic-script characters whenever the locale is Urdu; English values preserve their existing meaning.

**Validates: Requirements 1.3, 2.1, 2.2, 2.4, 5.1, 5.2**

### Property 2: Repository encoding scan rejects corrupted display text

For all checked-in Dart source and display-data files in the scan scope, no user-visible string or comment contains a known mojibake marker; if a marker is introduced, the validation result includes its file and source location.

**Validates: Requirements 1.3, 3.1, 3.3, 3.4, 4.4, 5.1**

### Property 3: Locale switching preserves worker state

For any valid worker setup state containing selected services, prices, role, and settings values, switching from English to Urdu and back changes only localized display text and directionality; all non-localized state remains equivalent.

**Validates: Requirements 2.3, 2.5, 5.5**

### Property 4: Persisted service normalization preserves identity and data

For any persisted service record, normalization preserves a recognized canonical English service identity, price, selection state, and unrelated fields; it replaces only a corrupted/missing Urdu value for known services, and preserves unknown custom English identity without inventing a destructive translation.

**Validates: Requirements 4.5, 2.3**

### Property 5: Valid Urdu remains valid through persistence round trip

For all predefined service and category records, writing the normalized bilingual representation and loading it again yields the same canonical English identity and valid Urdu display value without mojibake.

**Validates: Requirements 1.1, 2.2, 4.5, 5.1**

## Testing Strategy

### Unit and table-driven tests

- Test every affected localization key in English and Urdu for non-empty clean output and translation differences where required.
- Test missing-key fallback in both locales.
- Test the pure persisted-label normalizer with known legacy mojibake, missing Urdu, valid predefined Urdu, unknown custom labels, malformed maps, prices, and selection states.
- Test the marker scanner with clean and intentionally corrupted fixtures; assert diagnostics contain path and line/column.

### Widget tests

- Render `WorkerServicesSetupScreen` in Urdu and assert the AppBar title, top information header, profession, category/service labels, and key controls contain Urdu and no markers.
- Exercise empty custom service, invalid price, duplicate service, successful add, no-selection completion, save success, and save error paths in Urdu.
- Render the same setup screen in English and assert existing English title/header/action meaning.
- Render `/shared/settings` as a worker in both locales, exercise language/role/settings actions and dialogs, and assert visible text remains clean.
- Toggle language after selecting services and editing prices; assert state survives and Directionality changes as expected.

### Integration/manual checks

- With representative mocked Firestore documents, load legacy corrupted labels and verify canonical display and subsequent safe save.
- Perform a manual Urdu screenshot pass for the setup AppBar and top card, plus the worker settings route, because font shaping and visual RTL alignment are rendering concerns.
- Run `flutter analyze` and the available test suite after the focused tests.

Property-based tests are appropriate for pure normalization and mapping invariants, but not for Firebase I/O, visual layout, or one-time configuration. Use at least 100 generated cases for each pure property test; tag tests with `Feature: urdu-mojibake-fix, Property N: ...`.

## Repository Validation and Release Gate

The implementation review must explicitly include:

- `lib/screens/worker_services_setup_screen.dart`, including `_skillNamesUr`, `_servicesMap`, all Urdu feedback, and setup header;
- `lib/l10n/app_localizations.dart` and `lib/app_state.dart`;
- `lib/screens/mazdoor_flow.dart`, including `/shared/settings` and worker-specific bilingual labels;
- repository-wide scan results for other Dart and checked-in display data;
- any profile/service mapping or normalization helper.

Release is blocked if the scan reports a marker in user-visible text, affected Urdu lookup is empty, English meaning changes unintentionally, or `flutter analyze` introduces a new error attributable to this change.

## Risks and Rollback

### Risks

- A literal replacement may use an unnatural translation or alter the intended service meaning. Mitigate with an explicit bilingual inventory and Urdu review of each affected value.
- Persisted records may contain inconsistent English/Urdu pairs. Match by `titleEn` and repair only the display translation.
- Moving too many strings into localization could change fallback behavior or introduce missing keys. Keep centralization limited to shared/affected entries and test every key.
- Repository scans may flag harmless Unicode-like comments or fixtures. Classify intentional fixtures explicitly while keeping production source and comments clean.
- RTL text can change line wrapping or visual spacing. Validate the AppBar/top card and settings screens on a real Flutter render, not only source scans.

### Rollback

The change is source-only and can be reverted as one commit without a data migration. Roll back the localized literal/key changes and optional normalization helper while retaining existing Firestore records; the old records remain readable because the runtime fallback is non-destructive. If a release reveals a bad translation, revert only the affected mapping entry, preserving the scanner/tests and English behavior. Do not run a destructive Firestore rewrite as part of rollback.
