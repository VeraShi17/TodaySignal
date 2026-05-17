# Today’s Signal iOS App Development Progress

## 0. Project Overview

**Product Name:** 오늘의 시그널 / Today’s Signal  
**Product Type:** iOS SwiftUI App  
**Current Phase:** Phase 6 Polish & MVP Testing (in progress)  
**Target Users:** K-pop / 韩娱粉丝中的初中级韩语学习者

Today’s Signal is an iOS app that helps users understand Korean chat screenshots from idol bubble / DM / social media contexts. Users can upload a chat screenshot or paste Korean text, confirm the extracted chat bubbles, receive AI explanations for Korean vocabulary and grammar, and save unknown expressions as learning cards.

The MVP focuses on:

- Korean-to-Chinese chat understanding
- OCR text confirmation
- Bubble-by-bubble explanation
- Vocabulary and grammar learning cards
- Local-only storage
- Privacy-conscious design

The current design reference is based on the uploaded prototype file:

- `DesignReference/Today's Signal.html`

The uploaded HTML prototype loads React, ReactDOM, Babel, `styles.css`, `design-canvas.jsx`, `ios-frame.jsx`, `components.jsx`, `onboarding.jsx`, `screens.jsx`, and `app.jsx`. If these referenced files are available locally, place them under `DesignReference/` and use them as visual implementation references. If only the HTML file is available, use the PRD and this progress document as the source of truth for SwiftUI implementation.

---

## 1. Current Development Goal

Current goal:

> Build a runnable SwiftUI MVP skeleton that follows the Today’s Signal PRD and visual design direction.

The first development milestone should focus on **static UI + navigation + mock data**, before implementing OCR, AI analysis, or local persistence.

### 1.1 Current Phase Scope

In this phase, implement:

- Native SwiftUI project structure
- Onboarding flow
- Main tab navigation
- Home input page
- Text confirmation page using mock chat bubbles
- Analysis result page using mock AI explanation data
- Card preview modal
- Card library page with mock vocabulary and grammar cards
- Settings page with privacy explanation
- Reusable UI components

### 1.2 Current Phase Out of Scope

Do **not** implement yet:

- Real OCR
- Real screenshot parsing
- Real image upload processing
- Real chat bubble detection
- Real LLM API calls
- Real persistent storage
- User login
- Cloud sync
- App Store deployment
- Push notifications
- Payment or subscription features
- Share Extension
- Quiz or voice playback

---

## 2. MVP Scope

### 2.1 In Scope for MVP

| Area | Requirement |
|---|---|
| Platform | iOS app built with SwiftUI |
| Input | Upload screenshot, paste Korean text |
| OCR | Extract text from screenshot using Apple Vision / VisionKit |
| Text Confirmation | Show extracted content as editable chat bubbles |
| Bubble Role | Let user mark which side is idol / other person |
| AI Analysis | Explain other-person Korean bubbles |
| Explanation Output | Original text, Chinese translation, tone label, vocabulary, grammar / endings |
| Knowledge Actions | Known, unknown without card, unknown and generate card |
| Card Generation | Vocabulary card and grammar / ending card |
| Card Preview | Show card preview after generation |
| Card Library | Vocabulary tab, grammar tab, card detail, delete card |
| Local Storage | Store cards and user knowledge-point marks locally |
| Settings | Show privacy explanation and about information |

### 2.2 Out of Scope for MVP

| Feature | Reason |
|---|---|
| Account login | Reduce MVP complexity |
| Cloud sync | Privacy and development simplicity |
| Full analysis history | MVP only stores generated cards |
| Original screenshot storage | Privacy requirement |
| Quiz review | Future learning system |
| Voice playback | Future feature |
| Share Extension | Future mobile-native enhancement |
| Batch import | Future power-user feature |
| Textbook wordbook import | Future learning enhancement |
| Advanced user profile | Future personalization feature |
| Open-ended feedback chat | Future AI tutor feature |
| Full reply generation workflow | Future communication assistant feature |

---

## 3. Recommended Development Strategy

The development should be done in small, runnable milestones.

### Phase 1 — Static SwiftUI Prototype

Goal:

> Convert the PRD and design prototype into native SwiftUI screens using mock data.

Focus:

- UI fidelity
- Navigation
- Reusable components
- Realistic empty/loading/error states
- No real OCR or AI

### Phase 2 — Local Data and Interaction

Goal:

> Make the app interactive locally.

Focus:

- User can mark knowledge points
- Card preview appears
- Mock cards can be added to library
- Cards can be deleted
- User-selected side is preserved in the current session
- Local state management is clean

### Phase 3 — OCR Integration

Goal:

> Allow real screenshot input and text extraction.

Focus:

- Image picker
- Apple Vision OCR
- Initial text extraction
- Fallback to line-by-line text blocks
- Manual editing

### Phase 4 — AI Analysis Integration

Goal:

> Replace mock analysis with structured LLM output.

Focus:

- Prompt design
- JSON schema validation
- Request timeout handling
- Partial failure handling
- Korean-to-Chinese only

### Phase 5 — Local Persistence

Goal:

> Persist cards and knowledge-point marks locally.

Focus:

- SwiftData / Core Data / local JSON storage decision
- Vocabulary card persistence
- Grammar card persistence
- Delete card
- Known / skipped knowledge-point tracking

### Phase 6 — Polish and MVP Testing

Goal:

> Prepare the MVP for user testing.

Focus:

- Performance
- Visual polish
- Privacy copy
- Error states
- Simulator and real-device testing

---

## 4. Suggested SwiftUI File Structure

Use a simple, modular structure first. Avoid over-engineering.

```text
TodaySignal/
  TodaySignalApp.swift
  ContentView.swift

  Views/
    Onboarding/
      OnboardingView.swift
      OnboardingPageView.swift

    Main/
      MainTabView.swift
      HomeView.swift
      SettingsView.swift

    Analysis/
      TextConfirmationView.swift
      AnalysisResultView.swift
      CardPreviewModal.swift
      MyReplyFeedbackView.swift

    Cards/
      CardLibraryView.swift
      VocabularyCardDetailView.swift
      GrammarCardDetailView.swift

  Components/
    PrimaryButton.swift
    SecondaryButton.swift
    SignalCard.swift
    ChatBubbleView.swift
    ToneLabelView.swift
    KnowledgePointView.swift
    FlashcardView.swift
    EmptyStateView.swift
    LoadingStateView.swift

  Models/
    ChatBubble.swift
    AnalysisResult.swift
    KnowledgePoint.swift
    LearningCard.swift
    MockData.swift

  ViewModels/
    OnboardingViewModel.swift
    HomeViewModel.swift
    TextConfirmationViewModel.swift
    AnalysisResultViewModel.swift
    CardLibraryViewModel.swift

  Services/
    OCRService.swift
    AIAnalysisService.swift
    CardStorageService.swift

  Resources/
    Assets.xcassets
    Localizable.strings

  Docs/
    PRD.md
    design.md
    development-progress.md

  DesignReference/
    Today's Signal.html
    styles.css
    components.jsx
    onboarding.jsx
    screens.jsx
    app.jsx
    uploads/
```

### 4.1 Early-Phase Simplification

For the first static UI milestone, it is acceptable to only create:

```text
TodaySignal/
  ContentView.swift

  Views/
    OnboardingView.swift
    MainTabView.swift
    HomeView.swift
    TextConfirmationView.swift
    AnalysisResultView.swift
    CardLibraryView.swift
    SettingsView.swift

  Components/
    PrimaryButton.swift
    SignalCard.swift
    ChatBubbleView.swift

  Models/
    MockData.swift
```

The fuller structure can be introduced as the project grows.

---

## 5. Module Breakdown and Implementation Plan

### 5.1 Design Reference and Project Setup

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M0.1 | Design Reference Setup | Place uploaded design files under `DesignReference/` | 1 | ✅ 已完成 |
| M0.2 | PRD / Docs Setup | Add `Docs/PRD.md`, `Docs/design.md`, `Docs/development-progress.md` | 2 | ✅ 已完成 |
| M0.3 | Xcode Project Setup | Create SwiftUI iOS project, confirm simulator runs | 3 | ✅ 已完成 |
| M0.4 | Asset Setup | Add app icon placeholder, colors, reusable visual tokens | 4 | ✅ 已完成 |

Implementation notes:

- Keep the project runnable after every change.
- Do not implement OCR or AI in this phase.
- Use the design reference as visual inspiration, not as web code to directly embed.

### 5.2 Core Data Models

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M1.1 | ChatBubble Model | Represents extracted chat bubbles with side, role, text, type | 5 | ✅ 已完成 |
| M1.2 | AnalysisResult Model | Represents AI explanation for each bubble | 6 | ✅ 已完成 |
| M1.3 | KnowledgePoint Model | Represents vocabulary / grammar items and user action state | 7 | ✅ 已完成 |
| M1.4 | LearningCard Model | Represents vocabulary and grammar cards | 8 | ✅ 已完成 |
| M1.5 | MockData | Provide realistic sample chat bubbles, analysis results, cards | 9 | ✅ 已完成 |

Suggested model fields:

```swift
struct ChatBubble: Identifiable {
    let id: UUID
    var side: BubbleSide
    var speakerRole: SpeakerRole
    var type: BubbleType
    var text: String
    var isEditable: Bool
}

struct AnalysisResult: Identifiable {
    let id: UUID
    let bubbleID: UUID
    let originalText: String
    let translationZH: String
    let toneLabel: ToneLabel
    var vocabulary: [KnowledgePoint]
    var grammarPoints: [KnowledgePoint]
}

enum LearningCardType {
    case vocabulary
    case grammar
}
```

### 5.3 Reusable UI Components

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M2.1 | PrimaryButton | Main soft-pink CTA button | 10 | ✅ 已完成 |
| M2.2 | SecondaryButton | Secondary outline / light button | 11 | ✅ 已完成 |
| M2.3 | SignalCard | Rounded soft card container | 12 | ✅ 已完成 |
| M2.4 | ChatBubbleView | Left/right editable chat bubbles | 13 | ✅ 已完成 |
| M2.5 | ToneLabelView | Small rounded tone label pill | 14 | ✅ 已完成 |
| M2.6 | KnowledgePointView | Vocabulary / grammar item with action buttons | 15 | ✅ 已完成 |
| M2.7 | FlashcardView | Preview and library card UI | 16 | ✅ 已完成 |
| M2.8 | EmptyStateView | Friendly empty states | 17 | ✅ 已完成 |
| M2.9 | LoadingStateView | Analysis loading state | 18 | 未开始 |

Design requirements:

- Use rounded corners heavily.
- Keep colors soft and warm.
- Maintain strong readability.
- Use large tap areas for mobile usability.
- Do not create overly complex visual effects in MVP.

### 5.4 Navigation and App Shell

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M3.1 | ContentView | Controls onboarding vs main app entry | 19 | ✅ 已完成 |
| M3.2 | Onboarding Completion State | Store whether onboarding has been viewed in memory first | 20 | ✅ 已完成 |
| M3.3 | MainTabView | Bottom tabs: 解析, 卡片库, 设置 | 21 | ✅ 已完成 |
| M3.4 | Basic Navigation Stack | Navigate from Home to confirmation and analysis pages | 22 | ✅ 已完成 |

MVP tabs:

1. 解析
2. 卡片库
3. 设置

### 5.5 Onboarding Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M4.1 | OnboardingView | 2–3 onboarding pages | 23 | ✅ 已完成 |
| M4.2 | Onboarding Page 1 | "读懂韩语聊天里的小信号" | 24 | ✅ 已完成 |
| M4.3 | Onboarding Page 2 | "先确认文字，再开始解析" | 25 | ✅ 已完成 |
| M4.4 | Onboarding Page 3 | "把不认识的表达变成学习卡片" | 26 | ✅ 已完成 |
| M4.5 | Enter App CTA | Button to enter main app | 27 | ✅ 已完成 |

Recommended copy:

- Page 1 title: `读懂韩语聊天里的小信号`
- Page 1 body: `上传 idol bubble / DM / 聊天截图，帮你看懂每句话的意思、词尾和语气。`
- Page 2 title: `先确认文字，再开始解析`
- Page 2 body: `OCR 后你可以逐条修改识别出的气泡文字，避免识别错误影响解释。`
- Page 3 title: `把不认识的表达变成学习卡片`
- Page 3 body: `生词、词尾、语法点都可以保存成卡片，之后慢慢复习。`

### 5.6 Home / Input Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M5.1 | HomeView Layout | App name, subtitle, action card | 28 | ✅ 已完成 |
| M5.2 | Upload Screenshot Button | Static button first, later connects to image picker | 29 | ✅ 已完成 |
| M5.3 | Paste Text Button | Static button first, later opens text input | 30 | ✅ 已完成 |
| M5.4 | Privacy Note | Show "原始截图不会长期保存" | 31 | ✅ 已完成 |
| M5.5 | Mock Navigation | Navigate to TextConfirmationView with mock data | 32 | ✅ 已完成 |

Home must include:

- `오늘의 시그널`
- `Today’s Signal`
- `韩语聊天截图学习助手`
- Upload screenshot CTA
- Paste Korean text CTA
- Short privacy note

### 5.7 Text Confirmation Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M6.1 | TextConfirmationView Layout | Title, instructions, bubble list, bottom CTA | 33 | ✅ 已完成 |
| M6.2 | Editable Chat Bubbles | Allow editing mock bubble text | 34 | ✅ 已完成 |
| M6.3 | Delete Bubble | Allow deleting irrelevant mock bubbles | 35 | ✅ 已完成 |
| M6.4 | Side Selection | Select left or right as idol / other person | 36 | ✅ 已完成 |
| M6.5 | Image Bubble Placeholder | Display `[图片]` for image bubbles | 37 | ✅ 已完成 |
| M6.6 | Fallback Line Blocks UI | Mock fallback if bubble detection fails | 38 | ✅ 已完成 |
| M6.7 | Start Analysis CTA | Navigate to analysis result page | 39 | ✅ 已完成 |

Important UX:

- OCR results should be shown as chat bubbles, not a single plain text box.
- User should be able to correct text before AI analysis.
- Side selection is important because learning cards are generated by default from the other person’s bubbles.

### 5.8 Analysis Result Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M7.1 | AnalysisResultView Layout | Bubble-by-bubble explanation page | 40 | ✅ 已完成 |
| M7.2 | Original Bubble Display | Show original chat bubble | 41 | ✅ 已完成 |
| M7.3 | Chinese Translation Section | Show natural Chinese translation | 42 | ✅ 已完成 |
| M7.4 | Tone Label Section | Show fixed tone label | 43 | ✅ 已完成 |
| M7.5 | Vocabulary Section | Show vocabulary knowledge points | 44 | ✅ 已完成 |
| M7.6 | Grammar Section | Show grammar / ending knowledge points | 45 | ✅ 已完成 |
| M7.7 | Knowledge Point Actions | Known, unknown no card, generate card | 46 | ✅ 已完成 |
| M7.8 | Saved State UI | Show generated / known / skipped state | 47 | ✅ 已完成 |
| M7.9 | Loading State | Static loading view for future API integration | 48 | 未开始 |
| M7.10 | Partial Failure State | Static retry card for failed bubble | 49 | 未开始 |

Fixed tone labels:

- 普通陈述
- 亲近随意
- 可爱 / 撒娇
- 吐槽 / 开玩笑
- 安慰 / 关心
- 礼貌表达
- 冷淡 / 简短

Knowledge point actions:

1. 认识
2. 不认识，不生成卡片
3. 生成卡片

### 5.9 My Reply Feedback Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M8.1 | MyReplyFeedbackView | Small feedback card below user-side bubbles | 50 | ✅ 已完成 |
| M8.2 | Natural State | Show "这句表达自然，没有明显问题" | 51 | ✅ 已完成 |
| M8.3 | Needs Improvement State | Show issue explanation and suggested alternative | 52 | ✅ 已完成 |

This module is secondary. It should not become a full reply-generation workflow in the MVP.

### 5.10 Card Preview Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M9.1 | CardPreviewModal | Modal shown after tapping generate card | 53 | ✅ 已完成 |
| M9.2 | Vocabulary Preview | Show vocabulary card fields | 54 | ✅ 已完成 |
| M9.3 | Grammar Preview | Show grammar card fields | 55 | ✅ 已完成 |
| M9.4 | Auto-Saved Indicator | Show "已保存到卡片库" | 56 | ✅ 已完成 |
| M9.5 | Modal Actions | "知道了", "查看卡片库" | 57 | ✅ 已完成 |

Important:

- Card preview does not require a second confirmation.
- The card should be considered saved once the modal appears.

### 5.11 Card Library Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M10.1 | CardLibraryView Layout | Vocabulary / grammar segmented tabs | 58 | ✅ 已完成 |
| M10.2 | Vocabulary Card List | Show mock vocabulary cards | 59 | ✅ 已完成 |
| M10.3 | Grammar Card List | Show mock grammar cards | 60 | ✅ 已完成 |
| M10.4 | Card Detail View | Expand or navigate to detail | 61 | ✅ 已完成 |
| M10.5 | Delete Single Card | Delete card from local state | 62 | ✅ 已完成 |
| M10.6 | Empty States | Show friendly empty states | 63 | ✅ 已完成 |

MVP card library must support:

- vocabulary / grammar tabs
- card detail
- individual delete

Do not implement:

- search
- favorite
- quiz
- batch delete
- cloud sync

### 5.12 Settings Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M11.1 | SettingsView Layout | Privacy and about sections | 64 | ✅ 已完成 |
| M11.2 | Privacy Section | Explain local storage and AI processing | 65 | ✅ 已完成 |
| M11.3 | About Section | App name, version, short description | 66 | ✅ 已完成 |

Privacy copy should include:

- 原始截图不会长期保存；
- App 默认只在本地保存学习卡片和学习标记；
- 不保存完整解析历史；
- AI 解析时，确认后的文本可能会发送给模型服务处理；
- 请避免上传包含敏感个人信息的截图。

### 5.13 OCR Integration Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M12.1 | Image Picker | Select screenshot from photo library | 67 | ✅ 已完成 |
| M12.2 | OCRService Skeleton | Service interface for OCR | 68 | ✅ 已完成 |
| M12.3 | Apple Vision OCR | Extract text from image | 69 | ✅ 已完成 |
| M12.4 | OCR Result Mapping | Convert OCR text to editable blocks | 70 | ✅ 已完成 |
| M12.5 | Bubble Detection Heuristic | Attempt basic bubble grouping | 71 | ✅ 已完成（基础版） |
| M12.6 | OCR Failure Handling | Invalid input and fallback states | 72 | ✅ 已完成 |

Recommended approach:

- Start with OCR text extraction only.
- Then add simple grouping.
- Do not attempt perfect chat bubble detection in the first OCR iteration.
- Always keep manual editing as the reliable fallback.

### 5.14 AI Analysis Integration Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M13.1 | AIAnalysisService Skeleton | Define service interface | 73 | 未开始 |
| M13.2 | Prompt Template | Korean-to-Chinese structured explanation prompt | 74 | 未开始 |
| M13.3 | JSON Schema Definition | Define expected output structure | 75 | 未开始 |
| M13.4 | Mock-to-Real Toggle | Allow development with mock or real AI | 76 | 未开始 |
| M13.5 | API Request Integration | Connect to selected LLM API | 77 | 未开始 |
| M13.6 | JSON Validation | Validate response before UI rendering | 78 | 未开始 |
| M13.7 | Timeout Handling | Treat >60s as abnormal | 79 | 未开始 |
| M13.8 | Partial Failure Handling | Allow failed bubbles to retry | 80 | 未开始 |

Prompt requirements:

- Korean-to-Chinese only
- Fixed JSON output
- Fixed tone labels
- No hallucinated content
- Focus on useful vocabulary and grammar for intermediate-beginner learners
- Do not over-extract too many knowledge points

### 5.15 Local Persistence Module

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M14.1 | Storage Decision | Choose SwiftData, Core Data, or local JSON | 81 | 未开始 |
| M14.2 | Save Vocabulary Card | Persist vocabulary cards | 82 | 未开始 |
| M14.3 | Save Grammar Card | Persist grammar cards | 83 | 未开始 |
| M14.4 | Delete Card | Persist card deletion | 84 | 未开始 |
| M14.5 | Save Known Marks | Store known knowledge points | 85 | 未开始 |
| M14.6 | Save Skipped Marks | Store unknown-no-card knowledge points | 86 | 未开始 |
| M14.7 | Load Card Library | Load saved cards on launch | 87 | 未开始 |

MVP should not save:

- original screenshots
- full chat history
- full analysis history

### 5.16 QA, Polish, and MVP Readiness

| ID | Module | Functionality | Development Order | Status |
|---|---|---|---:|---|
| M15.1 | UI Polish | Spacing, colors, typography, icons | 88 | 未开始 |
| M15.2 | Simulator Testing | Test on common iPhone sizes | 89 | 未开始 |
| M15.3 | Real Device Testing | Test screenshot upload and OCR | 90 | 未开始 |
| M15.4 | Error State Testing | Invalid screenshot, OCR failure, AI timeout | 91 | 未开始 |
| M15.5 | Privacy Review | Confirm no screenshot persistence | 92 | 未开始 |
| M15.6 | MVP Demo Script | Prepare walkthrough demo | 93 | 未开始 |
| M15.7 | Known Issues List | Document limitations | 94 | 未开始 |

---

## 6. Development Order Summary

### Phase 1 — Static UI and Navigation

| Order | Task | Status |
|---:|---|---|
| 1 | Set up design references and docs | ✅ 已完成 |
| 2 | Create SwiftUI project and run simulator | ✅ 已完成 |
| 3 | Define mock data models | ✅ 已完成 |
| 4 | Build reusable visual components | ✅ 已完成 |
| 5 | Build onboarding flow | ✅ 已完成 |
| 6 | Build main tab navigation | ✅ 已完成 |
| 7 | Build home input page | ✅ 已完成 |
| 8 | Build text confirmation page with mock bubbles | ✅ 已完成 |
| 9 | Build analysis result page with mock data | ✅ 已完成 |
| 10 | Build card preview modal | ✅ 已完成 |
| 11 | Build card library page with mock cards | ✅ 已完成 |
| 12 | Build settings page | ✅ 已完成 |

### Phase 2 — Local Interactions

| Order | Task | Status |
|---:|---|---|
| 13 | Make knowledge-point actions interactive | ✅ 已完成 |
| 14 | Show card preview when generating card | ✅ 已完成 |
| 15 | Add generated mock card to in-memory card library | ✅ 已完成 |
| 16 | Delete card from in-memory state | ✅ 已完成 |
| 17 | Preserve selected other-person side during flow | ✅ 已完成 |

### Phase 3 — OCR

| Order | Task | Status |
|---:|---|---|
| 18 | Add image picker | ✅ 已完成 |
| 19 | Implement Apple Vision OCR | ✅ 已完成 |
| 20 | Map OCR output to editable lines | ✅ 已完成 |
| 21 | Add basic bubble grouping heuristic | ✅ 已完成（基础版） |
| 22 | Add invalid input and OCR fallback states | ✅ 已完成 |

### Phase 4 — AI Analysis

| Order | Task | Status |
|---:|---|---|
| 23 | Create AIAnalysisService | ✅ 已完成（基础版） |
| 24 | Write structured prompt | ✅ 已完成（基础版） |
| 25 | Define JSON schema | ✅ 已完成（基础版） |
| 26 | Connect real LLM API | ✅ 已完成（OpenAI 可切换） |
| 27 | Validate JSON output | ✅ 已完成（解码校验） |
| 28 | Implement timeout and partial failure handling | 🔄 进行中（已接入 timeout 与基础错误态） |

### Phase 5 — Persistence

| Order | Task | Status |
|---:|---|---|
| 29 | Choose local storage technology | ✅ 已完成（SwiftData） |
| 30 | Persist vocabulary cards | ✅ 已完成 |
| 31 | Persist grammar cards | ✅ 已完成 |
| 32 | Persist known / skipped knowledge marks | ✅ 已完成 |
| 33 | Load saved cards on app launch | ✅ 已完成 |

### Phase 6 — MVP Polish

| Order | Task | Status |
|---:|---|---|
| 34 | Polish UI based on design reference | 未开始 |
| 35 | Test iPhone simulator sizes | 未开始 |
| 36 | Test real screenshot OCR | 未开始 |
| 37 | Test AI error states | 未开始 |
| 38 | Review privacy behavior | 未开始 |
| 39 | Prepare MVP demo script | 未开始 |

---

## 7. Current Status

### 7.1 Completed

| Item | Notes |
|---|---|
| PRD draft created | Product direction, MVP scope, user flow, privacy requirements defined |
| `design.md` created | Design instructions for Claude / design agent |
| Design prototype uploaded | `Today's Signal.html` uploaded as design reference |
| **Phase 1: Static SwiftUI Prototype** | All static UI screens, navigation, mock data, and reusable components implemented |
| **Phase 2: Local Interactions** | Shared AppState, card generation → library flow, idol side preserved, card preview shows actual card |
| **Phase 3: OCR Integration (Iteration 1)** | PhotosPicker image upload, Apple Vision OCR, OCR→editable blocks mapping, Home error states, TextConfirmation edit flow |

### 7.2 In Progress

| Item | Notes |
|---|---|
| Phase 4 — AI Analysis Integration | AIAnalysisService 基础接入完成，正在补 prompt/schema/真实 API |

### 7.3 Not Started

| Item |
|---|
| AI analysis integration (Phase 4)（进行中） |
| Local persistence (Phase 5)（进行中） |
| MVP QA testing (Phase 6) |

---

## 8. Development Log

### 2026-05-16 — Phase 1 Implementation Complete

#### Created Files

**Theme:**
- `Theme/ColorTheme.swift` — App-wide color palette (from CSS design tokens)

**Models:**
- `Models/MockData.swift` — All data models (ChatBubble, AnalysisResult, KnowledgePoint, VocabularyCard, GrammarCard) + mock data

**Components:**
- `Components/PrimaryButton.swift` — Primary pink CTA + secondary outline button
- `Components/TonePillView.swift` — Colored tone/label pill (6 color variants)
- `Components/ChatBubbleView.swift` — Left/right chat bubble with idol marker + edit controls
- `Components/KnowledgePointView.swift` — Vocab/grammar knowledge point with action buttons
- `Components/SignalCard.swift` — Generic rounded card container
- `Components/FlashcardView.swift` — Vocab + grammar flashcard detail views

**Views:**
- `Views/OnboardingView.swift` — 3-page swipe onboarding with illustrations
- `Views/HomeView.swift` — Home input page with app mark, action card, privacy note, recent list
- `Views/TextConfirmationView.swift` — OCR review with editable bubbles, side selector, CTA
- `Views/AnalysisResultView.swift` — Bubble-by-bubble analysis with knowledge point actions + user reply feedback
- `Views/CardPreviewModal.swift` — Card preview sheet after generating a card
- `Views/CardLibraryView.swift` — Vocab/grammar segmented tabs, expandable detail, delete
- `Views/SettingsView.swift` — Privacy hero card + data/about sections
- `Views/MainTabView.swift` — 3-tab navigation (解析, 卡片库, 设置) with NavigationStack

**Modified Files:**
- `ContentView.swift` — Now routes between OnboardingView and MainTabView
- `Docs/development-progress.md` — Updated with Phase 1 completion status

#### What Was Implemented

- Full onboarding flow (3 pages with skip, page indicators, illustrations)
- Home input page with upload/paste buttons, privacy note, recent analyses
- Text confirmation page with mock chat bubbles, edit/delete controls, idol side selector
- Analysis result page with mock AI results, tone labels, vocabulary, grammar, user reply feedback
- Knowledge point action system (认识 / 不认识 / 生成卡片) — interactive in-place
- Card preview modal (vocabulary and grammar flashcard views)
- Card library with vocab/grammar tabs, expandable detail, swipe delete
- Settings page with privacy hero, data sections, about section
- Tab-based navigation with NavigationStack for analysis flow
- Warm cream/pink/lavender color theme matching design reference
- All mock data: chat bubbles, analysis results, vocabulary cards, grammar cards

#### What Is NOT Implemented Yet

- Real OCR (Apple Vision framework)
- Real image upload / photo picker
- Real chat bubble detection
- Real LLM API calls
- Persistent storage (SwiftData / CoreData)
- User login / account
- Cloud sync
- Quiz / spaced repetition
- Voice playback
- Share Extension
- Payment / subscription

#### Next Recommended Tasks

1. **Phase 2 — Local Interactions:** Wire knowledge point actions to in-memory card library state; make card preview navigation work end-to-end; preserve side selection throughout flow.
2. **Phase 3 — OCR Integration:** Add photo picker, integrate Apple Vision OCR, map OCR output to editable chat bubbles.
3. **Phase 4 — AI Analysis:** Design structured prompt, connect to LLM API, validate JSON output.
4. **Phase 5 — Persistence:** Choose SwiftData or local JSON, persist cards and knowledge marks.

#### Known Issues

- Onboarding state is in-memory only; app will show onboarding again on every launch until persistence is added.
- ~~Card library uses its own local state; generating a card from analysis does not yet add it to the library.~~ (Fixed in Phase 2)
- "粘贴韩语文本" button navigates to TextConfirmation with mock data; real text input UI not yet implemented.

### 2026-05-16 — Phase 2 Implementation Complete

#### Created Files

**Models:**
- `Models/AppState.swift` — Shared `@Observable` state manager that connects all views. Contains:
  - Chat bubbles and idol side selection (persisted across TextConfirmation → Analysis flow)
  - Analysis results with knowledge point action management
  - Card library (vocabulary + grammar cards) shared across tabs
  - Card generation logic (KnowledgePoint → VocabularyCard / GrammarCard)
  - Card preview state (shows actual generated card)
  - Navigation state (tab selection + NavigationPath)
  - Undo support (reverting a "saved" action removes the generated card)

#### Modified Files

- `Models/MockData.swift` — Added `sourcePointId: UUID?` to VocabularyCard and GrammarCard to track which knowledge point generated which card (enables undo)
- `ContentView.swift` — Creates `@State AppState` and injects via `.environment()` instead of local onboarding state
- `Views/MainTabView.swift` — Uses `@Environment(AppState.self)` for tab selection, navigation path, and routes; removed local `Tab` and `AnalysisRoute` enums (moved to AppState.swift)
- `Views/TextConfirmationView.swift` — Uses AppState for `chatBubbles` and `idolSide` instead of local `@State`; side selection now persists through the flow
- `Views/AnalysisResultView.swift` — Uses AppState for `analysisResults`, `savedCount`, `knownCount`; card generation triggers `AppState.updateKnowledgeAction()` which creates cards and shows preview; `AnalysisBubbleCardView` now receives `idolSide` from AppState
- `Views/CardPreviewModal.swift` — Now accepts `vocabCard: VocabularyCard?` and `grammarCard: GrammarCard?` to show the actual generated card instead of always `MockData.vocabularyCards[0]`; added `onGoToLibrary` callback
- `Views/CardLibraryView.swift` — Uses `@Environment(AppState.self)` instead of local `@State` arrays; delete calls `appState.deleteVocabCard/deleteGrammarCard`; empty state CTA switches to analysis tab

#### What Was Implemented

- **Shared state management:** `AppState` (@Observable) injected via SwiftUI environment, shared across all views
- **Card generation flow:** Tapping "生成卡片" on a knowledge point creates a real VocabularyCard or GrammarCard from the point's data and inserts it into the shared card library
- **Card preview shows actual card:** The CardPreviewModal now displays the exact card that was just generated, not a hardcoded mock card
- **Card library integration:** Cards generated in AnalysisResultView immediately appear in CardLibraryView
- **Card deletion:** Deleting a card in the library removes it from AppState; deleting from analysis (undo) also removes the generated card
- **Idol side preserved:** The `idolSide` selection in TextConfirmationView is stored in AppState and used by AnalysisBubbleCardView
- **Navigation wiring:** "查看卡片库" button navigates to library tab; CardPreviewModal "查看卡片库" also navigates correctly
- **Undo support:** Reverting a "saved" knowledge point back to "open" removes the corresponding card from the library (tracked via `sourcePointId`)
- **Empty state CTA:** Card library empty state "上传聊天截图" button switches to analysis tab

#### What Is NOT Implemented Yet

- Real LLM API calls
- Persistent storage (SwiftData / CoreData)
- Loading / error states for analysis
- User login / account / cloud sync

#### Next Recommended Tasks

1. **Phase 4 — AI Analysis:** Design structured prompt, connect to LLM API, validate JSON output.
2. **Phase 5 — Persistence:** Choose SwiftData or local JSON, persist cards and knowledge marks.
3. **Phase 6 — QA/Polish:** Add simulator and real-device coverage for OCR and analysis failure states.

#### Known Issues

- All state is in-memory; app resets on launch (persistence is Phase 5).
- Cards generated from knowledge points use placeholder example sentences ("예문이 곧 생성됩니다.") since real AI generation is not yet implemented.
- Onboarding shows on every launch until persistence is added.

### 2026-05-16 — Phase 3 OCR Integration (Iteration 1) Complete

#### Created Files

- `Services/OCRService.swift` — Apple Vision OCR service with Korean-priority recognition, line merge heuristic, and ChatBubble mapping.

#### Modified Files

- `Views/MainTabView.swift` — Integrated PhotosPicker flow, OCR async processing, loading overlay, error handling, and routing to TextConfirmationView using OCR output.
- `Views/HomeView.swift` — Added OCR error/empty-state banner with re-upload entry.
- `Views/TextConfirmationView.swift` — Added editable text-block sheet (edit/save/cancel) while preserving existing delete and side-selection flow.
- `Docs/development-progress.md` — Updated Phase 3 status and logs.

#### What Was Implemented

- User can tap "上传聊天截图" to open photo library and select one image.
- If image selection is canceled, app stays on HomeView without navigation.
- Selected image runs through Apple Vision OCR (`ko-KR` first, then `en-US`/`zh-Hans`).
- OCR lines are mapped into editable `ChatBubble` blocks (line-based fallback + simple left/right heuristic by bounding box).
- OCR success navigates to existing TextConfirmationView with recognized blocks.
- TextConfirmationView now supports editing each text block in addition to delete.
- Empty Korean detection and OCR failures show friendly HomeView guidance and keep re-upload path.

#### Known Gaps / Unfinished in Phase 3

- Bubble-side detection is heuristic only (midX split), not true visual bubble segmentation.
- Non-Korean but useful text is intentionally blocked by current `noKoreanDetected` rule.
- OCR output currently feeds TextConfirmation only; analysis remains mock (Phase 4 scope).

#### Next Step Recommendation (Phase 4 — AI Analysis Integration)

1. Define `AIAnalysisService` input/output schema based on confirmed bubbles.
2. Implement prompt + strict JSON validation with fixed tone labels.
3. Replace `AppState.startAnalysis()` mock path with async service call and add timeout/partial-failure UI.

### 2026-05-16 — Phase 4 AI Analysis Integration (Foundation)

#### Created Files

- `Services/AIAnalysisService.swift` — Added analysis service protocol, mock and OpenAI implementations, structured prompt + JSON schema, response decoding and validation, timeout/error mapping, and runtime config toggle.

#### Modified Files

- `Models/AppState.swift` — Added async analysis pipeline, loading state, and analysis error state; now calls `AIAnalysisService` instead of directly using mock results.
- `Views/MainTabView.swift` — Updated `onAnalyze` path to call async `AppState.startAnalysis()`.
- `Views/TextConfirmationView.swift` — Added analyzing/loading UI, retry-friendly error banner, and disabled interactions during analysis.
- `Docs/development-progress.md` — Updated Phase 4 status and in-progress notes.

#### What Was Implemented

- Introduced a pluggable analysis service layer (`AIAnalysisServicing`) for Phase 4.
- Added OpenAI-backed analysis service (`/v1/chat/completions`) with structured output schema and strict JSON decoding.
- Added runtime switch between mock and real OpenAI service via environment/config.
- Switched analysis trigger from sync mock assignment to async service call.
- Added user-visible loading and error state in text confirmation flow.
- Preserved existing Phase 1/2/3 UI structure and navigation behavior.

#### Remaining for Phase 4

- Per-bubble partial failure rendering (currently request-level fallback only).
- Production-safe key management migration (move API call from client to backend proxy before release).
- Timeout strategy UX refinement with explicit 30s/60s progress messaging.
- Real-user eval and prompt tuning on noisy OCR text samples.

### 2026-05-16 — Phase 5 Local Persistence (Part 1)

#### Created Files

- `Services/CardStorageService.swift` — Added SwiftData-backed local storage service and persisted model schema for vocabulary/grammar cards.

#### Modified Files

- `Models/AppState.swift` — AppState now loads cards from local storage on init and persists card add/delete/undo operations.
- `Docs/development-progress.md` — Updated Phase 5 status and persistence progress.

#### What Was Implemented

- Selected SwiftData for MVP local persistence.
- Vocabulary cards and grammar cards are now persisted locally.
- Card library data is loaded on app launch.
- Existing UI and interaction flow remain unchanged.

#### Remaining for Phase 5

- Add lightweight migration handling for future schema changes.
- Evaluate whether `idolSide` default preference should persist between sessions.

### 2026-05-16 — Phase 5 Local Persistence (Part 2)

#### Modified Files

- `Services/CardStorageService.swift` — Added persisted knowledge-mark model and read/write APIs for known/dismissed actions.
- `Models/AppState.swift` — Added onboarding persistence (`UserDefaults`) and applied persisted knowledge marks to new analysis results.
- `Docs/development-progress.md` — Updated Phase 5 completion status.

#### What Was Implemented

- `known / dismissed` knowledge-point marks now persist locally.
- Persisted marks are re-applied to freshly generated analysis results.
- Onboarding completion now persists across app relaunches.

#### Remaining Notes

- Current knowledge-mark key uses `type + term` (MVP-level heuristic); future versions may add stronger normalization.

### 2026-05-17 — Phase 6 MVP Testing & Input Flow Enhancement

#### Modified Files

- `Views/MainTabView.swift` — Replaced mock paste-text jump with real paste-text input sheet, validation, and line-to-bubble parsing.
- `Docs/testing-checklist-phase6.md` — Added paste-text and timeout/retry test cases.
- `Docs/development-progress.md` — Updated current phase and this changelog.

#### What Was Implemented

- Home `粘贴韩语文本` now opens an input sheet instead of using mock data directly.
- Pasted text is split by non-empty lines and converted into editable `ChatBubble`s.
- Added optional line prefix support for side mapping:
  - `L:` / `l:` / `左:` => left bubble
  - `R:` / `r:` / `右:` => right bubble
- Empty paste input is blocked with inline validation.
- Confirmation page remains the single editing gate before AI analysis.

#### Testing Additions

- Added manual test cases for paste flow, side-prefix parsing, empty-input validation.
- Added timeout/network failure scenario in AI flow checklist.

#### Remaining in MVP

- Phase 4: per-bubble partial failure retry model is still pending (currently request-level retry).
- Phase 6: run full real-device screenshot regression suite and finalize demo script.

### 2026-05-17 — OCR Bubble Region Assignment Iteration

#### Modified Files

- `Services/OCRService.swift` — OCR pipeline upgraded from line-only merge to region-first assignment with fallback; added reaction/nickname robustness refinements.
- `Docs/development-progress.md` — Added this fix log.

#### What Was Implemented

- Added `DetectedBubbleRegion` intermediate model.
- New OCR flow:
  - clean lines
  - filter system/header/reaction/nickname noise
  - detect candidate bubble regions
  - assign OCR lines into region buckets and merge within region
  - fallback to previous line-merge path when region detection is empty
- Added explicit reaction counter detection helper (`+10`-like text) and reused in region assembly.
- Kept short Korean messages by avoiding aggressive single-line short-text deletion.

#### Current Limitations

- Region detection is still geometric heuristic (derived from OCR boxes), not true pixel-level bubble segmentation.
- Complex mixed layouts may still need manual correction in confirmation view.

### 2026-05-17 — OCR Error Alert UX Update

#### Modified Files

- `Views/MainTabView.swift` — OCR failure now shows alert with confirm action.
- `Views/HomeView.swift` — removed inline OCR error banner and re-upload button.
- `Docs/development-progress.md` — added this UX update log.

#### What Was Implemented

- Replaced Home inline OCR error area with modal alert (`识别失败`).
- Alert message uses OCR error text (e.g. `未识别到文字内容，请重新上传更清晰的截图。`).
- Confirm action `我知道了` dismisses alert and keeps user on Home.
- Removed extra "重新上传截图" inline button as requested.

### 2026-05-17 — Text Confirmation Manual Split Support

#### Modified Files

- `Views/TextConfirmationView.swift` — added edit-time manual split behavior (blank-line delimiter).
- `Docs/development-progress.md` — added this feature log.

#### What Was Implemented

- In edit sheet save flow, one bubble can now be split into multiple bubbles.
- Split rule: users insert blank lines (double return) between segments.
- On save, each non-empty segment becomes a new bubble, preserving side/role/type.
- Added inline editing hint text explaining the blank-line split behavior.

#### Why

- OCR edge cases still require manual correction.
- Manual split significantly improves usability when one OCR bubble contains multiple actual messages.

### 2026-05-17 — OCR Short Tail Line Preservation Hotfix

#### Modified Files

- `Services/OCRService.swift` — improved preservation of short final lines in multi-line bubbles.
- `Docs/development-progress.md` — added this hotfix log.

#### What Was Implemented

- Relaxed width-ratio constraint for region grouping (`0.18...1.95`).
- Added explicit short-tail merge path (`<=3` Hangul chars) when vertically adjacent and side-aligned.
- Lowered minimum region width threshold for Hangul-containing groups (`0.05`) to avoid dropping tiny tail lines.

#### Why

- Real regression: final short line (1–2 chars / short tone fragment) of a multi-line bubble could be split out then discarded.
- This patch keeps those tail fragments attached to their parent bubble whenever geometry indicates line wrapping.

### 2026-05-17 — OCR Region Over-Split Rebalance Hotfix

#### Modified Files

- `Services/OCRService.swift` — rebalanced region merge thresholds and reduced aggressive long-region splitting.
- `Docs/development-progress.md` — added this hotfix log.

#### What Was Implemented

- Region-assembled output now runs one extra merge pass before becoming final candidates.
- Relaxed region line-grouping thresholds (`x` alignment / width ratio / wrap gap) to avoid over-splitting.
- Long-region split guard now triggers only for very long regions (higher text/line thresholds).
- Increased paragraph-break threshold in `splitLargeRegionLines` to avoid unnecessary splits.

#### Why

- Previous hotfix solved over-merge but introduced over-split on normal multi-line bubbles.
- This rebalance aims for midpoint behavior: keep noise filtering while reducing fragmentation.

### 2026-05-17 — OCR Region Over-Merge Hotfix

#### Modified Files

- `Services/OCRService.swift` — tightened region grouping thresholds; added long-region guard split by vertical paragraph gaps.
- `Docs/development-progress.md` — added this hotfix log.

#### What Was Implemented

- Reduced region grouping tolerance to avoid chaining multiple separate bubbles into one giant region.
- Added width-similarity and tighter wrapped-line gap checks during region detection.
- Added `splitLargeRegionLines` fallback:
  - if one assembled region text is abnormally long,
  - split it into multiple bubble candidates by larger vertical gaps.

#### Why

- Real screenshot regression showed “all useful lines merged into one bubble” even after noise filtering.
- This hotfix specifically targets over-merge while keeping existing noise filtering gains.

---

## 9. Rules for AI Coding Assistant

When modifying this project, follow these rules:

1. Read this progress document first.
2. Read `Docs/PRD.md` if available.
3. Read `Docs/design.md` if available.
4. Check `DesignReference/` before implementing UI.
5. Do not implement out-of-scope features unless explicitly requested.
6. Prefer small, incremental changes.
7. Keep the project runnable after each step.
8. Use mock data before integrating OCR or AI.
9. Do not add login, cloud sync, payment, or backend dependencies in the MVP static UI phase.
10. Do not store original screenshots in persistence.
11. If unsure about a product decision, ask before implementing.
12. After making changes, update this progress document.

Each progress update should include:

- What was implemented
- What files were changed
- What remains to be done
- Any known issues or decisions needed

---

## 10. Implementation Notes for Claude Code / AI IDE

### 10.1 First Prompt to Coding Agent

Suggested prompt:

```text
Please read Docs/development-progress.md, Docs/PRD.md, and Docs/design.md first.

Then implement Phase 1 only:
- create the SwiftUI app shell;
- onboarding flow;
- main tab view;
- home page;
- text confirmation page with mock chat bubbles;
- analysis result page with mock data;
- card preview modal;
- card library with mock cards;
- settings page.

Do not implement OCR, AI API calls, persistent storage, login, cloud sync, or backend integration.

Keep the project runnable in iPhone Simulator after your changes.
After implementation, update Docs/development-progress.md with completed tasks and changed files.
```

### 10.2 UI Implementation Priority

If time is limited, implement screens in this order:

1. MainTabView
2. HomeView
3. TextConfirmationView
4. AnalysisResultView
5. CardPreviewModal
6. CardLibraryView
7. OnboardingView
8. SettingsView

### 10.3 Risk Areas

| Risk | Mitigation |
|---|---|
| UI becomes too decorative | Prioritize readability and spacing |
| OCR accuracy is unreliable | Always include editable confirmation step |
| AI output is inconsistent | Use strict JSON schema and validation |
| MVP scope expands too much | Keep reply generation, quiz, voice, sync for future |
| Privacy concerns | Do not save screenshots or full histories |

---

## 11. Future Roadmap

### V1 Enhancements

- Feedback chat for asking follow-up questions
- Search cards
- Favorite / star cards
- Edit card content
- More detailed reply suggestions
- Better bubble detection

### V2 Learning System

- Quiz review
- Spaced repetition
- Learning statistics
- Audio pronunciation
- Personalized explanation depth
- User learning profile

### V3 Advanced Features

- Share Extension
- Batch screenshot import
- Textbook wordbook import
- Cloud sync
- Multi-device support
- Multi-language explanation
- Theme switching
- More advanced fan-chat reply assistant

---

## 12. MVP Definition of Done

The MVP can be considered complete when:

- User can upload or paste text
- OCR result can be confirmed and edited
- Chat bubbles can be marked by side
- User can view bubble-by-bubble Korean-to-Chinese explanations
- User can mark vocabulary / grammar points
- User can generate and preview learning cards
- Cards are saved locally
- Card library shows vocabulary and grammar tabs
- User can delete individual cards
- Settings page explains privacy behavior
- App does not store original screenshots or full analysis history
- A demo can show the full flow from screenshot/text input to saved card
