# Phase 6 Testing Checklist (Manual)

## Scope

- OCR extraction quality
- Text confirmation editing flow
- AI analysis request/response flow
- Persistence behavior (cards, marks, onboarding)
- Error handling and retry behavior

## A. OCR Pipeline

1. Upload a clear Korean chat screenshot with timestamps and nicknames.
- Expected: timestamp/nickname mostly filtered out.
- Expected: major bubble texts remain.

2. Upload screenshot containing short real messages (e.g. `쉬는시간~`, `연습끝~~`).
- Expected: short real message should not be removed as nickname.

3. Upload screenshot with multiline bubbles.
- Expected: wrapped lines in one bubble are merged into one text block.

4. Upload invalid/non-chat image.
- Expected: friendly OCR failure/empty message shown on Home.

5. Cancel photo picker.
- Expected: stay on Home, no crash.

## B. Text Confirmation

1. Edit an OCR line and save.
- Expected: list updates immediately.

2. Delete a line.
- Expected: line removed.

3. Insert a missing line via `手动插入一条消息`.
- Expected: new bubble appears with selected side.

4. Toggle idol side left/right.
- Expected: UI updates and later analysis uses current side.

## B2. Paste Text Flow

1. Home -> `粘贴韩语文本`, paste multiline Korean text, continue.
- Expected: navigate to confirmation and each non-empty line becomes one editable bubble.

2. Paste lines with side prefixes (e.g. `L:오늘 뭐해?`, `R:나 지금 집이야`).
- Expected: `L` lines map to left bubbles, `R` lines map to right bubbles.

3. Tap continue with empty input.
- Expected: inline validation appears, no navigation, no crash.

## C. AI Analysis Flow

1. Start analysis with valid content.
- Expected: navigate to `解析中` page, then to `解析结果`.

2. Verify loading page animation.
- Expected: phase text transitions, progress bar updates.

3. Force API error (invalid key).
- Expected: return to confirmation page with specific error message.

4. Simulate timeout/network unavailable (disable network or use blocked DNS).
- Expected: shows timeout or service unavailable message; user can retry from confirmation page.

5. If `OPENAI_SHOW_ERROR_DETAILS=true`.
- Expected: debug details include HTTP status and server message.

6. Check console logs.
- Expected: `[AIAnalysis] ... elapsed=...s` printed for success, and logger entries for failure.

## D. Persistence

1. Generate vocabulary/grammar cards.
- Expected: cards appear in library.

2. Relaunch app.
- Expected: cards persist.

3. Mark knowledge points as `认识` or `不认识，不生成卡片`.
- Expected: after new analysis run, marks re-apply by term key.

4. Complete onboarding, relaunch app.
- Expected: onboarding should not show again.

5. Debug reset in Settings.
- Expected: cards + marks + onboarding state all cleared.

## E. Regression Basics

1. Home tab, Library tab, Settings tab all open normally.
2. OCR -> Confirmation -> Loading -> Result path works end-to-end.
3. No crash when repeating analysis multiple times in one session.
