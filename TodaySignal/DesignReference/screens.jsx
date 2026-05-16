/* global React, Icon, PinkBtn, OutlineBtn, GhostBtn, TonePill, AppNav, TabBar, ChatBubble, KnowledgeItem, ActionRow, AppMark, IOSDevice */

// ─────────────────────────────────────────────────────────────
// HOME / INPUT
// ─────────────────────────────────────────────────────────────
function HomeScreen({ onUpload, onPaste, onTab }) {
  return (
    <div style={{ position: 'relative', height: '100%', background: 'var(--bg-page)' }}>
      {/* decorative top */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 320,
        background: 'radial-gradient(ellipse at 20% 0%, #FFE4EC 0%, transparent 55%), radial-gradient(ellipse at 90% 10%, #EFEAFA 0%, transparent 50%)',
        pointerEvents: 'none',
      }} />
      <div style={{ position: 'relative', padding: '64px 22px 0' }}>
        {/* header row */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 26 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <AppMark size={36} />
            <div>
              <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--ink-mute)', letterSpacing: 0.4 }}>TODAY'S SIGNAL</div>
            </div>
          </div>
          <div style={{
            width: 36, height: 36, borderRadius: 18, background: '#fff', border: '1px solid var(--line)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-mute)',
          }}>
            <Icon.Gear s={18} />
          </div>
        </div>

        {/* App title */}
        <div className="ko" style={{ fontSize: 38, fontWeight: 700, color: 'var(--ink)', letterSpacing: -0.5, lineHeight: 1.1 }}>
          오늘의 시그널
        </div>
        <div style={{ fontSize: 15, color: 'var(--ink-2)', marginTop: 8, fontWeight: 500 }}>
          韩语聊天截图学习助手 <span style={{ color: 'var(--pink-deep)', marginLeft: 4 }}>·</span> for K-pop fans
        </div>

        {/* Main action card */}
        <div style={{
          marginTop: 32,
          background: '#fff', borderRadius: 28, padding: 22,
          border: '1px solid var(--line)',
          boxShadow: '0 18px 40px -20px rgba(60,40,50,0.16), 0 1px 0 rgba(255,255,255,0.6) inset',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
            <span style={{
              width: 6, height: 6, borderRadius: 3, background: 'var(--pink)',
            }} />
            <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: 0.6 }}>NEW SIGNAL</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <PinkBtn onClick={onUpload} leftIcon={<Icon.Camera s={20} />}>上传聊天截图</PinkBtn>
            <OutlineBtn onClick={onPaste} leftIcon={<Icon.Paste s={18} />}>粘贴韩语文本</OutlineBtn>
          </div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 16, lineHeight: 1.55 }}>
            支持 idol bubble、DM、社交平台聊天截图。<br />
            上传后会先让你确认文字，再开始 AI 解析。
          </div>
        </div>

        {/* privacy note */}
        <div style={{
          marginTop: 18, padding: '12px 14px',
          background: 'var(--bg-lavender)', borderRadius: 14,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{ color: 'var(--lavender)' }}><Icon.Lock s={16} /></div>
          <div style={{ fontSize: 12.5, color: '#5E4C8A', lineHeight: 1.45 }}>
            原始截图不会长期保存，学习卡片仅保存在本机。
          </div>
        </div>

        {/* Recent / placeholder list */}
        <div style={{ marginTop: 26 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: 0.4 }}>最近解析</div>
            <span style={{ fontSize: 12, color: 'var(--ink-mute)' }}>本机 · 3 条</span>
          </div>
          {[
            { tag: '亲近随意', preview: '오늘 뭐해? ㅋㅋ', meta: '今天 · 3 个新卡片' },
            { tag: '可爱 / 撒娇', preview: '나 보고 싶었어?', meta: '昨天 · 2 个新卡片' },
            { tag: '安慰 / 关心', preview: '괜찮아, 무리하지 마', meta: '5月10日 · 1 个新卡片' },
          ].map((r, i) => (
            <div key={i} style={{
              background: '#fff', border: '1px solid var(--line)', borderRadius: 16,
              padding: '12px 14px', marginBottom: 8,
              display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10, background: 'var(--pink-tint)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--pink-deep)',
              }}>
                <Icon.Bubble s={18} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ko" style={{ fontSize: 14, fontWeight: 500, color: 'var(--ink)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {r.preview}
                </div>
                <div style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginTop: 2 }}>{r.meta}</div>
              </div>
              <TonePill kind={i === 0 ? 'pink' : i === 1 ? 'coral' : 'lavender'}>{r.tag}</TonePill>
            </div>
          ))}
        </div>
        <div style={{ height: 120 }} />
      </div>
      <TabBar active="解析" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// TEXT CONFIRMATION
// ─────────────────────────────────────────────────────────────
function ConfirmScreen({ idolSide = 'left', setIdolSide, onAnalyze, onBack }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="确认聊天内容" back="返回" trailing={<span style={{ fontSize: 14, color: 'var(--pink)' }}>编辑</span>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 22px 240px' }}>
        <div style={{
          background: 'var(--bg-soft)', borderRadius: 14, padding: '10px 12px',
          fontSize: 12.5, color: '#7A4A55', lineHeight: 1.5, marginBottom: 16,
          display: 'flex', gap: 10, alignItems: 'flex-start',
        }}>
          <div style={{ marginTop: 1, color: 'var(--pink-deep)' }}><Icon.Info s={14} /></div>
          <div>请检查 OCR 识别结果。你可以修改、删除气泡，或标记哪一侧是对方。</div>
        </div>

        {/* bubbles */}
        <div style={{ padding: '0 16px' }}>
          <ChatBubble side="left" idolSide={idolSide} text="오늘 뭐해? ㅋㅋ" editable />
          <ChatBubble side="right" idolSide={idolSide} text="나 지금 공부 중이야" editable />
          <ChatBubble side="left" idolSide={idolSide} image editable />
          <ChatBubble side="left" idolSide={idolSide} text="이거 봤어? 너무 귀엽잖아ㅋㅋ" editable />
          <ChatBubble side="right" idolSide={idolSide} text="ㅋㅋㅋㅋ 진짜 귀엽다" editable />
        </div>

        {/* fallback hint */}
        <div style={{
          marginTop: 18, padding: '10px 12px', borderRadius: 12,
          border: '1px dashed var(--line-2)', background: '#fff',
          fontSize: 12.5, color: 'var(--ink-mute)',
        }}>
          气泡识别不太准确？<span style={{ color: 'var(--pink-deep)', fontWeight: 600 }}>切换为逐行文本</span>
        </div>
      </div>

      {/* side selector + CTA bottom sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '16px 22px 30px',
        background: 'rgba(255,250,247,0.97)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderTop: '0.5px solid var(--line)',
      }}>
        <div style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--ink-2)', marginBottom: 8, letterSpacing: 0.4 }}>
          哪一侧是 IDOL / 对方？
        </div>
        <div style={{ display: 'flex', gap: 8, marginBottom: 14, padding: 4, background: '#F2EAEC', borderRadius: 14 }}>
          {['left', 'right'].map(s => {
            const on = s === idolSide;
            return (
              <div key={s} onClick={() => setIdolSide?.(s)} style={{
                flex: 1, height: 40, borderRadius: 10,
                background: on ? '#fff' : 'transparent',
                boxShadow: on ? '0 2px 6px rgba(60,40,50,0.08)' : 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                color: on ? 'var(--pink-deep)' : 'var(--ink-mute)', fontWeight: 600, fontSize: 14,
                cursor: 'pointer',
              }}>
                {s === 'left' ? '← 左侧' : '右侧 →'}
                {on && <span style={{ fontSize: 11, fontWeight: 500, color: 'var(--pink)' }}>IDOL</span>}
              </div>
            );
          })}
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <div style={{ flex: 1 }}>
            <PinkBtn onClick={onAnalyze} leftIcon={<Icon.Sparkle s={18} />}>开始解析</PinkBtn>
          </div>
          <OutlineBtn full={false} size="lg" onClick={onBack}>重新上传</OutlineBtn>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ANALYSIS RESULT (★ key screen)
// ─────────────────────────────────────────────────────────────
function AnalysisBubbleCard({ children }) {
  return (
    <div style={{
      background: 'var(--bg-elev)',
      borderRadius: 22, padding: 14,
      border: '1px solid var(--line)',
      marginBottom: 16,
    }}>{children}</div>
  );
}

function FieldRow({ label, children, tight }) {
  return (
    <div style={{ marginTop: tight ? 8 : 12 }}>
      <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 4 }}>
        {label}
      </div>
      <div>{children}</div>
    </div>
  );
}

function AnalysisScreen({ onSaveCard, onBack }) {
  const [states, setStates] = React.useState({ v1: 'saved', v2: 'open', g1: 'known', g2: 'open' });
  const set = (k, v) => setStates(s => ({ ...s, [k]: v }));

  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <AppNav title="解析结果" back="返回" trailing={<span style={{ fontSize: 14, color: 'var(--pink)' }}>完成</span>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 18px 120px' }}>
        {/* top note */}
        <div style={{
          background: 'var(--bg-lavender)', borderRadius: 14, padding: '10px 14px',
          fontSize: 12.5, color: '#5E4C8A', lineHeight: 1.5, marginBottom: 16,
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <Icon.Sparkle s={14} />
          <span>默认从对方气泡提取学习点。你可以选择要生成卡片的内容。</span>
        </div>

        {/* progress meta */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--ink-2)', letterSpacing: 0.4 }}>解析 1 / 3</span>
          <span style={{ flex: 1, height: 4, borderRadius: 2, background: 'var(--pink-tint)', position: 'relative', overflow: 'hidden' }}>
            <span style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: '33%', background: 'var(--pink)', borderRadius: 2 }} />
          </span>
          <span style={{ fontSize: 11, color: 'var(--ink-mute)' }}>3 个生词 · 2 个语法</span>
        </div>

        {/* ── Bubble 1 (idol) ── */}
        <AnalysisBubbleCard>
          <ChatBubble side="left" idolSide="left" text="오늘 뭐해? ㅋㅋ" />
          <FieldRow label="中文翻译">
            <div style={{ fontSize: 15, color: 'var(--ink)', lineHeight: 1.5 }}>今天在干嘛？哈哈</div>
          </FieldRow>
          <FieldRow label="语气" tight>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <TonePill kind="pink">亲近随意</TonePill>
              <TonePill kind="cream">日常开场</TonePill>
            </div>
          </FieldRow>

          {/* Vocab item */}
          <FieldRow label="生词">
            <KnowledgeItem kind="vocab" state={states.v1}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>오늘</span>
                <span style={{ fontSize: 12, color: 'var(--ink-mute)', fontFamily: 'ui-monospace, monospace' }}>[오늘]</span>
              </div>
              <div style={{ fontSize: 15, color: 'var(--ink-2)', marginTop: 2 }}>今天</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                <TonePill kind="gray">名词 / 副词</TonePill>
              </div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 8, lineHeight: 1.5 }}>
                聊天中常用于开启话题，类似中文的"今天"。
              </div>
              <ActionRow
                state={states.v1}
                onKnow={() => set('v1', 'known')}
                onSkip={() => set('v1', 'dismissed')}
                onSave={() => { set('v1', 'saved'); onSaveCard?.(); }}
              />
            </KnowledgeItem>
          </FieldRow>

          {/* Grammar item */}
          <FieldRow label="语法 / 词尾">
            <KnowledgeItem kind="grammar" state={states.g1}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>-해?</span>
              </div>
              <div style={{ fontSize: 15, color: 'var(--ink-2)', marginTop: 2 }}>做……吗？</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 8, lineHeight: 1.55 }}>
                <span style={{ color: 'var(--coral)', fontWeight: 600 }}>平语疑问</span>，语气自然亲近。<br/>
                适合朋友、熟人、亲近关系。
              </div>
              <ActionRow
                state={states.g1}
                onKnow={() => set('g1', 'known')}
                onSkip={() => set('g1', 'dismissed')}
                onSave={() => { set('g1', 'saved'); onSaveCard?.(); }}
              />
            </KnowledgeItem>
          </FieldRow>
        </AnalysisBubbleCard>

        {/* ── Bubble 2 (user reply) — My Reply Check ── */}
        <AnalysisBubbleCard>
          <ChatBubble side="right" idolSide="left" text="응원할게" />
          <div style={{
            background: '#fff', border: '1px solid var(--mint-soft)', borderRadius: 16,
            padding: '12px 14px', marginTop: 8,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <span style={{
                width: 22, height: 22, borderRadius: 11, background: 'var(--bg-mint)',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: 'var(--mint)',
              }}><Icon.Heart s={12} /></span>
              <span style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--ink-2)' }}>你的回复</span>
              <span style={{ flex: 1 }} />
              <TonePill kind="cream">可以更自然</TonePill>
            </div>
            <div style={{ fontSize: 13.5, color: 'var(--ink-2)', lineHeight: 1.55 }}>
              意思没错，但在粉丝回复 idol 的语境里有点直接。
            </div>
            <div style={{
              marginTop: 10, padding: 10, borderRadius: 12, background: 'var(--bg-mint)',
            }}>
              <div style={{ fontSize: 10.5, fontWeight: 700, color: '#3F8F66', letterSpacing: 0.5, marginBottom: 4 }}>更自然的说法</div>
              <div className="ko" style={{ fontSize: 15, fontWeight: 500, color: 'var(--ink)' }}>항상 응원하고 있어요!</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 2 }}>我一直都在为你应援！</div>
            </div>
          </div>
        </AnalysisBubbleCard>

        {/* ── Bubble 3 (idol) collapsed preview ── */}
        <AnalysisBubbleCard>
          <ChatBubble side="left" idolSide="left" text="이거 봤어? 너무 귀엽잖아ㅋㅋ" />
          <FieldRow label="中文翻译">
            <div style={{ fontSize: 15, color: 'var(--ink)', lineHeight: 1.5 }}>看到这个了吗？真的太可爱了哈哈</div>
          </FieldRow>
          <FieldRow label="语气" tight>
            <div style={{ display: 'flex', gap: 6 }}>
              <TonePill kind="coral">可爱 / 撒娇</TonePill>
              <TonePill kind="gray">吐槽 / 开玩笑</TonePill>
            </div>
          </FieldRow>

          {/* one collapsed item */}
          <FieldRow label="生词 + 语法">
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 12px', background: '#fff',
              border: '1px solid var(--line)', borderRadius: 14,
              marginBottom: 8,
            }}>
              <span className="ko" style={{ fontSize: 18, fontWeight: 700 }}>귀엽다</span>
              <span style={{ fontSize: 12, color: 'var(--ink-mute)' }}>· 可爱</span>
              <span style={{ flex: 1 }} />
              <Icon.ChevR s={16} />
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 12px', background: '#fff',
              border: '1px solid var(--line)', borderRadius: 14,
            }}>
              <span className="ko" style={{ fontSize: 18, fontWeight: 700 }}>-잖아</span>
              <span style={{ fontSize: 12, color: 'var(--ink-mute)' }}>· 不是……嘛</span>
              <span style={{ flex: 1 }} />
              <Icon.ChevR s={16} />
            </div>
          </FieldRow>
        </AnalysisBubbleCard>
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
          <div style={{ fontSize: 12, color: 'var(--ink-mute)' }}>已选学习点</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>
            <span style={{ color: 'var(--pink-deep)' }}>2</span> 个卡片 + 1 个已认识
          </div>
        </div>
        <PinkBtn full={false} size="md" leftIcon={<Icon.Bookmark s={14} />}>查看卡片库</PinkBtn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// CARD PREVIEW MODAL (overlay)
// ─────────────────────────────────────────────────────────────
function CardPreviewModal({ onDismiss, kind = 'vocab' }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(40,30,40,0.45)',
      backdropFilter: 'blur(4px)', WebkitBackdropFilter: 'blur(4px)',
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
    }}>
      <div style={{
        background: 'var(--bg-page)', borderTopLeftRadius: 32, borderTopRightRadius: 32,
        width: '100%', padding: '14px 22px 32px',
        boxShadow: '0 -20px 60px -10px rgba(60,40,50,0.3)',
        maxHeight: '85%', overflowY: 'auto',
      }}>
        {/* drag handle */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
          <div style={{ width: 40, height: 5, borderRadius: 3, background: '#E0D2D6' }} />
        </div>
        {/* success bar */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16,
          padding: '8px 12px', background: 'var(--bg-mint)', borderRadius: 12,
        }}>
          <span style={{ width: 22, height: 22, borderRadius: 11, background: 'var(--mint)', color: '#fff', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon.Check s={13} />
          </span>
          <span style={{ fontSize: 13, fontWeight: 600, color: '#3F8F66' }}>已保存到卡片库</span>
        </div>

        {/* Card */}
        <div style={{
          background: 'linear-gradient(160deg, #fff 0%, #FFF8F3 100%)',
          border: '1px solid var(--pink-soft)', borderRadius: 26,
          padding: 22,
          boxShadow: '0 18px 50px -16px rgba(245,140,160,0.4)',
        }}>
          {kind === 'vocab' ? (
            <>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
                <span style={{
                  fontSize: 10, fontWeight: 700, letterSpacing: 0.8,
                  padding: '4px 10px', borderRadius: 999, background: '#F4EEFC', color: '#7860B3',
                }}>VOCAB · 生词</span>
                <span style={{ flex: 1 }} />
                <Icon.Bookmark s={16} />
              </div>
              <div className="ko" style={{ fontSize: 40, fontWeight: 700, lineHeight: 1.1, color: 'var(--ink)' }}>번역</div>
              <div style={{ fontSize: 14, color: 'var(--ink-mute)', fontFamily: 'ui-monospace, monospace', marginTop: 4 }}>[버녁]</div>
              <div style={{ fontSize: 17, color: 'var(--ink-2)', marginTop: 8, fontWeight: 500 }}>翻译</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
                <TonePill kind="gray">名词</TonePill>
                <TonePill kind="lavender">常用</TonePill>
              </div>

              <div style={{ height: 1, background: 'var(--line)', margin: '18px 0' }} />

              <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginBottom: 6 }}>来自这条聊天</div>
              <div style={{
                background: '#fff', border: '1px solid var(--line)', borderRadius: 14,
                padding: '10px 14px', fontSize: 14, lineHeight: 1.5, color: 'var(--ink)',
              }}>
                <span className="ko">이거 번역해줄 수 있어?</span>
              </div>

              <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '14px 0 6px' }}>AI 例句</div>
              <div className="ko" style={{ fontSize: 15, fontWeight: 500, color: 'var(--ink)' }}>한국어 문장을 중국어로 번역했어요.</div>
              <div style={{ fontSize: 13, color: 'var(--ink-mute)', marginTop: 2 }}>我把韩语句子翻译成了中文。</div>

              <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, margin: '14px 0 4px' }}>用法笔记</div>
              <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.55 }}>
                常用于表示翻译文本或语言内容。在聊天中也会写成 "번역해줘"。
              </div>
            </>
          ) : null}
        </div>

        <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
          <div style={{ flex: 1 }}>
            <PinkBtn onClick={onDismiss}>知道了</PinkBtn>
          </div>
          <OutlineBtn full={false} size="lg">查看卡片库</OutlineBtn>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// CARD LIBRARY
// ─────────────────────────────────────────────────────────────
function LibraryScreen({ tab = 'vocab', setTab, expanded, setExpanded }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingBottom: 4 }}>
        <div style={{ padding: '0 22px 8px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--ink)' }}>卡片库</div>
          <span style={{ fontSize: 12, color: 'var(--ink-mute)' }}>本机 · 14 张</span>
        </div>
        {/* segmented */}
        <div style={{ padding: '8px 22px 4px' }}>
          <div style={{ display: 'flex', gap: 4, padding: 4, background: '#F2EAEC', borderRadius: 14 }}>
            {[{ k: 'vocab', label: '生词', n: 9 }, { k: 'grammar', label: '语法 / 词尾', n: 5 }].map(t => {
              const on = t.k === tab;
              return (
                <div key={t.k} onClick={() => setTab?.(t.k)} style={{
                  flex: 1, height: 38, borderRadius: 10,
                  background: on ? '#fff' : 'transparent',
                  boxShadow: on ? '0 2px 6px rgba(60,40,50,0.08)' : 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  color: on ? 'var(--ink)' : 'var(--ink-mute)', fontWeight: 600, fontSize: 14,
                  cursor: 'pointer',
                }}>
                  {t.label}
                  <span style={{
                    fontSize: 11, padding: '2px 6px', borderRadius: 8,
                    background: on ? 'var(--pink-tint)' : 'transparent',
                    color: on ? 'var(--pink-deep)' : 'var(--ink-faint)',
                    fontWeight: 700,
                  }}>{t.n}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '12px 22px 120px' }}>
        {tab === 'vocab' ? (
          <>
            {[
              { id: 'a', word: '번역', meaning: '翻译', pron: '[버녁]', pos: '名词', snippet: '이거 번역해줄 수 있어?', expand: true,
                example: '한국어 문장을 중국어로 번역했어요.', exZh: '我把韩语句子翻译成了中文。',
                note: '常用于表示翻译文本或语言内容。', tag: 'lavender', tagText: '名词' },
              { id: 'b', word: '응원', meaning: '应援 / 加油', pron: '[응원]', pos: '名词', snippet: '항상 응원하고 있어요!', tag: 'pink', tagText: '粉丝高频' },
              { id: 'c', word: '귀엽다', meaning: '可爱', pron: '[귀엽따]', pos: '形容词', snippet: '너무 귀엽잖아ㅋㅋ', tag: 'coral', tagText: '形容词' },
              { id: 'd', word: '오늘', meaning: '今天', pron: '[오늘]', pos: '名词 / 副词', snippet: '오늘 뭐해?', tag: 'gray', tagText: '日常' },
            ].map(c => (
              <VocabCard key={c.id} c={c} expanded={expanded === c.id} onToggle={() => setExpanded?.(expanded === c.id ? null : c.id)} />
            ))}
          </>
        ) : (
          <>
            {[
              { id: 'g1', point: '-잖아', meaning: '不是……嘛 / 你也知道……', tone: '带提醒、强调、拉近关系的语气', snippet: '나 어제 말했잖아.', tag: 'coral', tagText: '语尾' },
              { id: 'g2', point: '-해?', meaning: '做……吗？', tone: '平语疑问，自然亲近', snippet: '오늘 뭐해? ㅋㅋ', tag: 'pink', tagText: '平语' },
              { id: 'g3', point: '-아/어 줄 수 있어?', meaning: '可以……吗？', tone: '请求，语气友好', snippet: '이거 번역해줄 수 있어?', tag: 'lavender', tagText: '请求' },
            ].map(c => (
              <GrammarCard key={c.id} c={c} />
            ))}
          </>
        )}
      </div>
      <TabBar active="卡片库" />
    </div>
  );
}

function VocabCard({ c, expanded, onToggle }) {
  return (
    <div onClick={onToggle} style={{
      background: '#fff', borderRadius: 18, marginBottom: 10,
      border: `1px solid ${expanded ? 'var(--pink-soft)' : 'var(--line)'}`,
      padding: 14,
      boxShadow: expanded ? '0 14px 30px -16px rgba(245,140,160,0.4)' : 'none',
      transition: 'box-shadow .15s',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>{c.word}</span>
            <span style={{ fontSize: 11.5, color: 'var(--ink-mute)', fontFamily: 'ui-monospace, monospace' }}>{c.pron}</span>
            <TonePill kind={c.tag}>{c.tagText}</TonePill>
          </div>
          <div style={{ fontSize: 14.5, color: 'var(--ink-2)', marginTop: 4 }}>{c.meaning}</div>
          <div style={{
            fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 6,
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <Icon.Bubble s={12} />
            <span className="ko" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.snippet}</span>
          </div>
        </div>
        <div style={{
          width: 30, height: 30, borderRadius: 15, color: 'var(--ink-faint)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon.Trash s={14} />
        </div>
      </div>
      {expanded && (
        <div style={{ marginTop: 14, paddingTop: 14, borderTop: '1px dashed var(--line-2)' }}>
          <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6 }}>AI 例句</div>
          <div className="ko" style={{ fontSize: 14.5, fontWeight: 500, color: 'var(--ink)', marginTop: 4 }}>{c.example}</div>
          <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 2 }}>{c.exZh}</div>
          <div style={{ fontSize: 10.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.6, marginTop: 10 }}>用法笔记</div>
          <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.55 }}>{c.note}</div>
        </div>
      )}
    </div>
  );
}

function GrammarCard({ c }) {
  return (
    <div style={{
      background: '#fff', borderRadius: 18, marginBottom: 10,
      border: '1px solid var(--line)', padding: 14,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span className="ko" style={{ fontSize: 22, fontWeight: 700, color: 'var(--ink)' }}>{c.point}</span>
            <TonePill kind={c.tag}>{c.tagText}</TonePill>
          </div>
          <div style={{ fontSize: 14.5, color: 'var(--ink-2)', marginTop: 4 }}>{c.meaning}</div>
          <div style={{ fontSize: 12, color: 'var(--ink-mute)', marginTop: 4, fontStyle: 'italic' }}>{c.tone}</div>
          <div style={{
            fontSize: 12.5, color: 'var(--ink-mute)', marginTop: 8,
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <Icon.Bubble s={12} />
            <span className="ko" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.snippet}</span>
          </div>
        </div>
        <div style={{
          width: 30, height: 30, borderRadius: 15, color: 'var(--ink-faint)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon.Trash s={14} />
        </div>
      </div>
    </div>
  );
}

// Empty state variant
function LibraryEmptyScreen({ tab = 'vocab' }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingBottom: 4 }}>
        <div style={{ padding: '0 22px 8px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--ink)' }}>卡片库</div>
        </div>
        <div style={{ padding: '8px 22px 4px' }}>
          <div style={{ display: 'flex', gap: 4, padding: 4, background: '#F2EAEC', borderRadius: 14 }}>
            {['生词', '语法 / 词尾'].map((t, i) => (
              <div key={i} style={{
                flex: 1, height: 38, borderRadius: 10,
                background: i === 0 ? '#fff' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: i === 0 ? 'var(--ink)' : 'var(--ink-mute)', fontWeight: 600, fontSize: 14,
              }}>{t}</div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 32px' }}>
        <div style={{
          width: 96, height: 96, borderRadius: 28, background: 'var(--pink-tint)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--pink)',
          marginBottom: 18,
        }}>
          <Icon.Bookmark s={36} />
        </div>
        <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink)', marginBottom: 6, textAlign: 'center' }}>
          还没有生词卡片
        </div>
        <div style={{ fontSize: 14, color: 'var(--ink-mute)', textAlign: 'center', lineHeight: 1.5 }}>
          上传一张聊天截图，保存今天学到的新词吧。
        </div>
        <div style={{ marginTop: 22 }}>
          <PinkBtn full={false} size="md" leftIcon={<Icon.Camera s={16} />}>上传聊天截图</PinkBtn>
        </div>
      </div>
      <TabBar active="卡片库" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SETTINGS
// ─────────────────────────────────────────────────────────────
function SettingsScreen() {
  const SectionTitle = ({ children }) => (
    <div style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--ink-mute)', letterSpacing: 0.8, padding: '20px 22px 8px' }}>{children}</div>
  );
  const Row = ({ icon, iconBg, iconColor, title, sub, right, last }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
      borderBottom: last ? 'none' : '0.5px solid var(--line)',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 9,
        background: iconBg, color: iconColor,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, color: 'var(--ink)', fontWeight: 500 }}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: 'var(--ink-mute)', marginTop: 2 }}>{sub}</div>}
      </div>
      {right ?? <Icon.ChevR s={14} />}
    </div>
  );
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingBottom: 4, padding: '54px 22px 8px' }}>
        <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--ink)' }}>设置</div>
      </div>
      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 120 }}>
        {/* Privacy hero */}
        <div style={{ padding: '0 22px' }}>
          <div style={{
            background: 'linear-gradient(140deg, var(--bg-lavender) 0%, var(--bg-soft) 100%)',
            borderRadius: 20, padding: 18,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
              <span style={{
                width: 32, height: 32, borderRadius: 10, background: '#fff', color: 'var(--lavender)',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon.Lock s={18} /></span>
              <span style={{ fontSize: 15, fontWeight: 700, color: 'var(--ink)' }}>你的聊天，留在你手里</span>
            </div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.55 }}>
              原始截图不会长期保存；卡片只存在本机；不保存完整解析历史。
            </div>
          </div>
        </div>

        <SectionTitle>隐私与数据</SectionTitle>
        <div style={{ background: '#fff', margin: '0 22px', borderRadius: 18 }}>
          <Row icon={<Icon.Lock s={16} />} iconBg="#EFEAFA" iconColor="#7860B3" title="原始截图处理" sub="OCR 后立即丢弃，不留存" />
          <Row icon={<Icon.Bookmark s={16} />} iconBg="#FCEAEF" iconColor="var(--pink-deep)" title="卡片存储位置" sub="本机数据库" />
          <Row icon={<Icon.Sparkle s={16} />} iconBg="#FFEFE7" iconColor="#C8633F" title="AI 解析说明" sub="确认后的文本会发送至模型" />
          <Row icon={<Icon.Trash s={16} />} iconBg="#F1ECEE" iconColor="#776975" title="清除所有卡片" right={<span style={{ fontSize: 13, color: 'var(--pink-deep)' }}>清除</span>} last />
        </div>

        <SectionTitle>关于</SectionTitle>
        <div style={{ background: '#fff', margin: '0 22px', borderRadius: 18 }}>
          <Row icon={<Icon.Info s={16} />} iconBg="#E2F4EA" iconColor="#3F8F66" title="오늘의 시그널 · Today's Signal" sub="韩语聊天截图学习助手" />
          <Row icon={<Icon.Heart s={14} />} iconBg="#FCEAEF" iconColor="var(--pink-deep)" title="版本" right={<span style={{ fontSize: 13, color: 'var(--ink-mute)' }}>1.0.0 (MVP)</span>} />
          <Row icon={<Icon.Bubble s={16} />} iconBg="#EFEAFA" iconColor="#7860B3" title="反馈与建议" last />
        </div>

        <div style={{ textAlign: 'center', padding: '32px 22px 0', fontSize: 11, color: 'var(--ink-faint)' }}>
          Made for K-pop fans learning 한국어 ♡
        </div>
      </div>
      <TabBar active="设置" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// LOADING STATE (analysis in progress)
// ─────────────────────────────────────────────────────────────
function LoadingScreen() {
  return (
    <div style={{ height: '100%', background: 'var(--bg-page)', position: 'relative' }}>
      <AppNav title="解析中" />
      <div style={{ padding: '20px 22px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: 'calc(100% - 100px)' }}>
        {/* pulsing sparkle */}
        <div style={{ position: 'relative', width: 140, height: 140, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 32 }}>
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'radial-gradient(circle, #FFD8E1 0%, transparent 60%)', animation: 'ts-pulse 2s ease-in-out infinite' }} />
          <div style={{ position: 'absolute', inset: 20, borderRadius: '50%', border: '1.5px dashed var(--pink)', animation: 'ts-spin 6s linear infinite' }} />
          <div style={{
            width: 72, height: 72, borderRadius: 24,
            background: 'linear-gradient(140deg, #FFB6C7, #F58CA0)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: '#fff', boxShadow: '0 12px 30px -8px rgba(245,140,160,0.6)',
          }}><Icon.Sparkle s={32} /></div>
        </div>
        <div style={{ fontSize: 17, fontWeight: 700, color: 'var(--ink)' }}>正在读懂今天的聊天信号…</div>
        <div style={{ fontSize: 13, color: 'var(--ink-mute)', marginTop: 8, textAlign: 'center', lineHeight: 1.5 }}>
          AI 在分析每条气泡的<br/>翻译、词尾和语气
        </div>

        {/* step ticks */}
        <div style={{ display: 'flex', gap: 8, marginTop: 28 }}>
          {['解析气泡', '提取生词', '检查语气'].map((s, i) => (
            <div key={i} style={{
              padding: '6px 12px', borderRadius: 999,
              background: i < 2 ? 'var(--bg-mint)' : 'var(--pink-tint)',
              color: i < 2 ? '#3F8F66' : 'var(--pink-deep)',
              fontSize: 11.5, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 4,
            }}>
              {i < 2 ? <Icon.Check s={11} /> : <span style={{ width: 8, height: 8, borderRadius: 4, background: 'var(--pink)' }} />}
              {s}
            </div>
          ))}
        </div>
      </div>
      <style>{`
        @keyframes ts-pulse { 0%,100% { transform: scale(0.95); opacity: 0.8; } 50% { transform: scale(1.1); opacity: 1; } }
        @keyframes ts-spin { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}

Object.assign(window, {
  HomeScreen, ConfirmScreen, AnalysisScreen, CardPreviewModal,
  LibraryScreen, LibraryEmptyScreen, SettingsScreen, LoadingScreen,
});
