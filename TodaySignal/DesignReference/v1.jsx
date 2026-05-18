/* global React, Icon, PinkBtn, OutlineBtn, GhostBtn, TonePill, AppNav, TabBar, ChatBubble, KnowledgeItem, ActionRow, AppMark,
   HomeScreen, ConfirmScreen, AnalysisScreen, CardPreviewModal, LibraryScreen, SettingsScreen, LoadingScreen */

/* ─────────────────────────────────────────────────────────────
   V1 — incremental updates on top of MVP
   New: Reply Suggestion · Feedback Chat · My Reply Check ·
        Selectable idol bubbles · AI example sentences in cards ·
        Too-many-bubbles warning
   ───────────────────────────────────────────────────────────── */

// ─── Small primitives ────────────────────────────────────────
function Checkbox({ checked, onChange, label, sublabel, kind = 'default' }) {
  return (
    <label onClick={() => onChange?.(!checked)} style={{
      display: 'inline-flex', alignItems: 'center', gap: 10, cursor: 'pointer',
    }}>
      <span style={{
        width: 20, height: 20, borderRadius: 6,
        border: checked ? '1.5px solid var(--pink)' : '1.5px solid var(--line-2)',
        background: checked ? 'var(--pink)' : '#fff',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', transition: 'all .15s', flexShrink: 0,
      }}>
        {checked && <Icon.Check s={13} />}
      </span>
      <span>
        <span style={{ fontSize: 13.5, color: 'var(--ink)', fontWeight: 500 }}>{label}</span>
        {sublabel && <span style={{ display: 'block', fontSize: 11.5, color: 'var(--ink-mute)', marginTop: 1 }}>{sublabel}</span>}
      </span>
    </label>
  );
}

function CopyBtn({ size = 'sm', copied }) {
  return (
    <button style={{
      height: size === 'sm' ? 28 : 32,
      padding: '0 12px', borderRadius: 14,
      background: copied ? 'var(--bg-mint)' : '#FFF',
      border: `1px solid ${copied ? 'var(--mint-soft)' : 'var(--line-2)'}`,
      color: copied ? '#3F8F66' : 'var(--ink-2)',
      fontSize: 12, fontWeight: 600, cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 4,
    }}>
      {copied ? <Icon.Check s={12} /> : <CopyIcon />}
      {copied ? '已复制' : '复制'}
    </button>
  );
}
function CopyIcon({ s = 12 }) {
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <rect x="8" y="8" width="13" height="13" rx="2"/>
      <path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>
    </svg>
  );
}

// Tone chips for reply generation (selectable)
function ToneChip({ label, hint, icon, selected, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '8px 14px 8px 12px', borderRadius: 999,
      background: selected ? 'var(--pink)' : '#fff',
      border: `1.5px solid ${selected ? 'var(--pink)' : 'var(--line-2)'}`,
      color: selected ? '#fff' : 'var(--ink-2)',
      fontSize: 13, fontWeight: 600, cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      boxShadow: selected ? '0 4px 10px -3px rgba(245,140,160,0.45)' : 'none',
      transition: 'all .12s',
    }}>
      {icon && <span style={{ fontSize: 14 }}>{icon}</span>}
      {label}
      {hint && <span style={{ fontSize: 10.5, fontWeight: 500, opacity: 0.7 }}>· {hint}</span>}
    </button>
  );
}

// Chat bubble — V1 variant with two modes:
//   mode='ocr-edit'    → no checkbox; floating circular edit/删除 buttons on outer side
//   mode='reply-select'→ checkbox on idol bubbles only; user bubbles dim as context
function SelectableBubble({ side = 'left', text, idolSide, selected, onToggle, image, mode = 'ocr-edit' }) {
  const isIdol = side === idolSide;
  const isLeft = side === 'left';
  const isSelectMode = mode === 'reply-select';
  const isContext = isSelectMode && !isIdol; // user bubbles in reply-select = context only

  const fill = isLeft ? '#FFFFFF' : 'var(--pink-tint)';
  const border = (isSelectMode && selected)
    ? '1.5px solid var(--pink)'
    : (isIdol ? '1.5px solid var(--pink-soft)' : '1px solid var(--line)');

  return (
    <div style={{ display: 'flex', justifyContent: isLeft ? 'flex-start' : 'flex-end', marginBottom: 14, opacity: isContext ? 0.55 : 1 }}>
      <div style={{ maxWidth: '78%', position: 'relative', display: 'flex', alignItems: 'flex-start', gap: 6 }}>
        {/* checkbox on left side of idol bubbles — only in reply-select mode */}
        {isIdol && isSelectMode && (
          <div onClick={onToggle} style={{
            width: 22, height: 22, borderRadius: 7, marginTop: 18,
            background: selected ? 'var(--pink)' : '#fff',
            border: `1.5px solid ${selected ? 'var(--pink)' : 'var(--line-2)'}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', cursor: 'pointer', flexShrink: 0,
            boxShadow: selected ? '0 2px 6px rgba(245,140,160,0.4)' : 'none',
          }}>
            {selected && <Icon.Check s={13} />}
          </div>
        )}
        <div style={{ position: 'relative' }}>
          {isIdol && (
            <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--pink)', marginBottom: 4, marginLeft: 4, letterSpacing: 0.4 }}>
              IDOL · 对方
            </div>
          )}
          <div
            onClick={isIdol && isSelectMode ? onToggle : undefined}
            style={{
              background: fill, border, borderRadius: 18,
              padding: image ? 0 : '10px 14px',
              cursor: isIdol && isSelectMode ? 'pointer' : 'default',
              fontSize: 15, lineHeight: 1.45, color: 'var(--ink)',
              borderTopLeftRadius: isLeft ? 6 : 18,
              borderTopRightRadius: isLeft ? 18 : 6,
              boxShadow: (isSelectMode && selected) ? '0 6px 18px -8px rgba(245,140,160,0.4)' : '0 1px 1px rgba(60,40,50,0.04)',
              transition: 'all .12s',
            }}>
            {image
              ? <div style={{ width: 140, height: 110, borderRadius: 16, background: 'linear-gradient(135deg, #FBEAE0, #F8D9D0)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#B58474', fontSize: 13, fontWeight: 500 }}>[图片]</div>
              : <span className="ko">{text}</span>}
          </div>
          {/* floating circular edit / 删除 buttons — only in ocr-edit mode */}
          {!isSelectMode && (
            <div style={{
              position: 'absolute',
              top: isIdol ? 18 : -6,
              right: isLeft ? -32 : 'auto',
              left: isLeft ? 'auto' : -32,
              display: 'flex', flexDirection: 'column', gap: 6,
            }}>
              <div style={{
                width: 26, height: 26, borderRadius: 13, background: '#fff',
                border: '1px solid var(--line-2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--ink-mute)', cursor: 'pointer',
                boxShadow: '0 1px 2px rgba(60,40,50,0.05)',
              }}>
                <Icon.Edit s={12} />
              </div>
              <div style={{
                width: 26, height: 26, borderRadius: 13, background: '#fff',
                border: '1px solid var(--line-2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--ink-mute)', cursor: 'pointer',
                boxShadow: '0 1px 2px rgba(60,40,50,0.05)',
              }}>
                <Icon.X s={12} />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Hint card shown at end of bubble list in OCR-edit mode ───
function BubbleEditHint() {
  return (
    <div style={{
      marginTop: 18, padding: '14px 16px',
      border: '1.5px dashed var(--pink-soft)', borderRadius: 16,
      background: 'rgba(255,250,247,0.6)',
    }}>
      <div style={{ fontSize: 13, lineHeight: 1.5, marginBottom: 10 }}>
        <span style={{ color: 'var(--ink-mute)' }}>气泡识别不太准确？</span>
        <span style={{ color: 'var(--pink-deep)', fontWeight: 600, marginLeft: 6 }}>你可以逐条编辑后再继续</span>
      </div>
      <button style={{
        display: 'inline-flex', alignItems: 'center', gap: 8,
        background: 'transparent', border: 'none', padding: 0,
        color: 'var(--pink-deep)', fontSize: 14, fontWeight: 600, cursor: 'pointer',
      }}>
        <span style={{
          width: 22, height: 22, borderRadius: 11,
          border: '1.5px solid var(--pink)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--pink)',
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>
        </span>
        手动插入一条消息
      </button>
      <div style={{ fontSize: 11.5, color: 'var(--ink-faint)', marginTop: 10, lineHeight: 1.5 }}>
        当前版本中气泡顺序不参与 AI 解析；手动插入默认追加到底部。
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. HOME V1 — split into two cards
// ─────────────────────────────────────────────────────────────
function HomeScreenV1({ onLearn, onQuickReply }) {
  return (
    <div style={{ position: 'relative', height: '100%', background: 'var(--bg-page)' }}>
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 320,
        background: 'radial-gradient(ellipse at 20% 0%, #FFE4EC 0%, transparent 55%), radial-gradient(ellipse at 90% 10%, #EFEAFA 0%, transparent 50%)',
        pointerEvents: 'none',
      }} />
      <div style={{ position: 'relative', padding: '64px 22px 0', height: '100%', overflowY: 'auto', paddingBottom: 110 }}>
        {/* header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <AppMark size={36} />
            <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--ink-mute)', letterSpacing: 0.4 }}>TODAY'S SIGNAL</div>
          </div>
          <div style={{ width: 36, height: 36, borderRadius: 18, background: '#fff', border: '1px solid var(--line)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-mute)' }}>
            <Icon.Gear s={18} />
          </div>
        </div>
        <div className="ko" style={{ fontSize: 32, fontWeight: 700, color: 'var(--ink)', letterSpacing: -0.5, lineHeight: 1.1 }}>오늘의 시그널</div>
        <div style={{ fontSize: 14, color: 'var(--ink-2)', marginTop: 6, fontWeight: 500 }}>韩语聊天截图学习助手</div>

        {/* Task A: Learning */}
        <div style={{
          marginTop: 22, background: '#fff', borderRadius: 24, padding: 20,
          border: '1px solid var(--line)',
          boxShadow: '0 18px 40px -22px rgba(60,40,50,0.16)',
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--pink)' }} />
                <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--pink-deep)', letterSpacing: 0.6 }}>A · 学习解析</span>
              </div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink)', marginTop: 6 }}>读懂 idol 在说什么</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 4, lineHeight: 1.5 }}>
                上传聊天截图，看翻译、生词、语气和语法。
              </div>
            </div>
            <div style={{
              width: 44, height: 44, borderRadius: 14, background: 'var(--pink-tint)',
              color: 'var(--pink-deep)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <Icon.Sparkle s={20} />
            </div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <PinkBtn onClick={onLearn} leftIcon={<Icon.Camera s={20} />} size="md">上传聊天截图</PinkBtn>
            <OutlineBtn leftIcon={<Icon.Paste s={18} />} size="md">粘贴韩语文本</OutlineBtn>
          </div>
        </div>

        {/* Task B: Quick reply */}
        <div style={{
          marginTop: 14, background: 'linear-gradient(140deg, #FFFFFF 0%, var(--bg-lavender) 130%)',
          borderRadius: 24, padding: 20,
          border: '1px solid var(--lavender-soft)',
          boxShadow: '0 18px 40px -22px rgba(120,96,179,0.18)',
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ width: 6, height: 6, borderRadius: 3, background: '#7860B3' }} />
                <span style={{ fontSize: 11, fontWeight: 700, color: '#7860B3', letterSpacing: 0.6 }}>B · 快速实时回复</span>
              </div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink)', marginTop: 6 }}>想马上回一句韩语？</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 4, lineHeight: 1.5 }}>
                输入内容或上传截图，生成自然回复。
              </div>
            </div>
            <div style={{
              width: 44, height: 44, borderRadius: 14, background: '#fff',
              color: '#7860B3', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              border: '1px solid var(--lavender-soft)',
            }}>
              <Icon.Bubble s={20} />
            </div>
          </div>
          <button onClick={onQuickReply} style={{
            width: '100%', height: 46, borderRadius: 18, border: 'none',
            background: '#7860B3', color: '#fff',
            fontWeight: 600, fontSize: 15, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            boxShadow: '0 8px 20px -6px rgba(120,96,179,0.5)',
          }}>
            <Icon.Sparkle s={18} />快速实时回复
          </button>
        </div>

        {/* privacy note */}
        <div style={{
          marginTop: 18, padding: '10px 12px',
          background: 'rgba(255,255,255,0.6)', borderRadius: 12,
          display: 'flex', alignItems: 'center', gap: 8,
          border: '1px solid var(--line)',
        }}>
          <Icon.Lock s={14} />
          <div style={{ fontSize: 11.5, color: 'var(--ink-mute)', lineHeight: 1.45 }}>
            原始截图不会长期保存。
          </div>
        </div>

        {/* recent (compact) */}
        <div style={{ marginTop: 22, marginBottom: 12, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: 0.4 }}>最近</div>
          <span style={{ fontSize: 11.5, color: 'var(--ink-mute)' }}>本机 · 3 条</span>
        </div>
        {[
          { tag: '亲近随意', preview: '오늘 뭐해? ㅋㅋ', meta: '今天 · 学习解析 · 3 张卡片', tagKind: 'pink' },
          { tag: '回复', preview: '오늘도 수고했어요!', meta: '今天 · 回复建议', tagKind: 'lavender' },
          { tag: '可爱 / 撒娇', preview: '나 보고 싶었어?', meta: '昨天 · 2 张卡片', tagKind: 'coral' },
        ].map((r, i) => (
          <div key={i} style={{
            background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
            padding: '10px 12px', marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 30, height: 30, borderRadius: 9, background: r.tagKind === 'lavender' ? 'var(--bg-lavender)' : 'var(--pink-tint)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: r.tagKind === 'lavender' ? '#7860B3' : 'var(--pink-deep)',
            }}>
              <Icon.Bubble s={15} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="ko" style={{ fontSize: 13.5, fontWeight: 500, color: 'var(--ink)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.preview}</div>
              <div style={{ fontSize: 11, color: 'var(--ink-mute)', marginTop: 1 }}>{r.meta}</div>
            </div>
            <TonePill kind={r.tagKind}>{r.tag}</TonePill>
          </div>
        ))}
      </div>
      <TabBar active="解析" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. CONFIRM V1 — two modes:
//    mode='ocr'   → default. confirm OCR text. no checkboxes. edit/删除 per bubble.
//                   Learn analysis settings (incl. "同时检查我的回复") grouped together.
//    mode='reply' → entered by tapping 生成回复建议. checkboxes on idol bubbles only.
// ─────────────────────────────────────────────────────────────
function ConfirmScreenV1({
  idolSide = 'left', setIdolSide,
  checkMyReplies, setCheckMyReplies,
  selectedIdolIds, toggleIdol,
  onAnalyze, onEnterReplySelect, onCancelReplySelect, onConfirmReply,
  mode = 'ocr',
}) {
  const bubbles = [
    { id: 1, side: 'left',  text: '오늘 뭐해? ㅋㅋ' },
    { id: 2, side: 'right', text: '나 지금 공부 중이야' },
    { id: 3, side: 'left',  text: '오늘 너무 추웠어 ㅠㅠ' },
    { id: 4, side: 'left',  text: '다들 뭐해?' },
    { id: 5, side: 'right', text: '나는 너를 많이 좋아해요' },
  ];
  const userBubbles = bubbles.filter(b => b.side !== idolSide).length > 0;
  const selectedCount = selectedIdolIds?.length || 0;
  const isReply = mode === 'reply';

  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav
        title={isReply ? '选择要回复的消息' : '确认聊天内容'}
        back={isReply ? '取消' : '返回'}
      />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 22px 320px' }}>
        {/* mode-specific top hint */}
        {isReply ? (
          <div style={{
            background: 'var(--bg-lavender)', borderRadius: 14, padding: '10px 12px',
            fontSize: 12.5, color: '#5E4C8A', lineHeight: 1.5, marginBottom: 14,
            display: 'flex', gap: 10, alignItems: 'flex-start',
          }}>
            <div style={{ marginTop: 1, color: '#7860B3' }}><Icon.Bubble s={14} /></div>
            <div>
              <div style={{ fontWeight: 600, marginBottom: 2 }}>选择你想回复的 IDOL 消息</div>
              <div style={{ color: '#7C6BA0' }}>可选 1 条或多条，AI 会结合上下文生成回复建议。</div>
            </div>
          </div>
        ) : (
          <div style={{
            background: 'var(--bg-soft)', borderRadius: 14, padding: '10px 12px',
            fontSize: 12.5, color: '#7A4A55', lineHeight: 1.5, marginBottom: 14,
            display: 'flex', gap: 10, alignItems: 'flex-start',
          }}>
            <div style={{ marginTop: 1, color: 'var(--pink-deep)' }}><Icon.Info s={14} /></div>
            <div>
              <div style={{ fontWeight: 600, marginBottom: 2 }}>确认 OCR 文字是否正确</div>
              <div style={{ color: '#9A6F7A' }}>学习解析会分析所有对方气泡 · 点击下方按钮编辑或删除单条。</div>
            </div>
          </div>
        )}

        <div style={{ padding: '0 4px' }}>
          {bubbles.map(b => (
            <SelectableBubble
              key={b.id} side={b.side} idolSide={idolSide} text={b.text}
              mode={isReply ? 'reply-select' : 'ocr-edit'}
              selected={selectedIdolIds?.includes(b.id)}
              onToggle={() => toggleIdol?.(b.id)}
            />
          ))}
          {!isReply && <BubbleEditHint />}
        </div>
      </div>

      {/* ─── bottom sheet — varies by mode ─── */}
      {isReply ? (
        <ReplySelectBottomBar
          selectedCount={selectedCount}
          onCancel={onCancelReplySelect}
          onConfirm={onConfirmReply}
        />
      ) : (
        <OcrConfirmBottomBar
          idolSide={idolSide} setIdolSide={setIdolSide}
          checkMyReplies={checkMyReplies} setCheckMyReplies={setCheckMyReplies}
          showCheckMy={userBubbles}
          onAnalyze={onAnalyze}
          onEnterReplySelect={onEnterReplySelect}
        />
      )}
    </div>
  );
}

// ─── Bottom bar A: OCR confirm mode ───
function OcrConfirmBottomBar({ idolSide, setIdolSide, checkMyReplies, setCheckMyReplies, showCheckMy, onAnalyze, onEnterReplySelect }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      padding: '14px 22px 26px',
      background: 'rgba(255,250,247,0.97)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid var(--line)',
    }}>
      {/* side selector */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <span style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: 0.4 }}>IDOL / 对方在</span>
        <div style={{ display: 'flex', gap: 2, padding: 3, background: '#F2EAEC', borderRadius: 12 }}>
          {['left', 'right'].map(s => {
            const on = s === idolSide;
            return (
              <div key={s} onClick={() => setIdolSide?.(s)} style={{
                height: 28, padding: '0 14px', borderRadius: 9,
                background: on ? '#fff' : 'transparent',
                boxShadow: on ? '0 1px 4px rgba(60,40,50,0.08)' : 'none',
                display: 'flex', alignItems: 'center', gap: 4,
                color: on ? 'var(--pink-deep)' : 'var(--ink-mute)', fontWeight: 600, fontSize: 12.5,
                cursor: 'pointer',
              }}>
                {s === 'left' ? '左侧' : '右侧'}
              </div>
            );
          })}
        </div>
      </div>

      {/* Learn analysis settings group */}
      <div style={{
        background: 'var(--bg-elev)', border: '1px solid var(--line)',
        borderRadius: 14, padding: '10px 12px', marginBottom: 10,
      }}>
        <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: showCheckMy ? 8 : 0 }}>
          学习解析设置
        </div>
        {showCheckMy && (
          <Checkbox
            checked={checkMyReplies}
            onChange={setCheckMyReplies}
            label="同时检查我的回复"
            sublabel="检查你已发出的韩语是否自然"
          />
        )}
      </div>

      {/* Primary: 学习解析 */}
      <PinkBtn onClick={onAnalyze} leftIcon={<Icon.Sparkle s={18} />} size="md">学习解析</PinkBtn>

      {/* Secondary: 生成回复建议 (separate intent) */}
      <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
        <div>
          <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--ink)' }}>想回复对方？</div>
          <div style={{ fontSize: 11, color: 'var(--ink-mute)', marginTop: 1 }}>选择消息 · AI 生成韩语回复</div>
        </div>
        <button onClick={onEnterReplySelect} style={{
          height: 38, padding: '0 14px', borderRadius: 12, border: '1.5px solid var(--lavender-soft)',
          background: '#fff', color: '#7860B3',
          fontWeight: 600, fontSize: 13, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 6, flexShrink: 0,
        }}>
          <Icon.Bubble s={14} />生成回复建议
        </button>
      </div>
    </div>
  );
}

// ─── Bottom bar B: reply-selection mode ───
function ReplySelectBottomBar({ selectedCount, onCancel, onConfirm }) {
  const has = selectedCount > 0;
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      padding: '14px 22px 26px',
      background: 'rgba(248,245,255,0.97)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: '0.5px solid var(--lavender-soft)',
    }}>
      <div style={{ textAlign: 'center', marginBottom: 12, minHeight: 18 }}>
        {has ? (
          <span style={{ fontSize: 13, fontWeight: 600, color: '#7860B3' }}>
            ✓ 已选 {selectedCount} 条 IDOL 消息
          </span>
        ) : (
          <span style={{ fontSize: 12, color: 'var(--ink-mute)' }}>
            点击 IDOL 气泡选择 · 至少选 1 条
          </span>
        )}
      </div>
      <div style={{ display: 'flex', gap: 10 }}>
        <button onClick={onCancel} style={{
          flex: 0.8, height: 46, borderRadius: 18,
          background: '#fff', border: '1.5px solid var(--line-2)',
          color: 'var(--ink-2)', fontSize: 14, fontWeight: 600, cursor: 'pointer',
        }}>取消</button>
        <button onClick={onConfirm} disabled={!has} style={{
          flex: 1.6, height: 46, borderRadius: 18, border: 'none',
          background: has ? '#7860B3' : '#E5DFEE',
          color: '#fff', fontWeight: 600, fontSize: 14,
          cursor: has ? 'pointer' : 'default',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          boxShadow: has ? '0 6px 16px -4px rgba(120,96,179,0.45)' : 'none',
        }}>
          <Icon.Sparkle s={14} />确认生成回复
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. ANALYSIS V1 — adds My Reply Check + Feedback Chat
// ─────────────────────────────────────────────────────────────
function MyReplyCheckCard({ original, status, body, suggestion, suggestionZh }) {
  const natural = status === 'natural';
  return (
    <div style={{
      background: '#fff', border: `1px solid ${natural ? 'var(--mint-soft)' : 'var(--pink-soft)'}`, borderRadius: 18,
      padding: 14, marginBottom: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
        <span style={{
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.4,
          padding: '3px 9px', borderRadius: 999,
          background: 'var(--bg-mint)', color: '#3F8F66',
        }}>我的回复</span>
        <TonePill kind={natural ? 'mint' : 'cream'}>
          {natural ? '✓ 表达自然' : '可以更自然一点'}
        </TonePill>
      </div>
      <div style={{
        background: 'var(--bg-elev)', border: '1px solid var(--line)',
        borderRadius: 14, padding: '10px 14px',
      }}>
        <span className="ko" style={{ fontSize: 15, color: 'var(--ink)' }}>{original}</span>
      </div>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 10, lineHeight: 1.55 }}>{body}</div>
      {!natural && (
        <div style={{
          marginTop: 12, padding: 12, borderRadius: 14, background: 'var(--bg-mint)',
          border: '1px dashed var(--mint-soft)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 10.5, fontWeight: 700, color: '#3F8F66', letterSpacing: 0.5 }}>更自然的说法</span>
            <CopyBtn />
          </div>
          <div className="ko" style={{ fontSize: 15.5, fontWeight: 600, color: 'var(--ink)' }}>{suggestion}</div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 2 }}>{suggestionZh}</div>
        </div>
      )}
    </div>
  );
}

function FeedbackChatBlock({ onSend }) {
  const [value, setValue] = React.useState('');
  return (
    <div style={{
      background: 'linear-gradient(140deg, #FFFFFF, var(--bg-lavender) 200%)',
      border: '1px solid var(--lavender-soft)',
      borderRadius: 22, padding: 16, marginTop: 8,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <span style={{
          width: 28, height: 28, borderRadius: 9, background: '#fff', color: '#7860B3',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon.Sparkle s={16} /></span>
        <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--ink)' }}>还有哪里不懂？</div>
      </div>
      <div style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginBottom: 12, marginLeft: 36 }}>
        关于这次聊天的追问 · 答案不会保存为卡片
      </div>

      {/* quick chips */}
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
        {['这里为什么这么说？', '这几条要连起来看吗？', '这个语气自然吗？'].map(c => (
          <button key={c} onClick={() => setValue(c)} style={{
            padding: '7px 12px', borderRadius: 999, background: '#fff',
            border: '1px solid var(--lavender-soft)', color: '#7860B3',
            fontSize: 12, fontWeight: 500, cursor: 'pointer',
          }}>{c}</button>
        ))}
      </div>

      {/* input */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        background: '#fff', borderRadius: 16,
        border: '1px solid var(--lavender-soft)',
        padding: '4px 4px 4px 14px',
      }}>
        <input
          value={value} onChange={e => setValue(e.target.value)}
          placeholder="例如：这里为什么用 -는데？"
          style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontSize: 14, color: 'var(--ink)', height: 36, fontFamily: 'inherit',
          }}
        />
        <button onClick={() => onSend?.(value)} style={{
          height: 36, padding: '0 14px', borderRadius: 12, border: 'none',
          background: value ? '#7860B3' : '#E5DFEE',
          color: '#fff', fontSize: 13, fontWeight: 600,
          cursor: value ? 'pointer' : 'default',
        }}>发送</button>
      </div>
    </div>
  );
}

// Followup conversation example (showing one Q + A so the user knows what it looks like)
function FeedbackConversation() {
  return (
    <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 10 }}>
      {/* user q */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{
          background: '#7860B3', color: '#fff', borderRadius: 18, borderTopRightRadius: 6,
          padding: '10px 14px', fontSize: 14, maxWidth: '80%',
        }}>这里为什么用 -잖아？</div>
      </div>
      {/* AI a */}
      <div style={{ display: 'flex', justifyContent: 'flex-start', gap: 8 }}>
        <div style={{
          width: 26, height: 26, borderRadius: 8, background: 'var(--bg-lavender)',
          color: '#7860B3', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}><Icon.Sparkle s={13} /></div>
        <div style={{
          background: '#fff', border: '1px solid var(--lavender-soft)',
          borderRadius: 18, borderTopLeftRadius: 6,
          padding: '10px 14px', fontSize: 13.5, color: 'var(--ink-2)',
          maxWidth: '85%', lineHeight: 1.55,
        }}>
          <span className="ko" style={{ color: 'var(--ink)' }}>-잖아</span> 用来提醒对方"你也知道的"，<br/>
          带一点撒娇 / 强调感。这里 idol 用它，是因为想让你认同"真的很可爱"。
        </div>
      </div>
    </div>
  );
}

function AnalysisScreenV1({ checkMyReplies = true }) {
  const [states, setStates] = React.useState({ v1: 'saved', g1: 'open' });
  const set = (k, v) => setStates(s => ({ ...s, [k]: v }));

  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="解析结果" back="返回" trailing={<span style={{ fontSize: 14, color: 'var(--pink)' }}>完成</span>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 18px 110px' }}>
        {/* top note */}
        <div style={{
          background: 'var(--bg-lavender)', borderRadius: 14, padding: '10px 14px',
          fontSize: 12.5, color: '#5E4C8A', lineHeight: 1.5, marginBottom: 16,
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <Icon.Sparkle s={14} />
          <span>默认从对方气泡提取学习点。选择要生成卡片的内容。</span>
        </div>

        {/* ── idol bubble + analysis ── */}
        <div style={{
          background: 'var(--bg-elev)', borderRadius: 22, padding: 14,
          border: '1px solid var(--line)', marginBottom: 16,
        }}>
          <ChatBubble side="left" idolSide="left" text="이거 봤어? 너무 귀엽잖아ㅋㅋ" />
          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 4 }}>中文翻译</div>
            <div style={{ fontSize: 15, color: 'var(--ink)' }}>看到这个了吗？真的太可爱了哈哈</div>
          </div>
          <div style={{ marginTop: 10 }}>
            <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 4 }}>语气</div>
            <div style={{ display: 'flex', gap: 6 }}>
              <TonePill kind="coral">可爱 / 撒娇</TonePill>
              <TonePill kind="gray">吐槽 / 开玩笑</TonePill>
            </div>
          </div>

          <div style={{ marginTop: 12 }}>
            <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>生词 · 语法</div>
            <KnowledgeItem kind="vocab" state={states.v1}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>귀엽다</span>
                <span style={{ fontSize: 12, color: 'var(--ink-mute)', fontFamily: 'ui-monospace, monospace' }}>[귀엽따]</span>
              </div>
              <div style={{ fontSize: 15, color: 'var(--ink-2)', marginTop: 2 }}>可爱</div>
              <ActionRow state={states.v1} onKnow={() => set('v1', 'known')} onSkip={() => set('v1', 'dismissed')} onSave={() => set('v1', 'saved')} />
            </KnowledgeItem>
            <div style={{ height: 8 }} />
            <KnowledgeItem kind="grammar" state={states.g1}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>-잖아</span>
              </div>
              <div style={{ fontSize: 15, color: 'var(--ink-2)', marginTop: 2 }}>不是……嘛 / 你也知道……</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 6, lineHeight: 1.55 }}>
                带提醒、强调、拉近关系的语气。适合朋友、熟人。
              </div>
              <ActionRow state={states.g1} onKnow={() => set('g1', 'known')} onSkip={() => set('g1', 'dismissed')} onSave={() => set('g1', 'saved')} />
            </KnowledgeItem>
          </div>
        </div>

        {/* ── My Reply Check section ── */}
        {checkMyReplies && (
          <div style={{ marginBottom: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10, marginTop: 4 }}>
              <span style={{ width: 28, height: 28, borderRadius: 9, background: 'var(--bg-mint)', color: '#3F8F66', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon.Heart s={14} />
              </span>
              <div>
                <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>我的回复检查</div>
                <div style={{ fontSize: 11.5, color: 'var(--ink-mute)' }}>2 条 · 1 条可以更自然</div>
              </div>
            </div>
            <MyReplyCheckCard
              original="오늘도 수고했어요!"
              status="natural"
              body="语气礼貌、温柔，适合粉丝回复 idol。"
            />
            <MyReplyCheckCard
              original="나는 너를 많이 좋아해요"
              status="suggest"
              body="意思能理解，但在粉丝回复 idol 的语境中稍微有点直接。"
              suggestion="항상 응원하고 있어요!"
              suggestionZh="我一直都在为你应援！"
            />
          </div>
        )}

        {/* ── Feedback Chat ── */}
        <FeedbackChatBlock />
        <FeedbackConversation />
      </div>

      {/* bottom save bar */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '12px 22px 30px',
        background: 'rgba(255,250,247,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: '0.5px solid var(--line)',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11.5, color: 'var(--ink-mute)' }}>已保存</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>
            <span style={{ color: 'var(--pink-deep)' }}>1</span> 张卡片 · 1 个待选
          </div>
        </div>
        <PinkBtn full={false} size="md" leftIcon={<Icon.Bookmark s={14} />}>查看卡片库</PinkBtn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. REPLY SUGGESTION — entry from confirm or home
// ─────────────────────────────────────────────────────────────
const TONES = [
  { key: 'natural', label: '自然', hint: '日常' },
  { key: 'cute',    label: '可爱', hint: '撒娇' },
  { key: 'polite',  label: '礼貌', hint: '尊敬' },
  { key: 'friend',  label: '朋友感', hint: '亲近' },
  { key: 'flirty',  label: '暧昧感', hint: '不越界' },
];

function ReplySuggestionScreen({ from = 'confirm', tone, setTone, want, setWant, onGenerate, results }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="生成回复建议" back="返回" />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 22px 110px' }}>

        {/* context */}
        <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>
          {from === 'confirm' ? '你想回复这些消息' : '对方说了什么？'}
        </div>
        {from === 'confirm' ? (
          <div style={{
            background: '#fff', border: '1px solid var(--pink-soft)', borderRadius: 16,
            padding: 12, marginBottom: 8,
          }}>
            {['오늘 너무 추웠어 ㅠㅠ', '다들 뭐해?'].map((t, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'flex-start', gap: 8,
                padding: '8px 10px',
                background: 'var(--pink-tint)', border: '1px solid var(--pink-soft)',
                borderRadius: 12, marginBottom: i === 0 ? 6 : 0,
              }}>
                <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--pink-deep)', letterSpacing: 0.4, marginTop: 3 }}>IDOL</span>
                <span className="ko" style={{ fontSize: 14, color: 'var(--ink)', flex: 1 }}>{t}</span>
              </div>
            ))}
            <button style={{
              width: '100%', padding: '8px 0', background: 'transparent', border: 'none',
              color: 'var(--pink-deep)', fontSize: 12.5, fontWeight: 600, cursor: 'pointer', marginTop: 8,
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4,
            }}>
              <Icon.ChevL s={14} /> 返回修改选择
            </button>
          </div>
        ) : (
          <div style={{
            background: '#fff', border: '1px solid var(--line)', borderRadius: 16,
            padding: 12, marginBottom: 8,
          }}>
            <div style={{ marginBottom: 8 }}>
              <button style={{
                width: '100%', height: 42, borderRadius: 12, border: '1.5px dashed var(--line-2)',
                background: 'transparent', color: 'var(--ink-2)', fontSize: 14, fontWeight: 600,
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8, cursor: 'pointer',
              }}><Icon.Camera s={18} />上传截图</button>
            </div>
            <textarea
              placeholder="或直接粘贴 idol 原文 / 对话内容…"
              style={{
                width: '100%', boxSizing: 'border-box', minHeight: 76, padding: 12,
                border: '1px solid var(--line)', borderRadius: 12,
                fontSize: 14, fontFamily: 'inherit', resize: 'none', outline: 'none',
                color: 'var(--ink)',
              }}
            />
          </div>
        )}

        {/* what you want to say */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>
            你想表达什么？ <span style={{ fontWeight: 500, color: 'var(--ink-faint)', letterSpacing: 0 }}>· 可选</span>
          </div>
          <textarea
            value={want} onChange={e => setWant?.(e.target.value)}
            placeholder="例如：今天也辛苦啦，要好好吃饭"
            style={{
              width: '100%', boxSizing: 'border-box', minHeight: 72, padding: 12,
              border: '1px solid var(--line)', borderRadius: 14, background: '#fff',
              fontSize: 14, fontFamily: 'inherit', resize: 'none', outline: 'none',
              color: 'var(--ink)',
            }}
          />
          <div style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginTop: 4, lineHeight: 1.45 }}>
            不填也可以，系统会根据对方消息生成自然回复。
          </div>
        </div>

        {/* tone */}
        <div style={{ marginTop: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
            <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6 }}>回复语气</div>
            {tone === 'flirty' && (
              <span style={{ fontSize: 10.5, color: '#7860B3', background: 'var(--bg-lavender)', padding: '2px 8px', borderRadius: 999, fontWeight: 600 }}>
                轻微心动感，不越界
              </span>
            )}
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {TONES.map(t => (
              <ToneChip key={t.key} {...t} selected={tone === t.key} onClick={() => setTone?.(t.key)} />
            ))}
          </div>
        </div>

        {/* results */}
        {results && (
          <div style={{ marginTop: 22 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--ink-2)' }}>3 条建议</div>
              <button style={{ background: 'transparent', border: 'none', color: 'var(--pink-deep)', fontSize: 13, fontWeight: 600, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <Icon.Refresh s={13} />换一批
              </button>
            </div>
            {[
              { ko: '오늘도 너무 수고했어요! 밥 꼭 챙겨 먹어요 💗', zh: '今天也辛苦啦！一定要好好吃饭哦。', tone: '可爱 · 关心', kind: 'pink' },
              { ko: '추울 텐데 따뜻하게 입어요. 항상 응원해요!', zh: '会冷的话要穿暖和一点。一直支持你！', tone: '温柔 · 礼貌', kind: 'lavender' },
              { ko: '저도 지금 쉬고 있어요 ㅋㅋ 오빠도 잘 쉬어요~', zh: '我也在休息哈哈 哥哥也要好好休息哦～', tone: '朋友感 · 自然', kind: 'mint' },
            ].map((r, i) => (
              <div key={i} style={{
                background: '#fff', border: '1px solid var(--line)', borderRadius: 18,
                padding: 14, marginBottom: 10,
                boxShadow: '0 6px 20px -14px rgba(60,40,50,0.18)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <TonePill kind={r.kind}>{r.tone}</TonePill>
                  <CopyBtn />
                </div>
                <div className="ko" style={{ fontSize: 17, fontWeight: 600, color: 'var(--ink)', lineHeight: 1.45 }}>
                  {r.ko}
                </div>
                <div style={{ fontSize: 13, color: 'var(--ink-mute)', marginTop: 4, lineHeight: 1.5 }}>
                  {r.zh}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* bottom CTA */}
      {!results && (
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0,
          padding: '12px 22px 30px',
          background: 'rgba(255,250,247,0.97)',
          backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
          borderTop: '0.5px solid var(--line)',
        }}>
          <button onClick={onGenerate} style={{
            width: '100%', height: 52, borderRadius: 22, border: 'none',
            background: '#7860B3', color: '#fff',
            fontWeight: 700, fontSize: 16, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            boxShadow: '0 10px 24px -8px rgba(120,96,179,0.55)',
          }}>
            <Icon.Sparkle s={18} />生成 3 条回复
          </button>
        </div>
      )}
    </div>
  );
}

// Reply suggestion empty state
function ReplyEmptyScreen() {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="生成回复建议" back="返回" />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 36px' }}>
        <div style={{
          width: 96, height: 96, borderRadius: 28, background: 'var(--bg-lavender)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7860B3', marginBottom: 18,
        }}>
          <Icon.Bubble s={36} />
        </div>
        <div style={{ fontSize: 17, fontWeight: 700, color: 'var(--ink)', textAlign: 'center', marginBottom: 6 }}>
          先选一条想回复的消息
        </div>
        <div style={{ fontSize: 13.5, color: 'var(--ink-mute)', textAlign: 'center', lineHeight: 1.55 }}>
          回到 OCR 页面勾选 idol 气泡，<br/>或在这里输入你想说的话。
        </div>
        <div style={{ marginTop: 22, display: 'flex', flexDirection: 'column', gap: 8, width: '100%' }}>
          <button style={{
            height: 46, borderRadius: 18, border: 'none', background: '#7860B3', color: '#fff',
            fontSize: 14, fontWeight: 600, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}><Icon.ChevL s={14} />回到 OCR 选择气泡</button>
          <button style={{
            height: 46, borderRadius: 18, background: '#fff', border: '1.5px solid var(--line-2)',
            color: 'var(--ink)', fontSize: 14, fontWeight: 600, cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}><Icon.Edit s={14} />手动输入对方消息</button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5. STATES — loadings + too-many-bubbles
// ─────────────────────────────────────────────────────────────
function QuickReplyLoading() {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative' }}>
      <AppNav title="生成中" />
      <div style={{ padding: '24px 22px', height: 'calc(100% - 110px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{
          background: 'linear-gradient(140deg, #FFFFFF, var(--bg-lavender) 200%)',
          border: '1px solid var(--lavender-soft)',
          borderRadius: 24, padding: 28, width: '100%',
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          boxShadow: '0 20px 50px -20px rgba(120,96,179,0.3)',
        }}>
          <div style={{ position: 'relative', width: 88, height: 88, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 20 }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'radial-gradient(circle, #E0D6F5 0%, transparent 70%)', animation: 'ts-pulse 1.6s ease-in-out infinite' }} />
            <div style={{
              width: 56, height: 56, borderRadius: 18, background: 'linear-gradient(140deg, #C9B8E8, #7860B3)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
              boxShadow: '0 12px 28px -8px rgba(120,96,179,0.55)',
            }}><Icon.Bubble s={26} /></div>
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)', textAlign: 'center' }}>
            正在帮你组织自然韩语回复…
          </div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 6, textAlign: 'center', lineHeight: 1.55 }}>
            根据 idol 的消息 + 你的语气偏好<br/>生成 3 条候选
          </div>

          {/* 3 skeleton bars */}
          <div style={{ width: '100%', marginTop: 22, display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[1, 2, 3].map(i => (
              <div key={i} style={{
                background: 'rgba(255,255,255,0.7)', border: '1px solid var(--lavender-soft)',
                borderRadius: 14, padding: 12,
              }}>
                <div style={{ height: 14, width: '70%', borderRadius: 4, background: 'linear-gradient(90deg, #F0E8FA 25%, #FDEEF1 50%, #F0E8FA 75%)', backgroundSize: '200% 100%', animation: `ts-shimmer 1.4s ease-in-out infinite ${i * 0.15}s` }} />
                <div style={{ height: 10, width: '50%', borderRadius: 3, background: 'linear-gradient(90deg, #F4EFFA 25%, #FBF4F5 50%, #F4EFFA 75%)', backgroundSize: '200% 100%', animation: `ts-shimmer 1.4s ease-in-out infinite ${i * 0.15 + 0.1}s`, marginTop: 8 }} />
              </div>
            ))}
          </div>
        </div>
      </div>
      <style>{`
        @keyframes ts-pulse { 0%,100% { transform: scale(0.92); opacity: 0.7; } 50% { transform: scale(1.1); opacity: 1; } }
        @keyframes ts-shimmer { 0%{background-position: 200% 0;} 100%{background-position: -200% 0;} }
      `}</style>
    </div>
  );
}

function FeedbackChatLoading() {
  return (
    <div style={{
      display: 'flex', justifyContent: 'flex-start', gap: 8, marginTop: 10,
    }}>
      <div style={{
        width: 26, height: 26, borderRadius: 8, background: 'var(--bg-lavender)',
        color: '#7860B3', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}><Icon.Sparkle s={13} /></div>
      <div style={{
        background: '#fff', border: '1px solid var(--lavender-soft)',
        borderRadius: 18, borderTopLeftRadius: 6,
        padding: '10px 14px', fontSize: 13, color: 'var(--ink-mute)',
        display: 'inline-flex', alignItems: 'center', gap: 8,
      }}>
        <span>正在继续解释这个表达</span>
        <span style={{ display: 'inline-flex', gap: 3 }}>
          {[0,1,2].map(i => (
            <span key={i} style={{
              width: 4, height: 4, borderRadius: 2, background: '#7860B3',
              animation: `ts-bounce 1.2s ease-in-out infinite ${i*0.15}s`,
            }} />
          ))}
        </span>
      </div>
      <style>{`
        @keyframes ts-bounce { 0%,100%{transform:translateY(0);opacity:.4} 50%{transform:translateY(-4px);opacity:1} }
      `}</style>
    </div>
  );
}

// Too-many-bubbles screen
function TooManyBubblesScreen() {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="确认聊天内容" back="返回" />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 22px 200px' }}>
        {/* warning card */}
        <div style={{
          background: 'linear-gradient(140deg, #FFEFE7, #FBEFD8)', borderRadius: 18,
          border: '1px solid #F4D4B5', padding: 16, marginBottom: 16,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <span style={{
              width: 28, height: 28, borderRadius: 9, background: '#fff', color: '#C8633F',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon.Info s={16} /></span>
            <span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>识别到 14 条气泡</span>
          </div>
          <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.55, marginLeft: 36 }}>
            这张截图内容有点多，解析可能会变慢。<br/>
            建议裁剪成 10 条以内，或分批上传。
          </div>
        </div>

        {/* mini preview of stack */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 16 }}>
          {[
            { side: 'left', t: '오늘 뭐해? ㅋㅋ' },
            { side: 'right', t: '공부 중이야' },
            { side: 'left', t: '나도 같이 할까?' },
            { side: 'left', t: '아 너무 졸려…' },
            { side: 'right', t: '커피 한 잔 어때?' },
          ].map((b, i) => (
            <div key={i} style={{
              display: 'flex', justifyContent: b.side === 'left' ? 'flex-start' : 'flex-end',
            }}>
              <div className="ko" style={{
                background: b.side === 'left' ? '#fff' : 'var(--pink-tint)',
                border: '1px solid var(--line)', borderRadius: 14,
                padding: '6px 12px', fontSize: 13, color: 'var(--ink)',
                maxWidth: '75%',
              }}>{b.t}</div>
            </div>
          ))}
          <div style={{ textAlign: 'center', fontSize: 11.5, color: 'var(--ink-mute)', marginTop: 4 }}>
            … 还有 9 条
          </div>
        </div>
      </div>

      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '14px 22px 30px',
        background: 'rgba(255,250,247,0.97)',
        backdropFilter: 'blur(20px)',
        borderTop: '0.5px solid var(--line)',
        display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        <PinkBtn leftIcon={<Icon.Sparkle s={18} />} size="md">继续解析（可能稍慢）</PinkBtn>
        <OutlineBtn leftIcon={<Icon.Refresh s={16} />} size="md">重新上传</OutlineBtn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6. CARD PREVIEW MODAL V1 — with AI example
// ─────────────────────────────────────────────────────────────
function CardPreviewModalV1({ onDismiss, kind = 'vocab' }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(40,30,40,0.45)',
      backdropFilter: 'blur(4px)',
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
    }}>
      <div style={{
        background: 'var(--bg-page)', borderTopLeftRadius: 32, borderTopRightRadius: 32,
        width: '100%', padding: '14px 22px 32px',
        maxHeight: '92%', overflowY: 'auto',
        boxShadow: '0 -20px 60px -10px rgba(60,40,50,0.3)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
          <div style={{ width: 40, height: 5, borderRadius: 3, background: '#E0D2D6' }} />
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14,
          padding: '8px 12px', background: 'var(--bg-mint)', borderRadius: 12,
        }}>
          <span style={{ width: 22, height: 22, borderRadius: 11, background: 'var(--mint)', color: '#fff', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon.Check s={13} />
          </span>
          <span style={{ fontSize: 13, fontWeight: 600, color: '#3F8F66' }}>已保存到卡片库</span>
        </div>

        {kind === 'vocab' ? <VocabCardLarge /> : <GrammarCardLarge />}

        <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
          <div style={{ flex: 1 }}>
            <PinkBtn onClick={onDismiss}>知道了</PinkBtn>
          </div>
          <OutlineBtn full={false} size="lg">查看卡片库</OutlineBtn>
        </div>
      </div>
    </div>
  );
}

function VocabCardLarge() {
  return (
    <div style={{
      background: 'linear-gradient(160deg, #fff 0%, #FFF8F3 100%)',
      border: '1px solid var(--pink-soft)', borderRadius: 26,
      padding: 22, boxShadow: '0 18px 50px -16px rgba(245,140,160,0.4)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{
          fontSize: 10, fontWeight: 700, letterSpacing: 0.8,
          padding: '4px 10px', borderRadius: 999, background: '#F4EEFC', color: '#7860B3',
        }}>VOCAB · 生词</span>
        <span style={{ flex: 1 }} />
        <Icon.Bookmark s={16} />
      </div>
      <div className="ko" style={{ fontSize: 38, fontWeight: 700, lineHeight: 1.1, color: 'var(--ink)' }}>응원하다</div>
      <div style={{ fontSize: 13.5, color: 'var(--ink-mute)', fontFamily: 'ui-monospace, monospace', marginTop: 4 }}>[응원하다]</div>
      <div style={{ fontSize: 17, color: 'var(--ink-2)', marginTop: 8, fontWeight: 500 }}>支持 · 应援</div>
      <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
        <TonePill kind="gray">动词</TonePill>
        <TonePill kind="pink">粉丝高频</TonePill>
      </div>

      <div style={{ height: 1, background: 'var(--line)', margin: '18px 0' }} />

      {/* original */}
      <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>来自这条聊天</div>
      <div style={{
        background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
        padding: '10px 14px',
      }}>
        <span className="ko" style={{ fontSize: 14, color: 'var(--ink)' }}>항상 응원하고 있어요.</span>
      </div>

      {/* AI example */}
      <div style={{
        marginTop: 14, padding: 14, borderRadius: 16,
        background: 'var(--bg-lavender)', border: '1px dashed var(--lavender-soft)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
          <span style={{ color: '#7860B3' }}><Icon.Sparkle s={13} /></span>
          <span style={{ fontSize: 10.5, fontWeight: 700, color: '#7860B3', letterSpacing: 0.6 }}>AI 例句</span>
          <span style={{ flex: 1 }} />
          <CopyBtn />
        </div>
        <div className="ko" style={{ fontSize: 16, fontWeight: 600, color: 'var(--ink)', lineHeight: 1.45 }}>
          오늘도 너를 응원할게요.
        </div>
        <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 4 }}>今天也会支持你。</div>
      </div>

      <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '14px 0 4px' }}>用法笔记</div>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6 }}>
        常用于粉丝表达支持和鼓励。"응원"是名词、"응원하다"是动词，两个都很常见。
      </div>
    </div>
  );
}

function GrammarCardLarge() {
  return (
    <div style={{
      background: 'linear-gradient(160deg, #fff 0%, #FFF6EE 100%)',
      border: '1px solid #F4D4B5', borderRadius: 26,
      padding: 22, boxShadow: '0 18px 50px -16px rgba(255,160,138,0.35)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <span style={{
          fontSize: 10, fontWeight: 700, letterSpacing: 0.8,
          padding: '4px 10px', borderRadius: 999, background: '#FFEFE7', color: '#C8633F',
        }}>GRAMMAR · 语法 / 词尾</span>
        <span style={{ flex: 1 }} />
        <Icon.Bookmark s={16} />
      </div>
      <div className="ko" style={{ fontSize: 38, fontWeight: 700, lineHeight: 1.1, color: 'var(--ink)' }}>-잖아</div>
      <div style={{ fontSize: 17, color: 'var(--ink-2)', marginTop: 10, fontWeight: 500 }}>不是……嘛 / 你也知道……</div>
      <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
        <TonePill kind="coral">提醒 · 强调</TonePill>
        <TonePill kind="pink">拉近关系</TonePill>
      </div>

      <div style={{ height: 1, background: 'var(--line)', margin: '18px 0' }} />

      <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>来自这条聊天</div>
      <div style={{
        background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
        padding: '10px 14px',
      }}>
        <span className="ko" style={{ fontSize: 14, color: 'var(--ink)' }}>나 어제 말했잖아.</span>
      </div>

      <div style={{
        marginTop: 14, padding: 14, borderRadius: 16,
        background: 'var(--bg-lavender)', border: '1px dashed var(--lavender-soft)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
          <span style={{ color: '#7860B3' }}><Icon.Sparkle s={13} /></span>
          <span style={{ fontSize: 10.5, fontWeight: 700, color: '#7860B3', letterSpacing: 0.6 }}>AI 例句</span>
          <span style={{ flex: 1 }} />
          <CopyBtn />
        </div>
        <div className="ko" style={{ fontSize: 15.5, fontWeight: 600, color: 'var(--ink)' }}>우리 친구잖아.</div>
        <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 2 }}>我们不是朋友嘛。</div>
        <div style={{ height: 1, background: 'var(--lavender-soft)', margin: '10px 0' }} />
        <div className="ko" style={{ fontSize: 15.5, fontWeight: 600, color: 'var(--ink)' }}>내가 말했잖아.</div>
        <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 2 }}>我不是说过了嘛。</div>
      </div>

      <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '14px 0 4px' }}>适合关系 / 场景</div>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6 }}>
        朋友、熟人、亲近关系中使用。正式场合需谨慎，否则可能显得太随便。
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 7. CARD LIBRARY DETAIL V1 — fullscreen detail page with AI ex
// ─────────────────────────────────────────────────────────────
function LibraryDetailV1({ kind = 'vocab' }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="卡片详情" back="卡片库" trailing={<span style={{ color: 'var(--pink)', fontSize: 14, display: 'inline-flex', alignItems: 'center', gap: 4 }}><Icon.Trash s={14} />删除</span>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 22px 30px' }}>
        {kind === 'vocab' ? <VocabCardLarge /> : <GrammarCardLarge />}

        <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '20px 0 8px' }}>来源</div>
        <div style={{
          background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
          padding: '12px 14px',
        }}>
          <div style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginBottom: 4 }}>2026年5月17日 · 学习解析</div>
          <div style={{ fontSize: 13.5, color: 'var(--ink-2)' }}>
            来自一次聊天截图分析 · 第 2 条 idol 气泡
          </div>
        </div>

        <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '18px 0 8px' }}>相关卡片</div>
        {[
          { ko: '응원', zh: '应援', kind: 'pink', label: '相关词' },
          { ko: '-고 있어요', zh: '正在…… ', kind: 'lavender', label: '相关语法' },
        ].map((r, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
            padding: '10px 14px', marginBottom: 8,
          }}>
            <span className="ko" style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>{r.ko}</span>
            <span style={{ fontSize: 13, color: 'var(--ink-mute)' }}>· {r.zh}</span>
            <span style={{ flex: 1 }} />
            <TonePill kind={r.kind}>{r.label}</TonePill>
            <Icon.ChevR s={14} />
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  Checkbox, CopyBtn, ToneChip, SelectableBubble,
  HomeScreenV1, ConfirmScreenV1, AnalysisScreenV1,
  ReplySuggestionScreen, ReplyEmptyScreen,
  QuickReplyLoading, FeedbackChatLoading, TooManyBubblesScreen,
  CardPreviewModalV1, VocabCardLarge, GrammarCardLarge,
  LibraryDetailV1,
});
