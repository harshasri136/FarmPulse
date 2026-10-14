# 🌱 FarmPulse — Smart Farm Management

**Grow smarter. Harvest better.**

FarmPulse is a Flutter-based smart farm management application designed to help farmers organize farm details, manage crops, monitor expenses, track farming activities, and make informed decisions through analytics and weather information.

## ✨ Features

- 🏡 **Dashboard** — Overview of farms, crops, and total land area.
- 🌾 **Farm Management** — Add, view, edit, and delete farm details.
- 🌱 **Crop Management** — Track crop varieties, planting dates, harvest dates, growth stages, and crop status.
- 📊 **Insights & Analytics** — Visualize crop information and expense statistics.
- 🌦️ **Weather Information** — View weather forecasts and farming-related guidance.
- 🔔 **Reminders** — Organize important farming tasks and schedules.
- 💰 **Expense Tracking** — Record and monitor farm-related expenses.
- 📄 **Reports** — Generate and export farm management reports.
- 💾 **Local Storage** — Store application data using SQLite.
- 📱 **Responsive UI** — Green-themed interface designed for a clean farming experience.

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| SQLite / sqflite | Local database storage |
| Supabase Flutter | Backend integration capability |
| fl_chart | Analytics and charts |
| HTTP | Weather API requests |
| Google Fonts | Typography |
| CSV & PDF | Report generation |

> Supabase features require appropriate project configuration. Features listed above should be considered implemented only when verified in the application.

## 📂 Project Structure

```text
farmpulse/
├── android/
├── assets/
│   ├── icons/
│   └── images/
├── ios/
├── lib/
│   ├── core/
│   │   └── dashboard/
│   ├── models/
│   ├── screens/
│   └── services/
├── test/
├── web/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK compatible with the project's Dart SDK constraint
- Dart SDK
- Android Studio or Visual Studio Code
- Chrome for web testing
- Git

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/FarmPulse.git
cd FarmPulse
```

Replace `YOUR_USERNAME` with your GitHub username.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure application assets

Make sure the following files exist:

```text
assets/icons/pulse fa.png
assets/images/pulsefarm.png
```

### 4. Generate app icons and splash screen

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### 5. Configure SQLite web support

```bash
dart run sqflite_common_ffi_web:setup
```

### 6. Run the application

For Chrome:

```bash
flutter run -d chrome
```

For Android:

```bash
flutter run
```

## 🧪 Testing

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

## 🔐 Security

- Never commit passwords, access tokens, private API keys, or secret environment files.
- Configure Supabase Row Level Security (RLS) before exposing database access.
- Keep private configuration outside the public repository.
- Review `.gitignore` before committing project files.

## 🎨 Design

FarmPulse uses a nature-inspired green palette for a clear, modern farming interface.

- Primary Green: `#176B45`
- Dark Green: `#073B2A`
- Light Background: `#F5F8F4`

## 🗺️ Future Enhancements

- Advanced crop health monitoring
- Irrigation and field activity scheduling
- Offline synchronization with Supabase
- More detailed farm profitability analytics
- Push notifications for farming reminders
- Enhanced weather-based recommendations

## 🤝