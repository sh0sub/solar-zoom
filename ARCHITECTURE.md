# 🏗️ Architecture Design: Solar Zoom

> **Last Updated:** 2025-12-25
> **Version:** MVP 2.0 (Solar Warmth Update)

This document outlines the technical architecture, directory structure, and key design patterns used in **Solar Zoom**. It is intended to help developers (and you!) understand how the app works under the hood.

---

## 1. High-Level Architecture

Solar Zoom follows a **Service-Oriented Architecture** combined with **Provider** for state management. It separates **UI (Screens)** from **Business Logic (Services)** to ensure maintainability and testability.

```mermaid
graph TD
    UI[Screens (UI Layer)] -->|Consumes| Services[Services (Logic Layer)]
    Services -->|Controls| Hardware[Device Hardware]
    
    subgraph UI Layer
        Home[HomeScreen]
        Freeze[FreezeScreen]
        Smart[SmartModeScreen]
    end
    
    subgraph Service Layer - Providers
        Camera[CameraService]
        OCR[OcrService]
        TTS[TtsService]
    end
    
    subgraph Hardware/API
        CamHW[Camera Sensor]
        MLKit[Google ML Kit (On-Device)]
        Audio[Android/iOS TTS Engine]
    end
    
    Home --> Camera
    Smart --> Camera
    Smart --> OCR
    Smart --> TTS
    Camera --> CamHW
    OCR --> MLKit
    TTS --> Audio
```

---

## 2. Directory Structure

The project follows a standard "Layer-by-Feature" structure within `lib/`:

```
lib/
├── main.dart                  # Entry point using MultiProvider
├── theme/
│   └── app_theme.dart         # Design System (Solar Warmth: Colors, Typography)
├── screens/
│   ├── home_screen.dart       # Main Camera View (Zoom/Focus Logic)
│   ├── freeze_screen.dart     # Freeze Mode (Image Preview & Zoom)
│   └── smart_mode_screen.dart # OCR & TTS Features
└── services/
    ├── camera_service.dart    # Camera Controller Wrapper (Flash, Zoom, Focus)
    ├── ocr_service.dart       # ML Kit integration for Text Recognition
    └── tts_service.dart       # Text-to-Speech logic
```

---

## 3. Core Components

### 📸 CameraService (`services/camera_service.dart`)
*   **Role:** Manages the camera lifecycle, preview stream, and hardware settings.
*   **Key Logic:**
    *   **Focus:** Handles Tap-to-Focus (locks focus but maintains auto-exposure).
    *   **Zoom:** Manages min/max zoom levels and exposes a unified `currentZoom`.
    *   **Resolution:** Uses `ResolutionPreset.high` for optimal clarity vs. performance.

### 🧠 OcrService (`services/ocr_service.dart`)
*   **Role:** Extracts text from images.
*   **Tech:** `google_mlkit_text_recognition` (v2).
*   **Language:** Configured for `script: Script.korean` (supports English mixed).
*   **Optimization:** Processes specific `XFile` images captured by the camera.

### 🗣️ TtsService (`services/tts_service.dart`)
*   **Role:** Converts recognized text to speech.
*   **Tech:** `flutter_tts`.
*   **UX:**
    *   Sets language to Korean (`ko-KR`).
    *   Adjusts speech rate (0.5) for senior readability.
    *   Provides explicit `stop()` methods to interrupt speech.

---

## 4. UI & Theming Strategy

### 🌞 "Solar Warmth" Design System (`theme/app_theme.dart`)
We do not use hardcoded colors in widgets. Instead, we define a centralized `AppTheme`.
*   **Primary:** `#FF8C00` (Solar Orange) - Used for Action Buttons, Focus Indicators.
*   **Background:** `#1A1A1A` (Deep Charcoal) - Reduces eye strain.
*   **Surface:** `#FFF8F0` (Warm White) - Used for text and icons.

### ✨ Key UX Patterns
*   **Pinch-to-Zoom Separation:** Use `GestureDetector` flags (`_isScaling`) to ensure pinch gestures don't trigger "Tap-to-Focus" visual artifacts.
*   **Full Screen Mapping:** `CameraPreview` is wrapped in `Transform.scale` and `ClipRect` to ensure it fills 100% of the screen regardless of aspect ratio, eliminating black bars.

---

## 5. State Management Flow

1.  **User Action:** User taps "Freeze Button" in `HomeScreen`.
2.  **Service Call:** `HomeScreen` calls `CameraService.takePicture()`.
3.  **State Update:** `CameraService` handles the async hardware call and returns an `XFile`.
4.  **Navigation:** `HomeScreen` receives the file and pushes `FreezeScreen(file)`.
5.  **Reactive UI:** `FreezeScreen` manages its own temporary state (`currentScale`) for zooming the static image.

---

## 6. Future Considerations (MVP 3.0)

*   [ ] **LLM Integration:** Send OCR text to Gemini API for summarization ("이 약은 식후 30분에 드세요").
*   [ ] **Image Filtering:** Add high-contrast filters (Black/White, Inverted) in `CameraService` stream.
