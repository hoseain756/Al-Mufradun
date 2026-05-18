# Al-Mufradun (Adhkar Viewer) 🌙

A modern, feature-rich Islamic Flutter application dedicated to displaying daily Adhkar (supplications) with a premium user experience and a sleek **Material 3** design.

---

## ✨ Key Features

- **🎨 Modern Material 3 Design:** A clean, attractive user interface that supports the latest Google design standards.
- **🌓 Dynamic Light/Dark Mode:** Seamless switching between light and dark themes for comfortable reading in any environment.
- **📖 Premium Reading Experience:**
  - Utilizes the **Al-Nasakh** font for standard supplications.
  - Utilizes the **UthmanicHafs** font for Quranic texts.
  - Adjustable font sizes to suit individual reading preferences.
- **🔍 Smart & Instant Search:** A powerful search engine allowing quick access to Adhkar by text or category.
- **❤️ Favorites System:** Save your favorite Adhkar for quick and easy access at any time.
- **📂 Organized Categories:** Supplications are neatly categorized (Morning, Evening, Sleep, etc.) for effortless navigation.
- **📱 Social Sharing:** Full support for copying and sharing Adhkar texts across social media platforms.

---

## 🚀 Technologies Used

- **Flutter:** The core framework for cross-platform development.
- **Provider:** For efficient and scalable state management.
- **Shared Preferences:** For local persistence of user settings and favorites.
- **Google Fonts:** Providing professional UI typography (IBM Plex Sans Arabic).
- **OctIcons:** For modern, consistent, and minimal icon set.

---

## 🛠️ Project Structure

The application is structured for maintainability and scalability:

- `lib/models/`: Contains data models (e.g., `AdhkarModel`).
- `lib/providers/`: Houses business logic and state management (`AppProvider`).
- `lib/screens/`: Contains the various UI screens of the app.
- `lib/theme/`: Defines the app's themes, colors, and typography (`AppTheme`).
- `lib/widgets/`: Reusable UI components.
- `assets/adhkar.json`: The local database containing the Adhkar data.

---

## 🏁 Getting Started

To run this project locally, ensure you have Flutter installed, then execute the following commands:

```bash
# Clone the repository (if applicable)
# git clone <repository-url>

# Navigate to the project directory
# cd almufradun-main

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📜 License

This project is available for personal use and software development.

---

_Developed with ❤️ to serve those who remember Allah._
