# ALU Campus Incident Reporter (Mobile Application)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Academic%20Use-blue)](#)

A modern, role-based Flutter mobile application designed to bridge the communication gap between students and campus operations at the African Leadership University (ALU). The application enables students to report, photograph, and track campus issues—ranging from broken facilities, water outages, and electrical hazards to sanitation and safety concerns—while empowering authorized campus staff to review, prioritize, assign, and resolve incidents in real time.

---

## Key Features

### 1. Student Experience
- **ALU Institutional Authentication**: Restricted registration and login using verified `@alustudent.com` credentials with email verification flow.
- **Incident Reporting Workflow**:
  - Title, description, and incident category selection (Broken Facilities, Water Shortages, Electricity Outages, Damaged Furniture, Sanitation, Safety Concerns, Network/Internet, Other).
  - Campus Location selector (Main Building, Library, Cafeteria, Computer Labs, Dormitories, Sports Complex, etc.).
  - Severity / Priority tagging (Low, Medium, High, Critical).
  - Optional multi-photo attachment via Camera or Gallery uploaded to Firebase Storage.
- **Feed & Exploration**: Real-time incident feed with dynamic keyword search, category chip filters, status filters, and priority filtering.
- **Personal Submissions ("My Reports")**: Dedicated tracking tab to observe status progression on personal reports.
- **Privacy**: Students can report anonymously; their name is hidden from other students, and emails are never stored on reports. Staff can still look up the reporter to follow up and prevent misuse.
- **Upvote / "Me Too" Counter**: Allows students to flag incidents affecting multiple people to boost triage priority.

### 2. Authorized Staff Experience
- **Role-Based Access Control (RBAC)**: Automatically recognizes `@alueducation.com` email addresses or accounts with staff authorization.
- **Staff Command Center**: Real-time resolution metrics (Pending Triage, Under Review, In Progress, Resolved), incident volume distribution by category, and an urgent High/Critical queue.
- **Ticket Triage & Status Updates**: Staff can transition incidents across the lifecycle:
  `Pending` -> `Under Review` -> `In Progress` -> `Resolved` / `Dismissed`
- **Resolution Audit Trail**: Attach staff resolution notes and timestamps (e.g., "Plumbing contractor dispatched; new valve fitted").

---

## Architecture & State Management

The application is structured following clean architectural layers and the **MVVM (Model-View-ViewModel / Provider)** pattern:

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

### State Management Strategy
- **`AuthProvider`**: Manages current authentication lifecycle, session persistence, role evaluation (`isStudent` vs `isStaff`), ALU domain validation, and email verification states.
- **`IncidentProvider`**: Subscribes to the live Firestore stream, applies category/status/priority/keyword filters, and runs report creation, status updates, upvotes and deletion. Every change is confirmed by Firestore and flows back through the stream, so all screens stay in sync. A `ChangeNotifierProxyProvider` starts the subscription after login and clears all data on logout. Failed writes return `false` and expose an error message; nothing is faked locally.

---

## Security & Access Control

- **Domain restriction + verification**: Only `@alustudent.com` (student) and `@alueducation.com` (staff) addresses can register or sign in, and the app stays on the verification screen until the email is verified. The rules repeat this check using the token's `email_verified` claim, so it cannot be bypassed from the client.
- **Roles cannot be self-assigned**: A profile can only be created with the role that matches its email domain, and `role` can never be changed from the client. Extra staff can be promoted manually in the Firebase Console.
- **Firestore rules (`firestore.rules`)**:
  - Report reads are limited to verified ALU users. User profiles (which hold emails) are readable only by their owner and staff.
  - Reports cannot contain an email field, and anonymous reports must use the name "Anonymous".
  - A report can only be created by its author, starting as `pending` with zero votes.
  - Staff can change only `status`, `priority`, assignment fields and history. The author can only attach photo URLs to their own report. Any user can only add or remove their own upvote.
  - Staff can delete any report; authors only while it is still `pending`.
- **Storage rules (`storage.rules`)**: Only the report's author can upload (JPEG/PNG, under 5 MB); only the author or staff can delete; reading requires a verified ALU account.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.13.0 or higher)
- Android Studio with an Android emulator (or a physical device / iOS simulator)
- A Firebase project (free Spark plan is enough)
- Node.js, plus the Firebase CLI and FlutterFire CLI:
  `npm i -g firebase-tools` and `dart pub global activate flutterfire_cli`

### Firebase setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. **Authentication** -> Sign-in method -> enable **Email/Password**.
3. **Firestore Database** -> create a database (production mode).
4. **Storage** -> get started (a bucket is created).
5. From the project folder run `flutterfire configure`, choose your project and the Android/iOS platforms. This regenerates `lib/firebase_options.dart` and adds `android/app/google-services.json`. The app refuses to start while the template placeholder values are still in `firebase_options.dart`.
6. Deploy the security rules: `firebase login`, `firebase use <your-project-id>`, then `firebase deploy --only firestore:rules,storage`.

### Install & run
```bash
git clone <your-repository-url>
cd campus_incident_reporter
flutter pub get
flutter test          # unit and widget tests (no Firebase needed)
flutter run           # on an Android emulator or device
```

### Creating the accounts for a demo
- **Student**: register in the app with an `@alustudent.com` address and verify it from the email.
- **Staff**: register with an `@alueducation.com` address and verify it. Staff privileges come from the verified domain, or from setting `role` to `staff` on the user's document in the Firestore Console.
