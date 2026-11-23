# MazdoorLink

MazdoorLink is a bilingual English/Urdu Flutter app backed by Firebase. New customer bookings are **inspection visits only**, not bookings for repair work.

## Visit workflow

- **Customer:** Home → Plumber or Electrician → approved workers in that category → worker profile → **Request a Visit**. The customer enters an address, a preferred date/time, and an optional note. The request goes only to that worker. Visit status is visible under **Visits**.
- **Worker:** Dashboard → **Visit Requests** to accept or decline the proposed time, cancel a confirmed visit, or mark it complete. **Accept new visit requests** can be turned off without hiding the profile or cancelling existing requests. Offline workers can still receive requests if their switch is on.
- Visits are free in this version. They are stored in `visit_requests`, separate from repair `jobs`, with no checkout, wallet deduction, commission, or automatic repair booking. Only the customer and assigned worker can read a visit's address and note.

## Rollout

Deploy the updated Firestore rules and indexes to your Firebase project and wait for the indexes to finish building before releasing the app:

```sh
firebase deploy --only firestore:rules,firestore:indexes --project YOUR_PROJECT_ID
```

The rules stop old clients from creating repair jobs. Existing repair bookings remain accessible under **Repair Bookings** or **Repair booking history** and can still be completed. No data migration is required: past job records and old `skills` fields are left untouched. The app no longer reads or writes skill catalogs. Approved workers who haven't set visit availability are accepting requests by default.

## Run and test locally

With Flutter installed and a local `.env` file in the repository root (an empty file is enough for the unit and widget tests):

```sh
flutter pub get
flutter test
flutter run
```

The Firestore rules tests use a local emulator, not production data. With Node.js and the Firebase CLI installed:

```sh
npm --prefix test/firestore install
firebase emulators:exec --only firestore --project demo-mazdoorlink-visits "npm --prefix test/firestore test"
```
