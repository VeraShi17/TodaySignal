/* global React, Icon, PinkBtn, OutlineBtn, GhostBtn, TonePill, AppNav, TabBar, ChatBubble, KnowledgeItem, ActionRow, AppMark, IOSDevice */

// ─────────────────────────────────────────────────────────────
// ONBOARDING (3 pages)
// ─────────────────────────────────────────────────────────────
function OnboardingPage({ index, total = 3, title, body, illo, cta }) {
  return (
    <div style={{
      height: '100%', background: 'var(--bg-page)',
      position: 'relative', display: 'flex', flexDirection: 'column',
    }}>
      {/* decorative wash */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 360,
        background: 'radial-gradient(ellipse at 30% 0%, #FFE4EC 0%, transparent 60%), radial-gradient(ellipse at 80% 20%, #EFEAFA 0%, transparent 55%)',
        pointerEvents: 'none',
      }} />
      <div style={{ paddingTop: 70, paddingBottom: 14, display: 'flex', justifyContent: 'flex-end', paddingRight: 22, position: 'relative' }}>
        <span style={{ fontSize: 14, color: 'var(--ink-mute)', fontWeight: 500 }}>跳过</span>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px', position: 'relative' }}>
        {illo}
        <div style={{
          fontSize: 26, fontWeight: 700, color: 'var(--ink)',
          textAlign: 'center', marginTop: 36, marginBottom: 14, lineHeight: 1.3,
        }}>{title}</div>
        <div style={{
          fontSize: 15, color: 'var(--ink-2)', textAlign: 'center',
          lineHeight: 1.65, maxWidth: 280,
        }}>{body}</div>
      </div>
      <div style={{ padding: '0 28px 44px', position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 24 }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{
              width: i === index ? 22 : 6, height: 6, borderRadius: 3,
              background: i === index ? 'var(--pink)' : 'var(--pink-soft)',
              transition: 'width .2s',
            }} />
          ))}
        </div>
        {cta || (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 15, color: 'var(--ink-mute)' }}>左右滑动</span>
            <div style={{
              width: 56, height: 56, borderRadius: 28, background: 'var(--pink)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
              boxShadow: '0 10px 24px -8px rgba(245,140,160,0.6)',
            }}>
              <Icon.ChevR s={22} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// Illustrations — soft bubble compositions
function IlloBubbles() {
  return (
    <div style={{ position: 'relative', width: 280, height: 200 }}>
      {/* sparkles */}
      <div style={{ position: 'absolute', top: 8, left: 36, color: 'var(--lavender)' }}><Icon.Sparkle s={18} /></div>
      <div style={{ position: 'absolute', top: 60, right: 12, color: 'var(--coral)' }}><Icon.Sparkle s={14} /></div>
      <div style={{ position: 'absolute', bottom: 20, left: 14, color: 'var(--pink)' }}><Icon.Sparkle s={12} /></div>
      {/* left bubble */}
      <div style={{
        position: 'absolute', top: 32, left: 28,
        background: '#fff', border: '1px solid var(--line)',
        borderRadius: '20px 20px 20px 6px',
        padding: '14px 18px', boxShadow: '0 8px 20px -8px rgba(60,40,50,0.12)',
        fontSize: 16, color: 'var(--ink)',
      }}>
        <span className="ko">오늘 뭐해? ㅋㅋ</span>
      </div>
      {/* right bubble */}
      <div style={{
        position: 'absolute', bottom: 18, right: 22,
        background: 'var(--pink-tint)', border: '1px solid var(--pink-soft)',
        borderRadius: '20px 20px 6px 20px',
        padding: '14px 18px', boxShadow: '0 8px 20px -8px rgba(245,140,160,0.25)',
        fontSize: 16, color: 'var(--ink)',
      }}>
        <span className="ko">나 지금 공부 중이야</span>
      </div>
      {/* signal blip */}
      <div style={{
        position: 'absolute', top: 96, left: '50%', transform: 'translateX(-50%)',
        width: 44, height: 44, borderRadius: 22,
        background: 'linear-gradient(140deg, #FFB6C7, #F58CA0)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
        boxShadow: '0 8px 22px -6px rgba(245,140,160,0.55), 0 0 0 6px rgba(245,140,160,0.1)',
      }}>
        <Icon.Sparkle s={20} />
      </div>
    </div>
  );
}

function IlloEditBubble() {
  return (
    <div style={{ position: 'relative', width: 280, height: 200 }}>
      <div style={{
        position: 'absolute', top: 30, left: 36, width: 210,
        background: '#fff', border: '1.5px dashed var(--pink)',
        borderRadius: '20px 20px 20px 6px', padding: '14px 18px',
        fontSize: 16, color: 'var(--ink)',
      }}>
        <span className="ko">오늘 뭐해? ㅋㅋ</span>
      </div>
      {/* edit icon */}
      <div style={{
        position: 'absolute', top: 22, right: 22, width: 36, height: 36, borderRadius: 18,
        background: 'var(--pink)', color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 6px 16px -4px rgba(245,140,160,0.55)',
      }}>
        <Icon.Edit s={16} />
      </div>
      {/* second bubble cleaner */}
      <div style={{
        position: 'absolute', bottom: 14, left: 60, width: 180,
        background: 'var(--pink-tint)', border: '1px solid var(--pink-soft)',
        borderRadius: '20px 20px 6px 20px', padding: '12px 16px',
        fontSize: 15, color: 'var(--ink)',
      }}>
        <span className="ko">난 지금 공부 중</span>
      </div>
      <div style={{ position: 'absolute', top: 12, left: 18, color: 'var(--lavender)' }}><Icon.Sparkle s={14} /></div>
    </div>
  );
}

function IlloCards() {
  return (
    <div style={{ position: 'relative', width: 280, height: 200 }}>
      {[
        { rot: -10, x: 20, y: 24, bg: '#fff', ko: '오늘', zh: '今天' },
        { rot: 4, x: 80, y: 18, bg: 'var(--bg-lavender)', ko: '-잖아', zh: '不是…嘛' },
        { rot: -3, x: 140, y: 40, bg: 'var(--pink-tint)', ko: '응원', zh: '应援' },
      ].map((c, i) => (
        <div key={i} style={{
          position: 'absolute', left: c.x, top: c.y, width: 120, height: 150,
          background: c.bg, border: '1px solid var(--line)', borderRadius: 18,
          padding: '14px 14px', transform: `rotate(${c.rot}deg)`,
          boxShadow: '0 14px 30px -12px rgba(60,40,50,0.18)',
          display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--pink-deep)', letterSpacing: 0.6 }}>韩 · KO</div>
            <div className="ko" style={{ fontSize: 22, fontWeight: 700, marginTop: 8 }}>{c.ko}</div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 4 }}>{c.zh}</div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11, color: 'var(--ink-mute)' }}>
            <span>example</span>
            <Icon.Bookmark s={12} />
          </div>
        </div>
      ))}
      <div style={{ position: 'absolute', top: 0, left: 2, color: 'var(--coral)' }}><Icon.Sparkle s={14} /></div>
      <div style={{ position: 'absolute', bottom: 8, right: 8, color: 'var(--lavender)' }}><Icon.Sparkle s={12} /></div>
    </div>
  );
}

function Onboarding1({ onNext }) {
  return (
    <OnboardingPage
      index={0}
      title={<>读懂韩语聊天里的<br/>小信号</>}
      body="上传 idol bubble / DM / 聊天截图，帮你看懂每句话的意思、词尾和语气。"
      illo={<IlloBubbles />}
      cta={
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 15, color: 'var(--ink-mute)' }}>1 / 3</span>
          <div onClick={onNext} style={{
            width: 56, height: 56, borderRadius: 28, background: 'var(--pink)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
            boxShadow: '0 10px 24px -8px rgba(245,140,160,0.6)', cursor: 'pointer',
          }}>
            <Icon.ChevR s={22} />
          </div>
        </div>
      }
    />
  );
}

function Onboarding2({ onNext }) {
  return (
    <OnboardingPage
      index={1}
      title={<>先确认文字，<br/>再开始解析</>}
      body="OCR 后你可以逐条修改识别出的气泡文字，避免识别错误影响解释。"
      illo={<IlloEditBubble />}
      cta={
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 15, color: 'var(--ink-mute)' }}>2 / 3</span>
          <div onClick={onNext} style={{
            width: 56, height: 56, borderRadius: 28, background: 'var(--pink)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
            boxShadow: '0 10px 24px -8px rgba(245,140,160,0.6)', cursor: 'pointer',
          }}>
            <Icon.ChevR s={22} />
          </div>
        </div>
      }
    />
  );
}

function Onboarding3({ onStart }) {
  return (
    <OnboardingPage
      index={2}
      title={<>把不认识的表达<br/>变成学习卡片</>}
      body="生词、词尾、语法点都可以保存成卡片，之后慢慢复习。"
      illo={<IlloCards />}
      cta={<PinkBtn onClick={onStart}>开始使用</PinkBtn>}
    />
  );
}

Object.assign(window, { Onboarding1, Onboarding2, Onboarding3, OnboardingPage });
