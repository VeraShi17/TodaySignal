# Today's Signal · 오늘의 시그널

**A Chinese-language iOS app for learning Korean from real chat context.** Upload a screenshot or paste text, review the recognized messages, explore vocabulary, grammar and tone, then save useful expressions as study cards.

[English](README.md) · [简体中文](README.zh-CN.md)

> **Status:** Personal-use MVP. The app has not been released on the App Store. Its interface is in Chinese; the English documentation is for readers evaluating the project. The current Xcode target requires iOS 26.2 or later.

## Demo

[![Today's Signal demo preview](media/demo-preview.jpg)](media/todaysignal-demo.mp4)

[Watch the 48-second screen recording (MP4)](media/todaysignal-demo.mp4). It shows onboarding, OCR text review, message analysis and the card library. The recording uses an iPhone simulator.

## What it does

- **Understand chat screenshots:** Apple Vision OCR extracts Korean text, groups likely chat bubbles and lets the user correct the result before analysis.
- **Learn in context:** Message-by-message explanations include Chinese translations, tone labels, vocabulary and grammar or sentence endings.
- **Build a personal card library:** Save vocabulary and grammar cards locally with SwiftData; mark points as known or skip them.
- **Practice replies:** Generate Korean reply suggestions, check the user's own replies and ask follow-up questions about an analyzed message.

## How it is built

SwiftUI drives the interface and shared app state. `OCRService` handles on-device text recognition. Service protocols separate mock responses from optional OpenAI-backed analysis, reply, feedback and card-example services. Structured responses are decoded and checked before display; failed requests have visible retry paths. SwiftData stores cards and knowledge marks on the device.

```text
Screenshot or pasted text → OCR / editable chat bubbles → analysis and reply tools
                                             ↓
                                  local study cards (SwiftData)
```

## Run locally

1. Open `TodaySignal.xcodeproj` in Xcode and select the `TodaySignal` scheme. Use an iOS 26.2+ simulator or device. For a physical device, select your own development team in Signing & Capabilities.
2. Build and run. By default, AI services use mock data, so the main flow can be explored without an API key.
3. To try the real AI services for personal development, add `USE_REAL_OPENAI=1` and `OPENAI_API_KEY=<your key>` under **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**. `OPENAI_MODEL` is optional; the code defaults to `gpt-4.1-mini`. Do not commit your key.

When real AI is enabled, confirmed chat text and relevant follow-up context are sent from the app to OpenAI. Screenshot OCR runs on-device, and the original screenshot is not saved by the app. The API call currently originates on the client, so a public release would need a server-side key and request layer.

## Current scope and next steps

This is a working personal MVP, not a released product. The repository includes Swift Testing service and app-state contract tests, but still needs a repeatable simulator QA pass, CI, accessibility checks and performance measurements. The home screen's “Recent” rows are currently static sample content, not stored analysis history. Storage errors are not yet surfaced to users. These are the first areas I would address before a wider release.

Product notes and implementation history are in [the PRD](TodaySignal/Docs/PRD.md) and [V1 development notes](TodaySignal/Docs/development-progress-v1.md).
