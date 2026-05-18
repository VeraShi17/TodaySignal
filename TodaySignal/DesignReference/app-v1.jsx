/* global React, ReactDOM, IOSDevice, DesignCanvas, DCSection, DCArtboard,
   HomeScreenV1, ConfirmScreenV1, AnalysisScreenV1, CardPreviewModalV1,
   ReplySuggestionScreen, ReplyEmptyScreen,
   QuickReplyLoading, TooManyBubblesScreen, LibraryDetailV1,
   LibraryScreen, SettingsScreen, LoadingScreen,
   Onboarding1, Onboarding2, Onboarding3 */

const W = 390, H = 844;

function Frame({ children, dark = false }) {
  return <IOSDevice width={W} height={H} dark={dark}>{children}</IOSDevice>;
}

// ─── Interactive: full Learn flow (V1) ───
function LearnFlowV1() {
  // step: home → confirm → loading → analysis  |  confirm → reply-select → quickreply
  const [step, setStep] = React.useState('home');
  const [confirmMode, setConfirmMode] = React.useState('ocr'); // 'ocr' | 'reply'
  const [idolSide, setIdolSide] = React.useState('left');
  const [checkMy, setCheckMy] = React.useState(true);
  const [selectedIdol, setSelectedIdol] = React.useState([]);
  const [showCard, setShowCard] = React.useState(false);

  const toggleIdol = id => setSelectedIdol(s => s.includes(id) ? s.filter(x => x !== id) : [...s, id]);
  const reset = () => {
    setStep('home'); setConfirmMode('ocr'); setSelectedIdol([]); setShowCard(false);
  };

  const screen =
    step === 'home' ? (
      <HomeScreenV1
        onLearn={() => { setConfirmMode('ocr'); setStep('confirm'); }}
        onQuickReply={() => setStep('quickreply')}
      />
    ) :
    step === 'confirm' ? (
      <ConfirmScreenV1
        mode={confirmMode}
        idolSide={idolSide} setIdolSide={setIdolSide}
        checkMyReplies={checkMy} setCheckMyReplies={setCheckMy}
        selectedIdolIds={selectedIdol} toggleIdol={toggleIdol}
        onAnalyze={() => { setStep('loading'); setTimeout(() => setStep('analysis'), 1600); }}
        onEnterReplySelect={() => { setConfirmMode('reply'); }}
        onCancelReplySelect={() => { setConfirmMode('ocr'); setSelectedIdol([]); }}
        onConfirmReply={() => { setStep('quickreply'); }}
      />
    ) :
    step === 'loading' ? <LoadingScreen /> :
    step === 'analysis' ? <AnalysisScreenV1 checkMyReplies={checkMy} /> :
    step === 'quickreply' ? (
      <ReplySuggestionScreen from="confirm" tone="cute" setTone={() => {}} results onGenerate={() => {}} />
    ) : null;

  return (
    <Frame>
      {screen}
      {showCard && <CardPreviewModalV1 onDismiss={() => setShowCard(false)} />}
      {step !== 'home' && (
        <div onClick={reset} style={{
          position: 'absolute', top: 60, right: 12, zIndex: 200,
          fontSize: 11, color: 'var(--ink-mute)', background: 'rgba(255,255,255,0.85)',
          padding: '4px 10px', borderRadius: 999, cursor: 'pointer',
          border: '1px solid var(--line)',
        }}>↺ 重置</div>
      )}
    </Frame>
  );
}

// ─── Stateful reply suggestion frame ───
function ReplyFlow({ from = 'home' }) {
  const [tone, setTone] = React.useState('cute');
  const [want, setWant] = React.useState('');
  const [results, setResults] = React.useState(false);
  const [loading, setLoading] = React.useState(false);

  if (loading) return <Frame><QuickReplyLoading /></Frame>;

  return (
    <Frame>
      <ReplySuggestionScreen
        from={from}
        tone={tone} setTone={setTone}
        want={want} setWant={setWant}
        results={results}
        onGenerate={() => { setLoading(true); setTimeout(() => { setLoading(false); setResults(true); }, 1400); }}
      />
    </Frame>
  );
}

function App() {
  return (
    <DesignCanvas>
      <DCSection id="proto" title="V1 · Interactive Prototypes" subtitle="The full learn flow + quick reply flow — tap through. Focus any artboard fullscreen.">
        <DCArtboard id="learn-flow" label="★ Learn flow · tap 上传聊天截图" width={W} height={H}>
          <LearnFlowV1 />
        </DCArtboard>
        <DCArtboard id="reply-home" label="Quick reply · from Home" width={W} height={H}>
          <ReplyFlow from="home" />
        </DCArtboard>
        <DCArtboard id="reply-confirm" label="Quick reply · from Confirm" width={W} height={H}>
          <ReplyFlow from="confirm" />
        </DCArtboard>
      </DCSection>

      <DCSection id="home" title="① Home V1" subtitle="Split into 学习解析 (A) + 快速实时回复 (B) cards · privacy + recent">
        <DCArtboard id="home-v1" label="Home · two tasks" width={W} height={H}>
          <Frame><HomeScreenV1 /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="confirm" title="② OCR Confirmation V1" subtitle="Two modes: OCR-confirm (default, no checkboxes) vs Reply-select (entered via 生成回复建议)">
        <DCArtboard id="confirm-ocr-default" label="★ Mode A · OCR 确认 (default · no checkboxes)" width={W} height={H}>
          <Frame>
            <ConfirmScreenV1
              mode="ocr"
              idolSide="left" setIdolSide={() => {}}
              checkMyReplies={true} setCheckMyReplies={() => {}}
              selectedIdolIds={[]} toggleIdol={() => {}}
            />
          </Frame>
        </DCArtboard>
        <DCArtboard id="confirm-ocr-uncheck" label="Mode A · 不检查我的回复" width={W} height={H}>
          <Frame>
            <ConfirmScreenV1
              mode="ocr"
              idolSide="left" setIdolSide={() => {}}
              checkMyReplies={false} setCheckMyReplies={() => {}}
              selectedIdolIds={[]} toggleIdol={() => {}}
            />
          </Frame>
        </DCArtboard>
        <DCArtboard id="confirm-reply-empty" label="★ Mode B · 选择要回复 (no selection)" width={W} height={H}>
          <Frame>
            <ConfirmScreenV1
              mode="reply"
              idolSide="left" setIdolSide={() => {}}
              checkMyReplies={true} setCheckMyReplies={() => {}}
              selectedIdolIds={[]} toggleIdol={() => {}}
            />
          </Frame>
        </DCArtboard>
        <DCArtboard id="confirm-reply-selected" label="Mode B · 2 条已选" width={W} height={H}>
          <Frame>
            <ConfirmScreenV1
              mode="reply"
              idolSide="left" setIdolSide={() => {}}
              checkMyReplies={true} setCheckMyReplies={() => {}}
              selectedIdolIds={[3, 4]} toggleIdol={() => {}}
            />
          </Frame>
        </DCArtboard>
        <DCArtboard id="confirm-toomany" label="Too-many-bubbles warning" width={W} height={H}>
          <Frame><TooManyBubblesScreen /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="analysis" title="③ Analysis Result V1" subtitle="Adds My Reply Check + Feedback Chat at bottom">
        <DCArtboard id="analysis-v1" label="★ Analysis · with reply check + feedback" width={W} height={H}>
          <Frame><AnalysisScreenV1 checkMyReplies={true} /></Frame>
        </DCArtboard>
        <DCArtboard id="analysis-no-check" label="Analysis · no my-reply check" width={W} height={H}>
          <Frame><AnalysisScreenV1 checkMyReplies={false} /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="reply" title="④ Reply Suggestion" subtitle="Quick韩语回复 · from confirm or home · tones · 3 results">
        <DCArtboard id="reply-from-confirm" label="Reply · from Confirm (selected bubbles)" width={W} height={H}>
          <Frame>
            <ReplySuggestionScreen from="confirm" tone="cute" setTone={() => {}} />
          </Frame>
        </DCArtboard>
        <DCArtboard id="reply-from-home" label="Reply · from Home (input)" width={W} height={H}>
          <Frame>
            <ReplySuggestionScreen from="home" tone="natural" setTone={() => {}} />
          </Frame>
        </DCArtboard>
        <DCArtboard id="reply-flirty" label="Reply · 暧昧感 tone hint" width={W} height={H}>
          <Frame>
            <ReplySuggestionScreen from="confirm" tone="flirty" setTone={() => {}} />
          </Frame>
        </DCArtboard>
        <DCArtboard id="reply-results" label="★ Reply · 3 suggestions" width={W} height={H}>
          <Frame>
            <ReplySuggestionScreen from="confirm" tone="cute" setTone={() => {}} results />
          </Frame>
        </DCArtboard>
        <DCArtboard id="reply-empty" label="Reply · empty state" width={W} height={H}>
          <Frame><ReplyEmptyScreen /></Frame>
        </DCArtboard>
        <DCArtboard id="reply-loading" label="Reply · loading state" width={W} height={H}>
          <Frame><QuickReplyLoading /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="cards" title="⑤ Cards · with AI examples" subtitle="Card preview modal + library detail page · AI 例句 highlighted in lavender">
        <DCArtboard id="card-modal-vocab" label="Modal · 生词 (AI example)" width={W} height={H}>
          <Frame>
            <HomeScreenV1 />
            <CardPreviewModalV1 kind="vocab" />
          </Frame>
        </DCArtboard>
        <DCArtboard id="card-modal-grammar" label="Modal · 语法 / 词尾 (2 AI examples)" width={W} height={H}>
          <Frame>
            <HomeScreenV1 />
            <CardPreviewModalV1 kind="grammar" />
          </Frame>
        </DCArtboard>
        <DCArtboard id="card-detail-vocab" label="Library detail · 生词" width={W} height={H}>
          <Frame><LibraryDetailV1 kind="vocab" /></Frame>
        </DCArtboard>
        <DCArtboard id="card-detail-grammar" label="Library detail · 语法" width={W} height={H}>
          <Frame><LibraryDetailV1 kind="grammar" /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="kept" title="⑥ Unchanged screens (kept from MVP)" subtitle="Onboarding, Library list, Settings — same as MVP">
        <DCArtboard id="onb1" label="Onboarding 1" width={W} height={H}>
          <Frame><Onboarding1 /></Frame>
        </DCArtboard>
        <DCArtboard id="onb2" label="Onboarding 2" width={W} height={H}>
          <Frame><Onboarding2 /></Frame>
        </DCArtboard>
        <DCArtboard id="onb3" label="Onboarding 3" width={W} height={H}>
          <Frame><Onboarding3 /></Frame>
        </DCArtboard>
        <DCArtboard id="library-list" label="Library list" width={W} height={H}>
          <Frame><LibraryScreen tab="vocab" setTab={() => {}} expanded="a" setExpanded={() => {}} /></Frame>
        </DCArtboard>
        <DCArtboard id="settings" label="Settings" width={W} height={H}>
          <Frame><SettingsScreen /></Frame>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
