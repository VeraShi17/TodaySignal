/* global React, IOSDevice, DesignCanvas, DCSection, DCArtboard, DCPostIt */
/* Screen components from window: HomeScreen, ConfirmScreen, AnalysisScreen, CardPreviewModal,
   LibraryScreen, LibraryEmptyScreen, SettingsScreen, LoadingScreen,
   Onboarding1, Onboarding2, Onboarding3 */

const W = 390, H = 844;

function Frame({ children, dark = false }) {
  return <IOSDevice width={W} height={H} dark={dark}>{children}</IOSDevice>;
}

// ─── Interactive prototype: the full main flow in one frame ───
function InteractiveFlow() {
  const [step, setStep] = React.useState('home'); // home -> loading -> confirm -> analysis -> modal
  const [idolSide, setIdolSide] = React.useState('left');
  const [showModal, setShowModal] = React.useState(false);

  const screen =
    step === 'home' ? (
      <HomeScreen
        onUpload={() => { setStep('confirm'); }}
        onPaste={() => { setStep('confirm'); }}
      />
    ) :
    step === 'confirm' ? (
      <ConfirmScreen
        idolSide={idolSide} setIdolSide={setIdolSide}
        onAnalyze={() => {
          setStep('loading');
          setTimeout(() => setStep('analysis'), 1800);
        }}
        onBack={() => setStep('home')}
      />
    ) :
    step === 'loading' ? <LoadingScreen /> :
    step === 'analysis' ? (
      <AnalysisScreen onSaveCard={() => setShowModal(true)} onBack={() => setStep('confirm')} />
    ) : <HomeScreen />;

  return (
    <Frame>
      {screen}
      {showModal && <CardPreviewModal onDismiss={() => setShowModal(false)} />}
      {/* tiny reset hint */}
      {step !== 'home' && (
        <div onClick={() => { setStep('home'); setShowModal(false); }} style={{
          position: 'absolute', top: 60, right: 12, zIndex: 200,
          fontSize: 11, color: 'var(--ink-mute)', background: 'rgba(255,255,255,0.85)',
          padding: '4px 10px', borderRadius: 999, cursor: 'pointer',
          border: '1px solid var(--line)',
        }}>↺ 重置</div>
      )}
    </Frame>
  );
}

// ─── Onboarding wrapper with internal nav ───
function OnboardingPrototype() {
  const [page, setPage] = React.useState(0);
  return (
    <Frame>
      {page === 0 && <Onboarding1 onNext={() => setPage(1)} />}
      {page === 1 && <Onboarding2 onNext={() => setPage(2)} />}
      {page === 2 && <Onboarding3 onStart={() => setPage(0)} />}
    </Frame>
  );
}

// ─── App ───
function App() {
  const [libTab, setLibTab] = React.useState('vocab');
  const [libExpanded, setLibExpanded] = React.useState('a');
  return (
    <DesignCanvas>
      <DCSection id="proto" title="Interactive Prototype" subtitle="The full 解析 flow — click 上传聊天截图 to walk through. Focus any artboard for full size.">
        <DCArtboard id="flow" label="★ Main Flow · Tap through" width={W} height={H}>
          <InteractiveFlow />
        </DCArtboard>
        <DCArtboard id="onb" label="Onboarding · 3 pages" width={W} height={H}>
          <OnboardingPrototype />
        </DCArtboard>
      </DCSection>

      <DCSection id="onboarding" title="Onboarding" subtitle="3-screen first-run intro · soft pink wash · sparkle signal mark">
        <DCArtboard id="o1" label="01 · Read the signal" width={W} height={H}>
          <Frame><Onboarding1 /></Frame>
        </DCArtboard>
        <DCArtboard id="o2" label="02 · Confirm first" width={W} height={H}>
          <Frame><Onboarding2 /></Frame>
        </DCArtboard>
        <DCArtboard id="o3" label="03 · Save as cards" width={W} height={H}>
          <Frame><Onboarding3 /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="flow" title="Main Flow · 解析" subtitle="Home → Confirm → Loading → Analysis → Card Modal">
        <DCArtboard id="home" label="Home · Input" width={W} height={H}>
          <Frame><HomeScreen /></Frame>
        </DCArtboard>
        <DCArtboard id="confirm" label="Confirm · OCR review" width={W} height={H}>
          <Frame><ConfirmScreen idolSide="left" setIdolSide={() => {}} /></Frame>
        </DCArtboard>
        <DCArtboard id="loading" label="Loading · 解析中" width={W} height={H}>
          <Frame><LoadingScreen /></Frame>
        </DCArtboard>
        <DCArtboard id="analysis" label="★ Analysis · key screen" width={W} height={H}>
          <Frame><AnalysisScreen /></Frame>
        </DCArtboard>
        <DCArtboard id="modal" label="Card preview modal" width={W} height={H}>
          <Frame>
            <HomeScreen />
            <CardPreviewModal />
          </Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="library" title="Card Library · 卡片库" subtitle="Vocab/grammar tabs, expandable detail, empty state">
        <DCArtboard id="lib-vocab" label="Library · 生词 (expanded)" width={W} height={H}>
          <Frame>
            <LibraryScreen tab="vocab" setTab={() => {}} expanded="a" setExpanded={() => {}} />
          </Frame>
        </DCArtboard>
        <DCArtboard id="lib-grammar" label="Library · 语法 / 词尾" width={W} height={H}>
          <Frame>
            <LibraryScreen tab="grammar" setTab={() => {}} expanded={null} setExpanded={() => {}} />
          </Frame>
        </DCArtboard>
        <DCArtboard id="lib-empty" label="Library · empty state" width={W} height={H}>
          <Frame><LibraryEmptyScreen /></Frame>
        </DCArtboard>
      </DCSection>

      <DCSection id="settings" title="Settings · 设置" subtitle="Privacy-forward · local-only">
        <DCArtboard id="settings" label="Settings" width={W} height={H}>
          <Frame><SettingsScreen /></Frame>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
