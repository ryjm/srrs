::  behavioral tests for the %seer agent.
::
::  each test drives the real agent with a fixed bowl. Covered: revision
::  and recall behavior, authoritative operation replay, atomic plan
::  application, universal worker proof/lease fences, and bounded reads.
::
::  run on a ship with the desk installed:
::    -test /=seer=/tests ~
::
/-  mcp, *seer
/+  *test, *seer, mcp-contract=seer-mcp, effects=seer-effects
/=  seer-agent  /app/seer
|%
++  fixed-now  ~2026.9.2
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    src  ~zod
    dap  %seer
    sap  /gall/hood
    now  fixed-now
    byk  [~zod %seer da+fixed-now]
  ==
::  +ag: fresh agent core under the fixed bowl
::
++  ag
  =/  core  ~(. seer-agent bol)
  +:on-init:core
::  +do: apply one %seer-action poke, keeping only the next core
::
++  do
  |=  [core=agent:gall act=action]
  ^-  agent:gall
  (do-command core (command-for core act))
::  +do-noun: apply one %noun poke (dojo-style commands)
::
++  do-noun
  |=  [core=agent:gall a=*]
  ^-  agent:gall
  +:(on-poke:core %noun !>(a))
++  command-for
  |=  [core=agent:gall act=action]
  ^-  command
  (make-command (slav %da (peek-epoch core)) (scot %uv (shax (jam [on-save:core act]))) act)
++  do-command
  |=  [core=agent:gall cmd=command]
  ^-  agent:gall
  +:(on-poke:core %seer-action !>(cmd))
++  peek-receipt
  |=  [core=agent:gall cmd=command]
  ^-  json
  =/  query  [epoch.cmd operation.cmd `digest.cmd]
  =/  res  (on-peek:core /x/operation-result/[(scot %uv (jam query))])
  ?>  ?=([~ ~ *] res)
  (need ((soft json) q.q.u.u.res))
++  fixture-model
  ^-  assistant-model
  %*  .  *assistant-model
    id        %test-model
    provider  %codex
    role      %smol
    selector  'openai/test'
    model     'test'
    label     'Test'
    description  'Configured provider'
  ==
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
++  peek-version
  |=  [core=agent:gall kind=entity-kind who=@p scope=@tas id=@tas]
  ^-  (unit entity-version)
  =/  res  (on-peek:core /x/entity-version/[kind]/[(scot %p who)]/[scope]/[id])
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(unit entity-version)) q.q.u.u.res))
++  peek-work
  |=  [core=agent:gall kind=entity-kind scope=@tas id=@tas]
  ^-  (unit work-record)
  =/  res  (on-peek:core /x/work/[kind]/~zod/[scope]/[id])
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(unit work-record)) q.q.u.u.res))
++  peek-epoch
  |=  core=agent:gall
  ^-  @t
  =/  res  (on-peek:core /x/agent-context)
  ?>  ?=([~ ~ *] res)
  =/  jon  (need ((soft json) q.q.u.u.res))
  ?>  ?=(%o -.jon)
  =/  epoch  (~(got by p.jon) 'idempotency_epoch')
  ?>  ?=(%s -.epoch)
  p.epoch
++  peek-read
  |=  [core=agent:gall query=agent-read]
  ^-  json
  =/  res  (on-peek:core /x/agent-read/[(scot %uv (jam query))])
  ?>  ?=([~ ~ *] res)
  (need ((soft json) q.q.u.u.res))
++  peek-packet
  |=  [core=agent:gall id=@ux]
  ^-  json
  =/  res  (on-peek:core /x/context-packet/[(scot %ux id)]/[(scot %ud 262.144)])
  ?>  ?=([~ ~ *] res)
  (need ((soft json) q.q.u.u.res))
++  peek-snapshot
  |=  [core=agent:gall id=@ux bytes=@ud]
  ^-  json
  =/  res  (on-peek:core /x/evidence-snapshot/[(scot %ux id)]/0/[(scot %ud bytes)]/[(scot %ud 65.536)])
  ?>  ?=([~ ~ *] res)
  (need ((soft json) q.q.u.u.res))
++  at-time
  |=  [core=agent:gall now=@da]
  ^-  agent:gall
  =/  later  ~(. seer-agent %*(. bol now now))
  +:(on-load:later on-save:core)
++  take-clay
  |=  [core=agent:gall id=@tas generation=@ud content=@t]
  ^-  agent:gall
  =/  remote  ~(. seer-agent %*(. bol src ~nec))
  =.  core  +:(on-load:remote on-save:core)
  =/  acquired=acquired-context  [content %full ~]
  =.  core
    +:(on-agent:core [%shared-fetch id (scot %ud generation) ~] [%fact %noun !>([%1 'Clay fixture' %txt acquired])])
  +:(on-load:ag on-save:core)
++  read-query
  ^-  agent-read
  %*  .  *agent-read
    kind        %orientation
    projection  %metadata
    limit       20
    max-bytes   32.768
  ==
++  json-field
  |=  [value=json key=@t]
  ^-  json
  ?>  ?=(%o -.value)
  (~(got by p.value) key)
++  json-text
  |=  [value=json key=@t]
  ^-  @t
  =/  field  (json-field value key)
  ?>  ?=(%s -.field)
  p.field
++  json-rows
  |=  [value=json key=@t]
  ^-  (list json)
  =/  field  (json-field value key)
  ?>  ?=(%a -.field)
  p.field
::  +make-proof: the bridge's canonical hmac construction
::
++  make-proof
  |=  [secret=@t action=@tas id=@tas worker=@t nonce=@t epoch=@da operation=@t attempt=@ud lease=@ux fields=(list @t)]
  ^-  @
  ?>  ?=(^ fields)
  =/  parts=(list @t)
    %+  welp
      ~['seer-bridge-v2' `@t`action `@t`id worker nonce '2' (scot %da epoch) operation (decimal-text attempt) (scot %ux lease)]
    t.fields
  =/  payload=@t
    %-  crip
    %-  zing
    %+  turn  parts
    |=(part=@t "{(trip (decimal-text (met 3 part)))}:{(trip part)}")
  (hmac-sha256t:hmac:crypto secret payload)
++  bridge-test-secret  '0123456789abcdef0123456789abcdef'
++  bridge-command
  |=  [core=agent:gall act=action nonce=@t]
  ^-  command
  =/  request  (need (worker-request act))
  =/  key  (work-key ~zod act)
  =/  job=(unit work-record)
    ?~  key  ~
    (peek-work core kind.u.key scope.u.key id.u.key)
  =/  attempt=@ud  ?:(?|((claim-action act) ?=(%replace-assistant-models -.act)) 0 ?~(job 0 attempt.u.job))
  =/  lease=@ux  ?:(=(0 attempt) 0x0 ?~(job 0x0 lease.u.job))
  =/  epoch  (slav %da (peek-epoch core))
  =/  proof
    (make-proof bridge-test-secret -.act id.request worker.request nonce epoch nonce attempt lease fields.request)
  (make-command epoch nonce [%bridge-action worker.request nonce proof attempt lease act])
++  do-bridge
  |=  [core=agent:gall act=action nonce=@t]
  ^-  agent:gall
  =.  core  (do core [%issue-bridge-nonce nonce])
  (do-command core (bridge-command core act nonce))
::
::  A bounded read report survives freezing; it cannot overstate coverage.
::
++  test-library-read-report-is-authoritative-and-proof-bound
  ^-  tang
  =/  core  (do-noun ag [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%new-stack %selected 'Selected' ~])
  =.  core  (do core [%new-stack %unseen 'Unseen' ~])
  =.  core  (do core [%new-item ~zod ~zod %selected %c1 'Selected card' *perm-config 'Q' 'A'])
  =.  core  (do core [%new-item ~zod ~zod %unseen %c2 'Unseen card' *perm-config 'Other' 'Answer'])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'report-catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%request-change %coverage %library profile 'Rename selected stack' %.n])
  =.  core  (do core [%start-change %coverage])
  =.  core  (do-bridge core [%claim-change %coverage 'worker-1'] 'report-claim')
  =/  observations=(list entity-precondition)
    :~  [[%stack ~zod %root %selected] (peek-version core %stack ~zod %root %selected) %.y %.n]
        [[%card ~zod %selected %c1] (peek-version core %card ~zod %selected %c1) %.y %.n]
    ==
  =/  full  '{"scope":"local-library","complete":true,"omissions":[]}'
  =/  partial  '{"scope":"local-library","complete":false,"omissions":[{"scope":"stacks","reason":"page-incomplete","next_cursor":"more-stacks"}]}'
  =.  core  (do core [%issue-bridge-nonce 'report-full'])
  =/  overstated
    (bridge-command core [%prepare-change-packet %coverage 'worker-1' observations full ~ 65.536 24.000] 'report-full')
  =.  core  (do-command core overstated)
  =/  blocked  (need (peek-work core %change %root %coverage))
  =.  core  (do core [%issue-bridge-nonce 'report-tamper'])
  =/  signed
    (bridge-command core [%prepare-change-packet %coverage 'worker-1' observations partial ~ 65.536 24.000] 'report-tamper')
  =/  outer  payload.signed
  ?>  ?=(%bridge-action -.outer)
  =/  inner  ;;(action payload.outer)
  ?>  ?=(%prepare-change-packet -.inner)
  =/  changed  '{"scope":"local-library","complete":false,"omissions":[{"reason":"different-omission"}]}'
  =/  forged
    (make-command epoch.signed operation.signed outer(payload inner(read-report changed)))
  =.  core  (do-command core forged)
  =.  core
    (do-bridge core [%prepare-change-packet %coverage 'worker-1' observations partial ~ 65.536 24.000] 'report-freeze')
  =/  work  (need (peek-work core %change %root %coverage))
  =/  packet  (peek-packet core (need packet.work))
  =/  library  (need (de:json:html (json-text (json-field packet 'card') 'front')))
  =/  coverage  (json-field library 'source_coverage')
  ;:  weld
    (expect-eq !>('blocked') !>((json-text (peek-receipt core overstated) 'status')))
    (expect-eq !>('incomplete-library-observation') !>((json-text (peek-receipt core overstated) 'reason')))
    (expect-eq !>(~) !>(packet.blocked))
    (expect-eq !>(0) !>(invocations.blocked))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core forged) 'status')))
    (expect-eq !>(b+%.n) !>((json-field coverage 'complete')))
    (expect-eq !>(n+'1') !>((json-field coverage 'unobserved_stack_count')))
    (expect-eq !>(n+'1') !>((json-field coverage 'unobserved_card_count')))
    (expect-eq !>((need (de:json:html partial))) !>((json-field library 'read_report')))
    (expect-eq !>(0) !>(invocations.work))
  ==
::
::  sm-2: box walks the fixed intervals on %good and resets on %again.
::
++  test-sm2-scheduling
  ^-  tang
  =/  core  ag
  =.  core  (do core [%new-stack %s1 'Stack one' ~])
  =.  core
    %+  do  core
    :*  %new-item  ~zod  ~zod  %s1  %c1
        'Card'  *perm-config  'front'  'back'
    ==
  =/  ans
    |=  [c=agent:gall g=recall-grade]
    (do c [%answered-item ~zod %s1 %c1 g])
  =.  core  (ans core %good)
  =/  l1=learn
    learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  =.  core  (ans core %good)
  =/  l2=learn
    learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  =.  core  (ans core %again)
  =/  l3=learn
    learn:(~(got by items:(need (peek-stack core %s1))) %c1)
  ;:  weld
    (expect-eq !>(1) !>(`@`box.l1))
    (expect-eq !>(~m15) !>(`@dr`interval.l1))
    (expect-eq !>(2) !>(`@`box.l2))
    (expect-eq !>(~d1) !>(`@dr`interval.l2))
    (expect-eq !>(0) !>(`@`box.l3))
    (expect-eq !>(~s5) !>(`@dr`interval.l3))
  ==
::
::  A bad universal proof cannot publish a login challenge or consume nonce.
::
++  test-bridge-proof-boundary
  ^-  tang
  =/  core  (do-noun ag [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%request-login %login-codex %codex])
  =.  core  (do-bridge core [%claim-login %login-codex 'worker-1'] 'claim')
  =.  core  (do-bridge core [%checkpoint-work [%login ~zod %root %login-codex] 'worker-1' %provider-started] 'started')
  =.  core  (do core [%issue-bridge-nonce 'challenge'])
  =/  act=action  [%post-login-challenge %login-codex 'worker-1' 'https://auth.openai.com/activate' 'ABCD-EFGH']
  =/  good  (bridge-command core act 'challenge')
  =/  outer  (need ((soft $>(%bridge-action action)) payload.good))
  =/  bad  (make-command epoch.good 'bad-challenge' outer(proof +(proof.outer)))
  =.  core  (do-command core bad)
  =/  after-bad  (~(got by (peek-logins core)) %login-codex)
  =.  core  (do-command core good)
  =/  after-good  (~(got by (peek-logins core)) %login-codex)
  ;:  weld
    (expect-eq !>(%working) !>(status.after-bad))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core bad) 'status')))
    (expect-eq !>(%challenge) !>(status.after-good))
    (expect-eq !>('ABCD-EFGH') !>(user-code.after-good))
  ==
::
++  test-empty-catalog-replacement
  ^-  tang
  =/  core  (do-noun ag [%set-bridge-capability bridge-test-secret])
  =/  act=action  [%replace-assistant-models 'worker-1' ~]
  =.  core  (do core [%issue-bridge-nonce 'empty-catalog'])
  =/  cmd  (bridge-command core act 'empty-catalog')
  =.  core  (do-command core cmd)
  =/  receipt  (peek-receipt core cmd)
  ;:  weld
    (expect-eq !>('ok') !>((json-text receipt 'status')))
    (expect-eq !>('none') !>((json-text receipt 'effect')))
    (expect-eq !>(~) !>(models:(peek-ai core)))
  ==
::
++  test-claude-challenge-mcp-to-source
  ^-  tang
  =/  core  (do-noun ag [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%request-login %login-claude %claude])
  =.  core  (do-bridge core [%claim-login %login-claude 'worker-1'] 'claim')
  =.  core
    (do-bridge core [%checkpoint-work [%login ~zod %root %login-claude] 'worker-1' %provider-started] 'started')
  =/  auth-url  'https://claude.com/cai/oauth/authorize?state=opaque'
  =/  args=(map name:parameter:tool:mcp argument:tool:mcp)  ~
  =.  args
    %-  ~(gas by args)
    :~  ['login_id' %string 'login-claude']
        ['worker_id' %string 'worker-1']
        ['auth_url' %string auth-url]
        ['user_code' %string '']
    ==
  =/  accepted
    (do-bridge core (mutation-action:mcp-contract %post-login-challenge ~zod args ~) 'accepted')
  =/  wrong-host
    (~(put by args) 'auth_url' [%string 'https://claude.com.evil.example/cai/oauth/authorize?state=opaque'])
  =/  host-blocked
    (do-bridge core (mutation-action:mcp-contract %post-login-challenge ~zod wrong-host ~) 'wrong-host')
  =/  wrong-path
    (~(put by args) 'auth_url' [%string 'https://claude.com/cai/oauth/authorize-unrelated?state=opaque'])
  =/  path-blocked
    (do-bridge core (mutation-action:mcp-contract %post-login-challenge ~zod wrong-path ~) 'wrong-path')
  =/  delivered  (~(got by (peek-logins accepted)) %login-claude)
  =/  rejected-host  (~(got by (peek-logins host-blocked)) %login-claude)
  =/  rejected-path  (~(got by (peek-logins path-blocked)) %login-claude)
  ;:  weld
    (expect-eq !>(%challenge) !>(status.delivered))
    (expect-eq !>(auth-url) !>(auth-url.delivered))
    (expect-eq !>(%working) !>(status.rejected-host))
    (expect-eq !>(%working) !>(status.rejected-path))
    (expect-eq !>('') !>(auth-url.rejected-host))
    (expect-eq !>('') !>(auth-url.rejected-path))
  ==
::
++  test-atomic-change-validation
  ^-  tang
  =/  core  ag
  =/  stack-op=state-operation  [%create-stack %planned '' 'Planned' '' '' '' '' '']
  =/  card-op=state-operation  [%create-card %planned %card 'Card' 'front' 'back' '' '' '']
  =/  bad-op  card-op(title '')
  =/  fences=(list entity-precondition)
    ~[[[%stack ~zod %root %planned] ~ %.y %.n] [[%card ~zod %planned %card] ~ %.y %.y]]
  =/  invalid  (command-for core [%propose-change %bad 'Create' 'Create two entities' ~[stack-op bad-op] fences])
  =.  core  (do-command core invalid)
  =/  after-invalid  (peek-stack core %planned)
  =.  core  (do core [%propose-change %good 'Create' 'Create two entities' ~[stack-op card-op] fences])
  =/  staged  (peek-stack core %planned)
  =/  request  (~(got by changes:(peek-ai core)) %good)
  =/  query  read-query
  =/  described
    (snag 0 (json-rows (peek-read core query(kind %change, id `%good, projection %detail)) 'changes'))
  =.  core  (do core [%apply-change %good (need plan.request)])
  =/  committed  (need (peek-stack core %planned))
  ;:  weld
    (expect-eq !>('invalid') !>((json-text (peek-receipt core invalid) 'status')))
    (expect-eq !>(~) !>(after-invalid))
    (expect-eq !>(~) !>(staged))
    (expect-eq !>(~) !>((json-field described 'provider')))
    (expect-eq !>(~) !>((json-field described 'model_id')))
    (expect-eq !>(~) !>((json-field described 'model_role')))
    (expect-eq !>(%.y) !>((~(has by items.committed) %card)))
    (expect-eq !>(%.y) !>((~(has by review-items.committed) %card)))
  ==
::
++  test-operation-replay-and-retirement
  ^-  tang
  =/  core  ag
  =/  original  (make-command (slav %da (peek-epoch core)) 'same-operation' [%new-stack %once 'Original' ~])
  =.  core  (do-command core original)
  =/  receipt  (peek-receipt core original)
  =/  replayed  (do-command core original)
  =/  conflict  (make-command epoch.original operation.original [%new-stack %other 'Other' ~])
  =.  core  (do-command replayed conflict)
  =/  conflict-receipt  (peek-receipt core conflict)
  =.  core  (do core [%retire-operation-epoch ~])
  =.  core  (do-command core conflict)
  ;:  weld
    (expect-eq !>(receipt) !>((peek-receipt replayed original)))
    (expect-eq !>('conflict') !>((json-text conflict-receipt 'status')))
    (expect-eq !>(~) !>((peek-stack core %other)))
    (expect-eq !>('replay-expired') !>((json-text (peek-receipt core original) 'status')))
  ==
::
++  test-reset-epoch
  ^-  tang
  =/  current  ag
  =/  later-bowl  bol
  =/  later  ~(. seer-agent later-bowl(now (add fixed-now ~d1)))
  =/  restored  +:(on-load:later on-save:current)
  =/  fresh  +:on-init:later
  ;:  weld
    (expect-eq !>((peek-epoch current)) !>((peek-epoch restored)))
    (expect-eq !>(%.n) !>(=((peek-epoch current) (peek-epoch fresh))))
  ==
::
++  test-imported-content-revisions
  ^-  tang
  =/  peer-bowl  bol
  =/  peer  ~(. seer-agent peer-bowl(our ~nec, src ~nec))
  =.  peer  (do peer [%new-stack %s1 'Remote stack' ~])
  =.  peer
    (do peer [%new-item ~nec ~nec %s1 %c1 'A' *perm-config 'front' 'back'])
  =/  source  (need (peek-stack peer %s1))
  =/  core  +:(on-agent:ag /import/~nec/s1 [%fact %seer-stack !>(source)])
  =/  first  (need (peek-version core %card ~nec %s1 %c1))
  =.  peer  (do peer [%edit-item ~nec %s1 %c1 'B' *perm-config 'front' 'back'])
  =.  source  (need (peek-stack peer %s1))
  =.  core  +:(on-agent:core /import/~nec/s1 [%fact %seer-primary-delta !>([%update-stack ~nec source])])
  =/  changed  (need (peek-version core %card ~nec %s1 %c1))
  =.  peer  (do peer [%edit-item ~nec %s1 %c1 'A' *perm-config 'front' 'back'])
  =.  source  (need (peek-stack peer %s1))
  =.  core  +:(on-agent:core /import/~nec/s1 [%fact %seer-primary-delta !>([%update-stack ~nec source])])
  =/  restored  (need (peek-version core %card ~nec %s1 %c1))
  ;:  weld
    (expect-eq !>(%.y) !>((gth content-revision.changed content-revision.first)))
    (expect-eq !>(%.y) !>((gth content-revision.restored content-revision.changed)))
    (expect-eq !>(incarnation.first) !>(incarnation.restored))
  ==
::
++  test-content-review-and-incarnation
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core
    (do core [%new-item ~zod ~zod %s1 %c1 'A' *perm-config 'front' 'back'])
  =/  first  (need (peek-version core %card ~zod %s1 %c1))
  =/  first-stack  (need (peek-version core %stack ~zod %root %s1))
  =.  core  (do core [%answered-item ~zod %s1 %c1 %good])
  =/  graded  (need (peek-version core %card ~zod %s1 %c1))
  =/  graded-stack  (need (peek-version core %stack ~zod %root %s1))
  =.  core
    (do core [%edit-item ~zod %s1 %c1 'B' *perm-config 'front' 'back'])
  =/  edited  (need (peek-version core %card ~zod %s1 %c1))
  =.  core  +:(on-load:ag on-save:core)
  =.  core
    (do core [%edit-item ~zod %s1 %c1 'A' *perm-config 'front' 'back'])
  =/  restored  (need (peek-version core %card ~zod %s1 %c1))
  =.  core  (do core [%delete-item %s1 %c1])
  =/  deleted  (need (peek-version core %card ~zod %s1 %c1))
  =.  core
    (do core [%new-item ~zod ~zod %s1 %c1 'A' *perm-config 'front' 'back'])
  =/  recreated  (need (peek-version core %card ~zod %s1 %c1))
  ;:  weld
    (expect-eq !>(content-revision.first) !>(content-revision.graded))
    (expect-eq !>(content-revision.first-stack) !>(content-revision.graded-stack))
    (expect-eq !>(%.y) !>((gth review-revision.graded review-revision.first)))
    (expect-eq !>(%.y) !>((gth content-revision.edited content-revision.graded)))
    (expect-eq !>(%.y) !>((gth content-revision.restored content-revision.edited)))
    (expect-eq !>(incarnation.first) !>(incarnation.restored))
    (expect-eq !>(%.n) !>(present.deleted))
    (expect-eq !>(%.y) !>(present.recreated))
    (expect-eq !>(%.y) !>((gth incarnation.recreated incarnation.first)))
  ==
::
++  test-versioned-command-boundary
  ^-  tang
  =/  act=action  [%new-stack %wire-test 'Wire test' ~]
  =/  old-wire  (mule |.((on-poke:ag %seer-action !>(act))))
  =/  wrong-version  (mule |.((on-poke:ag %seer-action !>([1 act]))))
  =/  accepted  (do ag act)
  ;:  weld
    (expect-eq !>(%.y) !>(?=(%| -.old-wire)))
    (expect-eq !>(%.y) !>(?=(%| -.wrong-version)))
    (expect-eq !>(%.y) !>(?=(^ (peek-stack accepted %wire-test))))
  ==
::
::  Local transport is not human authority, including cached schema-2 tools.
::
++  test-planner-transport-cannot-grant-operator-actions
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =/  untrusted  ~(. seer-agent %*(. bol sap /khan))
  =.  core  +:(on-load:untrusted on-save:core)
  =/  grade  (command-for core [%answered-item ~zod %s1 %c1 %good])
  =.  core  (do-command core grade)
  =/  edit  (command-for core [%ask-card %edit-grant ~zod %s1 %c1 %edit fixture-model 'Change it' ~ 65.536 32.768])
  =.  core  (do-command core edit)
  =/  source  (command-for core [%add-context-source %source [%stack ~zod %s1 ~] %note 'Note' '' 'Evidence'])
  =.  core  (do-command core source)
  =/  grant  (command-for core [%set-context-egress %source (silt ~[%codex])])
  =.  core  (do-command core grant)
  =/  spend  (command-for core [%request-change %spend %library fixture-model 'Plan changes' %.y])
  =.  core  (do-command core spend)
  =/  start  (command-for core [%start-change %spend])
  =.  core  (do-command core start)
  =/  item  (~(got by items:(need (peek-stack core %s1))) %c1)
  ;:  weld
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core grade) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core edit) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core grant) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core spend) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core start) 'status')))
    (expect-eq !>('ok') !>((json-text (peek-receipt core source) 'status')))
    (expect-eq !>(0) !>(`@`box.learn.item))
    (expect-eq !>(%.n) !>((~(has by questions:(peek-ai core)) %edit-grant)))
  ==
::
::  Cancellation fences a correctly signed late result from the old lease.
::
++  test-worker-checkpoint-and-cancellation
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%ask-card %q1 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =.  core  (do-bridge core [%claim-card-question %q1 'worker-1'] 'claim')
  =/  running  (need (peek-work core %question %root %q1))
  =.  core  (do core [%issue-bridge-nonce 'early'])
  =/  early  (bridge-command core [%answer-card-question %q1 'worker-1' 'Not invoked' ~] 'early')
  =.  core  (do-command core early)
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %provider-started] 'started')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %output-received] 'received')
  =.  core  (do core [%issue-bridge-nonce 'late'])
  =/  late  (bridge-command core [%answer-card-question %q1 'worker-1' 'Late answer' ~] 'late')
  =.  core  (do core [%cancel-work [%question ~zod %root %q1]])
  =.  core  (do-command core late)
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  =/  stopped  (need (peek-work core %question %root %q1))
  ;:  weld
    (expect-eq !>(%running) !>(execution.running))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core early) 'status')))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core late) 'status')))
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>(%cancelled) !>(execution.stopped))
    (expect-eq !>(%.n) !>(=('Late answer' response.question)))
  ==
::
::  Exact retained asks avoid a second invocation; changed inputs cannot reuse.
::
++  test-source-qualified-answer-reuse
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%ask-card %q1 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =.  core  (do-bridge core [%claim-card-question %q1 'worker-1'] 'claim')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %provider-started] 'started')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %output-received] 'received')
  =.  core  (do-bridge core [%answer-card-question %q1 'worker-1' 'Qualified explanation' ~] 'answer')
  =/  completed  (need (peek-work core %question %root %q1))
  =.  core  (do core [%ask-card %q2 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =/  reused  (~(got by questions:(peek-ai core)) %q2)
  =/  reused-work  (need (peek-work core %question %root %q2))
  =.  core  (do core [%edit-item ~zod %s1 %c1 'Card' *perm-config 'changed front' 'back'])
  =.  core  (do core [%ask-card %q3 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =/  fresh  (~(got by questions:(peek-ai core)) %q3)
  ;:  weld
    (expect-eq !>(1) !>(invocations.completed))
    (expect-eq !>(%answered) !>(status.reused))
    (expect-eq !>('Qualified explanation') !>(response.reused))
    (expect-eq !>(0) !>(invocations.reused-work))
    (expect-eq !>(%pending) !>(status.fresh))
  ==
::
::  Attaching evidence never grants provider egress implicitly.
::
++  test-source-egress-requires-owner-grant
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%add-context-source %source [%stack ~zod %s1 ~] %note 'Private note' '' 'Private evidence'])
  =/  selections=(list evidence-selection)  ~[[%source 0 ~ %.y %.y]]
  =.  core  (do core [%ask-card %denied ~zod %s1 %c1 %ask profile 'Explain' selections 65.536 32.768])
  =/  denied  (~(got by questions:(peek-ai core)) %denied)
  =/  denied-work  (need (peek-work core %question %root %denied))
  =.  core  (do core [%set-context-egress %source (silt ~[%codex])])
  =.  core  (do core [%ask-card %allowed ~zod %s1 %c1 %ask profile 'Explain' selections 65.536 32.768])
  =/  allowed  (~(got by questions:(peek-ai core)) %allowed)
  ;:  weld
    (expect-eq !>(%failed) !>(status.denied))
    (expect-eq !>(0) !>(invocations.denied-work))
    (expect-eq !>(%pending) !>(status.allowed))
    (expect-eq !>(%.y) !>(?=(^ packet.allowed)))
  ==
::
++  test-bounded-library-navigation
  ^-  tang
  =/  query  read-query
  =/  empty  (peek-read ag query)
  =/  core  (do ag [%new-stack %bounded 'Bounded stack' ~])
  =/  body  (rep 3 (reap 8.000 'x'))
  =.  core
    =/  remaining=@ud  100
    |-
    ?:  =(0 remaining)  core
    =/  id=@tas  (cat 3 'card-' (scot %ud remaining))
    =.  core
      (do core [%new-item ~zod ~zod %bounded id 'Card' *perm-config body body])
    $(remaining (dec remaining))
  =/  orientation  (peek-read core query)
  =.  query  query(kind %card, stack `%bounded, limit 7)
  =/  walk
    =/  cursor=(unit @t)  ~
    =/  seen=(list @t)  ~
    =/  proof=tang  ~
    =/  pages=@ud  0
    |-
    ?>  (lth pages 20)
    =/  page  (peek-read core query(cursor cursor))
    =.  proof
      ;:  weld  proof
        (expect-eq !>('ok') !>((json-text page 'status')))
        (expect-eq !>(%.y) !>((lte (met 3 (en:json:html page)) max-bytes.query)))
      ==
    =/  rows  (json-rows page 'cards')
    =.  seen  (weld seen (turn rows |=(row=json (json-text row 'card_id'))))
    =/  next  (json-field page 'next_cursor')
    ?~  next  [seen proof]
    ?>  ?=(%s -.next)
    $(cursor `p.next, pages +(pages))
  =/  all-ids  -.walk
  =/  detail
    (peek-read core query(id `%card-42, projection %detail, limit 1))
  =/  selected  (snag 0 (json-rows detail 'cards'))
  =/  fresh  ag
  =/  restored  +:(on-load:fresh on-save:core)
  =/  reloaded  (peek-read restored query(id `%card-42, projection %detail, limit 1))
  =/  card-count  (json-field (json-field (json-field orientation 'counts') 'card') 'total')
  ;:  weld  +.walk
    (expect-eq !>('ok') !>((json-text empty 'status')))
    (expect-eq !>(n+'100') !>(card-count))
    (expect-eq !>(100) !>((lent all-ids)))
    (expect-eq !>(100) !>((lent ~(tap in (sy all-ids)))))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html orientation)) 32.768)))
    (expect-eq !>(body) !>((json-text selected 'front')))
    (expect-eq !>(body) !>((json-text selected 'back')))
    (expect-eq !>((json-rows detail 'cards')) !>((json-rows reloaded 'cards')))
  ==
::
++  test-scoped-cursor-and-watermark
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'One' ~])
  =.  core  (do core [%new-stack %s2 'Two' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %a 'A' *perm-config 'front-a' 'back-a'])
  =.  core  (do core [%new-item ~zod ~zod %s1 %b 'B' *perm-config 'front-b' 'back-b'])
  =/  query  read-query
  =.  query  query(kind %card, stack `%s1, limit 1)
  =/  first  (peek-read core query)
  =/  cursor  (json-text first 'next_cursor')
  =/  token  (json-text first 'watermark')
  =.  core  (do core [%new-item ~zod ~zod %s2 %c 'C' *perm-config 'unrelated' 'body'])
  =/  unchanged  (peek-read core query(since `token))
  =/  second  (peek-read core query(cursor `cursor))
  =/  first-id  (json-text (snag 0 (json-rows first 'cards')) 'card_id')
  =/  second-id  (json-text (snag 0 (json-rows second 'cards')) 'card_id')
  =/  wrong-scope  (peek-read core query(stack `%s2, cursor `cursor))
  =.  core  (do core [%edit-item ~zod %s1 %a 'Changed' *perm-config 'front-a' 'back-a'])
  =/  expired  (peek-read core query(cursor `cursor))
  =/  refreshed  (peek-read core query)
  =/  bad-cursor  (peek-read core query(cursor `'not-a-cursor'))
  ;:  weld
    (expect-eq !>('unchanged') !>((json-text unchanged 'status')))
    (expect-eq !>(a+~) !>((json-field unchanged 'cards')))
    (expect-eq !>('ok') !>((json-text second 'status')))
    (expect-eq !>(%.y) !>(!=(first-id second-id)))
    (expect-eq !>(b+%.y) !>((json-field second 'complete')))
    (expect-eq !>('snapshot-expired') !>((json-text wrong-scope 'status')))
    (expect-eq !>('snapshot-expired') !>((json-text expired 'status')))
    (expect-eq !>(b+%.n) !>((json-field expired 'complete')))
    (expect-eq !>('ok') !>((json-text refreshed 'status')))
    (expect-eq !>('invalid-query') !>((json-text bad-cursor 'status')))
  ==
::
++  test-bounded-detail-and-work-resumption
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'One' ~])
  =/  quotes  (rep 3 (reap 2.048 '"'))
  =.  core  (do core [%new-item ~zod ~zod %s1 %a 'A' *perm-config quotes quotes])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core
    (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'register-model')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%ask-card %q1 ~zod %s1 %a %ask profile 'Explain' ~ 65.536 32.768])
  =.  core  (do core [%request-login %l1 %codex])
  =/  query  read-query
  =/  metadata  (peek-read core query(kind %question, status `%pending))
  =/  question  (snag 0 (json-rows metadata 'questions'))
  ?>  ?=(%o -.question)
  =/  detail  (peek-read core query(kind %question, id `%q1, projection %detail, limit 1, max-bytes 65.536))
  =/  answerable  (snag 0 (json-rows detail 'questions'))
  =/  limited  (peek-read core query(kind %card, stack `%s1, id `%a, projection %detail, max-bytes 5.000))
  =/  tiny  (peek-read core query(max-bytes 1.024))
  =/  missing  (peek-read core query(kind %question, id `%not-found))
  ;:  weld
    (expect-eq !>(%.n) !>((~(has by p.question) 'front')))
    (expect-eq !>(%.n) !>((~(has by p.question) 'question')))
    (expect-eq !>(quotes) !>((json-text answerable 'front')))
    (expect-eq !>('Explain') !>((json-text answerable 'question')))
    (expect-eq !>('limit-exceeded') !>((json-text limited 'status')))
    (expect-eq !>(b+%.n) !>((json-field limited 'complete')))
    (expect-eq !>('not-found') !>((json-text missing 'status')))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html limited)) 5.000)))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html tiny)) 1.024)))
  ==
::
++  test-owner-command-and-remote-review-copy
  ^-  tang
  =/  core  (do ag [%new-stack %shared 'Local stack' ~])
  =.  core
    (do core [%new-item ~zod ~zod %shared %local 'Local card' *perm-config 'front' 'back'])
  =/  local-bowl  bol
  =/  peer-bowl  local-bowl(our ~nec, src ~nec)
  =/  peer  ~(. seer-agent peer-bowl)
  =.  peer  (do peer [%new-stack %shared 'Remote stack' ~])
  =.  peer
    (do peer [%new-item ~nec ~nec %shared %remote 'Remote card' *perm-config 'remote-front' 'remote-back'])
  =/  source  (need (peek-stack peer %shared))
  =/  incoming  ~(. seer-agent local-bowl(src ~nec))
  =.  incoming  +:(on-load:incoming on-save:core)
  =/  denied
    (mule |.((do incoming [%begin-capture %foreign 'No' 'No' 'No' 'No'])))
  =.  incoming
    +:(on-agent:incoming /import/~nec/shared [%fact %seer-stack !>(source)])
  =.  core  +:(on-load:ag on-save:incoming)
  =/  reviewed
    (on-poke:core %seer-action !>((command-for core [%answered-item ~nec %shared %remote %good])))
  =/  copies
    (murn -.reviewed (soft ,[%pass wire=path %agent destination=[ship=@p app=@tas] %poke mark=@tas body=vase]))
  =/  sent  (snag 0 copies)
  =/  receiver  ~(. seer-agent local-bowl(our ship.destination.sent))
  =.  receiver  +:(on-load:receiver on-save:+.reviewed)
  =.  receiver  +:(on-poke:receiver mark.sent body.sent)
  =/  local  (need (peek-stack receiver %shared))
  ?>  ?=(%.y -.info.local)
  ;:  weld
    (expect-eq !>(%.y) !>(?=(%| -.denied)))
    (expect-eq !>('Local stack') !>(title.p.info.local))
    (expect-eq !>(%.y) !>((~(has by items.local) %local)))
    (expect-eq !>(%.y) !>((~(has by items.local) %remote)))
  ==
::
++  test-read-observation-dependencies
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'One' ~])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'initial-model')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%begin-capture %cap 'Capture' 'Goal' 'Source' 'Owner'])
  =.  core  (do core [%add-context-source %source [%capture %cap] %note 'Note' '' 'Source'])
  =.  core  (do core [%set-context-egress %source (silt ~[%codex])])
  =.  core  (do core [%prepare-capture %cap profile ~[[%source 0 ~ %.y %.y]] 65.536 32.768])
  =/  snapshot  (peek-ai core)
  =/  session  (~(got by captures.snapshot) %cap)
  =/  source  (~(got by contexts.snapshot) %source)
  =/  fences=(list entity-precondition)
    ~[[[%stack ~zod %root %s1] (peek-version core %stack ~zod %root %s1) %.n %.n] [[%card ~zod %s1 %c1] ~ %.y %.y]]
  =.  core
    (do core [%stage-card %cap %p1 %s1 %c1 'Card' 'front' 'back' 'Reason' 'Source' 'Owner' 'Goal' 'Claim' 'New' 'Caveat' packet.session ~[[(need snapshot.source) 0 6 'Source']] fences])
  =.  session  (~(got by captures:(peek-ai core)) %cap)
  =/  draft  (~(got by proposals.session) %p1)
  =/  digest  (shax (jam [~zod ~[[%create-card %s1 %c1 'Card' 'front' 'back' '' '' '']] fences]))
  =.  core  (do core [%approve-proposal %cap %p1 digest])
  =/  query  read-query
  =/  overview  (peek-read core query)
  =/  cards  (peek-read core query(kind %card, stack `%s1))
  =/  row  (snag 0 (json-rows cards 'cards'))
  =.  query  query(owner `~nec)
  =/  before  (peek-read core query)
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core
    %:  do-bridge  core
      [%replace-assistant-models 'worker-1' ~[profile(description 'Changed definition')]]
      'publish-model'
    ==
  =/  after  (peek-read core query(since `(json-text before 'watermark')))
  ;:  weld
    (expect-eq !>(b+%.y) !>((json-field row 'has_provenance')))
    (expect-eq !>(n+'0') !>((json-field (json-field (json-field overview 'counts') 'card') 'without_provenance')))
    (expect-eq !>('ok') !>((json-text after 'status')))
  ==
::
++  test-read-validation-and-minimum-budget
  ^-  tang
  =/  query  read-query
  =/  missing  (peek-read ag query(kind %card, stack `%absent))
  =/  invalid  (peek-read ag query(kind %stack, card `%bad-scope))
  =/  malformed  (on-peek:ag /x/agent-read/not-a-query)
  ?>  ?=([~ ~ *] malformed)
  =/  malformed-page  (need ((soft json) q.q.u.u.malformed))
  =/  oversized
    (peek-read ag query(cursor `(rep 3 (reap 17.000 'x'))))
  =/  long=@tas  (rep 3 (reap 128 'a'))
  =.  query  query(kind %question, stack `long, card `long, id `long, max-bytes 1.024)
  =/  first  (peek-read ag query)
  =/  unchanged  (peek-read ag query(since `(json-text first 'watermark')))
  ;:  weld
    (expect-eq !>('not-found') !>((json-text missing 'status')))
    (expect-eq !>(b+%.n) !>((json-field missing 'complete')))
    (expect-eq !>('invalid-query') !>((json-text invalid 'status')))
    (expect-eq !>('invalid-query') !>((json-text malformed-page 'status')))
    (expect-eq !>('invalid-query') !>((json-text oversized 'status')))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html oversized)) 32.768)))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html unchanged)) 1.024)))
  ==
::
::  Unlink exact owner/card scopes, retaining the immutable queued input.
::
++  test-source-deletion-retains-history-and-fences-completion
  ^-  tang
  =/  core  (do ag [%new-stack %shared 'Local' ~])
  =.  core  (do core [%new-stack %other 'Unrelated' ~])
  =.  core  (do core [%new-item ~zod ~zod %shared %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do core [%new-item ~zod ~zod %shared %c2 'Sibling' *perm-config 'sibling' 'back'])
  =/  peer  ~(. seer-agent %*(. bol our ~nec, src ~nec))
  =.  peer  (do peer [%new-stack %shared 'Remote' ~])
  =/  remote-stack  (need (peek-stack peer %shared))
  =.  core  +:(on-agent:core /import/~nec/shared [%fact %seer-stack !>(remote-stack)])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%add-context-source %note [%stack ~zod %shared ~] %note 'Note' '' 'Historical note'])
  =.  core  (do core [%add-context-source %file [%stack ~zod %shared `%c1] %file 'File' 'fixture.txt' 'Historical file'])
  =.  core  (do core [%add-context-source %clay [%stack ~zod %shared `%c1] %clay 'Clay' '/~nec/base/fixture/txt' ''])
  =/  clay  (~(got by contexts:(peek-ai core)) %clay)
  =.  core  (take-clay core %clay generation.clay 'Historical Clay')
  =.  core  (do core [%add-context-source %pending [%stack ~zod %shared ~] %web 'Pending web' 'https://example.invalid/pending' ''])
  =.  core  (do core [%add-context-source %working [%stack ~zod %shared `%c1] %web 'Working web' 'https://example.invalid/working' ''])
  =.  core  (do core [%add-context-source %sibling [%stack ~zod %shared `%c2] %note 'Sibling' '' 'Sibling evidence'])
  =.  core  (do core [%add-context-source %other [%stack ~zod %other ~] %note 'Other' '' 'Other evidence'])
  =.  core  (do core [%add-context-source %remote [%stack ~nec %shared ~] %note 'Remote' '' 'Remote evidence'])
  =.  core  (do core [%set-context-egress %note (silt ~[%codex])])
  =.  core  (do core [%set-context-egress %file (silt ~[%codex])])
  =.  core  (do core [%set-context-egress %clay (silt ~[%codex])])
  =/  selections=(list evidence-selection)
    ~[[%note 0 ~ %.y %.y] [%file 0 ~ %.y %.y] [%clay 0 ~ %.y %.y]]
  =.  core  (do core [%ask-card %queued ~zod %shared %c1 %ask profile 'Explain' selections 65.536 32.768])
  =/  before  (peek-ai core)
  =/  question  (~(got by questions.before) %queued)
  =/  queued  (need (peek-work core %question %root %queued))
  =/  packet  (need packet.question)
  =/  prompt  (json-text (peek-packet core packet) 'canonical_prompt')
  =.  core  (do core [%refresh-context-source %clay])
  =.  clay  (~(got by contexts:(peek-ai core)) %clay)
  =.  core  (do-bridge core [%claim-context-source %working 'worker-1'] 'claim-web')
  =.  core  (do-bridge core [%checkpoint-work [%context ~zod %root %working] 'worker-1' %provider-started] 'start-web')
  =.  core  (do-bridge core [%checkpoint-work [%context ~zod %root %working] 'worker-1' %output-received] 'receive-web')
  =.  core  (do core [%issue-bridge-nonce 'late-web'])
  =/  late  (bridge-command core [%finish-context-source %working 'worker-1' 'Late' 'Late web bytes' 'https://example.invalid/working'] 'late-web')
  =.  core  (do core [%delete-item %shared %c1])
  =/  card-deleted  (peek-ai core)
  =.  core  (do core [%delete-stack ~zod %shared])
  =/  stack-deleted  (peek-ai core)
  =.  core  (do-command core late)
  =.  core  (take-clay core %clay generation.clay 'Late Clay bytes')
  =.  core  (do core [%issue-bridge-nonce 'claim-archived'])
  =/  reclaim  (bridge-command core [%claim-context-source %pending 'worker-2'] 'claim-archived')
  =.  core  (do-command core reclaim)
  =/  after  (peek-ai core)
  =/  archived-work  (need (peek-work core %context %root %working))
  =/  note  (~(got by contexts.before) %note)
  =/  file  (~(got by contexts.before) %file)
  =/  old-clay  (~(got by contexts.before) %clay)
  =/  sibling  (~(got by contexts.before) %sibling)
  ::  The queued packet remains a live dependency past the collection cutoff.
  =.  core  (at-time core (add fixed-now ~d31))
  =.  core  (do core [%collect-retained ~])
  =/  query  read-query
  =/  pending  (peek-read core query(kind %context, status `%pending))
  ;:  weld
    (expect-eq !>(%pending) !>(status.question))
    (expect-eq !>(%queued) !>(execution.queued))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %file)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %clay)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %working)))
    (expect-eq !>((~(got by contexts.before) %note)) !>((~(got by contexts.card-deleted) %note)))
    (expect-eq !>((~(got by contexts.before) %pending)) !>((~(got by contexts.card-deleted) %pending)))
    (expect-eq !>((~(got by contexts.before) %sibling)) !>((~(got by contexts.card-deleted) %sibling)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %note)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %pending)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %sibling)))
    (expect-eq !>((~(got by contexts.before) %other)) !>((~(got by contexts.after) %other)))
    (expect-eq !>((~(got by contexts.before) %remote)) !>((~(got by contexts.after) %remote)))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core late) 'status')))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core reclaim) 'status')))
    (expect-eq !>(%cancelled) !>(execution.archived-work))
    (expect-eq !>(contexts.stack-deleted) !>(contexts.after))
    (expect-eq !>(evidence.stack-deleted) !>(evidence.after))
    (expect-eq !>(~) !>((json-rows pending 'contexts')))
    (expect-eq !>(prompt) !>((json-text (peek-packet core packet) 'canonical_prompt')))
    (expect-eq !>('Historical note') !>((json-text (peek-snapshot core (need snapshot.note) 15) 'text')))
    (expect-eq !>('Historical file') !>((json-text (peek-snapshot core (need snapshot.file) 15) 'text')))
    (expect-eq !>('Historical Clay') !>((json-text (peek-snapshot core (need snapshot.old-clay) 15) 'text')))
    (expect-eq !>('purged') !>((json-text (peek-snapshot core (need snapshot.sibling) 16) 'status')))
    (expect-eq !>(~) !>((peek-stack core %shared)))
    (expect-eq !>(%.y) !>(?=(^ (peek-stack core %other))))
  ==
::
::  Normal deletion archives eagerly; inject only the missing-parent fixture.
::
++  test-orphan-sweep-is-exact-and-idempotent
  ^-  tang
  =/  core  (do ag [%new-stack %orphan 'Orphan fixture' ~])
  =.  core  (do core [%new-stack %keep 'Keep' ~])
  =.  core  (do core [%add-context-source %orphan [%stack ~zod %orphan ~] %note 'Orphan' '' 'Retained orphan'])
  =.  core  (do core [%add-context-source %keep [%stack ~zod %keep ~] %note 'Keep' '' 'Keep evidence'])
  =/  peer  ~(. seer-agent %*(. bol our ~nec, src ~nec))
  =.  peer  (do peer [%new-stack %orphan 'Other owner' ~])
  =/  remote-stack  (need (peek-stack peer %orphan))
  =.  core  +:(on-agent:core /import/~nec/orphan [%fact %seer-stack !>(remote-stack)])
  =.  core  (do core [%add-context-source %remote [%stack ~nec %orphan ~] %note 'Remote' '' 'Remote evidence'])
  =/  before  (peek-ai core)
  =/  source  (~(got by contexts.before) %orphan)
  ::  Preserve the current saved vase/mold; remove its first field's parent
  ::  without invoking deletion. This is not an old-state migration fixture.
  =/  saved  on-save:core
  =.  saved  saved(q [(~(del by stacks.before) %orphan) +.q.saved])
  =.  core  +:(on-load:ag saved)
  =.  core  (do core [%archive-orphan-contexts ~])
  =/  swept  (peek-ai core)
  =/  archived  (~(got by contexts.swept) %orphan)
  =/  version  (peek-version core %context ~zod %root %orphan)
  =.  core  (do core [%archive-orphan-contexts ~])
  =/  repeated  (peek-ai core)
  =/  query  read-query
  =/  history  (peek-read core query(kind %context, id `%orphan, status `%archived))
  =/  history-rows  (json-rows history 'contexts')
  =/  historical=json  ?~(history-rows o+~ i.history-rows)
  ;:  weld
    (expect-eq !>(%.n) !>(active.archived))
    (expect-eq !>(+(generation.source)) !>(generation.archived))
    (expect-eq !>((~(got by contexts.before) %keep)) !>((~(got by contexts.swept) %keep)))
    (expect-eq !>((~(got by contexts.before) %remote)) !>((~(got by contexts.swept) %remote)))
    (expect-eq !>(swept) !>(repeated))
    (expect-eq !>(version) !>((peek-version core %context ~zod %root %orphan)))
    (expect-eq !>('ok') !>((json-text history 'status')))
    (expect-eq !>(s+'archived') !>((json-field historical 'status')))
    (expect-eq !>(s+'ready') !>((json-field historical 'acquisition_status')))
    (expect-eq !>(b+%.n) !>((json-field historical 'active')))
    (expect-eq !>(s+'~zod') !>((json-field historical 'owner')))
    (expect-eq !>(s+(scot %ux (need snapshot.source))) !>((json-field historical 'snapshot_ref')))
    (expect-eq !>(a+~) !>((json-field historical 'legal_next_actions')))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html history)) 32.768)))
    (expect-eq !>('Retained orphan') !>((json-text (peek-snapshot core (need snapshot.source) 15) 'text')))
  ==
::
::  Only uninvoked expired work can be reclaimed; the former lease stays dead.
::
++  test-competing-claims-and-checkpoint-aware-recovery
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%ask-card %safe ~zod %s1 %c1 %ask profile 'Explain safe' ~ 65.536 32.768])
  =.  core  (do core [%ask-card %unknown ~zod %s1 %c1 %ask profile 'Explain unknown' ~ 65.536 32.768])
  =.  core  (do core [%issue-bridge-nonce 'claim-one'])
  =.  core  (do core [%issue-bridge-nonce 'claim-two'])
  =/  first  (bridge-command core [%claim-card-question %safe 'worker-1'] 'claim-one')
  =/  second  (bridge-command core [%claim-card-question %safe 'worker-2'] 'claim-two')
  =.  core  (do-command core first)
  =/  winner  (need (peek-work core %question %root %safe))
  =.  core  (do-command core second)
  =/  contested  (need (peek-work core %question %root %safe))
  =.  core  (do core [%issue-bridge-nonce 'early-recovery'])
  =/  early  (bridge-command core [%recover-work [%question ~zod %root %safe] 'worker-1'] 'early-recovery')
  =.  core  (do-command core early)
  =.  core  (do-bridge core [%claim-card-question %unknown 'worker-1'] 'claim-unknown')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %unknown] 'worker-1' %provider-started] 'start-unknown')
  =.  core  (do core [%issue-bridge-nonce 'expired-heartbeat'])
  =/  expired  (bridge-command core [%heartbeat-work [%question ~zod %root %safe] 'worker-1'] 'expired-heartbeat')
  =.  core  (do core [%issue-bridge-nonce 'old-result'])
  =/  old-result  (bridge-command core [%answer-card-question %safe 'worker-1' 'Old lease answer' ~] 'old-result')
  =.  core  (at-time core (need lease-until.winner))
  =.  core  (do-command core expired)
  =.  core  (do-bridge core [%recover-work [%question ~zod %root %safe] 'worker-1'] 'recover-safe')
  =/  requeued  (need (peek-work core %question %root %safe))
  =/  pending  (~(got by questions:(peek-ai core)) %safe)
  =.  core  (do core [%issue-bridge-nonce 'recover-unknown'])
  =/  recover-unknown  (bridge-command core [%recover-work [%question ~zod %root %unknown] 'worker-1'] 'recover-unknown')
  =.  core  (do-command core recover-unknown)
  =/  unknown  (need (peek-work core %question %root %unknown))
  =/  ambiguous  (~(got by questions:(peek-ai core)) %unknown)
  =.  core  (do core [%issue-bridge-nonce 'retry-unknown'])
  =/  retry-unknown  (bridge-command core [%claim-card-question %unknown 'worker-2'] 'retry-unknown')
  =.  core  (do-command core retry-unknown)
  =.  core  (do-bridge core [%claim-card-question %safe 'worker-2'] 'claim-recovered')
  =/  recovered  (need (peek-work core %question %root %safe))
  =.  core  (do-command core old-result)
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %safe] 'worker-2' %provider-started] 'start-recovered')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %safe] 'worker-2' %output-received] 'receive-recovered')
  =.  core  (do-bridge core [%answer-card-question %safe 'worker-2' 'Recovered answer' ~] 'answer-recovered')
  =/  completed  (need (peek-work core %question %root %safe))
  =/  answered  (~(got by questions:(peek-ai core)) %safe)
  ;:  weld
    (expect-eq !>('ok') !>((json-text (peek-receipt core first) 'status')))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core second) 'status')))
    (expect-eq !>(winner) !>(contested))
    (expect-eq !>('lease-not-expired') !>((json-text (peek-receipt core early) 'reason')))
    (expect-eq !>('lease-expired') !>((json-text (peek-receipt core expired) 'reason')))
    (expect-eq !>(%queued) !>(execution.requeued))
    (expect-eq !>(%pending) !>(status.pending))
    (expect-eq !>(0) !>(invocations.requeued))
    (expect-eq !>(+(attempt.winner)) !>(attempt.recovered))
    (expect-eq !>(%.n) !>(=(lease.winner lease.recovered)))
    (expect-eq !>('worker-2') !>(worker.recovered))
    (expect-eq !>('work-fenced') !>((json-text (peek-receipt core old-result) 'reason')))
    (expect-eq !>(%answered) !>(status.answered))
    (expect-eq !>('Recovered answer') !>(response.answered))
    (expect-eq !>(%succeeded) !>(execution.completed))
    (expect-eq !>(1) !>(invocations.completed))
    (expect-eq !>('outcome-unknown') !>((json-text (peek-receipt core recover-unknown) 'status')))
    (expect-eq !>(%blocked) !>(execution.unknown))
    (expect-eq !>(%unknown) !>(effect.unknown))
    (expect-eq !>(%failed) !>(status.ambiguous))
    (expect-eq !>(1) !>(invocations.unknown))
    (expect-eq !>(%.n) !>(retryable.unknown))
    (expect-eq !>('blocked') !>((json-text (peek-receipt core retry-unknown) 'status')))
    (expect-eq !>(unknown) !>((need (peek-work core %question %root %unknown))))
  ==
::
::  Rotation revokes both old proofs and the old attempt, even if re-signed.
::
++  test-secret-rotation-fences-late-publication
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%ask-card %q1 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =.  core  (do-bridge core [%claim-card-question %q1 'worker-1'] 'claim')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %provider-started] 'started')
  =.  core  (do-bridge core [%checkpoint-work [%question ~zod %root %q1] 'worker-1' %output-received] 'received')
  =/  running  (need (peek-work core %question %root %q1))
  =/  act=action  [%answer-card-question %q1 'worker-1' 'Revoked answer' ~]
  =.  core  (do core [%issue-bridge-nonce 'late'])
  =/  late  (bridge-command core act 'late')
  =/  next-secret=@t  'fedcba9876543210fedcba9876543210'
  =.  core  (do-noun core [%set-bridge-capability next-secret])
  =/  rotated  (peek-ai core)
  ::  Reissue the nonce to isolate secret validation from nonce revocation.
  =.  core  (do core [%issue-bridge-nonce 'late'])
  =.  core  (do-command core late)
  =.  core  (do core [%issue-bridge-nonce 'resigned'])
  =/  request  (need (worker-request act))
  =/  epoch  (slav %da (peek-epoch core))
  =/  proof
    (make-proof next-secret -.act id.request worker.request 'resigned' epoch 'resigned' attempt.running lease.running fields.request)
  =/  resigned
    (make-command epoch 'resigned' [%bridge-action worker.request 'resigned' proof attempt.running lease.running act])
  =.  core  (do-command core resigned)
  =/  stopped  (need (peek-work core %question %root %q1))
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  ;:  weld
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core late) 'status')))
    (expect-eq !>('work-fenced') !>((json-text (peek-receipt core resigned) 'reason')))
    (expect-eq !>(%blocked) !>(execution.stopped))
    (expect-eq !>(%unknown) !>(effect.stopped))
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>(%.n) !>(=('Revoked answer' response.question)))
    (expect-eq !>(rotated) !>((peek-ai core)))
    (expect-eq !>(~) !>(artifacts.learning.rotated))
  ==
::
::  Rejection suppresses identical inputs, not the underlying factual claim.
::
++  test-proposal-rejection-deduplicates-without-disproof
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do-noun core [%set-bridge-capability bridge-test-secret])
  =.  core  (do-bridge core [%replace-assistant-models 'worker-1' ~[fixture-model]] 'catalog')
  =/  profile  (~(got by models:(peek-ai core)) %test-model)
  =.  core  (do core [%begin-capture %cap 'Capture' 'Goal' 'Source' 'Owner'])
  =.  core  (do core [%add-context-source %source [%capture %cap] %note 'Note' '' 'Source'])
  =.  core  (do core [%set-context-egress %source (silt ~[%codex])])
  =.  core  (do core [%prepare-capture %cap profile ~[[%source 0 ~ %.y %.y]] 65.536 32.768])
  =/  session  (~(got by captures:(peek-ai core)) %cap)
  =/  source  (~(got by contexts:(peek-ai core)) %source)
  =/  citations=(list evidence-citation)  ~[[(need snapshot.source) 0 6 'Source']]
  =/  stack-version  (peek-version core %stack ~zod %root %s1)
  =/  stage
    |=  [id=@tas card=@tas front=@t rationale=@t packet=(unit @ux) citations=(list evidence-citation)]
    ^-  action
    =/  fences=(list entity-precondition)
      ~[[[%stack ~zod %root %s1] stack-version %.n %.n] [[%card ~zod %s1 card] ~ %.y %.y]]
    [%stage-card %cap id %s1 card 'Candidate' front 'back' rationale 'Source' 'Owner' 'Goal' 'Claim' 'New' 'Caveat' packet citations fences]
  =.  core  (do core (stage %p1 %c1 'front' 'First rationale' packet.session citations))
  ::  Keep the capture open so later suppression is not a closed-session no-op.
  =.  core  (do core (stage %keep %keeper 'Different front' 'Keep open' packet.session citations))
  =.  session  (~(got by captures:(peek-ai core)) %cap)
  =/  first  (~(got by proposals.session) %p1)
  =.  core  (do core [%reject-proposal %cap %p1 ~])
  =/  rejected  (peek-ai core)
  =/  original  (~(got by artifacts.learning.rejected) (need artifact.first))
  =/  repeat  (command-for core [%reject-proposal %cap %p1 `'That must be false'])
  =.  core  (do-command core repeat)
  =/  duplicate-one  (command-for core (stage %p2 %c2 'front' 'Renamed and reworded' packet.session citations))
  =.  core  (do-command core duplicate-one)
  =/  duplicate-two  (command-for core (stage %p3 %c3 'front' 'Another rationale' packet.session citations))
  =.  core  (do-command core duplicate-two)
  =/  suppressed  (peek-ai core)
  =/  proposals  (~(got by captures.suppressed) %cap)
  ::  A fresh source revision is new evidence, not automatic factual disproof.
  =.  core  (do core [%refresh-context-source %source])
  =.  source  (~(got by contexts:(peek-ai core)) %source)
  =.  citations  ~[[(need snapshot.source) 0 6 'Source']]
  =.  core  (do core [%prepare-capture %cap profile ~[[%source 0 ~ %.y %.y]] 65.536 32.768])
  =.  session  (~(got by captures:(peek-ai core)) %cap)
  =/  restage  (command-for core (stage %fresh %c1 'front' 'Reconsider with fresh evidence' packet.session citations))
  =.  core  (do-command core restage)
  =.  session  (~(got by captures:(peek-ai core)) %cap)
  =/  fresh  (~(got by proposals.session) %fresh)
  =/  digest
    (shax (jam [~zod ~[[%create-card %s1 %c1 'Candidate' 'front' 'back' '' '' '']] preconditions.fresh]))
  =.  core  (do core [%approve-proposal %cap %fresh digest])
  =/  after  (peek-ai core)
  =/  approved  (~(got by artifacts.learning.after) (need artifact.fresh))
  =/  card  (~(got by items:(need (peek-stack core %s1))) %c1)
  ;:  weld
    (expect-eq !>('blocked') !>((json-text (peek-receipt core repeat) 'status')))
    (expect-eq !>('rejected-identical') !>((json-text (peek-receipt core duplicate-one) 'reason')))
    (expect-eq !>('rejected-identical') !>((json-text (peek-receipt core duplicate-two) 'reason')))
    (expect-eq !>(%open) !>(status.proposals))
    (expect-eq !>(1) !>(rejected.proposals))
    (expect-eq !>(%.n) !>((~(has by proposals.proposals) %p2)))
    (expect-eq !>(%.n) !>((~(has by proposals.proposals) %p3)))
    (expect-eq !>(artifacts.learning.rejected) !>(artifacts.learning.suppressed))
    (expect-eq !>(stacks.rejected) !>(stacks.suppressed))
    (expect-eq !>(%rejected) !>(decision.original))
    (expect-eq !>(~) !>(reason.original))
    (expect-eq !>(%.y) !>(available.original))
    (expect-eq !>(~) !>(observations.learning.suppressed))
    (expect-eq !>('ok') !>((json-text (peek-receipt core restage) 'status')))
    (expect-eq !>(original) !>((~(got by artifacts.learning.after) id.original)))
    (expect-eq !>(`id.original) !>(prior.approved))
    (expect-eq !>(%approved) !>(decision.approved))
    (expect-eq !>('front') !>((clean-body:effects front.content.card)))
    (expect-eq !>('back') !>((clean-body:effects back.content.card)))
    (expect-eq !>('Source') !>((json-text (peek-snapshot core snapshot:(snag 0 citations.original) 6) 'text')))
  ==
--
