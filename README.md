# 🌞 Solar Vision (솔라 비전)

> **"눈이 침침한 부모님을 위한 AI 시각 비서"**
>
> **Solar Vision**은 단순한 돋보기를 넘어, 어르신들의 "제2의 눈"이 되어드리는 인공지능 시각 보조 앱입니다.
> (구 Solar Zoom 프로젝트가 **Solar Vision**으로 새롭게 태어났습니다.)

<p align="center">
  <img src="https://via.placeholder.com/150/FF8C00/FFF8F0?text=Solar+Vision" alt="Solar Vision Icon" width="120" />
</p>

## ✨ 왜 Solar Vision 인가요?

기존의 돋보기 앱들은 단순히 크게만 보여줍니다. 하지만 **Solar Vision**은 **"보고, 이해하고, 읽어줍니다."**
시력이 약한 어르신들이 겪는 답답함을 기술(OCR, TTS, VLM)과 배려(따뜻한 UI)로 해결했습니다.

### 🌟 핵심 기능 (Core Features)

#### 1. 🔍 스마트 돋보기 (Smart Magnifier)
- **선명한 확대:** 최대 **10배율**까지 깨짐 없이 선명하게 확대합니다.
- **직관적인 조작:** 핀치 줌(두 손가락)과 슬라이더를 모두 지원하여 누구나 쉽게 조절할 수 있습니다.
- **자동 초점 & 밝기 고정:** 어두운 식당 메뉴판이나 흔들리는 약병도 선명하게 보여줍니다.

#### 2. ❄️ 찰나의 포착 (Freeze & Catch)
- **흔들림 없는 정지:** [멈춤] 버튼을 누르면 그 순간을 **사진으로 포착(Capture)**하여 얼려둡니다.
- **WYSIWYG(보이는 그대로):** 멈춘 화면 그대로 확대/축소하고, 그 상태 그대로 글자를 읽습니다. (화면과 결과의 불일치 해결)
- **디테일 탐색:** 정지 된 상태에서도 자유롭게 확대해서 작은 글씨를 확인할 수 있습니다.

#### 3. 🗣️ 글자 읽어주기 (AI Voice)
- **똑똑한 판독 (OCR):** "이게 무슨 약이지?" 궁금할 때 [글자 읽기]를 누르면 AI가 글자를 찾아냅니다.
- **친절한 음성 (TTS):** 찾은 글자를 어르신들이 듣기 편한 속도와 목소리로 읽어드립니다.
- **편리한 UI:** 읽어주는 동안 화면을 가리지 않으며, 원하는 구절을 터치하면 다시 읽어줍니다.

#### 4. 🎨 "Solar Warmth" 디자인
- **고대비 테마:** 검정 배경에 `Solar Orange` 오렌지색 포인트로 눈의 피로를 최소화했습니다.
- **큰 글씨 & 버튼:** 큼직한 버튼과 직관적인 아이콘으로 오타를 방지합니다.
- **일관된 경험:** 모든 화면에서 "뒤로 가기" 등의 조작 방식이 통일되어 있어 배우기 쉽습니다.

---

## 🛠 기술 스택 (Tech Stack)

*   **Framework:** [Flutter](https://flutter.dev) (Cross-platform)
*   **Camera:** `camera` (Custom Capture-First Logic)
*   **AI Engine:** 
    *   **Offline:** Google ML Kit (Text Recognition) - *Current*
    *   **Online:** Google Gemini 1.5 Flash (VLM) - *Planned for MVP 3*
*   **Accessibility:** `flutter_tts`, Haptic Feedback
*   **State Management:** `provider`

---

## 🚀 향후 로드맵 (Vision for MVP 3)

**Solar Vision**은 이제 "보는 도구"에서 "대화하는 비서"로 진화합니다.

- [ ] **AI 문맥 이해:** "이 약은 언제 먹는 거야?"라고 물으면 Gemini가 사용법을 요약해줍니다.
- [ ] **하이브리드 모드:** 인터넷이 없어도 기본 기능은 언제나 100% 작동합니다.
- [ ] **음성 대화:** 버튼을 누르는 대신 말로 명령할 수 있습니다.

---

## 📱 설치 및 배포

### 권장 환경
*   Android 8.0 이상
*   iOS 14.0 이상

### 빌드 (Build)
```bash
flutter build appbundle
```
생성된 `app-release.aab` 파일을 구글 플레이 콘솔에 업로드하세요.

---

*Created with ❤️ for our parents.*
