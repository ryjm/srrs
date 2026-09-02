::  Behavioral tests for the %seer agent.
::
::  These drive the real agent:gall value built from /app/seer with a
::  fixed bowl, so they cover observable contracts: the versioned-state
::  migration chain, SM-2 review scheduling, the bridge HMAC proof
::  boundary (pinned to the cross-language fixture in
::  bridge/seer-ai-bridge.test.mjs), and change-operation validation.
::
::  Run on a ship with the desk installed:
::    -test /=seer=/tests ~
::
/-  *seer
/+  *test
/=  seer-agent  /app/seer
|%
++  fixed-now  ~2026.9.2
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    src  ~zod
    dap  %seer
    now  fixed-now
    byk  [~zod %seer da+fixed-now]
  ==
::  +ag: fresh agent core under the fixed bowl
::
++  ag  ~(. seer-agent bol)
::  +do: apply one %seer-action poke, keeping only the next core
::
++  do
  |=  [core=agent:gall act=action]
  ^-  agent:gall
  +:(on-poke:core %seer-action !>(act))
::  +do-noun: apply one %noun poke (dojo-style commands)
::
++  do-noun
  |=  [core=agent:gall a=*]
  ^-  agent:gall
  +:(on-poke:core %noun !>(a))
++  peek-logins
  |=  core=agent:gall
  ^-  (map @tas login-request)
  =/  res  (on-peek:core /x/logins)
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(map @tas login-request)) q.q.u.u.res))
++  peek-stack
  |=  [core=agent:gall name=@tas]
  ^-  (unit stack)
  =/  res  (on-peek:core /x/stacks/[name])
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(unit stack)) q.q.u.u.res))
++  peek-ai
  |=  core=agent:gall
  ^-  ai-state
  =/  res  (on-peek:core /x/ai-state)
  ?>  ?=([~ ~ *] res)
  (need ((soft ai-state) q.q.u.u.res))
::  +make-proof: the bridge's canonical HMAC construction
::
++  make-proof
  |=  [secret=@t action=@tas id=@tas worker=@t nonce=@t fields=(list @t)]
  ^-  @
  =/  parts=(list @t)
    (welp ~['seer-bridge-v1' `@t`action `@t`id worker nonce] fields)
  =/  payload=@t
    (crip (zing (turn parts |=(part=@t "{<(met 3 part)>}:{(trip part)}"))))
  (hmac-sha256t:hmac:crypto secret payload)
::  the exact proof the node bridge produces for this tuple
::  (bridge/seer-ai-bridge.test.mjs: cross-language HMAC fixture)
::
++  fixture-proof
  0x302.62aa.d179.84e6.9883.62ca.1c52.ce9e.4977.c0f7.2cc6.f465.a62f.e29c.46d2.e798
::
::  every legacy state version must land on the current head, and a
::  marker value must survive to prove the migration branch ran rather
::  than the fresh-install fallback.
::
++  test-state-migration
  ^-  tang
  =/  marker=login-request
    [%probe %codex %pending '' '' '' '' '' fixed-now fixed-now]
  =/  probe-logins  (malt ~[[%probe marker]])
  =/  old-twelve
    !>([%12 ~ ~ ~ ~ ~ ~ ~ ~ probe-logins '' ~ ~ ~])
  =/  old-thirteen
    !>([%13 ~ ~ ~ ~ ~ ~ ~ ~ probe-logins '' ~ ~ ~ ~ 0 ~ ~ ~])
  =/  from-twelve    +:(on-load:ag old-twelve)
  =/  from-thirteen  +:(on-load:ag old-thirteen)
  =/  resaved  +:(on-load:ag on-save:from-twelve)
  ;:  weld
    %+  expect-eq  !>(%.y)
    !>((~(has by (peek-logins from-twelve)) %probe))
  ::
    %+  expect-eq  !>(%.y)
    !>((~(has by (peek-logins from-thirteen)) %probe))
  ::
    %+  expect-eq  !>(14)
    !>(;;(@ud -.q:on-save:from-twelve))
  ::
    %+  expect-eq  !>(14)
    !>(;;(@ud -.q:on-save:from-thirteen))
  ::
    %+  expect-eq  !>(%.y)
    !>((~(has by (peek-logins resaved)) %probe))
  ==
::
::  SM-2: box walks the fixed intervals on %good and resets on %again.
::
++  test-sm2-scheduling
  ^-  tang
  =/  core  ag
  =.  core  (do core [%new-stack %s1 'Stack one' ~])
  =.  core
    (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =/  ans
    |=  [c=agent:gall g=recall-grade]
    (do c [%answered-item ~zod %s1 %c1 g])
  =.  core  (ans core %good)
  =/  l1=learn  learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  =.  core  (ans core %good)
  =/  l2=learn  learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  =.  core  (ans core %again)
  =/  l3=learn  learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  ;:  weld
    (expect-eq !>(1) !>(`@`box.l1))
    (expect-eq !>(~m15) !>(`@dr`interval.l1))
    (expect-eq !>(2) !>(`@`box.l2))
    (expect-eq !>(~d1) !>(`@dr`interval.l2))
    (expect-eq !>(0) !>(`@`box.l3))
    (expect-eq !>(~s5) !>(`@dr`interval.l3))
  ==
::
::  the agent must accept exactly the proof bytes the node bridge
::  computes, and reject a corrupted proof without advancing state.
::
++  test-bridge-proof-fixture
  ^-  tang
  =/  secret  '0123456789abcdef0123456789abcdef'
  =/  core  ag
  =.  core  (do-noun core [%set-bridge-capability secret])
  =.  core  (do core [%request-login %login-codex %codex])
  =.  core  (do core [%issue-bridge-nonce 'nonce-a'])
  =.  core
    %+  do  core
    :*  %claim-login  %login-codex  'worker-1'  'nonce-a'
        (make-proof secret %claim-login %login-codex 'worker-1' 'nonce-a' ~)
    ==
  =/  after-claim  (~(got by (peek-logins core)) %login-codex)
  =.  core  (do core [%issue-bridge-nonce 'nonce-bad'])
  =.  core
    %+  do  core
    :*  %post-login-challenge  %login-codex  'worker-1'
        'https://auth.openai.com/activate'  'ABCD-EFGH'
        'nonce-bad'  +(fixture-proof)
    ==
  =/  after-bad  (~(got by (peek-logins core)) %login-codex)
  =.  core  (do core [%issue-bridge-nonce 'nonce-fixture'])
  =.  core
    %+  do  core
    :*  %post-login-challenge  %login-codex  'worker-1'
        'https://auth.openai.com/activate'  'ABCD-EFGH'
        'nonce-fixture'  fixture-proof
    ==
  =/  after-fix  (~(got by (peek-logins core)) %login-codex)
  ;:  weld
    (expect-eq !>(%working) !>(status.after-claim))
    (expect-eq !>('worker-1') !>(worker.after-claim))
    (expect-eq !>(%working) !>(status.after-bad))
    (expect-eq !>(%challenge) !>(status.after-fix))
    (expect-eq !>('https://auth.openai.com/activate') !>(auth-url.after-fix))
    (expect-eq !>('ABCD-EFGH') !>(user-code.after-fix))
  ==
::
::  library change plans only accept well-shaped operations.
::
++  test-change-operation-validation
  ^-  tang
  =/  core  ag
  =.  core  (do core [%new-stack %s1 'Stack one' ~])
  =.  core
    (do core [%request-change %ch1 %library *assistant-model 'plan work'])
  =.  core  (do core [%claim-change %ch1 'worker-1'])
  =/  bad-op=state-operation
    [%create-card %s1 %c9 '' 'front' 'back' '' '' '']
  =/  good-op=state-operation
    [%create-card %s1 %c9 'Title' 'front' 'back' '' '' '']
  =.  core  (do core [%stage-change-operation %ch1 'worker-1' bad-op])
  =.  core  (do core [%stage-change-operation %ch1 'worker-1' good-op])
  =/  req  (~(got by changes:(peek-ai core)) %ch1)
  ;:  weld
    (expect-eq !>(%working) !>(status.req))
    (expect-eq !>(1) !>((lent operations.req)))
  ==
--
