/-  *seer
::
::  Seer's browser UI is deliberately server-rendered.  HTMX is the only
::  client-side runtime: links and forms ask the agent for fresh HTML and
::  replace #seer-app.  Everything still works as ordinary HTML without it.
::
|%
+$  page
  $%  [%review ~]
      [%inbox ~]
      [%stacks ~]
      [%subscriptions ~]
      [%stack owner=@p name=@tas]
  ==
::
++  render
  |=  $:  our=@p
          stacks=(map @tas stack)
          subscriptions=(map [@p @tas] stack)
          captures=(map @tas capture)
          questions=(map @tas card-question)
          models=(map @tas assistant-model)
          changes=(map @tas change-request)
          reviews=(list review)
          =page
          notice=(unit @t)
      ==
  ^-  manx
  =/  stack-count=@ud  (lent ~(tap by stacks))
  =/  subscription-count=@ud  (lent ~(tap by subscriptions))
  =/  pending-count=@ud
    =/  rows=(list [@tas capture])  ~(tap by captures)
    |-
    ?~  rows  0
    (add (lent ~(tap by proposals.i.rows)) $(rows t.rows))
  =/  completed-count=@ud
    =/  rows=(list [@tas capture])  ~(tap by captures)
    |-
    ?~  rows  0
    (add ?:(=(%complete status.+.i.rows) 1 0) $(rows t.rows))
  =/  open-change-count=@ud
    =/  rows=(list [@tas change-request])  ~(tap by changes)
    |-
    ?~  rows  0
    =/  open=?
      ?|  =(%pending status.+.i.rows)
          =(%working status.+.i.rows)
          =(%ready status.+.i.rows)
          =(%failed status.+.i.rows)
      ==
    (add ?:(open 1 0) $(rows t.rows))
  =/  inbox-count=@ud  (add pending-count open-change-count)
  =/  library-active=?
    ?|  ?=(%stacks -.page)
        ?=(%stack -.page)
    ==
  =<  document
  |%
  ++  document
    ^-  manx
    :-  [%html ~]
    :~
      ;head
        ;meta(charset "utf-8");
        ;meta
          =name     "viewport"
          =content  "width=device-width, initial-scale=1, viewport-fit=cover"
          ;
        ==
        ;meta(name "theme-color", content "#f7f7f6", media "(prefers-color-scheme: light)");
        ;meta(name "theme-color", content "#111110", media "(prefers-color-scheme: dark)");
        ;link(rel "icon", type "image/png", href "/apps/seer/tile.png");
        ;title: Seer
        ;script(src "https://unpkg.com/htmx.org@2.0.2");
        ;style:'''
               :root {
                 color-scheme: light dark;
                 --bg: #f7f7f6;
                 --surface: #ffffff;
                 --surface-2: #efefed;
                 --line: #d8d8d4;
                 --line-strong: #a6a6a0;
                 --ink: #191918;
                 --muted: #6f6f69;
                 --soft: #9a9a93;
                 --focus: #334dde;
                 --danger: #b42318;
                 --success-bg: #e8f4e9;
                 --success-line: #9fc5a3;
                 --chrome: rgba(247, 247, 246, .92);
                 --shadow: 0 1px 2px rgba(25, 25, 24, .05), 0 8px 24px rgba(25, 25, 24, .04);
               }
               @media (prefers-color-scheme: dark) {
                 :root {
                   --bg: #111110;
                   --surface: #181817;
                   --surface-2: #242422;
                   --line: #383835;
                   --line-strong: #666660;
                   --ink: #f0f0ed;
                   --muted: #aaa9a2;
                   --soft: #777770;
                   --focus: #8899ff;
                   --danger: #ff8a80;
                   --success-bg: #18271a;
                   --success-line: #46694a;
                   --chrome: rgba(17, 17, 16, .92);
                   --shadow: 0 1px 2px rgba(0, 0, 0, .28), 0 8px 24px rgba(0, 0, 0, .16);
                 }
               }
               * { box-sizing: border-box; }
               html { background: var(--bg); color: var(--ink); font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; font-size: 15px; }
               body { margin: 0; min-height: 100vh; -webkit-font-smoothing: antialiased; }
               a { color: inherit; }
               button, input, textarea { font: inherit; }
               button, .button {
                 align-items: center; background: var(--ink); border: 1px solid var(--ink);
                 border-radius: 4px; color: var(--bg); cursor: pointer; display: inline-flex;
                 font-size: .86rem; font-weight: 650; justify-content: center;
                 min-height: 2.6rem; padding: .62rem .9rem; text-decoration: none;
               }
               button:hover, .button:hover { filter: invert(12%); }
               button:focus-visible, .button:focus-visible, input:focus-visible, textarea:focus-visible, summary:focus-visible, a:focus-visible {
                 outline: 2px solid var(--focus); outline-offset: 2px;
               }
               button.secondary, .button.secondary { background: var(--surface); border-color: var(--line); color: var(--ink); }
               button.danger { background: transparent; border-color: var(--line); color: var(--danger); }
               input, textarea, select {
                 background: var(--surface); border: 1px solid var(--line); border-radius: 3px;
                 color: var(--ink); padding: .72rem .78rem; width: 100%;
               }
               input:hover, textarea:hover, select:hover { border-color: var(--line-strong); }
               textarea { line-height: 1.5; min-height: 7.5rem; resize: vertical; }
               label { color: var(--muted); display: grid; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .75rem; gap: .4rem; }
               form { display: grid; gap: .85rem; }
               h1, h2, h3, p { margin: 0; }
               h1 { font-size: clamp(1.8rem, 4vw, 2.45rem); font-weight: 650; letter-spacing: -.035em; line-height: 1.08; }
               h2 { font-size: 1.05rem; font-weight: 650; letter-spacing: -.015em; }
               h3 { font-size: .95rem; font-weight: 650; }
               .app-shell { display: grid; grid-template-columns: 15.5rem minmax(0, 1fr); min-height: 100vh; }
               .sidebar { background: var(--surface-2); border-right: 1px solid var(--line); display: flex; flex-direction: column; min-height: 100vh; padding: 1.2rem .75rem; position: sticky; top: 0; }
               .brand { display: block; font-size: 1.05rem; font-weight: 700; padding: .65rem .75rem 1.4rem; text-decoration: none; }
               .brand-sub { color: var(--muted); display: block; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .68rem; font-weight: 400; margin-top: .25rem; }
               .primary-nav { border-top: 1px solid var(--line); display: grid; }
               .nav-link { align-items: center; border-bottom: 1px solid var(--line); color: var(--muted); display: flex; gap: .75rem; justify-content: space-between; padding: .8rem .75rem; text-decoration: none; }
               .nav-link:hover { background: var(--surface); color: var(--ink); }
               .nav-link.active { box-shadow: inset 2px 0 0 var(--ink); color: var(--ink); }
               .nav-count { color: var(--soft); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .72rem; }
               .sidebar-foot { color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .7rem; margin-top: auto; padding: 1rem .75rem 0; }
               .workspace { min-width: 0; position: relative; }
               .request-status { background: var(--ink); height: 3px; left: 0; opacity: 0; position: absolute; right: 0; top: 0; transition: opacity .15s ease .12s; z-index: 2; }
               .request-status.htmx-request { opacity: 1; }
               .content { margin: 0 auto; max-width: 980px; padding: 3.4rem 3.5rem 7rem; }
               .page-head { align-items: end; border-bottom: 1px solid var(--line); display: flex; gap: 2rem; justify-content: space-between; margin-bottom: 1.5rem; padding-bottom: 1.35rem; }
               .page-copy { display: grid; gap: .45rem; }
               .kicker, .eyebrow { color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .7rem; letter-spacing: .06em; text-transform: uppercase; }
               .muted { color: var(--muted); line-height: 1.5; }
               .stat { min-width: 5rem; text-align: right; }
               .count { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 1.8rem; line-height: 1; }
               .meta { color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .7rem; }
               .section { margin-top: 1.5rem; }
               .panel, .card { background: var(--surface); border: 1px solid var(--line); border-radius: 4px; padding: 1.15rem; }
               .form-panel { display: grid; gap: 1rem; margin-top: 1.5rem; }
               .form-head { display: grid; gap: .25rem; }
               .two { display: grid; gap: .8rem; grid-template-columns: repeat(2, minmax(0, 1fr)); }
               .stack-list { background: var(--surface); border: 1px solid var(--line); border-radius: 4px; overflow: hidden; }
               .stack-row + .stack-row { border-top: 1px solid var(--line); }
               .stack-link { align-items: center; display: flex; gap: 1rem; justify-content: space-between; min-height: 4.6rem; padding: 1rem 1.1rem; text-decoration: none; }
               .stack-link:hover { background: var(--surface-2); }
               .stack-name { display: grid; gap: .28rem; min-width: 0; }
               .row-end { align-items: end; color: var(--muted); display: grid; flex: none; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .7rem; gap: .25rem; text-align: right; }
               .flash { background: var(--success-bg); border: 1px solid var(--success-line); border-radius: 3px; margin-bottom: 1rem; padding: .8rem 1rem; }
               .empty { background: var(--surface); border: 1px dashed var(--line-strong); color: var(--muted); display: grid; gap: .55rem; padding: 2.2rem 1.4rem; text-align: center; }
               .review-card { background: var(--surface); border: 1px solid var(--line); border-radius: 4px; margin: 0 auto; max-width: 760px; }
               .review-head { align-items: start; border-bottom: 1px solid var(--line); display: flex; gap: 1rem; justify-content: space-between; padding: 1rem 1.2rem; }
               .pill { border: 1px solid var(--line); border-radius: 999px; color: var(--muted); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .68rem; padding: .25rem .5rem; white-space: nowrap; }
               .prompt { font-family: Georgia, "Times New Roman", serif; font-size: clamp(1.35rem, 3vw, 1.85rem); line-height: 1.45; padding: 2.2rem 1.5rem; white-space: pre-wrap; }
               details.reveal { border-top: 1px solid var(--line); }
               details.reveal > summary { cursor: pointer; font-size: .86rem; font-weight: 650; list-style-position: inside; padding: 1rem 1.2rem; }
               .answer { border-top: 1px solid var(--line); font-family: Georgia, "Times New Roman", serif; line-height: 1.6; padding: 1.5rem; white-space: pre-wrap; }
               .grades { border-top: 1px solid var(--line); display: grid; grid-template-columns: repeat(4, 1fr); }
               .grades form { display: block; }
               .grades form + form { border-left: 1px solid var(--line); }
               .grades button { background: var(--surface); border: 0; border-radius: 0; color: var(--ink); min-height: 3rem; text-transform: capitalize; width: 100%; }
               .grades form:nth-child(3) button { background: var(--ink); color: var(--bg); }
               .stack-head { align-items: start; display: flex; gap: 1rem; justify-content: space-between; }
               .breadcrumb { color: var(--muted); display: inline-block; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .72rem; margin-bottom: 1rem; text-decoration: none; }
               .breadcrumb:hover { color: var(--ink); }
               .action-row { display: flex; flex-wrap: wrap; gap: .55rem; }
               .stack-layout { align-items: start; display: grid; gap: 1rem; grid-template-columns: minmax(0, 1.25fr) minmax(19rem, .75fr); margin-top: 1.5rem; }
               .editor-column { display: grid; gap: 1rem; }
               .editor-column .section { margin-top: 0; }
               .item-list { padding: 0; }
               .item { padding: 1.1rem; }
               .item + .item { border-top: 1px solid var(--line); }
               .item details { margin-top: .7rem; }
               .item details > summary { color: var(--muted); cursor: pointer; font-size: .8rem; }
               .item .prompt { font-family: inherit; font-size: 1rem; padding: 1rem 0; }
               .item .answer { font-family: inherit; font-size: .9rem; padding: 1rem 0 0; }
               .item-actions { align-items: center; display: flex; flex-wrap: wrap; gap: .5rem; margin-top: .9rem; }
               .ai-card { border-top: 1px solid var(--line); display: grid; gap: .85rem; margin-top: 1rem; padding-top: 1rem; }
               .ai-head { align-items: center; display: flex; gap: 1rem; justify-content: space-between; }
               .ai-history { display: grid; gap: .75rem; }
               .ai-turn { background: var(--surface-2); border-radius: 3px; display: grid; gap: .55rem; padding: .85rem; }
               .ai-question { font-weight: 650; line-height: 1.45; }
               .ai-answer { border-top: 1px solid var(--line); line-height: 1.55; padding-top: .55rem; white-space: pre-wrap; }
               .ai-revision { border-top: 1px solid var(--line); padding-top: .55rem; }
               .ai-revision > summary { color: var(--muted); cursor: pointer; font-size: .78rem; font-weight: 650; }
               .ai-diff { display: grid; gap: .65rem; grid-template-columns: repeat(2, minmax(0, 1fr)); padding-top: .75rem; }
               .ai-version { border-left: 2px solid var(--line-strong); display: grid; gap: .4rem; padding-left: .7rem; }
               .ai-version p { font-size: .82rem; line-height: 1.5; margin: 0; white-space: pre-wrap; }
               .ai-waiting { color: var(--muted); font-size: .82rem; }
               .ai-form { background: transparent; display: grid; gap: .7rem; }
               .ai-form-row { align-items: end; display: grid; gap: .65rem; grid-template-columns: 7rem minmax(0, 1fr) minmax(15rem, 19rem) auto; }
               .ai-form textarea { min-height: 3rem; }
               .ai-model-empty { border: 1px dashed var(--line-strong); color: var(--muted); font-size: .84rem; line-height: 1.5; padding: .8rem; }
               .inline { display: inline; }
               .inline button { width: auto; }
               .danger-zone { background: transparent; }
               .capture-list { display: grid; gap: 1rem; }
               .capture-history { margin-top: 2.2rem; }
               .capture { background: var(--surface); border: 1px solid var(--line); border-radius: 4px; overflow: hidden; }
               .capture-head { align-items: start; border-bottom: 1px solid var(--line); display: flex; gap: 1rem; justify-content: space-between; padding: 1.15rem; }
               .capture-copy { display: grid; gap: .35rem; min-width: 0; }
               .capture-meta { align-items: center; color: var(--muted); display: flex; flex-wrap: wrap; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .68rem; gap: .4rem .7rem; }
               .proposal { padding: 1.15rem; }
               .proposal + .proposal { border-top: 1px solid var(--line); }
               .proposal-head { align-items: start; display: flex; gap: 1rem; justify-content: space-between; }
               .proposal-body { display: grid; gap: .9rem; margin-top: 1rem; }
               .proposal-prompt { font-family: Georgia, "Times New Roman", serif; font-size: 1.15rem; line-height: 1.5; white-space: pre-wrap; }
               .proposal-answer { background: var(--surface-2); border-left: 2px solid var(--line-strong); line-height: 1.55; padding: .85rem 1rem; white-space: pre-wrap; }
               .provenance { border-top: 1px solid var(--line); color: var(--muted); display: grid; font-size: .82rem; gap: .4rem; padding-top: .8rem; }
               .decision-row { align-items: center; display: flex; flex-wrap: wrap; gap: .55rem; justify-content: flex-end; }
               .decision-row form { display: block; }
               .proposal-conflict { color: var(--danger); font-size: .82rem; line-height: 1.45; }
               .command-panel { display: grid; gap: 1rem; }
               .command-form { border-top: 1px solid var(--line); padding-top: 1rem; }
               .command-controls { align-items: end; display: grid; gap: .7rem; grid-template-columns: minmax(9rem, .6fr) minmax(16rem, 1.4fr) auto; }
               .change-list { display: grid; gap: .75rem; }
               .change-body { padding: 1rem 1.15rem 1.15rem; }
               .operation-list { display: grid; gap: .55rem; }
               .operation { border: 1px solid var(--line); border-radius: 3px; display: grid; gap: .65rem; padding: .8rem; }
               .operation-head { align-items: center; display: flex; gap: .6rem; justify-content: space-between; }
               .operation p { line-height: 1.5; }
               .mobile-only { display: none; }
               .compose-trigger { cursor: pointer; }
               .compose-body { display: grid; gap: 1rem; }
               .hidden { display: none; }
               .app-footer { border-top: 1px solid var(--line); margin-top: 3rem; padding-top: 1rem; }
               @media (max-width: 850px) {
                 .app-shell { grid-template-columns: 12.5rem minmax(0, 1fr); }
                 .content { padding-left: 2rem; padding-right: 2rem; }
                 .stack-layout { grid-template-columns: 1fr; }
               }
               @media (max-width: 650px) {
                 * { -webkit-tap-highlight-color: transparent; }
                 html { font-size: 16px; }
                 body { overscroll-behavior-y: none; }
                 .app-shell { display: block; min-height: 100dvh; padding-bottom: calc(4.45rem + env(safe-area-inset-bottom)); }
                 .sidebar { display: contents; }
                 .brand {
                   align-items: center; backdrop-filter: blur(18px); -webkit-backdrop-filter: blur(18px);
                   background: var(--chrome); border-bottom: 1px solid var(--line); display: flex;
                   height: calc(3.65rem + env(safe-area-inset-top)); justify-content: space-between;
                   left: 0; padding: calc(.7rem + env(safe-area-inset-top)) 1rem .7rem;
                   position: fixed; right: 0; top: 0; z-index: 30;
                 }
                 .brand-sub { display: block; font-size: .62rem; margin: 0; }
                 .primary-nav {
                   backdrop-filter: blur(18px); -webkit-backdrop-filter: blur(18px);
                   background: var(--chrome); border: 0; border-top: 1px solid var(--line);
                   bottom: 0; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr));
                   left: 0; padding-bottom: env(safe-area-inset-bottom); position: fixed;
                   right: 0; z-index: 30;
                 }
                 .nav-link {
                   border: 0; border-right: 1px solid var(--line); color: var(--muted);
                   display: grid; gap: .15rem; justify-items: center; min-height: 4.4rem;
                   padding: .72rem .25rem .62rem; position: relative;
                 }
                 .nav-link:last-child { border-right: 0; }
                 .nav-link.active { background: var(--surface); box-shadow: inset 0 2px 0 var(--ink); }
                 .nav-count { font-size: .62rem; line-height: 1; }
                 .sidebar-foot { display: none; }
                 .workspace { min-height: 100dvh; }
                 .request-status { position: fixed; z-index: 40; }
                 .content {
                   max-width: none; padding: calc(5rem + env(safe-area-inset-top)) 1rem
                   calc(6.5rem + env(safe-area-inset-bottom));
                 }
                 .page-head { align-items: end; gap: 1rem; margin-bottom: 1.25rem; padding-bottom: 1.1rem; }
                 .page-copy { gap: .35rem; min-width: 0; }
                 .page-copy .muted { font-size: .9rem; }
                 h1 { font-size: 1.65rem; letter-spacing: -.04em; }
                 h2 { font-size: 1rem; }
                 .kicker, .eyebrow { font-size: .62rem; letter-spacing: .075em; }
                 .count { font-size: 1.55rem; }
                 .stat { min-width: 4.2rem; }
                 .meta { font-size: .65rem; }
                 button, .button { border-radius: 6px; font-size: .88rem; min-height: 3rem; touch-action: manipulation; }
                 input, textarea, select { border-radius: 6px; font-size: 1rem; min-height: 3rem; padding: .8rem .85rem; }
                 textarea { min-height: 8.5rem; }
                 form { gap: 1rem; }
                 label { font-size: .72rem; gap: .45rem; }
                 .desktop-only { display: none; }
                 .mobile-only { display: block; }
                 .panel, .card, .stack-list, .review-card, .mobile-compose {
                   border-radius: 9px; box-shadow: var(--shadow);
                 }
                 .stack-list { overflow: clip; }
                 .stack-link { min-height: 4.9rem; padding: 1rem; }
                 .stack-name { gap: .22rem; }
                 .row-end { font-size: .62rem; }
                 .empty { border-style: solid; border-radius: 9px; padding: 2rem 1.1rem; }
                 .mobile-compose {
                   background: var(--surface); border: 1px solid var(--line); margin-top: 1rem;
                   overflow: hidden;
                 }
                 .compose-trigger {
                   align-items: center; display: flex; justify-content: space-between;
                   list-style: none; min-height: 4.4rem; padding: .85rem 1rem;
                 }
                 .compose-trigger::-webkit-details-marker { display: none; }
                 .compose-trigger:hover { background: var(--surface-2); }
                 .compose-title { display: grid; gap: .2rem; }
                 .compose-trigger::after {
                   color: var(--muted); content: "+"; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
                   font-size: 1.15rem; font-weight: 400; line-height: 1;
                 }
                 details[open] > .compose-trigger::after { content: "−"; }
                 .compose-body { border-top: 1px solid var(--line); padding: 1rem; }
                 .two { grid-template-columns: 1fr; }
                 .flash {
                   border-radius: 7px; font-size: .86rem; margin-bottom: 1rem;
                   padding: .75rem .85rem;
                 }
                 .review-card { margin: 0; max-width: none; }
                 .review-head { padding: .9rem 1rem; }
                 .prompt {
                   align-items: center; display: flex; font-size: 1.45rem;
                   min-height: 12rem; padding: 1.5rem 1.1rem;
                 }
                 details.reveal > summary { min-height: 3.4rem; padding: 1rem; touch-action: manipulation; }
                 .answer { padding: 1.2rem 1.1rem; }
                 .grades { grid-template-columns: repeat(4, minmax(0, 1fr)); }
                 .grades form + form { border-left: 1px solid var(--line); border-top: 0; }
                 .grades button { font-size: .72rem; min-height: 3.25rem; padding: .5rem .15rem; }
                 .stack-head { display: grid; gap: 1rem; }
                 .breadcrumb { display: block; margin-bottom: .8rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
                 .action-row { width: 100%; }
                 .action-row form, .action-row button { width: 100%; }
                 .stack-layout { gap: 1rem; grid-template-columns: 1fr; margin-top: 1rem; }
                 .item { padding: 1rem; }
                 .item details > summary { align-items: center; display: flex; min-height: 2.75rem; touch-action: manipulation; }
                 .item-actions { display: grid; grid-template-columns: 1fr auto; }
                 .ai-form-row { grid-template-columns: 1fr; }
                 .ai-form-row button { width: 100%; }
                 .ai-diff { grid-template-columns: 1fr; }
                 .item-actions form:first-child, .item-actions form:first-child button { width: 100%; }
                 .editor-column { gap: 1rem; }
                 .settings-disclosure { box-shadow: none; }
                 .settings-disclosure .compose-trigger { min-height: 3.7rem; }
                 .danger-zone { margin-top: 0; }
                 .capture { border-radius: 9px; box-shadow: var(--shadow); }
                 .capture-head { padding: 1rem; }
                 .proposal { padding: 1rem; }
                 .proposal-head { display: grid; gap: .6rem; }
                 .decision-row { display: grid; grid-template-columns: 1fr 1fr; width: 100%; }
                 .decision-row form, .decision-row button { width: 100%; }
                 .command-controls { grid-template-columns: 1fr; }
                 .command-controls button { width: 100%; }
                 .app-footer { display: none; }
               }
               '''
      ==
      ;body
        =hx-boost   "true"
        =hx-target  "#seer-app"
        =hx-select  "#seer-app"
        =hx-swap    "outerHTML show:top"
        ;main#seer-app.app-shell
          =hx-indicator  "#request-status"
          ;aside.sidebar
            ;a.brand(href "/apps/seer/review")
              ;span: Seer
              ;span.brand-sub: spaced repetition
            ==
            ;nav.primary-nav(aria-label "Primary")
              ;a
                =class         ?:(?=(%review -.page) "nav-link active" "nav-link")
                =aria-current  ?:(?=(%review -.page) "page" "false")
                =href          "/apps/seer/review"
                ;span: Review
                ;span.nav-count: {<(lent reviews)>}
              ==
              ;a
                =class         ?:(?=(%inbox -.page) "nav-link active" "nav-link")
                =aria-current  ?:(?=(%inbox -.page) "page" "false")
                =href          "/apps/seer/inbox"
                ;span: Inbox
                ;span.nav-count: {<inbox-count>}
              ==
              ;a
                =class         ?:(library-active "nav-link active" "nav-link")
                =aria-current  ?:(library-active "page" "false")
                =href          "/apps/seer/stacks"
                ;span: Library
                ;span.nav-count: {<stack-count>}
              ==
              ;a
                =class         ?:(?=(%subscriptions -.page) "nav-link active" "nav-link")
                =aria-current  ?:(?=(%subscriptions -.page) "page" "false")
                =href          "/apps/seer/subscriptions"
                ;span: Shared
                ;span.nav-count: {<subscription-count>}
              ==
            ==
            ;div.sidebar-foot: {(scow %p our)}
          ==
          ;div.workspace
            ;div#request-status.request-status(role "status", aria-label "Loading");
            ;div.content
              ;+
              ?~  notice
                ;div.hidden;
              ;div.flash(role "status"): {(trip u.notice)}
              ;+  page-body
              ;footer.app-footer.meta
                ;p: Local-first · served by %seer
              ==
            ==
          ==
        ==
      ==
    ==
  ::
  ++  page-body
    ^-  manx
    ?-  -.page
      %review         review-page
      %inbox          inbox-page
      %stacks         stacks-page
      %subscriptions  subscriptions-page
      %stack          (stack-page owner.page name.page)
    ==
  ::
  ++  inbox-page
    ^-  manx
    =/  sessions=(list [@tas capture])  ~(tap by captures)
    =/  requests=(list [@tas change-request])  ~(tap by changes)
    =/  available-models=(list [@tas assistant-model])  ordered-assistant-models
    =/  waiting=?  (changes-waiting requests)
    ;section
      =hx-get      "/apps/seer/inbox"
      =hx-trigger  ?:(waiting "every 2s" "none")
      ;div.page-head
        ;div.page-copy
          ;div.kicker: command surface
          ;h1: Change Seer
          ;p.muted: Describe an outcome. The assistant drafts a reviewable plan; your ship changes only after approval.
        ==
        ;div.stat
          ;div.count: {<open-change-count>}
          ;div.meta: open plans
        ==
      ==
      ;section.panel.command-panel
        ;div.form-head
          ;div.kicker: prompt → plan → approval
          ;h2: What should change?
          ;p.muted: Library plans use typed operations with stale-state checks. Functionality requests become implementation briefs for Codex or Claude and never rewrite the desk silently.
        ==
        ;+
        ?~  available-models
          ;div.ai-model-empty: No signed-in model provider is available. Sign in with Codex or Claude Code on this machine; the bridge will publish its models here automatically.
        ;form.command-form
          =method   "post"
          =action   "/apps/seer/actions/request-change"
          =hx-post  "/apps/seer/actions/request-change"
          ;label
            ;span: instruction
            ;textarea(name "prompt", required "", placeholder "Rename the MCP stack to “Seer AI integration”, then tighten the card about approval boundaries.");
          ==
          ;div.command-controls
            ;label
              ;span: target
              ;select(name "target")
                ;option(value "library"): My library
                ;option(value "desk"): Seer itself · proposal only
              ==
            ==
            ;label
              ;span: plan with
              ;select(name "model", required "")
                ;*
                %+  turn  available-models
                |=  [model-id=@tas profile=assistant-model]
                ;option(value (tas-tape model-id), title (trip description.profile)): {(model-option-label profile)}
              ==
            ==
            ;button(type "submit"): Draft plan
          ==
        ==
      ==
      ;+
      ?~  requests
        ;div.hidden;
      ;section.change-list.section
        ;div.form-head
          ;div.kicker: review queue
          ;h2: Change requests
        ==
        ;*
        %+  turn  requests
        |=  [change-id=@tas request=change-request]
        (change-row change-id request)
      ==
      ;section.capture-history
        ;div.form-head
          ;div.kicker: card captures
          ;h2: Capture inbox
          ;p.muted: Codex and Claude draft cards here. Nothing enters review until you approve it.
        ==
        ;+
        ?:  =(0 pending-count)
          ;div.empty
            ;h2: Your inbox is clear
            ;p: Ask an AI to “learn this with Seer” and its source-grounded drafts will appear here.
            ;a.button.secondary(href "/apps/seer/stacks"): Open library
          ==
        ;div.capture-list
          ;*
          %+  turn  sessions
          |=  [capture-id=@tas session=capture]
          (capture-section capture-id session)
        ==
      ==
      ;+
      ?:  =(0 completed-count)
        ;div.hidden;
      ;section.capture-history
        ;div.form-head
          ;div.kicker: memory trail
          ;h2: Recent captures
          ;p.muted: Completed AI sessions stay visible across clients. Approved cards keep their source trail.
        ==
        ;div.stack-list.section
          ;*
          %+  turn  sessions
          |=  [capture-id=@tas session=capture]
          (capture-history-row capture-id session)
        ==
      ==
    ==
  ::
  ++  change-row
    |=  [change-id=@tas request=change-request]
    ^-  manx
    ;article.capture.change-request
      ;div.capture-head
        ;div.capture-copy
          ;div.eyebrow: {(trip target.request)} · {(role-name role.profile.request)} · {(trip label.profile.request)}
          ;h3: {(trip prompt.request)}
          ;div.capture-meta
            ;span: {(tas-tape change-id)}
            ;span: {<(lent operations.request)>} operations
          ==
        ==
        ;span.pill: {(trip status.request)}
      ==
      ;div.proposal-body.change-body
        ;+
        ?-  status.request
          %pending
            ;div.ai-waiting: Waiting for the local assistant bridge to claim this request…
          %working
            ;div.ai-waiting: {(trip label.profile.request)} is reading the current state and drafting a plan…
          %ready
            ;div
              ;div.proposal-answer: {(trip summary.request)}
              ;+
              ?:  =(%desk target.request)
                ;div.provenance
                  ;p: This is an implementation brief, not an executable desk patch. It is durable and available to AI clients through MCP.
                  ;details.reveal
                    ;summary: Inspect implementation brief
                    ;div.proposal-answer: {(trip artifact.request)}
                  ==
                ==
              ;div.operation-list
                ;*
                %+  turn  operations.request
                |=  op=state-operation
                (operation-row op)
              ==
              ;div.decision-row
                ;form.inline
                  =method   "post"
                  =action   "/apps/seer/actions/reject-change"
                  =hx-post  "/apps/seer/actions/reject-change"
                  ;input(type "hidden", name "change-id", value (tas-tape change-id));
                  ;button.danger(type "submit"): Reject
                ==
                ;+
                ?:  =(%library target.request)
                  ;form.inline(hx-confirm "Apply every operation in this plan to your Seer library?")
                    =method   "post"
                    =action   "/apps/seer/actions/apply-change"
                    =hx-post  "/apps/seer/actions/apply-change"
                    ;input(type "hidden", name "change-id", value (tas-tape change-id));
                    ;button(type "submit"): Approve and apply
                  ==
                ;span.pill: proposal only
              ==
            ==
          %failed
            ;div
              ;div.proposal-conflict: {(trip response.request)}
              ;div.decision-row
                ;form.inline
                  =method   "post"
                  =action   "/apps/seer/actions/retry-change"
                  =hx-post  "/apps/seer/actions/retry-change"
                  ;input(type "hidden", name "change-id", value (tas-tape change-id));
                  ;button.secondary(type "submit"): Rebuild plan
                ==
                ;form.inline
                  =method   "post"
                  =action   "/apps/seer/actions/reject-change"
                  =hx-post  "/apps/seer/actions/reject-change"
                  ;input(type "hidden", name "change-id", value (tas-tape change-id));
                  ;button.danger(type "submit"): Reject
                ==
              ==
            ==
          %applied
            (change-result change-id request "Applied")
          %rejected
            (change-result change-id request "Rejected")
        ==
      ==
    ==
  ::
  ++  operation-row
    |=  op=state-operation
    ^-  manx
    ;article.operation
      ;div.operation-head
        ;span.pill: {(trip kind.op)}
        ;span.meta: /{(tas-tape stack.op)}{?:(!=(card.op 0) "/{(tas-tape card.op)}" "")}
      ==
      ;+
      ?-  kind.op
        %create-stack  ;p: Create stack “{(trip title.op)}”.
        %rename-stack  ;p: Rename “{(trip original-title.op)}” to “{(trip title.op)}”.
        %delete-stack  ;p: Delete stack “{(trip original-title.op)}” and all of its cards.
        %create-card   (card-operation-detail op %.n)
        %edit-card     (card-operation-detail op %.y)
        %delete-card   ;p: Delete “{(trip original-title.op)}”.
        %queue-card    ;p: Queue “{(trip original-title.op)}” for review.
      ==
    ==
  ::
  ++  card-operation-detail
    |=  [op=state-operation editing=?]
    ^-  manx
    ;details.reveal
      ;summary: {?:(editing "Inspect before and after" "Inspect new card")}
      ;div.ai-diff
        ;+
        ?:  editing
          ;div.ai-version
            ;div.eyebrow: before
            ;p: {(trip original-title.op)}
            ;p: {(trip original-front.op)}
            ;p: {(trip original-back.op)}
          ==
        ;div.hidden;
        ;div.ai-version
          ;div.eyebrow: after
          ;p: {(trip title.op)}
          ;p: {(trip front.op)}
          ;p: {(trip back.op)}
        ==
      ==
    ==
  ::
  ++  change-result
    |=  [change-id=@tas request=change-request label=tape]
    ^-  manx
    ;div
      ;div.ai-answer: {label} · {(trip summary.request)}
      ;div.decision-row
        ;form.inline
          =method   "post"
          =action   "/apps/seer/actions/delete-change"
          =hx-post  "/apps/seer/actions/delete-change"
          ;input(type "hidden", name "change-id", value (tas-tape change-id));
          ;button.danger(type "submit"): Forget
        ==
      ==
    ==
  ::
  ++  capture-section
    |=  [capture-id=@tas session=capture]
    ^-  manx
    =/  drafts=(list [@tas proposal])  ~(tap by proposals.session)
    ?~  drafts
      ;div.hidden;
    ;article.capture
      ;div.capture-head
        ;div.capture-copy
          ;div.eyebrow: {(tas-tape capture-id)} · {(trip created-by.session)}
          ;h2: {(trip title.session)}
          ;p.muted: {(trip goal.session)}
          ;div.capture-meta
            ;span: {<(lent drafts)>} pending
            ;span: {<approved.session>} approved
            ;span: {<rejected.session>} rejected
            ;span: source · {(trip source.session)}
          ==
        ==
        ;form.inline(hx-confirm "Reject every remaining proposal in this capture?")
          =method   "post"
          =action   "/apps/seer/actions/discard-capture"
          =hx-post  "/apps/seer/actions/discard-capture"
          ;input(type "hidden", name "capture", value (tas-tape capture-id));
          ;button.danger(type "submit"): Clear
        ==
      ==
      ;div
        ;*
        %+  turn  drafts
        |=  [proposal-id=@tas draft=proposal]
        (proposal-row capture-id proposal-id draft)
      ==
    ==
  ::
  ++  proposal-row
    |=  [capture-id=@tas proposal-id=@tas draft=proposal]
    ^-  manx
    =/  target=(unit stack)  (~(get by stacks) stack.draft)
    =/  conflict=?
      ?~  target  %.y
      (~(has by items.u.target) card.draft)
    ;article.proposal
      ;div.proposal-head
        ;div.capture-copy
          ;div.eyebrow: {(tas-tape stack.draft)} / {(tas-tape card.draft)}
          ;h3: {(trip title.draft)}
        ==
        ;span.pill: {(trip created-by.draft)}
      ==
      ;div.proposal-body
        ;div.proposal-prompt: {(trip front.draft)}
        ;details.reveal
          ;summary: Inspect proposed answer
          ;div.proposal-answer: {(trip back.draft)}
        ==
        ;div.provenance
          ;p: Why this matters · {(trip rationale.draft)}
          ;p: Source · {(trip source.draft)}
        ==
        ;+
        ?:  conflict
          ;div.proposal-conflict: This target stack is missing or the card ID is already in use. Reject this draft or ask the AI to stage a corrected ID.
        ;div.hidden;
        ;div.decision-row
          ;form.inline
            =method   "post"
            =action   "/apps/seer/actions/reject-proposal"
            =hx-post  "/apps/seer/actions/reject-proposal"
            ;input(type "hidden", name "capture", value (tas-tape capture-id));
            ;input(type "hidden", name "proposal", value (tas-tape proposal-id));
            ;button.danger(type "submit"): Reject
          ==
          ;+
          ?:  conflict
            ;span.hidden;
          ;form.inline
            =method   "post"
            =action   "/apps/seer/actions/approve-proposal"
            =hx-post  "/apps/seer/actions/approve-proposal"
            ;input(type "hidden", name "capture", value (tas-tape capture-id));
            ;input(type "hidden", name "proposal", value (tas-tape proposal-id));
            ;button(type "submit"): Approve card
          ==
        ==
      ==
    ==
  ::
  ++  capture-history-row
    |=  [capture-id=@tas session=capture]
    ^-  manx
    ?.  =(%complete status.session)
      ;div.hidden;
    ;article.stack-row
      ;div.stack-link
        ;div.stack-name
          ;h3: {(trip title.session)}
          ;div.meta: {(tas-tape capture-id)} · {(trip created-by.session)} · {(trip source.session)}
        ==
        ;div.row-end
          ;span: {<approved.session>} approved · {<rejected.session>} rejected
          ;form.inline(hx-confirm "Remove this completed capture from history?")
            =method   "post"
            =action   "/apps/seer/actions/delete-capture"
            =hx-post  "/apps/seer/actions/delete-capture"
            ;input(type "hidden", name "capture", value (tas-tape capture-id));
            ;button.danger(type "submit"): Forget
          ==
        ==
      ==
    ==
  ::
  ++  review-page
    ^-  manx
    =/  total  (lent reviews)
    ;section
      ;div.page-head
        ;div.page-copy
          ;div.kicker: session
          ;h1: Review
          ;p.muted: Work through the cards due now.
        ==
        ;div.stat
          ;div.count: {<total>}
          ;div.meta: cards ready
        ==
      ==
      ;+
      ?~  reviews
        ;div.empty
          ;h2: Nothing due
          ;p: Your review queue is clear.
          ;a.button.secondary(href "/apps/seer/stacks"): Open library
        ==
      (review-card i.reviews)
    ==
  ::
  ++  review-card
    |=  rev=review
    ^-  manx
    =/  maybe-stack  (lookup-stack who.rev stack.rev)
    ?~  maybe-stack
      ;div.empty: This review points to a stack that is no longer available.
    =/  maybe-item  (~(get by items.u.maybe-stack) item.rev)
    ?~  maybe-item
      ;div.empty: This review points to a card that is no longer available.
    =/  current  u.maybe-item
    ;article.review-card
      ;div.review-head
        ;div
          ;div.eyebrow: {(scow %p who.rev)} / {(tas-tape stack.rev)}
          ;h2: {(trip title.content.current)}
        ==
        ;span.pill: box {<box.learn.current>}
      ==
      ;div.prompt: {(trip (body-text front.content.current))}
      ;details.reveal
        ;summary: Reveal answer
        ;div.answer: {(trip (body-text back.content.current))}
        ;div.grades
          ;+  (grade-form rev %again "again")
          ;+  (grade-form rev %hard "hard")
          ;+  (grade-form rev %good "good")
          ;+  (grade-form rev %easy "easy")
        ==
      ==
      ;+  (question-panel who.rev stack.rev item.rev "/apps/seer/review" 'review')
    ==
  ::
  ++  grade-form
    |=  [rev=review grade=recall-grade label=tape]
    ^-  manx
    ;form
      =method     "post"
      =action     "/apps/seer/actions/answer"
      =hx-post    "/apps/seer/actions/answer"
      =hx-target  "#seer-app"
      =hx-select  "#seer-app"
      =hx-swap    "outerHTML"
      ;input(type "hidden", name "owner", value (scow %p who.rev));
      ;input(type "hidden", name "stack", value (tas-tape stack.rev));
      ;input(type "hidden", name "item", value (tas-tape item.rev));
      ;input(type "hidden", name "answer", value label);
      ;button(type "submit"): {label}
    ==
  ::
  ++  stacks-page
    ^-  manx
    =/  stack-list  ~(tap by stacks)
    ;section
      ;div.page-head
        ;div.page-copy
          ;div.kicker: local
          ;h1: Library
          ;p.muted: Stacks stored on this ship.
        ==
        ;div.stat
          ;div.count: {<(lent stack-list)>}
          ;div.meta: stacks
        ==
      ==
      ;div.stack-list
        ;+
        ?~  stack-list
          ;div.empty
            ;h2: No stacks yet
            ;p: Create one below to start collecting cards.
          ==
        ;div
          ;*
          %+  turn  stack-list
          |=  [name=@tas =stack]
          (stack-card our name stack %.y)
        ==
      ==
      ;section.panel.form-panel.desktop-only
        ;div.form-head
          ;div.kicker: create
          ;h2: New stack
          ;p.muted: Give it a stable ID and a display name.
        ==
        ;+  new-stack-form
      ==
      ;details.mobile-compose.mobile-only
        ;summary.compose-trigger
          ;span.compose-title
            ;span.kicker: create
            ;strong: New stack
          ==
        ==
        ;div.compose-body
          ;p.muted: Give it a stable ID and a name you will recognize.
          ;+  new-stack-form
        ==
      ==
    ==
  ::
  ++  subscriptions-page
    ^-  manx
    =/  sub-list  ~(tap by subscriptions)
    ;section
      ;div.page-head
        ;div.page-copy
          ;div.kicker: network
          ;h1: Shared
          ;p.muted: Stacks followed from other ships.
        ==
        ;div.stat
          ;div.count: {<(lent sub-list)>}
          ;div.meta: subscriptions
        ==
      ==
      ;div.stack-list
        ;+
        ?~  sub-list
          ;div.empty
            ;h2: No subscriptions
            ;p: Follow a public stack by ship and stack ID.
          ==
        ;div
          ;*
          %+  turn  sub-list
          |=  [[owner=@p name=@tas] =stack]
          (stack-card owner name stack %.n)
        ==
      ==
      ;section.panel.form-panel.desktop-only
        ;div.form-head
          ;div.kicker: subscribe
          ;h2: Follow a remote stack
        ==
        ;+  subscription-form
      ==
      ;details.mobile-compose.mobile-only
        ;summary.compose-trigger
          ;span.compose-title
            ;span.kicker: subscribe
            ;strong: Follow a stack
          ==
        ==
        ;div.compose-body
          ;p.muted: Add a public stack from another ship.
          ;+  subscription-form
        ==
      ==
    ==
  ::
  ++  stack-card
    |=  [owner=@p name=@tas =stack owned=?]
    ^-  manx
    ;article.stack-row
      ;a.stack-link(href (stack-url owner name))
        ;div.stack-name
          ;h2: {(stack-title stack)}
          ;div.meta: /{(tas-tape name)}
        ==
        ;div.row-end
          ;span: {<(lent ~(tap by `(map @tas item)`items.stack))>} cards
          ;span: Open
        ==
      ==
    ==
  ::
  ++  stack-page
    |=  [owner=@p name=@tas]
    ^-  manx
    =/  maybe-stack  (lookup-stack owner name)
    ?~  maybe-stack
      ;section.empty
        ;div.kicker: not found
        ;h1: Stack unavailable
        ;p: This stack is missing or the link is invalid.
        ;a.button.secondary(href "/apps/seer/stacks"): Back to library
      ==
    =/  selected=stack  u.maybe-stack
    =/  item-count=@ud  (lent ~(tap by `(map @tas item)`items.selected))
    =/  has-cards=?  (gth item-count 0)
    ;section
      ;a.breadcrumb(href "/apps/seer/stacks"): Library / {(tas-tape name)}
      ;div.stack-head
        ;div.page-copy
          ;h1: {(stack-title selected)}
          ;p.muted: {<item-count>} cards · owned by {(scow %p owner)}
        ==
        ;div.action-row
          ;+  (stack-actions owner name has-cards)
        ==
      ==
      ;div.stack-layout
        ;+  (card-list owner name selected)
        ;+  (stack-editor owner name has-cards)
      ==
    ==
  ::
  ++  stack-actions
    |=  [owner=@p name=@tas has-cards=?]
    ^-  manx
    ?:  =(owner our)
      ?.  has-cards
        ;span.meta: Add a card to start reviewing.
      ;form.inline
        =method   "post"
        =action   "/apps/seer/actions/review-stack"
        =hx-post  "/apps/seer/actions/review-stack"
        ;input(type "hidden", name "stack", value (tas-tape name));
        ;button(type "submit"): Start review
      ==
    ;form.inline
      =method   "post"
      =action   "/apps/seer/actions/copy-stack"
      =hx-post  "/apps/seer/actions/copy-stack"
      ;input(type "hidden", name "owner", value (scow %p owner));
      ;input(type "hidden", name "stack", value (tas-tape name));
      ;button(type "submit"): Copy stack
    ==
  ::
  ++  card-list
    |=  [owner=@p name=@tas =stack]
    ^-  manx
    =/  rows=(list [@tas item])
      ~(tap by `(map @tas item)`items.stack)
    ?~  rows
      ;div.empty: This stack has no cards yet.
    ;div.card.item-list
      ;*
      %+  turn  rows
      |=  [item-name=@tas =item]
      (item-row owner name item-name item =(owner our))
    ==
  ::
  ++  stack-editor
    |=  [owner=@p name=@tas has-cards=?]
    ^-  manx
    ?.  =(owner our)
      ;div.hidden;
    ;div.editor-column
      ;section.panel.form-panel.desktop-only
        ;div.form-head
          ;div.kicker: create
          ;h2: Add a card
        ==
        ;+  (add-card-form name)
      ==
      ;+
      ?:  has-cards
        (mobile-card-composer name %.n)
      (mobile-card-composer name %.y)
      ;section.panel.danger-zone.desktop-only
        ;div.kicker: stack settings
        ;+  (delete-stack-form name)
      ==
      ;details.mobile-compose.mobile-only.settings-disclosure
        ;summary.compose-trigger
          ;span.compose-title
            ;span.kicker: manage
            ;strong: Stack settings
          ==
        ==
        ;div.compose-body
          ;p.muted: Permanently remove this stack and every card in it.
          ;+  (delete-stack-form name)
        ==
      ==
    ==
  ::
  ++  mobile-card-composer
    |=  [name=@tas opened=?]
    ^-  manx
    ?:  opened
      ;details.mobile-compose.mobile-only(open "")
        ;summary.compose-trigger
          ;span.compose-title
            ;span.kicker: create
            ;strong: Add your first card
          ==
        ==
        ;div.compose-body
          ;p.muted: Start with one prompt and the answer you want to remember.
          ;+  (add-card-form name)
        ==
      ==
    ;details.mobile-compose.mobile-only
      ;summary.compose-trigger
        ;span.compose-title
          ;span.kicker: create
          ;strong: Add a card
        ==
      ==
      ;div.compose-body
        ;+  (add-card-form name)
      ==
    ==
  ::
  ++  new-stack-form
    ^-  manx
    ;form
      =method   "post"
      =action   "/apps/seer/actions/new-stack"
      =hx-post  "/apps/seer/actions/new-stack"
      ;div.two
        ;label
          ;span: stack ID
          ;input(name "name", required "", pattern "[a-z0-9][a-z0-9-]*", placeholder "urbit-basics", autocomplete "off", autocapitalize "none", spellcheck "false");
        ==
        ;label
          ;span: display name
          ;input(name "title", required "", placeholder "Urbit basics");
        ==
      ==
      ;button(type "submit"): Create stack
    ==
  ::
  ++  subscription-form
    ^-  manx
    ;form
      =method   "post"
      =action   "/apps/seer/actions/import"
      =hx-post  "/apps/seer/actions/import"
      ;div.two
        ;label
          ;span: ship
          ;input(name "ship", required "", pattern "~[a-z-]+", placeholder "~sampel-palnet", autocomplete "off", autocapitalize "none", spellcheck "false");
        ==
        ;label
          ;span: stack
          ;input(name "stack", required "", pattern "[a-z0-9][a-z0-9-]*", placeholder "urbit-basics", autocomplete "off", autocapitalize "none", spellcheck "false");
        ==
      ==
      ;button(type "submit"): Follow stack
    ==
  ::
  ++  add-card-form
    |=  name=@tas
    ^-  manx
    ;form
      =method   "post"
      =action   "/apps/seer/actions/new-item"
      =hx-post  "/apps/seer/actions/new-item"
      ;input(type "hidden", name "stack", value (tas-tape name));
      ;div.two
        ;label
          ;span: card ID
          ;input(name "name", required "", pattern "[a-z0-9][a-z0-9-]*", placeholder "what-is-nock", autocomplete "off", autocapitalize "none", spellcheck "false");
        ==
        ;label
          ;span: title
          ;input(name "title", required "", placeholder "What is Nock?");
        ==
      ==
      ;label
        ;span: front
        ;textarea(name "front", required "", placeholder "Question or prompt");
      ==
      ;label
        ;span: back
        ;textarea(name "back", required "", placeholder "Answer");
      ==
      ;button(type "submit"): Add card
    ==
  ::
  ++  delete-stack-form
    |=  name=@tas
    ^-  manx
    ;form.inline(hx-confirm "Delete this stack and all of its cards?")
      =method     "post"
      =action     "/apps/seer/actions/delete-stack"
      =hx-post    "/apps/seer/actions/delete-stack"
      ;input(type "hidden", name "stack", value (tas-tape name));
      ;button.danger(type "submit"): Delete stack
    ==
  ::
  ++  item-row
    |=  [owner=@p stack-name=@tas item-name=@tas =item owned=?]
    ^-  manx
    ;article.item
      ;h3: {(trip title.content.item)}
      ;details
        ;summary: show card
        ;div.prompt.section: {(trip (body-text front.content.item))}
        ;div.answer: {(trip (body-text back.content.item))}
      ==
      ;+  (question-panel owner stack-name item-name (stack-url owner stack-name) 'stack')
      ;+  (item-actions owner stack-name item-name)
    ==
  ::
  ++  question-panel
    |=  [owner=@p stack-name=@tas item-name=@tas poll-url=tape return=@t]
    ^-  manx
    =/  rows=(list [@tas card-question])
      (card-questions owner stack-name item-name)
    =/  waiting=?  (questions-waiting rows)
    ?:  waiting
      ;section.ai-card
        =hx-get      poll-url
        =hx-trigger  "every 2s"
        =hx-target   "#seer-app"
        =hx-select   "#seer-app"
        =hx-swap     "outerHTML"
        ;+  (question-panel-body owner stack-name item-name return rows)
      ==
    ;section.ai-card
      ;+  (question-panel-body owner stack-name item-name return rows)
    ==
  ::
  ++  question-panel-body
    |=  $:  owner=@p
            stack-name=@tas
            item-name=@tas
            return=@t
            rows=(list [@tas card-question])
        ==
    ^-  manx
    =/  available-models=(list [@tas assistant-model])
      ordered-assistant-models
    ;div
      ;div.ai-head
        ;div
          ;div.eyebrow: assistant panel
          ;h3: Ask or improve this card
        ==
        ;span.pill: {<`@ud`(lent available-models)>} models · OMP
      ==
      ;+
      ?~  rows
        ;div.hidden;
      ;div.ai-history.section
        ;*
        %+  turn  rows
        |=  [question-id=@tas job=card-question]
        (question-row question-id job return)
      ==
      ;+
      ?~  available-models
        ;div.ai-model-empty.section
          No signed-in model provider is available. Sign in with Codex or Claude Code on this machine; the local bridge will publish its models here automatically.
        ==
      ;form.ai-form.section
        =method   "post"
        =action   "/apps/seer/actions/ask-card"
        =hx-post  "/apps/seer/actions/ask-card"
        ;input(type "hidden", name "owner", value (scow %p owner));
        ;input(type "hidden", name "stack", value (tas-tape stack-name));
        ;input(type "hidden", name "item", value (tas-tape item-name));
        ;input(type "hidden", name "return", value (trip return));
        ;div.ai-form-row
          ;label
            ;span: action
            ;select(name "mode")
              ;option(value "ask"): Ask
              ;+
              ?:  =(owner our)
                ;option(value "edit"): Edit
              ;option(value "edit", disabled ""): Edit · owned only
            ==
          ==
          ;label
            ;span: request
            ;textarea(name "question", required "", placeholder "Ask a question or describe what should change.");
          ==
          ;label
            ;span: answer with
            ;select(name "model", required "")
              ;*
              %+  turn  available-models
              |=  [model-id=@tas profile=assistant-model]
              ;option(value (tas-tape model-id), title (trip description.profile)): {(model-option-label profile)}
            ==
          ==
          ;button(type "submit"): Send
        ==
      ==
    ==
  ::
  ++  question-row
    |=  [question-id=@tas job=card-question return=@t]
    ^-  manx
    ;article.ai-turn
      ;div.ai-head
        ;div.meta: {(trip mode.job)} · {(role-name role.profile.job)} · {(trip label.profile.job)}
        ;span.pill: {(trip status.job)}
      ==
      ;div.ai-question: {(trip prompt.job)}
      ;+
      ?-  status.job
        %pending
          ;div.ai-waiting: Waiting for the local assistant bridge…
        %working
          ?:  =(%edit mode.job)
            ;div.ai-waiting: {(trip label.profile.job)} is revising the card…
          ;div.ai-waiting: {(trip label.profile.job)} is thinking…
        %answered
          ?:  =(%ask mode.job)
            ;div.ai-answer: {(trip response.job)}
          ;div
            ;div.ai-answer: {(trip response.job)}
            ;details.ai-revision
              ;summary: Review the edit
              ;div.ai-diff
                ;div.ai-version
                  ;div.eyebrow: before
                  ;p: {(trip title.job)}
                  ;p: {(trip (body-text front.job))}
                  ;p: {(trip (body-text back.job))}
                ==
                ;div.ai-version
                  ;div.eyebrow: after
                  ;p: {(trip result-title.job)}
                  ;p: {(trip result-front.job)}
                  ;p: {(trip result-back.job)}
                ==
              ==
            ==
          ==
        %failed
          ;div
            ;div.proposal-conflict: {(trip response.job)}
            ;div.item-actions
              ;form.inline
                =method   "post"
                =action   "/apps/seer/actions/retry-card-question"
                =hx-post  "/apps/seer/actions/retry-card-question"
                ;input(type "hidden", name "question-id", value (tas-tape question-id));
                ;input(type "hidden", name "owner", value (scow %p owner.job));
                ;input(type "hidden", name "stack", value (tas-tape stack.job));
                ;input(type "hidden", name "return", value (trip return));
                ;button.secondary(type "submit"): Try again
              ==
              ;form.inline
                =method   "post"
                =action   "/apps/seer/actions/delete-card-question"
                =hx-post  "/apps/seer/actions/delete-card-question"
                ;input(type "hidden", name "question-id", value (tas-tape question-id));
                ;input(type "hidden", name "owner", value (scow %p owner.job));
                ;input(type "hidden", name "stack", value (tas-tape stack.job));
                ;input(type "hidden", name "return", value (trip return));
                ;button.danger(type "submit"): Dismiss
              ==
            ==
          ==
      ==
    ==
  ::
  ++  ordered-assistant-models
    ^-  (list [@tas assistant-model])
    %+  sort  ~(tap by models)
    |=  [a=[@tas assistant-model] b=[@tas assistant-model]]
    =/  a-rank=@ud  (role-rank role.+.a)
    =/  b-rank=@ud  (role-rank role.+.b)
    ?:  =(a-rank b-rank)
      (lth -.a -.b)
    (lth a-rank b-rank)
  ::
  ++  role-rank
    |=  role=omp-role
    ^-  @ud
    ?-  role
      %smol     0
      %default  1
      %slow     2
    ==
  ::
  ++  role-name
    |=  role=omp-role
    ^-  tape
    ?-  role
      %smol     "Fast"
      %default  "Balanced"
      %slow     "Deep"
    ==
  ::
  ++  model-option-label
    |=  profile=assistant-model
    ^-  tape
    =/  provider-name=tape
      ?-  provider.profile
        %codex   "Codex"
        %claude  "Claude Code"
      ==
    "{(role-name role.profile)} · {(trip label.profile)} · {provider-name}"
  ::
  ++  card-questions
    |=  [owner=@p stack-name=@tas item-name=@tas]
    ^-  (list [@tas card-question])
    %+  skim  ~(tap by questions)
    |=  [question-id=@tas job=card-question]
    ?&  =(owner owner.job)
        =(stack-name stack.job)
        =(item-name card.job)
    ==
  ::
  ++  questions-waiting
    |=  rows=(list [@tas card-question])
    ^-  ?
    ?~  rows  %.n
    ?|  =(%pending status.+.i.rows)
        =(%working status.+.i.rows)
        $(rows t.rows)
    ==
  ::
  ++  changes-waiting
    |=  rows=(list [@tas change-request])
    ^-  ?
    ?~  rows  %.n
    ?|  =(%pending status.+.i.rows)
        =(%working status.+.i.rows)
        $(rows t.rows)
    ==
  ::
  ++  item-actions
    |=  [owner=@p stack-name=@tas item-name=@tas]
    ^-  manx
    ?.  =(owner our)
      ;div.hidden;
    ;div.item-actions
      ;form.inline
        =method   "post"
        =action   "/apps/seer/actions/raise-item"
        =hx-post  "/apps/seer/actions/raise-item"
        ;input(type "hidden", name "stack", value (tas-tape stack-name));
        ;input(type "hidden", name "item", value (tas-tape item-name));
        ;button.secondary(type "submit"): Review next
      ==
      ;form.inline(hx-confirm "Delete this card?")
        =method     "post"
        =action     "/apps/seer/actions/delete-item"
        =hx-post    "/apps/seer/actions/delete-item"
        ;input(type "hidden", name "stack", value (tas-tape stack-name));
        ;input(type "hidden", name "item", value (tas-tape item-name));
        ;button.danger(type "submit"): Delete
      ==
    ==
  ::
  ++  lookup-stack
    |=  [owner=@p name=@tas]
    ^-  (unit stack)
    ?:  =(owner our)
      (~(get by stacks) name)
    (~(get by subscriptions) [owner name])
  ::
  ++  stack-title
    |=  =stack
    ^-  tape
    ?.  ?=(%.y -.info.stack)
      (tas-tape name.stack)
    (trip title.p.info.stack)
  ::
  ++  body-text
    |=  raw=@t
    ^-  @t
    =/  marker  (find ";>" (trip raw))
    ?~  marker  raw
    =/  start  (add 3 u.marker)
    (cut 3 [start (met 3 raw)] raw)
  ::
  ++  tas-tape
    |=  value=@tas
    ^-  tape
    (trip value)
  ::
  ++  stack-url
    |=  [owner=@p name=@tas]
    ^-  tape
    "/apps/seer/stack/{(scow %p owner)}/{(tas-tape name)}"
  --
--
