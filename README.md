# ALU Campus Incident Reporter (Mobile App)

Ever noticed a broken tap, a dead socket, or a water outage on campus and had no idea who to tell? This Flutter app fixes that. It's a role-based mobile app that connects students at African Leadership University (ALU) with campus operations. Students can report an issue, snap a photo, and follow it until it's sorted. Authorized staff can review, prioritize, assign, and resolve incidents in real time.

It covers the everyday stuff: broken facilities, water outages, electrical hazards, sanitation and safety concerns.

---

## What it does

### For students
- **ALU-only sign-in**: You can only register and log in with a verified `@alustudent.com` email, and you'll need to confirm it through the verification email.
- **Reporting an incident**:
  - Add a title and description, then pick a category (Broken Facilities, Water Shortages, Electricity Outages, Damaged Furniture, Sanitation, Safety Concerns, Network/Internet, or Other).
  - Choose where it happened (Main Building, Library, Cafeteria, Computer Labs, Dormitories, Sports Complex, and more).
  - Set a severity: Low, Medium, High or Critical.
  - Optionally attach several photos from the camera or gallery. They're uploaded to Firebase Storage.
- **Feed and search**: A live feed of incidents you can search by keyword and filter by category, status or priority.
- **My Reports**: A tab just for your own submissions, so you can watch their status change over time.
- **Privacy**: You can report anonymously. Other students won't see your name, and emails are never stored on reports. Staff can still look up who reported something so they can follow up and stop misuse.
- **"Me Too" upvotes**: If an issue affects a lot of people, hit the upvote. It helps staff see what needs attention first.

### For authorized staff
- **Role-based access (RBAC)**: The app recognizes `@alueducation.com` emails, or accounts with staff authorization, and gives them the staff view automatically.
- **Staff Command Center**: Live numbers for Pending Triage, Under Review, In Progress and Resolved, plus incident volume by category and a queue of urgent High/Critical reports.
- **Triage and status updates**: Staff move incidents through the full lifecycle:
  `Pending` -> `Under Review` -> `In Progress` -> `Resolved` / `Dismissed`
- **Resolution audit trail**: Staff can add resolution notes with timestamps, like "Plumbing contractor dispatched; new valve fitted."

---

## How it's built

The app uses clean architectural layers and the **MVVM (Model-View-ViewModel / Provider)** pattern. Here's the layout:

```
lib/
├── config/             # Application constants, theme definitions, and styling
│   ├── constants.dart
│   └── theme.dart
├── models/             # Immutable data models with Firestore serialization
│   ├── incident_model.dart
│   └── user_model.dart
├── services/           # Backend communication (Firebase Auth, Cloud Firestore, Firebase Storage)
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── providers/          # ChangeNotifier state management controllers
│   ├── auth_provider.dart
│   └── incident_provider.dart
├── screens/            # UI presentation layer
│   ├── splash_screen.dart
│   ├── auth/           # Login, Register, and Email Verification screens
│   ├── home/           # Main scaffold & tab views (Feed, My Reports, Dashboard, Profile)
│   │   └── tabs/dashboard/  # Staff command center and student transparency views
│   └── incident/       # Create Incident, Details view, Staff action bar, Status Update dialog
├── utils/              # Pure helpers (form and email validators)
│   └── validators.dart
├── widgets/            # Reusable UI components
│   ├── category_chip.dart
│   ├── custom_text_field.dart
│   ├── incident_card.dart
│   ├── loading_overlay.dart
│   ├── dashboard/      # Metric tile, urgent queue, category chart, pulse card, hotline card...
│   ├── photo_attachment_section.dart
│   ├── staff_reporter_contact.dart
│   ├── status_badge.dart
│   └── status_timeline.dart
└── firebase_options.dart # Platform configuration options
```

### State management
- **`AuthProvider`** handles the login lifecycle and session persistence. It also determines the user's role (`isStudent` vs `isStaff`), checks the ALU email domain, and tracks email verification.
- **`IncidentProvider`** listens to the live Firestore stream and applies the category, status, priority, and keyword filters. It also handles creating reports, updating statuses, upvoting, and deleting. Every change is confirmed by Firestore and flows back through the stream, so all screens stay in sync. A `ChangeNotifierProxyProvider` starts the subscription after login and clears everything on logout. If a write fails, it returns `false` and exposes an error message. Nothing is faked locally.

---

## Security and access control

- **Domain restriction and verification**: Only `@alustudent.com` (student) and `@alueducation.com` (staff) addresses can register or sign in. The app keeps you on the verification screen until your email is verified. The security rules repeat this check using the token's `email_verified` claim, so it can't be bypassed from the client.
- **No self-assigned roles**: A profile can only be created with the role that matches its email domain, and `role` can never be changed from the client. If you need extra staff, promote them manually in the Firebase Console.
- **Firestore rules (`firestore.rules`)**:
  - Only verified ALU users can read reports. User profiles (which contain emails) can only be read by their owner and staff.
  - Reports can't contain an email field, and anonymous reports must use the name "Anonymous".
  - Only a report's author can create it, and it has to start as `pending` with zero votes.
  - Staff can change only `status`, `priority`, assignment fields and history. Authors can only attach photo URLs to their own report. Anyone can add or remove their own upvote, and nobody else's.
  - Staff can delete any report. Authors can delete theirs only while it's still `pending`.
- **Storage rules (`storage.rules`)**: Only the report's author can upload (JPEG/PNG, under 5 MB). Only the author or staff can delete. You need a verified ALU account to read anything.

---

## Getting started

### What you'll need
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.13.0 or higher)
- Android Studio with an Android emulator (or a physical device / iOS simulator)
- A Firebase project (the free Spark plan is enough)
- Node.js, plus the Firebase CLI and FlutterFire CLI:
  `npm i -g firebase-tools` and `dart pub global activate flutterfire_cli`

### Firebase setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. **Authentication** -> Sign-in method -> enable **Email/Password**.
3. **Firestore Database** -> create a database (production mode).
4. **Storage** -> Get started (a bucket is created for you).
5. From the project folder, run `flutterfire configure` and choose your project and the Android/iOS platforms. This regenerates `lib/firebase_options.dart` and adds `android/app/google-services.json`. The app won't start while the template placeholder values are still in `firebase_options.dart`.
6. Deploy the security rules: run `firebase login`, then `firebase use <your-project-id>`, then `firebase deploy --only firestore: rules, storage`.

### Install and run
```bash
git clone <https://github.com/kenny260/report.git>
cd campus_incident_reporter
flutter pub get
flutter test          # unit and widget tests (no Firebase needed)
flutter run           # on an Android emulator or device
```

### Setting up accounts for a demo
- **Student**: Register in the app with an `@alustudent.com` address and verify it from the email.
- **Staff**: Register with an `@alueducation.com` address and verify it. Staff privileges come from the verified domain, or you can set `role` to `staff` on the user's document in the Firestore Console.
