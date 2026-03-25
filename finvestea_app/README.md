# Finvestea App

A Flutter-based personal finance and portfolio tracking application. This repository is a fork of [Flutter_task_finvestea](https://github.com/Akeshya-IT/Flutter_task_finvestea) with Completed Task Assigned — primarily full Firebase integration replacing the original mock/local data layer.

---

## What's New (Changes from Original)

### 🔥 Firebase Integration
The original app used local/mock data. This version wires everything up to Firebase:

- **`main.dart`** — App entry point is now `async`; Firebase is initialized via `Firebase.initializeApp()` using `DefaultFirebaseOptions` before the app starts.
- **`firebase_options.dart`** — Firebase platform configuration added.

---

### 🔐 Authentication — `auth_service.dart`
Replaced mock authentication with real **Firebase Authentication**:

- `signIn()` now calls `FirebaseAuth.instance.signInWithEmailAndPassword()` and maps the Firebase user to the internal `AuthUser` model.
- `register()` now calls `FirebaseAuth.instance.createUserWithEmailAndPassword()` and also creates a Firestore user document on successful registration.
- `signOut()` properly calls `FirebaseAuth.instance.signOut()`.
- Added a `setCurrentUser` setter to allow restoring session state on app launch.
- `FirebaseAuthException` errors are caught and re-thrown as typed `AuthException` with user-friendly messages.

---

### 🗄️ Firestore Service — `firestore_service.dart` *(New File)*
A brand-new service layer for Firestore CRUD operations:

| Function | Description |
|---|---|
| `addFireUser(AuthUser)` | Creates a new user document in the `users` collection on registration |
| `addFireHolding(Holding)` | Persists a new investment/holding to the `investment` collection |
| `getFireHoldings()` | Fetches all holdings for the currently logged-in user (filtered by `portfolioId == uid`) |

---

### 💼 Portfolio Service — `portfolio_service.dart`
Connected portfolio management to Firebase:

- `portfolioId` now uses the real Firebase user UID (`AuthService().currentUser!.uid`) instead of the hardcoded `'default_portfolio'` string.
- `addHolding()` now calls `addFireHolding()` to persist new investments to Firestore.
- `addFromFireStore()` — new method that fetches all holdings from Firestore and loads them into local state, used on login/app resume.
- Added `getHoldings()` and `clearHoldings()` helper methods.

---

### 🖥️ Screens

#### Login Screen — `login_screen.dart`
- After successful login, `PortfolioService().addFromFireStore()` is called to pre-load the user's holdings.

#### Register Screen — `register_screen.dart`
- After successful registration, `PortfolioService().addFromFireStore()` is called to sync holdings.

#### Splash Screen — `splash_screen.dart`
- On app launch, checks if a Firebase user session already exists (`FirebaseAuth.instance.currentUser`).
- If session found, restores `AuthUser` into `AuthService` and loads holdings from Firestore — enabling **persistent login**.
- Added `mounted` check before navigation to prevent state errors.

#### Profile Screen — `profile_screen.dart`
- Profile name and email now pulled from `AuthService().currentUser` (real Firebase user data) instead of hardcoded `'John Doe'` / `'john.doe@example.com'`.
- Sign-out button now calls `AuthService().signOut()` and `PortfolioService().clearHoldings()`.

#### Settings Screen — `settings_screen.dart`
- Sign-out action wired up to `AuthService().signOut()` and `PortfolioService().clearHoldings()`.

#### Portfolio Reports Screen — `portfolio_reports_screen.dart`
- Reports now load **real user holdings** via `PortfolioService().getHoldings()` instead of demo data.
- Holdings are grouped by name + asset type and aggregated (cost basis, current value, units, returns).
- **Bar Chart** added (using `fl_chart`) for investment growth trajectory — shows invested vs current value per holding with interactive touch to display details.
- **Pie Chart** added for investment allocation by asset type — interactive touch highlights slices with label + value.
- Empty state handling: chart tabs and top performers section are conditionally hidden when no holdings exist.
- Import portfolio button now refreshes the reports view after import completes.

---

## Tech Stack

- **Flutter** (Dart)
- **Firebase Authentication** — email/password login & registration
- **Cloud Firestore** — persistent storage for users and investment holdings
- **fl_chart** — bar and pie charts for portfolio analytics
- **go_router** — navigation

## Firestore Data Structure
```
users/
  └── {docId}
        ├── id: <firebase_uid>
        ├── full_name: <displayName>
        └── email: <email>

investment/
  └── {docId}
        ├── portfolioId: <firebase_uid>
        ├── name: <holding name>
        ├── assetType: <type>
        ├── costBasis: <amount>
        ├── currentValue: <amount>
        ├── quantity: <units>
        └── purchaseDate: <date>
```
