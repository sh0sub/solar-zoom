# 🌞 Solar Zoom (솔라줌)

> **"세상을 더 밝고, 더 크게, 더 따뜻하게"**
>
> **Solar Zoom** is a premium magnifier application designed specifically for **seniors and users with low vision**. It combines powerful magnification tools with AI-based text recognition (OCR) and voice guidance (TTS) in a **warm, high-contrast interface** that is easy to see and easier to use.

<p align="center">
  <img src="https://via.placeholder.com/150/FF8C00/FFF8F0?text=App+Icon" alt="Solar Zoom Icon" width="120" />
</p>

## ✨ Why Solar Zoom?

Most magnifier apps are cold, complex, or full of ads. **Solar Zoom** is different.
We focus on **Accessibility** and **Emotional Design** using our signature **"Solar Warmth"** theme to provide comfort and clarity.

### 🌟 Key Features

*   **🔍 Crystal Clear Magnifier**
    *   **Up to 10x Zoom:** Seamless zoom with high-quality preview.
    *   **Pinch-to-Zoom:** Natural gesture control (works in both Live & Freeze modes).
    *   **Smart Focus:** Large, animated target indicator that locks focus without dizziness.
    *   **Steady Brightness:** Auto-exposure lock prevents screen darkening when touching white paper.

*   **❄️ Freeze Mode (멈춤 모드)**
    *   **Capture & Read:** Take a temporary photo of shaky menus or pill bottles to read comfortably.
    *   **Deep Zoom:** Zoom in further on the frozen image without blurs.

*   **🗣️ Smart AI Vision (OCR & TTS)**
    *   **Text Recognition:** Instantly recognizes Korean and English text using on-device ML.
    *   **Voice Guidance:** Reads the recognized text aloud with a natural, soothing voice.
    *   **Compassion UI:** Visual sound waves show when the app is speaking to you.

*   **🎨 "Solar Warmth" Design System**
    *   **Colors:** High-contrast `Solar Orange` (#FF8C00) and `Deep Charcoal` (#1A1A1A).
    *   **Typography:** Large, bold `Noto Sans KR` for maximum readability.
    *   **Haptics:** Subtle vibrations confirm every button press.

---

## 🛠 Technical Stack

*   **Framework:** [Flutter](https://flutter.dev) (Dart)
*   **Camera:** `camera`, `camera_avfoundation`
    *   Custom implementation for 1:1 screen mapping and full-screen preview.
*   **AI & ML:** `google_mlkit_text_recognition` (On-device OCR)
*   **Audio:** `flutter_tts` (Text-to-Speech)
*   **State Management:** `provider`
*   **Styling:** Custom `AppTheme` with neumorphic "Soft UI" components.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.x or higher)
*   Android Studio / Xcode

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/sh0sub/solar-zoom.git
    cd solar-zoom
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

## 📱 Build for Release

To generate the Android App Bundle (AAB) for Google Play:

```bash
flutter build appbundle
```

The output file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🤝 Contributing

We welcome contributions to make technology more accessible for everyone!
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Created with ❤️ for our parents.*
