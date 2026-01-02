# 🌞 Solar Vision (솔라 비전)

> **"당신의 눈이 되어드리는 따뜻한 햇살, Solar Vision"**

<p align="center">
  <img src="https://via.placeholder.com/150/FF8C00/FFF8F0?text=Solar+Vision" alt="Solar Vision App Icon" width="120" />
</p>

## 📖 Brand Story: 왜 "Solar Vision" 인가요?

**Solar Vision**이라는 이름에는 단순히 잘 보이게 만든다는 기능적 목표 그 이상의 **철학**이 담겨 있습니다.

### ☀️ Solar (따뜻한 햇살)
차가운 기계적인 도구가 아닌, **따뜻한 반려 도구**가 되고자 합니다.
*   **밝음과 선명함:** 어두운 곳을 비추는 태양처럼, 흐릿한 시야를 선명하고 밝게 밝혀줍니다.
*   **따뜻한 감성:** 눈이 편안한 **Solar Orange(태양의 주황빛)** 컬러를 사용하여, 기술이 낯선 어르신들에게 심리적인 안정감과 따뜻함을 전합니다.

### 👁️ Vision (새로운 시각)
단순히 '확대(Zoom)'하는 것을 넘어, **'세상을 이해하는 눈(Vision)'**을 제공합니다.
*   **Zoom to Vision:** 기존의 돋보기(`Solar Zoom`)가 물리적인 크기를 키우는 데 집중했다면, `Solar Vision`은 인공지능(AI)을 통해 **글자를 읽고, 내용을 이해하고, 의미를 전달**합니다.
*   **Active Agent:** 사용자가 수동적으로 들여다보는 것이 아니라, 앱이 먼저 "이것은 약봉지입니다, 하루 3번 드세요"라고 알려주는 **능동적인 시각 비서**로 진화합니다.

---

## ✨ 핵심 기능 (Key Features)

가장 직관적이고, 가장 배려 깊은 기능들만 담았습니다.

### 1. 🔍 스마트 돋보기 (Smart Magnifier)
- **선명한 확대:** 최대 **10배율**까지 깨짐 없이 선명하게 확대합니다.
- **직관적인 조작:** 핀치 줌(두 손가락)과 슬라이더를 모두 지원하여 누구나 쉽게 조절할 수 있습니다.
- **자동 초점 & 밝기 고정:** 어두운 식당 메뉴판이나 흔들리는 약병도 선명하게 보여줍니다.

### 2. ❄️ "찰나의 포착" (Freeze & Catch)
- **흔들림 없는 정지:** [멈춤] 버튼을 누르면 그 순간을 **사진으로 포착(Capture)**하여 얼려둡니다.
- **WYSIWYG(보이는 그대로):** 멈춘 화면 그대로 확대/축소하고, 그 상태 그대로 글자를 읽습니다. (화면과 결과의 불일치 완벽 해결)
- **디테일 탐색:** 정지 된 상태에서도 자유롭게 확대(포컬 줌)해서 작은 글씨를 편안하게 확인하세요.

### 3. 🗣️ AI 보이스 리더 (Voice Reader)
- **똑똑한 판독 (OCR):** "이게 무슨 글자지?" 궁금할 때 [글자 읽기]를 누르면 AI가 즉시 글자를 찾아냅니다.
- **친절한 음성 (TTS):** 찾은 글자를 어르신들이 듣기 편한 속도와 목소리로 또박또박 읽어드립니다.
- **편리한 UI:** 읽어주는 동안 화면을 가리지 않으며, 원하는 구절을 터치하면 다시 읽어줍니다.

---

## 🛠 기술 스택 (Tech Stack)

*   **Framework:** [Flutter](https://flutter.dev) (Cross-platform)
*   **Camera Distinction:** `camera` + Custom Capture Logic (Parallel Execution for Zero-Lag)
*   **AI Engine:** 
    *   **Offline First:** Google ML Kit (Text Recognition) - *Instant & Secure*
    *   **Online Expansion:** Google Gemini 1.5 Flash (VLM) - *Coming in MVP 3*
*   **UX/UI:** "Solar Warmth" Design System (High Contrast Neumorphism)

---

## � 설치 및 이용 안내

### 권장 환경
*   Android 8.0 이상 / iOS 14.0 이상

### 앱 빌드 및 배포
```bash
# 의존성 설치
flutter pub get

# 릴리즈 빌드 (Android App Bundle)
flutter build appbundle
```
생성된 `app-release.aab` 파일을 구글 플레이 콘솔에 업로드하세요.

---

*Created with ❤️ for our parents.*
