<div align="center">

# 🚗 Ridooo

### *Your Smart Ride-Sharing Companion*

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.0-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase)](https://supabase.com)

*A modern, feature-rich ride-sharing platform built with Flutter and Supabase*

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Tech Stack](#-tech-stack)

---

</div>

## 📱 Overview

**Ridooo** is a comprehensive ride-sharing platform that brings convenience to your fingertips. Built with cutting-edge technology, it offers seamless transportation solutions with real-time tracking, secure authentication, and an intuitive user interface designed for both riders and drivers.

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔐 Authentication & Security
- Secure email-based authentication
- Email verification system
- Protected user sessions
- Encrypted data transmission

### 🗺️ Location & Navigation
- Real-time GPS tracking
- Google Maps integration
- Live ride tracking
- Smart route optimization

</td>
<td width="50%">

### 🚕 Ride Management
- Quick & easy ride booking
- Multiple vehicle options
- Ride history tracking
- Trip status updates

### 💳 Payments & More
- Secure payment processing
- Digital receipts
- Driver ratings & reviews
- Push notifications

</td>
</tr>
</table>

## 🛠️ Tech Stack

<table>
<tr>
<td align="center" width="25%">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" /><br/>
<b>Frontend Framework</b>
</td>
<td align="center" width="25%">
<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" /><br/>
<b>Backend & Database</b>
</td>
<td align="center" width="25%">
<img src="https://img.shields.io/badge/Google_Maps-4285F4?style=for-the-badge&logo=google-maps&logoColor=white" /><br/>
<b>Maps & Location</b>
</td>
<td align="center" width="25%">
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" /><br/>
<b>Programming Language</b>
</td>
</tr>
</table>

**Architecture**: Clean Architecture with Dependency Injection  
**Services**: Geolocator, Geocoding, Image Picker, URL Launcher

## 📸 Screenshots

<div align="center">

### 🎨 App Interface

<table>
<tr>
<td align="center">
<img src="screenshoots/ss1.jpeg" width="220" alt="Welcome Screen"/>
<br/><sub><b>Welcome Screen</b></sub>
</td>
<td align="center">
<img src="screenshoots/ss2.jpeg" width="220" alt="Authentication"/>
<br/><sub><b>Authentication</b></sub>
</td>
<td align="center">
<img src="screenshoots/ss3.jpeg" width="220" alt="Home Dashboard"/>
<br📋 Prerequisites

Before you begin, ensure you have the following installed:

```
✅ Flutter SDK (^3.7.0)
✅ Dart SDK (^3.7.0)  
✅ Android Studio / VS Code
✅ Git
```

**Required Accounts:**
- 🔹 [Supabase Account](https://supabase.com)
- 🔹 [Google Cloud Console](https://console.cloud.google.com) (for Maps API)

## 🚀 Installation

### **Step 1:** Clone the Repository
```bash
git clone https://github.com/yourusername/ridooo.git
cd ridooo
```

### **Step 2:** Install Dependencies
```bash
flutter pub get
```

### **Step 3:** Configure Supabase 🔧
1. Create a new project at [supabase.com](https://supabase.com)
2. Navigate to the SQL Editor
3. Run the schema file: `supabase_complete_schema_v2.sql`
4. Update your Supabase credentials in the project

### **Step 4:** Configure Google Maps 🗺️
1. Get your API key from [Google Cloud Console](https://console.cloud.google.com)
2. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
3. Add your API key:
   - **Android**: `android/app/src/main/AndroidManifest.xml`
   - **iOS**: `ios/Runner/AppDelegate.swift`

### **Step 5:** Run the Application 🎯
```bash
flutter run
```

> 💡 **Tip**: Use `flutter run -d chrome` for web or `flutter run -d windows` for desktopoogle Maps API Key

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/ridooo.git
cd ridooo
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
- Create a Supabase project at [supabase.com](https://supabase.com)
- R📁 Project Structure

```
ridooo/
│
├── 📂 lib/
│   ├── 📂 core/                    # Core utilities & constants
│   ├── 📂 features/                # Feature modules
│   │   ├── 📂 auth/               # Authentication
│   │   ├── 📂 ride/               # Ride management
│   │   └── 📂 profile/            # User profiles
│   ├── 📄 injection_container.dart # Dependency injection
│   ├── 📄 main.dart               # App entry point
│   └── 📄 splash_screen.dart      # Splash screen
│
├── 📂 android/                     # Android platform code
├── 📂 ios/                         # iOS platform code
├── 📂 assets/                      # Images, fonts, icons
└── 📄 pubspec.yaml                # Dependencies
```

## ⚙️ Environment Setup

Run the setup script for your platform:

| Platform | Command |
|----------|---------|
| 🪟 **Windows** | `.\setup.ps1` |
| 🍎 **macOS/Linux** | `./setup.sh` |

## 📦 Building for Production

<table>
<tr>
<td width="50%">

### Android APK
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/`

</td>
<td width="50%">

### iOS IPA
```bash
flutter build ios --release
```
**Output**: `build/ios/iphoneos/`

</t🤝 Contributing

We welcome contributions! Here's how you can help:

<table>
<tr>
<td>

### 🔀 How to Contribute

1. **Fork** the project
2. **Create** your feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit** your changes
   ```bash
   git commit -m 'Add AmazingFeature'
   ```
4. **Push** to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open** a Pull Request

</td>
</tr>
</table>

### 📝 Contribution Guidelines
- ✨ Follow the existing code style
- 📚 Update documentation as needed
- ✅ Test your changes thoroughly
- 🐛 Create an issue before making major changes

## 📄 License

This project is licensed under the **MIT License**

## 💬 Support

<div align="center">

**Need Help?** We're here for you!

[![Issues](https://img.shields.io/badge/Issues-Open%20an%20Issue-red?style=for-the-badge)](https://github.com/yourusername/ridooo/issues)
[![Discussions](https://img.shields.io/badge/Discussions-Join%20the%20Conversation-blue?style=for-the-badge)](https://github.com/yourusername/ridooo/discussions)

</div>

---

<div align="center">

### ⭐ Star this repository if you found it helpful!

Made with ❤️ using Flutter

**[⬆ Back to Top](#-ridooo)**

</div> Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and queries, please open an issue in the repository.

---

Made with ❤️ using Flutter
