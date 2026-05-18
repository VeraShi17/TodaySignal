# Today’s Signal iOS App V1 Development Progress

## 0. Project Overview

**Product Name:** 오늘의 시그널 / Today’s Signal  
**Platform:** iOS SwiftUI App  
**Current Version Target:** V1  
**Current Development Mode:** Incremental development based on completed MVP  
**Primary Users:** K-pop / 韩娱粉丝中的初中级韩语学习者

Today’s Signal is an iOS Korean chat learning assistant. The MVP already supports Korean chat screenshot OCR, left/right speaker separation, idol-side analysis, vocabulary / grammar explanation, and learning card generation.

V1 upgrades the app from:

> “看懂 idol 韩语聊天”

to:

> “能继续追问、能检查我的回复、能快速生成自然韩语回复，并补齐学习卡片例句。”

The V1 design reference is based on:

```text
DesignReference/Today's Signal - V1.html
```

The V1 HTML prototype references these design files:

```text
styles.css
design-canvas.jsx
ios-frame.jsx
components.jsx
onboarding.jsx
screens.jsx
v1.jsx
app-v1.jsx
```

If these files are available locally, keep them under `DesignReference/` and use them as the visual source of truth for V1 implementation.

---

## 1. Current MVP Baseline

### 1.1 MVP Already Completed

| Area | Current MVP Capability | Status |
|---|---|---|
| Screenshot Input | User can upload screenshot | 已完成 |
| Text Input | User can paste Korean text | 已完成 |
| OCR | Screenshot OCR can extract chat text | 已完成 |
| Speaker Separation | Left/right chat bubbles can be separated | 已完成 |
| Idol Side Selection | User can select idol / other-person side | 已完成 |
| Idol-side Analysis | System analyzes idol-side messages | 已完成 |
| Translation | Shows Chinese natural translation | 已完成 |
| Vocabulary Explanation | Extracts and explains vocabulary | 已完成 |
| Grammar / Ending Explanation | Extracts and explains grammar / endings | 已完成 |
| Learning Cards | Supports card generation and library | 已完成 |
| Local-only MVP | No login / cloud sync required | 已完成 |

### 1.2 MVP Limitations to Address in V1

| Limitation | V1 Direction |
|---|---|
| Learning card AI examples not implemented | Add generated examples to vocabulary and grammar cards |
| No follow-up Q&A | Add Feedback Chat on Analysis Result page |
| User’s own reply not evaluated | Add “同时检查我的回复” during analysis |
| Reply suggestion tied to no clear flow | Add independent Quick Reply path |
| No homepage quick reply entry | Add Home quick real-time reply card |
| No selected bubble reply flow | Add selectable idol bubbles and Reply Suggestion page |
| No screenshot-length warning | Add too-many-bubbles warning state |

---

## 2. V1 Scope

### 2.1 V1 Must-have

| Module | Requirement |
|---|---|
| Card Example Generation | Generate AI examples for vocabulary and grammar cards |
| Feedback Chat | Add unified follow-up chat input on Analysis Result page |
| My Reply Check | Evaluate user-side Korean replies during analysis |
| Quick Reply Suggestion | Independent flow for generating Korean replies |
| Home Quick Reply Entry | Add quick reply entry on Home page |
| OCR Confirmation Update | Add selected bubble state, “同时检查我的回复” toggle, and “生成回复建议” button |
| Reply Suggestion Page | New page for context, Chinese intent, tone selection, and reply results |
| Reply Results | Generate 3 Korean replies with Chinese meaning and tone note |
| Copy Actions | Copy reply suggestions and improved reply alternatives |
| Too-many-bubbles Warning | Warn if OCR detects more than 12 bubbles |
| V1 Progress Tracking | Keep this document updated after each development step |

### 2.2 V1 Should-have

| Module | Requirement |
|---|---|
| Feedback Chat Quick Chips | Suggested questions like “这里为什么这么说？” |
| Reply Loading States | Dedicated loading state for reply generation |
| Feedback Loading States | Dedicated loading state for follow-up explanation |
| Reply Suggestion Empty State | Friendly empty state when no context or intent is provided |
| Partial Error Handling | Retry for failed feedback/reply calls |
| UI Polish | Match V1 design reference visual style |

### 2.3 Out of Scope for V1

Do **not** implement these in V1 unless explicitly requested:

| Feature | Reason |
|---|---|
| Audio pronunciation | Future / V1.5 |
| User learning profile | Future / V1.5 |
| Textbook wordbook import | Future / V2 |
| Quiz | Future learning system |
| Share Extension | Future mobile-native enhancement |
| Cloud sync | Future account/system feature |
| Login | Future account/system feature |
| Payment / subscription | Not relevant to V1 |
| Feedback Chat saving as card | Future |
| Full chat history saving | Privacy and scope |
| Complex long-term tutor memory | Future |
| Complex social/community features | Not product focus |

---

## 3. Recommended Development Strategy

V1 should be implemented incrementally on top of the completed MVP.

Recommended sequence:

1. Update data models and mock data for V1.
2. Update Home UI with Quick Reply entry.
3. Update OCR Confirmation page with selection, toggle, and new actions.
4. Add Reply Suggestion page with mock flow.
5. Update Analysis Result page with My Reply Check and Feedback Chat.
6. Update card preview / card library to show AI examples.
7. Connect V1 UI to existing or new AI service functions.
8. Add loading, error, and edge states.
9. Persist only what belongs to the existing local card system.
10. Polish UI and update progress document.

---

## 4. Suggested SwiftUI File Structure for V1

Add new files without over-rewriting MVP files.

```text
TodaySignal/
  Views/
    Main/
      HomeView.swift
      MainTabView.swift

    Analysis/
      TextConfirmationView.swift
      AnalysisResultView.swift
      FeedbackChatView.swift
      MyReplyCheckSection.swift
      ReplyCheckCardView.swift

    Reply/
      ReplySuggestionView.swift
      ReplyContextSelectorView.swift
      ReplyToneSelectorView.swift
      ReplySuggestionResultView.swift
      ReplySuggestionCardView.swift

    Cards/
      CardPreviewModal.swift
      CardLibraryView.swift
      VocabularyCardDetailView.swift
      GrammarCardDetailView.swift

  Components/
    PrimaryButton.swift
    SecondaryButton.swift
    SignalCard.swift
    ChatBubbleView.swift
    SelectableChatBubbleView.swift
    ToneLabelView.swift
    FeedbackInputBar.swift
    LoadingStateView.swift
    EmptyStateView.swift
    CopyButton.swift
    WarningBanner.swift

  Models/
    ChatBubble.swift
    AnalysisResult.swift
    KnowledgePoint.swift
    LearningCard.swift
    ReplySuggestion.swift
    ReplyCheckResult.swift
    FeedbackMessage.swift
    MockDataV1.swift

  ViewModels/
    TextConfirmationViewModel.swift
    AnalysisResultViewModel.swift
    ReplySuggestionViewModel.swift
    FeedbackChatViewModel.swift
    CardLibraryViewModel.swift

  Services/
    AIAnalysisService.swift
    ReplySuggestionService.swift
    ReplyCheckService.swift
    FeedbackChatService.swift
    CardExampleService.swift

  Docs/
    PRD_V1.md
    development-progress-v1.md

  DesignReference/
    Today's Signal - V1.html
    styles.css
    components.jsx
    screens.jsx
    v1.jsx
    app-v1.jsx
```

---

## 5. V1 Module Breakdown and Implementation Plan

### 5.1 Documentation and Design Reference Setup

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M0.1 | Add V1 PRD | Add `Docs/PRD_V1.md` or equivalent V1 requirement document | 1 | 未开始 |
| V1-M0.2 | Add V1 Progress Doc | Add this file as `Docs/development-progress-v1.md` | 2 | 未开始 |
| V1-M0.3 | Add V1 Design Reference | Place `Today's Signal - V1.html` under `DesignReference/` | 3 | 未开始 |
| V1-M0.4 | Verify Design Assets | Confirm referenced CSS/JSX files exist locally if needed | 4 | 未开始 |
| V1-M0.5 | Review Current MVP Code | Identify existing Home, OCR, Analysis, Card files to update | 5 | 未开始 |

Implementation notes:

- Do not delete MVP design references.
- Keep V1 design reference separate from MVP design reference.
- Use V1 design as visual guidance, not as web code to embed.

### 5.2 V1 Data Models and Mock Data

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M1.1 | Extend LearningCard | Add AI example sentence fields to vocabulary and grammar cards | 6 | 未开始 |
| V1-M1.2 | ReplySuggestion Model | Add model for generated reply suggestions | 7 | 未开始 |
| V1-M1.3 | ReplyCheckResult Model | Add model for evaluating user-side replies | 8 | 未开始 |
| V1-M1.4 | FeedbackMessage Model | Add model for Feedback Chat messages | 9 | 未开始 |
| V1-M1.5 | Bubble Selection State | Add selected-for-reply state for idol bubbles | 10 | 未开始 |
| V1-M1.6 | MockDataV1 | Add mock V1 reply suggestions, reply check results, feedback messages, example cards | 11 | 未开始 |

Suggested model examples:

```swift
struct ReplySuggestion: Identifiable {
    let id: UUID
    let replyKo: String
    let replyZh: String
    let tone: ReplyTone
    let noteZh: String
}
```

```swift
enum ReplyTone: String, CaseIterable {
    case natural = "自然"
    case cute = "可爱"
    case polite = "礼貌"
    case friendly = "朋友感"
    case subtleFlirty = "暧昧感"
}
```

```swift
struct ReplyCheckResult: Identifiable {
    let id: UUID
    let bubbleID: UUID
    let originalReply: String
    let status: ReplyCheckStatus
    let feedbackZh: String
    let suggestedReplyKo: String?
    let suggestedReplyZh: String?
}
```

```swift
enum ReplyCheckStatus {
    case natural
    case needsImprovement
}
```

### 5.3 Home Page V1 Update

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M2.1 | Home Layout Review | Review current Home layout and identify insertion point | 12 | 未开始 |
| V1-M2.2 | Quick Reply Card | Add “快速实时回复” soft card | 13 | 未开始 |
| V1-M2.3 | Learning vs Reply Separation | Visually separate “学习解析” and “快速回复” tasks | 14 | 未开始 |
| V1-M2.4 | Quick Reply Navigation | Navigate from Home to ReplySuggestionView | 15 | 未开始 |
| V1-M2.5 | Home Copy Polish | Add V1 microcopy while keeping page simple | 16 | 未开始 |

Home should contain two clear task cards:

#### Learning Analysis Card

- Title: `学习解析`
- Copy: `上传聊天截图，学习 idol 说的话。`
- CTA: `开始学习解析`

#### Quick Reply Card

- Title: `快速实时回复`
- Copy: `想马上回一句韩语？输入内容或上传截图，生成自然回复。`
- CTA: `快速实时回复`

### 5.4 OCR / Text Confirmation Page V1 Update

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M3.1 | Detect My-side Bubbles | Identify non-idol side as user/my side after idol side selection | 17 | 未开始 |
| V1-M3.2 | My Reply Check Toggle | Add `同时检查我的回复` toggle | 18 | 未开始 |
| V1-M3.3 | Toggle Display Rule | Show toggle only when my-side Korean bubbles exist | 19 | 未开始 |
| V1-M3.4 | Default Toggle State | Default on when my-side Korean bubbles are detected | 20 | 未开始 |
| V1-M3.5 | Selectable Idol Bubbles | Allow selecting one or more idol-side bubbles for reply suggestion | 21 | 未开始 |
| V1-M3.6 | Selection Visual State | Add checkbox / highlight / selected border state | 22 | 未开始 |
| V1-M3.7 | Bottom Action Bar | Add `学习解析` and `生成回复建议` buttons | 23 | 未开始 |
| V1-M3.8 | No Selection Hint | If no bubble selected for reply, show `请先选择想回复的消息。` | 24 | 未开始 |
| V1-M3.9 | Too-many-bubbles Warning | Show warning if OCR identifies more than 12 bubbles | 25 | 未开始 |
| V1-M3.10 | Route to ReplySuggestion | Pass selected idol bubbles into ReplySuggestionView | 26 | 未开始 |
| V1-M3.11 | Route to Analysis | Pass `checkMyReplyEnabled` into AnalysisResultView | 27 | 未开始 |

Recommended bottom UI:

```text
☑ 同时检查我的回复

[学习解析]
[生成回复建议]
```

Too-many-bubbles warning copy:

```text
这张截图内容有点多，解析可能会变慢。建议裁剪成 10 条以内的聊天内容，或分批上传。
```

Buttons:

- `继续解析`
- `重新上传`

### 5.5 Reply Suggestion Flow

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M4.1 | ReplySuggestionView | Create new page for quick reply generation | 28 | 未开始 |
| V1-M4.2 | Entry from Home | Support homepage quick reply entry | 29 | 未开始 |
| V1-M4.3 | Entry from OCR Confirmation | Support selected idol bubbles as context | 30 | 未开始 |
| V1-M4.4 | Context Display | Show selected idol bubbles or pasted text | 31 | 未开始 |
| V1-M4.5 | Home Entry Input Options | Support upload screenshot or paste text state in UI | 32 | 未开始 |
| V1-M4.6 | Chinese Intent Input | Add optional Chinese text input field | 33 | 未开始 |
| V1-M4.7 | Reply Tone Selector | Add tone chips: 自然 / 可爱 / 礼貌 / 朋友感 / 暧昧感 | 34 | 未开始 |
| V1-M4.8 | Default Tone | Default tone is `自然` | 35 | 未开始 |
| V1-M4.9 | Generate Button | Add `生成 3 条回复` CTA | 36 | 未开始 |
| V1-M4.10 | Reply Loading State | Show `正在帮你组织自然韩语回复…` | 37 | 未开始 |
| V1-M4.11 | Reply Results List | Show 3 reply suggestion cards | 38 | 未开始 |
| V1-M4.12 | Copy Reply | Add copy action to each generated reply | 39 | 未开始 |
| V1-M4.13 | Empty State | Show `先选择一条想回复的消息，或输入你想说的话。` | 40 | 未开始 |

Reply Suggestion input fields:

| Field | Required | Notes |
|---|---|---|
| Idol message / context | Optional but recommended | From selected bubbles or pasted text |
| Chinese intent | Optional | User may say what they want to express |
| Tone | Required / default | Default `自然` |
| Output count | Fixed | V1 fixed at 3 |

Tone options:

- 自然
- 可爱
- 礼貌
- 朋友感
- 暧昧感

Result card fields:

- Korean reply
- Chinese meaning
- Tone note
- Copy button

### 5.6 Analysis Result Page V1 Update

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M5.1 | Analysis Layout Review | Review existing AnalysisResultView | 41 | 未开始 |
| V1-M5.2 | My Reply Check Section | Add section below or between analysis sections | 42 | 未开始 |
| V1-M5.3 | Reply Check Natural State | Show natural feedback card | 43 | 未开始 |
| V1-M5.4 | Reply Check Improvement State | Show issue explanation and suggested alternative | 44 | 未开始 |
| V1-M5.5 | Copy Suggested Alternative | Add copy button for improved reply | 45 | 未开始 |
| V1-M5.6 | Conditional Display | Show section only when check is enabled and my-side replies exist | 46 | 未开始 |
| V1-M5.7 | Feedback Chat Section | Add bottom unified follow-up input | 47 | 未开始 |
| V1-M5.8 | Feedback Input Bar | Add text field and send button | 48 | 未开始 |
| V1-M5.9 | Feedback Quick Chips | Add optional quick chips | 49 | 未开始 |
| V1-M5.10 | Feedback Loading State | Show `正在继续解释这个表达…` | 50 | 未开始 |
| V1-M5.11 | Feedback Response Card | Show AI response below input or in thread-like card | 51 | 未开始 |
| V1-M5.12 | Analysis Context Passing | Pass current analysis context to FeedbackChatViewModel | 52 | 未开始 |

Recommended Analysis Result sections:

```text
Section 1: 对方消息学习解析
Section 2: 我的回复检查
Section 3: 继续追问
```

My reply check labels:

- `表达自然`
- `可以更自然一点`

Avoid harsh wording like:

- `错误`
- `不对`
- `表达很差`

Use gentle wording:

- `这句可以更自然一点`
- `意思能理解，但语气稍微有点直接`

### 5.7 Learning Card Example Generation

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M6.1 | Vocabulary Card Data Update | Add example sentence and translation fields | 53 | 未开始 |
| V1-M6.2 | Grammar Card Data Update | Add 1–2 example sentences and translations | 54 | 未开始 |
| V1-M6.3 | Card Preview Modal Update | Show AI examples in preview | 55 | 未开始 |
| V1-M6.4 | Vocabulary Card Detail Update | Show example in card library detail | 56 | 未开始 |
| V1-M6.5 | Grammar Card Detail Update | Show examples in card library detail | 57 | 未开始 |
| V1-M6.6 | Mock Example Data | Add realistic Korean examples to mock cards | 58 | 未开始 |
| V1-M6.7 | Card Generation Integration | Ensure new cards include examples when generated | 59 | 未开始 |
| V1-M6.8 | Example Missing Fallback | If example generation fails, show graceful placeholder or retry | 60 | 未开始 |

Vocabulary card example fields:

- AI example sentence
- Chinese translation

Grammar card example fields:

- 1–2 Korean example sentences
- Chinese translations
- Usage context / relationship note

### 5.8 Service Layer and AI Integration

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M7.1 | Service Interface Review | Review existing AIAnalysisService | 61 | 未开始 |
| V1-M7.2 | ReplySuggestionService | Add service for generating reply suggestions | 62 | 未开始 |
| V1-M7.3 | ReplyCheckService | Add service for evaluating user replies | 63 | 未开始 |
| V1-M7.4 | FeedbackChatService | Add service for follow-up questions | 64 | 未开始 |
| V1-M7.5 | CardExampleService | Add service or extend card generation to include examples | 65 | 未开始 |
| V1-M7.6 | Mock Service Mode | Support mock responses for development and testing | 66 | 未开始 |
| V1-M7.7 | Real API Integration | Connect V1 service calls to selected LLM API | 67 | 未开始 |
| V1-M7.8 | JSON Schema Validation | Validate AI outputs before rendering | 68 | 未开始 |
| V1-M7.9 | Timeout Handling | Add timeout handling for V1 AI calls | 69 | 未开始 |
| V1-M7.10 | Partial Failure Handling | Let individual V1 calls fail gracefully | 70 | 未开始 |

Recommended services:

```swift
protocol ReplySuggestionServiceProtocol {
    func generateReplies(context: ReplyContext, intentZh: String?, tone: ReplyTone) async throws -> [ReplySuggestion]
}
```

```swift
protocol ReplyCheckServiceProtocol {
    func checkReplies(_ replies: [ChatBubble], context: [ChatBubble]) async throws -> [ReplyCheckResult]
}
```

```swift
protocol FeedbackChatServiceProtocol {
    func ask(question: String, context: AnalysisContext) async throws -> FeedbackMessage
}
```

Performance goals:

| Function | Target |
|---|---|
| Reply Suggestion | 10–20 seconds |
| Feedback Chat | 10–20 seconds |
| Learning Analysis | 30 seconds |
| Timeout | >60 seconds should show retry/error state |

### 5.9 Prompt and JSON Schema Design

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M8.1 | Reply Suggestion Prompt | Generate 3 natural Korean replies | 71 | 未开始 |
| V1-M8.2 | Reply Suggestion Schema | Define JSON schema for reply suggestions | 72 | 未开始 |
| V1-M8.3 | Reply Check Prompt | Evaluate user replies gently | 73 | 未开始 |
| V1-M8.4 | Reply Check Schema | Define JSON schema for reply check results | 74 | 未开始 |
| V1-M8.5 | Feedback Chat Prompt | Answer follow-up questions with analysis context | 75 | 未开始 |
| V1-M8.6 | Feedback Chat Schema | Define response format for follow-up answers | 76 | 未开始 |
| V1-M8.7 | Card Example Prompt | Generate Korean examples for card content | 77 | 未开始 |
| V1-M8.8 | Safety Rules | Add boundaries for idol/fan reply suggestions | 78 | 未开始 |

Safety rules for reply generation:

- Keep fan-idol boundary respectful.
- Avoid overly intimate or invasive content.
- “暧昧感” should mean light, subtle, cute, not explicit.
- Do not generate harassment, sexual, or manipulative messages.
- Keep replies short and chat-friendly.
- Prefer natural Korean over literal Chinese translation.

### 5.10 Local Storage Updates

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M9.1 | Storage Model Migration | Add example fields to saved cards | 79 | 未开始 |
| V1-M9.2 | Backward Compatibility | Existing MVP cards without examples should still load | 80 | 未开始 |
| V1-M9.3 | Save New Card Examples | Save generated examples with new cards | 81 | 未开始 |
| V1-M9.4 | Do Not Save Quick Replies | Reply suggestions should not be saved by default | 82 | 未开始 |
| V1-M9.5 | Do Not Save Feedback History | Feedback chat history not persisted in V1 | 83 | 未开始 |
| V1-M9.6 | Do Not Save Screenshots | Continue not saving original screenshots | 84 | 未开始 |

Persistence rules:

Save:

- learning cards;
- card examples;
- known / skipped knowledge-point marks, if already supported.

Do not save by default:

- quick reply suggestions;
- feedback chat history;
- original screenshots;
- full analysis history;
- user Chinese intent for replies.

### 5.11 Loading, Empty, Error, and Warning States

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M10.1 | Reply Loading | `正在帮你组织自然韩语回复…` | 85 | 未开始 |
| V1-M10.2 | Feedback Loading | `正在继续解释这个表达…` | 86 | 未开始 |
| V1-M10.3 | Reply Empty State | `先选择一条想回复的消息，或输入你想说的话。` | 87 | 未开始 |
| V1-M10.4 | Too-many-bubbles Warning | Show warning for >12 bubbles | 88 | 未开始 |
| V1-M10.5 | Reply Generation Error | Show retry for failed quick replies | 89 | 未开始 |
| V1-M10.6 | Feedback Error | Show retry for failed follow-up answer | 90 | 未开始 |
| V1-M10.7 | Reply Check Partial Failure | Show available reply checks, retry failed ones | 91 | 未开始 |
| V1-M10.8 | Card Example Failure | Allow card to save without example or retry example generation | 92 | 未开始 |

### 5.12 QA and Polish

| ID | Module | Implementation Functionality | Order | Status |
|---|---|---|---:|---|
| V1-M11.1 | V1 Visual Polish | Match V1 design reference | 93 | 未开始 |
| V1-M11.2 | Navigation QA | Test Home → Reply, OCR → Reply, OCR → Analysis | 94 | 未开始 |
| V1-M11.3 | Reply Flow QA | Test all tone options and copy actions | 95 | 未开始 |
| V1-M11.4 | Feedback Chat QA | Test follow-up questions and loading/error states | 96 | 未开始 |
| V1-M11.5 | My Reply Check QA | Test natural and improvement states | 97 | 未开始 |
| V1-M11.6 | Card Example QA | Test new and old cards | 98 | 未开始 |
| V1-M11.7 | Privacy QA | Confirm no screenshot/full feedback history persistence | 99 | 未开始 |
| V1-M11.8 | Performance QA | Measure response times for V1 AI calls | 100 | 未开始 |
| V1-M11.9 | Demo Script | Prepare V1 demo path | 101 | 未开始 |
| V1-M11.10 | Progress Doc Update | Mark completed work and next steps | 102 | 未开始 |

---

## 6. Development Order Summary

### Phase V1-A — Docs, Models, and Mock UI

| Order | Task | Status |
|---:|---|---|
| 1 | Add V1 docs and design reference | 未开始 |
| 2 | Extend data models for reply suggestions, reply checks, feedback messages, card examples | 未开始 |
| 3 | Add V1 mock data | 未开始 |
| 4 | Update Home with Quick Reply card | 未开始 |
| 5 | Update OCR confirmation page with toggle, bubble selection, and reply button | 未开始 |
| 6 | Add ReplySuggestionView with mock results | 未开始 |
| 7 | Update AnalysisResultView with my reply check and feedback chat UI | 未开始 |
| 8 | Update card preview and card details with AI examples | 未开始 |

### Phase V1-B — Local Interaction

| Order | Task | Status |
|---:|---|---|
| 9 | Make idol bubbles selectable for reply suggestion | 未开始 |
| 10 | Pass selected bubbles to ReplySuggestionView | 未开始 |
| 11 | Implement tone selector state | 未开始 |
| 12 | Implement Chinese intent input state | 未开始 |
| 13 | Generate mock 3 replies | 未开始 |
| 14 | Add copy actions | 未开始 |
| 15 | Toggle my reply check on/off | 未开始 |
| 16 | Add mock feedback chat response interaction | 未开始 |

### Phase V1-C — AI Service Integration

| Order | Task | Status |
|---:|---|---|
| 17 | Implement ReplySuggestionService | 已完成 |
| 18 | Implement ReplyCheckService | 未开始 |
| 19 | Implement FeedbackChatService | 未开始 |
| 20 | Implement card example generation | 未开始 |
| 21 | Add JSON schema validation | 未开始 |
| 22 | Add timeout and retry handling | 未开始 |

### Phase V1-D — Persistence and Compatibility

| Order | Task | Status |
|---:|---|---|
| 23 | Migrate card storage schema for examples | 未开始 |
| 24 | Support old cards without examples | 未开始 |
| 25 | Save examples with new cards | 未开始 |
| 26 | Confirm quick replies and feedback history are not persisted | 未开始 |

### Phase V1-E — QA and Polish

| Order | Task | Status |
|---:|---|---|
| 27 | Polish V1 UI based on design reference | 未开始 |
| 28 | Test all V1 flows in simulator | 未开始 |
| 29 | Test OCR → reply suggestion path | 未开始 |
| 30 | Test OCR → learning analysis + reply check path | 未开始 |
| 31 | Test feedback chat | 未开始 |
| 32 | Test privacy requirements | 未开始 |
| 33 | Update progress document | 未开始 |

---

## 7. V1 User Flows

### 7.1 Flow A: Learning Analysis + My Reply Check

```text
Upload screenshot / paste text
→ OCR and speaker separation
→ User confirms bubbles
→ User selects idol / other side
→ If my-side Korean bubbles exist, “同时检查我的回复” is shown and default enabled
→ User taps 学习解析
→ System analyzes idol-side bubbles
→ System checks my-side replies
→ Analysis Result shows:
   - idol message learning analysis
   - my reply check section
   - feedback chat section
```

### 7.2 Flow B: Quick Reply from Home

```text
Home
→ Quick Real-time Reply
→ User uploads screenshot or pastes idol text
→ User optionally enters Chinese intent
→ User selects tone
→ User taps 生成 3 条回复
→ System returns 3 Korean replies
→ User copies one
```

### 7.3 Flow C: Quick Reply from OCR Confirmation

```text
Upload screenshot / paste text
→ OCR confirmation page
→ User selects idol side
→ User selects one or more idol bubbles
→ User taps 生成回复建议
→ ReplySuggestionView opens with selected bubbles as context
→ User optionally enters Chinese intent
→ User selects tone
→ Generate 3 replies
```

### 7.4 Flow D: Feedback Chat

```text
Analysis Result
→ User scrolls to bottom
→ User enters follow-up question
→ System answers based on current analysis context
→ V1 does not save feedback chat history
→ V1 does not generate cards from feedback chat
```

---

## 8. Current Status

### 8.1 Completed

| Item | Notes |
|---|---|
| MVP core functionality | Screenshot OCR, speaker separation, idol-side analysis, learning cards |
| V1 PRD direction | Feedback chat, reply suggestion, my reply check, card examples |
| V1 design prototype | Uploaded as `Today's Signal - V1.html` |

### 8.2 In Progress

| Item | Notes |
|---|---|
| V1 development planning | This document defines module breakdown and implementation order |

### 8.3 Not Started

| Item |
|---|
| V1 model updates |
| V1 Home quick reply entry |
| OCR confirmation selection/toggle update |
| Reply Suggestion page |
| My Reply Check section |
| Feedback Chat |
| Card example generation |
| V1 AI service integration |
| V1 persistence migration |
| V1 QA and polish |

---

## 9. Development Log

### 2026-05-17

#### Created

- V1 development progress document.
- V1 module breakdown and implementation order.
- V1 development phases.

#### Current Task

- Start V1 incremental development from completed MVP.
- First recommended implementation step:
  1. Add V1 models and mock data.
  2. Update Home with Quick Reply card.
  3. Update OCR confirmation page with reply-related actions.

#### Next Recommended Task

Begin **Phase V1-A: Docs, Models, and Mock UI**.

---

## 10. Rules for AI Coding Assistant

When modifying this project for V1:

1. Read this V1 progress document first.
2. Read the existing MVP code before making changes.
3. Check `DesignReference/Today's Signal - V1.html` and related V1 design files before implementing UI.
4. Implement V1 incrementally; do not rewrite the entire MVP app.
5. Preserve existing MVP flows unless V1 explicitly updates them.
6. Use mock data first before integrating new AI APIs.
7. Keep the app runnable after each step.
8. Do not implement Future features unless explicitly requested.
9. Do not add login, cloud sync, subscription, quiz, audio pronunciation, or textbook import in V1.
10. Do not persist original screenshots, full feedback chat history, or quick reply history by default.
11. Keep UI consistent with the existing soft, rounded, cute-but-readable design language.
12. After making code changes, update this document.

Each update should include:

- What was implemented;
- What files were changed;
- Which status rows changed;
- Known issues;
- Next recommended task.

---

## 11. Suggested Prompt for Claude Code / AI IDE

Use this prompt when asking an AI coding assistant to continue V1 development:

```text
Please read:

- Docs/development-progress-v1.md
- The existing SwiftUI MVP code
- DesignReference/Today's Signal - V1.html and related design files

The MVP is already completed. Please start V1 incremental development.

Implement Phase V1-A only:
1. Add or extend models for:
   - ReplySuggestion
   - ReplyCheckResult
   - FeedbackMessage
   - learning card AI examples
2. Add V1 mock data.
3. Update HomeView with a Quick Real-time Reply card.
4. Update TextConfirmationView with:
   - “同时检查我的回复” toggle
   - selectable idol bubbles
   - “学习解析” and “生成回复建议” actions
5. Add a mock ReplySuggestionView with:
   - selected context display
   - optional Chinese intent input
   - tone selector
   - mock 3 reply results
6. Update AnalysisResultView with placeholder sections for:
   - My Reply Check
   - Feedback Chat
7. Update card preview/detail UI to show AI examples using mock data.

Do not integrate real AI APIs yet.
Do not implement audio pronunciation, user learning profile, textbook import, login, cloud sync, quiz, or Share Extension.
Keep the app runnable after changes.
After implementation, update Docs/development-progress-v1.md with completed tasks and changed files.
```

---

## 12. Recent Iteration Notes (2026-05-18)

### 12.1 Feedback Chat Guardrail Update

- Added a new post-validation guardrail for overly generic follow-up answers in `FeedbackChatService`.
- If the answer is too short or matches generic phrasing (e.g. "就是这个意思"), the app now returns a more actionable fallback prompt to guide users toward grammar-focused follow-up questions.
- New fallback reason telemetry:
  - `feedback.too_generic`

### 12.2 Prompt Strategy Update

- `FeedbackChat` system prompt was tightened into a grammar-learning-first mode.
- Ambiguous questions now prioritize grammar-ending and syntax explanation over broad translation/chat.
- "How to reply" behavior remains supported but constrained to 1-2 short examples.

### 12.3 UI and Flow Update

- Reply-check cards are now shown inline following original chat bubble order in `AnalysisResultView`, rather than grouped at the bottom.
- This improves readability and bubble-to-feedback alignment in multi-reply scenarios.

### 12.4 Next Validation Checklist

- Run 10-15 real screenshot samples and record:
  - generic fallback hit rate (`feedback.too_generic`)
  - over-correction rate in `ReplyCheck`
  - user comprehension for grammar-focused quick prompts

---

## 13. V1 Definition of Done

V1 can be considered complete when:

- Home includes Quick Real-time Reply entry.
- OCR confirmation page supports:
  - my reply check toggle;
  - idol bubble selection;
  - learning analysis action;
  - reply suggestion action.
- Reply Suggestion page supports:
  - selected idol bubble context;
  - pasted/direct text context;
  - optional Chinese intent;
  - tone selector;
  - generation of 3 Korean replies;
  - copy actions.
- Analysis Result page supports:
  - idol-side learning analysis;
  - my reply check section;
  - feedback chat section.
- Learning cards include AI examples:
  - vocabulary cards have example sentence and translation;
  - grammar cards have 1–2 examples and translations.
- V1 AI services are integrated or mock/real toggle exists.
- V1 loading, empty, error, and warning states are implemented.
- Old MVP cards remain compatible.
- App does not save original screenshots, full feedback chat history, or quick reply history by default.
- V1 UI matches the V1 design reference and remains readable on iPhone Simulator.
