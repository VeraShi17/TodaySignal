/* global React */
// components.jsx — base controls, icons, bubble, knowledge cards, tab bar

// ─── Icons (simple rounded line icons, 1.6px stroke) ───
const stroke = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.6, strokeLinecap: 'round', strokeLinejoin: 'round' };
const Icon = {
  Sparkle: ({ s = 18 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/>
    </svg>
  ),
  Camera: ({ s = 20 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M4 8a2 2 0 0 1 2-2h2l1.5-2h5L16 6h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8Z"/>
      <circle cx="12" cy="13" r="3.5"/>
    </svg>
  ),
  Paste: ({ s = 20 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <rect x="6" y="4" width="12" height="16" rx="2.5"/>
      <path d="M9 4h6M9 9h6M9 13h6M9 17h3"/>
    </svg>
  ),
  Edit: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M14.5 4.5l5 5L8 21H3v-5L14.5 4.5Z"/>
    </svg>
  ),
  Trash: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M4 7h16M10 11v6M14 11v6M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13M9 7V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v3"/>
    </svg>
  ),
  X: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M6 6l12 12M18 6L6 18"/>
    </svg>
  ),
  Check: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M4 12l5 5L20 6"/>
    </svg>
  ),
  Bubble: ({ s = 20 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H10l-4 4v-4H6a2 2 0 0 1-2-2V6Z"/>
    </svg>
  ),
  Book: ({ s = 20 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M4 5a2 2 0 0 1 2-2h6v18H6a2 2 0 0 1-2-2V5ZM12 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"/>
    </svg>
  ),
  Gear: ({ s = 20 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <circle cx="12" cy="12" r="3"/>
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1A2 2 0 1 1 4.3 17l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1A2 2 0 1 1 7 4.3l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/>
    </svg>
  ),
  ChevL: ({ s = 18 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}><path d="M15 5l-7 7 7 7"/></svg>
  ),
  ChevR: ({ s = 18 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}><path d="M9 5l7 7-7 7"/></svg>
  ),
  Refresh: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M3 12a9 9 0 0 1 15.5-6.3L21 8M21 4v4h-4M21 12a9 9 0 0 1-15.5 6.3L3 16M3 20v-4h4"/>
    </svg>
  ),
  Bookmark: ({ s = 16 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M6 4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v17l-6-4-6 4V4Z"/>
    </svg>
  ),
  Lock: ({ s = 18 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <rect x="5" y="11" width="14" height="10" rx="2"/>
      <path d="M8 11V7a4 4 0 0 1 8 0v4"/>
    </svg>
  ),
  Info: ({ s = 18 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <circle cx="12" cy="12" r="9"/>
      <path d="M12 11v6M12 7.5v.5"/>
    </svg>
  ),
  Heart: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}>
      <path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10Z"/>
    </svg>
  ),
  Plus: ({ s = 14 }) => (
    <svg width={s} height={s} viewBox="0 0 24 24" {...stroke}><path d="M12 5v14M5 12h14"/></svg>
  ),
};

// ─── Buttons ───
function PinkBtn({ children, onClick, full = true, leftIcon, size = 'lg', disabled }) {
  const heights = { lg: 56, md: 46, sm: 34 };
  const fontSize = { lg: 17, md: 15, sm: 13 };
  return (
    <button onClick={onClick} disabled={disabled} style={{
      height: heights[size], width: full ? '100%' : 'auto', padding: '0 22px',
      borderRadius: heights[size] / 2.5, border: 'none',
      background: disabled ? '#F4D7DE' : 'var(--pink)',
      color: '#fff', fontWeight: 600, fontSize: fontSize[size],
      letterSpacing: 0.1, cursor: disabled ? 'default' : 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: disabled ? 'none' : '0 6px 18px -6px rgba(245,140,160,0.55), 0 2px 4px rgba(245,140,160,0.18)',
      transition: 'transform .12s, box-shadow .12s',
    }}>
      {leftIcon}
      {children}
    </button>
  );
}
function OutlineBtn({ children, onClick, full = true, leftIcon, size = 'lg' }) {
  const heights = { lg: 56, md: 46, sm: 34 };
  const fontSize = { lg: 17, md: 15, sm: 13 };
  return (
    <button onClick={onClick} style={{
      height: heights[size], width: full ? '100%' : 'auto', padding: '0 22px',
      borderRadius: heights[size] / 2.5,
      background: '#fff', border: '1.5px solid var(--line-2)', color: 'var(--ink)',
      fontWeight: 600, fontSize: fontSize[size], cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    }}>
      {leftIcon}
      {children}
    </button>
  );
}
function GhostBtn({ children, onClick, color = 'var(--ink-mute)' }) {
  return (
    <button onClick={onClick} style={{
      background: 'transparent', border: 'none', color, padding: '8px 4px',
      fontSize: 14, fontWeight: 500, cursor: 'pointer',
    }}>{children}</button>
  );
}

// ─── Pills ───
function TonePill({ children, kind = 'pink' }) {
  const map = {
    pink:    { bg: '#FCEAEF', fg: '#C04D6A' },
    coral:   { bg: '#FFEFE7', fg: '#C8633F' },
    lavender:{ bg: '#EFEAFA', fg: '#7860B3' },
    mint:    { bg: '#E2F4EA', fg: '#3F8F66' },
    cream:   { bg: '#FBEFD8', fg: '#A77839' },
    gray:    { bg: '#F1ECEE', fg: '#776975' },
  }[kind];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center',
      padding: '4px 11px', borderRadius: 999,
      background: map.bg, color: map.fg, fontSize: 12, fontWeight: 600, letterSpacing: 0.1,
    }}>{children}</span>
  );
}

// ─── App-level chrome ───
function AppNav({ title, back, trailing, dark }) {
  return (
    <div style={{
      paddingTop: 54, paddingBottom: 8, position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 44,
    }}>
      {back && (
        <div style={{ position: 'absolute', left: 16, display: 'flex', alignItems: 'center', color: 'var(--pink)', fontSize: 15, fontWeight: 500 }}>
          <Icon.ChevL s={20} /><span style={{ marginLeft: -2 }}>{back}</span>
        </div>
      )}
      <div style={{ fontSize: 16, fontWeight: 600, color: 'var(--ink)' }}>{title}</div>
      {trailing && (<div style={{ position: 'absolute', right: 16, color: 'var(--ink-mute)' }}>{trailing}</div>)}
    </div>
  );
}

function TabBar({ active = '解析' }) {
  const items = [
    { key: '解析', icon: <Icon.Sparkle s={22} /> },
    { key: '卡片库', icon: <Icon.Book s={22} /> },
    { key: '设置', icon: <Icon.Gear s={22} /> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 30, paddingTop: 10,
      background: 'rgba(255,250,247,0.92)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid var(--line)',
      display: 'flex', justifyContent: 'space-around',
      zIndex: 30,
    }}>
      {items.map(i => {
        const on = i.key === active;
        return (
          <div key={i.key} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            color: on ? 'var(--pink)' : 'var(--ink-faint)',
          }}>
            {i.icon}
            <span style={{ fontSize: 10.5, fontWeight: on ? 600 : 500 }}>{i.key}</span>
          </div>
        );
      })}
    </div>
  );
}

// ─── Chat bubble ───
function ChatBubble({ side = 'left', text, image, idolSide, editable, badge }) {
  const isIdol = side === idolSide;
  const isLeft = side === 'left';
  const fill =
    isLeft ? '#FFFFFF' : 'var(--pink-tint)';
  const border = isIdol ? '1.5px solid var(--pink)' : '1px solid var(--line)';
  return (
    <div style={{ display: 'flex', justifyContent: isLeft ? 'flex-start' : 'flex-end', marginBottom: 10 }}>
      <div style={{ maxWidth: '78%', position: 'relative' }}>
        {isIdol && (
          <div style={{ fontSize: 10, fontWeight: 600, color: 'var(--pink)', marginBottom: 4, marginLeft: 4, letterSpacing: 0.4 }}>
            IDOL · 对方
          </div>
        )}
        <div style={{
          background: fill, border, borderRadius: 18,
          padding: image ? 0 : '10px 14px',
          fontSize: 15, lineHeight: 1.45, color: 'var(--ink)',
          borderTopLeftRadius: isLeft ? 6 : 18,
          borderTopRightRadius: isLeft ? 18 : 6,
          boxShadow: '0 1px 1px rgba(60,40,50,0.04)',
        }}>
          {image
            ? (
              <div style={{ width: 140, height: 110, borderRadius: 16, background: 'linear-gradient(135deg, #FBEAE0, #F8D9D0)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#B58474', fontSize: 13, fontWeight: 500 }}>
                [图片]
              </div>
            )
            : <span className="ko">{text}</span>
          }
        </div>
        {editable && (
          <div style={{
            position: 'absolute', top: isIdol ? 18 : -6, right: isLeft ? -28 : 'auto', left: isLeft ? 'auto' : -28,
            display: 'flex', flexDirection: 'column', gap: 6,
          }}>
            <div style={{ width: 22, height: 22, borderRadius: 11, background: '#fff', border: '1px solid var(--line)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-mute)' }}>
              <Icon.Edit s={11} />
            </div>
            <div style={{ width: 22, height: 22, borderRadius: 11, background: '#fff', border: '1px solid var(--line)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-mute)' }}>
              <Icon.X s={11} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Knowledge point item (vocab + grammar share base) ───
function KnowledgeItem({ kind = 'vocab', children, state = 'open' }) {
  // state: 'open' | 'known' | 'saved' | 'dismissed'
  const accent = kind === 'vocab' ? 'var(--lavender)' : 'var(--coral)';
  const accentBg = kind === 'vocab' ? '#F4EEFC' : '#FFEEE6';
  const labelText = kind === 'vocab' ? '生词' : '语法 / 词尾';
  const stateBadge =
    state === 'known' ? <TonePill kind="mint">✓ 已标记认识</TonePill> :
    state === 'saved' ? <TonePill kind="pink">★ 已生成卡片</TonePill> :
    null;
  return (
    <div style={{
      background: '#fff', border: `1px solid ${state === 'saved' ? 'var(--pink-soft)' : 'var(--line)'}`,
      borderRadius: 18, padding: '14px 16px 14px',
      opacity: state === 'dismissed' ? 0.5 : 1,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        <span style={{
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.4,
          padding: '3px 8px', borderRadius: 999,
          background: accentBg, color: accent === 'var(--lavender)' ? '#7860B3' : '#C8633F',
        }}>{labelText}</span>
        {stateBadge}
      </div>
      {children}
    </div>
  );
}

function ActionRow({ state, onKnow, onSkip, onSave }) {
  if (state === 'known') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12 }}>
        <span style={{ fontSize: 13, color: 'var(--mint)', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Icon.Check s={14} /> 已认识
        </span>
        <span style={{ flex: 1 }} />
        <GhostBtn>撤销</GhostBtn>
      </div>
    );
  }
  if (state === 'saved') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12 }}>
        <span style={{ fontSize: 13, color: 'var(--pink-deep)', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Icon.Bookmark s={13} /> 已保存到卡片库
        </span>
        <span style={{ flex: 1 }} />
        <GhostBtn>查看</GhostBtn>
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12 }}>
      <button onClick={onKnow} style={{
        height: 32, padding: '0 12px', borderRadius: 16,
        background: '#F4ECEF', border: 'none', color: 'var(--ink-2)',
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', gap: 4,
      }}>
        <Icon.Check s={13} /> 认识
      </button>
      <button onClick={onSkip} style={{
        height: 32, padding: '0 10px', borderRadius: 16,
        background: 'transparent', border: 'none', color: 'var(--ink-mute)',
        fontSize: 13, cursor: 'pointer',
      }}>
        不认识
      </button>
      <span style={{ flex: 1 }} />
      <button onClick={onSave} style={{
        height: 32, padding: '0 14px', borderRadius: 16,
        background: 'var(--pink)', border: 'none', color: '#fff',
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', gap: 4,
        boxShadow: '0 4px 10px -3px rgba(245,140,160,0.55)',
      }}>
        <Icon.Plus s={13} /> 生成卡片
      </button>
    </div>
  );
}

// Wordmark — sparkle in a soft pink rounded square
function AppMark({ size = 56 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.32,
      background: 'linear-gradient(140deg, #FFB6C7 0%, #F58CA0 60%, #E97089 100%)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff',
      boxShadow: '0 12px 30px -10px rgba(245,140,160,0.6), inset 0 1px 0 rgba(255,255,255,0.6)',
      position: 'relative',
    }}>
      <Icon.Sparkle s={size * 0.45} />
    </div>
  );
}

Object.assign(window, {
  Icon, PinkBtn, OutlineBtn, GhostBtn, TonePill,
  AppNav, TabBar, ChatBubble, KnowledgeItem, ActionRow, AppMark,
});
