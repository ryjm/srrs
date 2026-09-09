::  behavioral tests for the %seer agent.
::
::  each test drives the real agent with a fixed bowl. the runtime is
::  simulated by feeding the ship's own outbound request wires back
::  through on-arvo with iris responses and behn wakes. Covered:
::  revision and recall behavior, authoritative operation replay, atomic
::  plan application, ship-native provider execution and sign-in,
::  destination policy, and bounded reads.
::
::  run on a ship with the desk installed:
::    -test /=seer=/tests ~
::
/-  *seer
/+  *test, *seer, effects=seer-effects, net=seer-net, oa=seer-oauth
/=  seer-agent  /app/seer
|%
++  fixed-now  ~2026.9.2
++  in-one-hour  (add fixed-now ~h1)
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
::  +run: apply one %seer-action poke, keeping the cards it emits
::
++  run
  |=  [core=agent:gall act=action]
  ^-  [(list card:agent:gall) agent:gall]
  (on-poke:core %seer-action !>((command-for core act)))
::  +do-noun: apply one %noun poke (dojo-style commands)
::
++  do-noun
  |=  [core=agent:gall a=*]
  ^-  agent:gall
  +:(on-poke:core %noun !>(a))
::  +arvo: deliver one runtime sign on a wire the ship issued
::
++  arvo
  |=  [core=agent:gall =wire sign=sign-arvo]
  ^-  [(list card:agent:gall) agent:gall]
  (on-arvo:core wire sign)
++  wake
  ^-  sign-arvo
  [%behn %wake ~]
++  finished
  |=  [status=@ud headers=header-list:http body=@t]
  ^-  sign-arvo
  [%iris %http-response %finished [status headers] `['text/plain' (as-octs:mimes:html body)]]
++  progress
  |=  bytes=@ud
  ^-  sign-arvo
  [%iris %http-response %progress [200 ~] bytes ~ ~]
++  cancelled
  ^-  sign-arvo
  [%iris %http-response %cancel ~]
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
::  +fixture-model: the profile a catalog of one model named 'test' yields
::
++  fixture-model
  ^-  assistant-model
  %*  .  *assistant-model
    id        %codex-test
    provider  %codex
    role      %default
    selector  'openai-codex/test'
    model     'test'
    label     'Test'
    origin    'catalog'
  ==
++  peek-logins
  |=  core=agent:gall
  ^-  (map @tas login-request)
  =/  res  (on-peek:core /x/logins)
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(map @tas login-request)) q.q.u.u.res))
++  peek-accounts
  |=  core=agent:gall
  ^-  (map ai-provider account-view)
  =/  res  (on-peek:core /x/accounts)
  ?>  ?=([~ ~ *] res)
  (need ((soft ,(map ai-provider account-view)) q.q.u.u.res))
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
++  peek-context
  |=  core=agent:gall
  ^-  json
  =/  res  (on-peek:core /x/agent-context)
  ?>  ?=([~ ~ *] res)
  (need ((soft json) q.q.u.u.res))
++  peek-epoch
  |=  core=agent:gall
  ^-  @t
  (json-text (peek-context core) 'idempotency_epoch')
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
++  json-object
  |=  fields=(list [@t json])
  ^-  json
  (pairs:enjs:format fields)
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
::
::  the ship's outbound cards
::
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list [wire=path req=request:http])
  %+  murn  cards
  |=  c=card:agent:gall
  ^-  (unit [wire=path req=request:http])
  =/  hit  ((soft ,[%pass wire=path %arvo %i %request req=request:http *]) c)
  ?~  hit  ~
  `[wire.u.hit req.u.hit]
++  waits
  |=  cards=(list card:agent:gall)
  ^-  (list [wire=path at=@da])
  %+  murn  cards
  |=  c=card:agent:gall
  ^-  (unit [wire=path at=@da])
  =/  hit  ((soft ,[%pass wire=path %arvo %b %wait at=@da]) c)
  ?~  hit  ~
  `[wire.u.hit at.u.hit]
::  +passes: the ship's own moves; the verb wrapper's facts are noise
::
++  passes
  |=  cards=(list card:agent:gall)
  ^-  (list card:agent:gall)
  (skim cards |=(c=card:agent:gall ?=([%pass *] c)))
++  snapshot-text
  |=  [core=agent:gall id=@ux]
  ^-  tape
  =/  record  (~(got by snapshots.evidence:(peek-ai core)) id)
  (trip (json-text (peek-snapshot core id bytes.record) 'text'))
++  cancels
  |=  cards=(list card:agent:gall)
  ^-  (list path)
  %+  murn  cards
  |=  c=card:agent:gall
  ^-  (unit path)
  =/  hit  ((soft ,[%pass wire=path %arvo %i %cancel-request ~]) c)
  ?~  hit  ~
  `wire.u.hit
++  request-on
  |=  [cards=(list card:agent:gall) =wire]
  ^-  (unit request:http)
  =/  rows  (skim (requests cards) |=([w=path *] =(w wire)))
  ?~  rows  ~
  `req.i.rows
++  wait-on
  |=  [cards=(list card:agent:gall) =wire]
  ^-  (unit @da)
  =/  rows  (skim (waits cards) |=([w=path *] =(w wire)))
  ?~  rows  ~
  `at.i.rows
++  cancel-on
  |=  [cards=(list card:agent:gall) =wire]
  ^-  ?
  ?=(^ (skim (cancels cards) |=(w=path =(w wire))))
++  wire-headed
  |=  [cards=(list card:agent:gall) head=@tas]
  ^-  (unit path)
  =/  rows  (skim (requests cards) |=([w=path *] ?&(?=(^ w) =(head i.w))))
  ?~  rows  ~
  `wire.i.rows
++  request-wire
  |=  [kind=@tas id=@tas attempt=@ud]
  ^-  wire
  /seer-request/[kind]/[id]/(scot %ud attempt)
++  deadline-wire
  |=  [kind=@tas id=@tas attempt=@ud]
  ^-  wire
  /seer-deadline/[kind]/[id]/(scot %ud attempt)
++  login-wire
  |=  [id=@tas step=@tas attempt=@ud]
  ^-  wire
  /seer-login/[id]/[step]/(scot %ud attempt)
++  poll-wire
  |=  [id=@tas attempt=@ud]
  ^-  wire
  /seer-poll/[id]/(scot %ud attempt)
++  body-json
  |=  req=request:http
  ^-  json
  ?~  body.req  ~
  (fall (decode:net q.u.body.req) ~)
::
::  provider fixtures
::
++  catalog-body
  |=  [slug=@t label=@t]
  ^-  @t
  (en:json:html (json-object ~[['data' a+~[(json-object ~[['id' s+slug] ['display_name' s+label]])]]]))
++  sse-body
  |=  events=(list json)
  ^-  @t
  %+  rap  3
  %+  turn  events
  |=(event=json (rap 3 'data: ' (en:json:html event) '\0a\0a' ~))
++  codex-message
  |=  text=@t
  ^-  json
  %-  json-object
  :~  ['type' s+'response.output_item.done']
      ['item' (json-object ~[['type' s+'message'] ['content' a+~[(json-object ~[['type' s+'output_text'] ['text' s+text]])]]])]
  ==
++  codex-completed
  |=  [input=@ud output=@ud]
  ^-  json
  %-  json-object
  :~  ['type' s+'response.completed']
      :-  'response'
      (json-object ~[['usage' (json-object ~[['input_tokens' (numb:enjs:format input)] ['output_tokens' (numb:enjs:format output)]])]])
  ==
::  +codex-answer: a complete responses-api stream carrying one answer
::
++  codex-answer
  |=  [answer=@t input=@ud output=@ud]
  ^-  @t
  =/  text  (en:json:html (json-object ~[['answer' s+answer] ['citations' a+~]]))
  (sse-body ~[(codex-message text) (codex-completed input output)])
++  jwt
  |=  claims=json
  ^-  @t
  =/  segment  |=(text=@t (base64url:oa (met 3 text) text))
  (rap 3 (segment '{"alg":"none","typ":"JWT"}') '.' (segment (en:json:html claims)) '.' 'sig' ~)
++  epoch-seconds
  |=  at=@da
  ^-  @ud
  (div (sub at ~1970.1.1) ~s1)
++  codex-access-token
  %-  jwt
  %-  json-object
  :~  ['exp' (numb:enjs:format (epoch-seconds in-one-hour))]
      ['https://api.openai.com/auth' (json-object ~[['chatgpt_account_id' s+'acct-1']])]
  ==
++  codex-id-token
  %-  jwt
  %-  json-object
  :~  ['exp' (numb:enjs:format (epoch-seconds in-one-hour))]
      ['email' s+'person@example.com']
      ['https://api.openai.com/auth' (json-object ~[['chatgpt_account_id' s+'acct-1']])]
  ==
++  codex-token-body
  ^-  @t
  %-  en:json:html
  %-  json-object
  :~  ['access_token' s+codex-access-token]
      ['refresh_token' s+'codex-refresh-1']
      ['id_token' s+codex-id-token]
      ['token_type' s+'Bearer']
  ==
++  claude-token-body
  ^-  @t
  %-  en:json:html
  %-  json-object
  :~  ['access_token' s+'sk-ant-oat01-access']
      ['refresh_token' s+'sk-ant-ort01-refresh']
      ['expires_in' (numb:enjs:format 3.600)]
      ['account' (json-object ~[['uuid' s+'user-1'] ['email_address' s+'person@example.com']])]
      ['scope' s+'user:inference']
  ==
::  +connect: sign a provider in with an api key, then answer the catalog
::  request the ship sends so one model named 'test' is registered.
::
++  connect
  |=  [core=agent:gall provider=ai-provider]
  ^-  agent:gall
  =/  key  ?:(=(%codex provider) 'sk-test-codex-key' 'sk-ant-api03-test-key')
  =^  cards  core  (run core [%import-account provider %api-key key '' '' ~ ''])
  =/  catalog  (need (wire-headed cards %seer-catalog))
  +:(arvo core catalog (finished 200 ~ (catalog-body 'test' 'Test')))
::  +connected-question: a stack with one card, a codex account, and
::  question q1 dispatched at attempt 1
::
++  connected-question
  ^-  [cards=(list card:agent:gall) core=agent:gall]
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  (run core [%ask-card %q1 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
::  +web-source: attach one web source under stack s1 and keep the cards
::
++  web-source
  |=  [core=agent:gall id=@tas url=@t]
  ^-  [cards=(list card:agent:gall) core=agent:gall]
  (run core [%add-context-source id [%stack ~zod %s1 ~] %web 'Web' url ''])
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
::  A copy starts its own review history unless the learner keeps it.
::
++  test-copy-stack-resets-learning-unless-kept
  ^-  tang
  =/  peer  ~(. seer-agent %*(. bol our ~nec, src ~nec))
  =.  peer  (do peer [%new-stack %shared 'Remote' ~])
  =.  peer  (do peer [%new-item ~nec ~nec %shared %c1 'Card' *perm-config 'front' 'back'])
  =.  peer  (do peer [%answered-item ~nec %shared %c1 %good])
  =.  peer  (do peer [%answered-item ~nec %shared %c1 %good])
  =/  source  (need (peek-stack peer %shared))
  =/  learned  (~(got by items.source) %c1)
  =/  core  +:(on-agent:ag /import/~nec/shared [%fact %seer-stack !>(source)])
  =/  kept  (do core [%copy-stack ~nec %shared %.y])
  =/  reset  (do core [%copy-stack ~nec %shared %.n])
  =/  kept-stack  (need (peek-stack kept %shared))
  =/  kept-item  (~(got by items.kept-stack) %c1)
  =/  reset-item  (~(got by items:(need (peek-stack reset %shared))) %c1)
  ?>  ?=(%.y -.info.kept-stack)
  ;:  weld
    (expect-eq !>(2) !>(`@`box.learn.learned))
    (expect-eq !>(%.y) !>(?=(^ last-review.learned)))
    (expect-eq !>(~zod) !>(owner.p.info.kept-stack))
    (expect-eq !>(~zod) !>(author.content.kept-item))
    (expect-eq !>(learn.learned) !>(learn.kept-item))
    (expect-eq !>(last-review.learned) !>(last-review.kept-item))
    (expect-eq !>(.2.5) !>(ease.learn.reset-item))
    (expect-eq !>(~s0) !>(`@dr`interval.learn.reset-item))
    (expect-eq !>(0) !>(`@`box.learn.reset-item))
    (expect-eq !>(~) !>(last-review.reset-item))
  ==
::
::  A catalog response replaces one provider's models; an empty response
::  withdraws nothing, and a signed-out provider cannot be refreshed.
::
++  test-catalog-replaces-only-its-provider
  ^-  tang
  =/  core  (connect ag %codex)
  =.  core  (connect core %claude)
  =/  both  models:(peek-ai core)
  =^  cards  core  (run core [%refresh-catalog %codex])
  =/  catalog  (need (wire-headed cards %seer-catalog))
  =^  ignored  core  (arvo core catalog (finished 200 ~ (catalog-body 'gpt-5-mini' 'GPT-5 mini')))
  =/  replaced  models:(peek-ai core)
  =^  again  core  (run core [%refresh-catalog %codex])
  =^  ignored  core  (arvo core (need (wire-headed again %seer-catalog)) (finished 200 ~ '{"data":[]}'))
  =/  after-empty  models:(peek-ai core)
  =/  signed-out  (do-noun core [%clear-account %codex])
  =/  refused  (command-for signed-out [%refresh-catalog %codex])
  =.  signed-out  (do-command signed-out refused)
  =/  mini  (~(got by replaced) %codex-gpt-5-mini)
  ;:  weld
    (expect-eq !>(%.y) !>((~(has by both) %codex-test)))
    (expect-eq !>(%.y) !>((~(has by both) %claude-test)))
    (expect-eq !>(%.n) !>((~(has by replaced) %codex-test)))
    (expect-eq !>(%.y) !>((~(has by replaced) %claude-test)))
    (expect-eq !>(%smol) !>(role.mini))
    (expect-eq !>('openai-codex/gpt-5-mini') !>(selector.mini))
    (expect-eq !>('GPT-5 mini') !>(label.mini))
    (expect-eq !>('catalog') !>(origin.mini))
    (expect-eq !>(replaced) !>(after-empty))
    (expect-eq !>('blocked') !>((json-text (peek-receipt signed-out refused) 'status')))
    (expect-eq !>('sign-in-required') !>((json-text (peek-receipt signed-out refused) 'reason')))
    (expect-eq !>(%.n) !>((~(has by (peek-accounts signed-out)) %codex)))
    (expect-eq !>(%.y) !>((~(has by (peek-accounts signed-out)) %claude)))
    (expect-eq !>(replaced) !>(models:(peek-ai signed-out)))
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
  =/  login  (command-for core [%request-login %login-codex %codex])
  =.  core  (do-command core login)
  =/  import  (command-for core [%import-account %codex %api-key 'sk-planner-key' '' '' ~ ''])
  =.  core  (do-command core import)
  =/  item  (~(got by items:(need (peek-stack core %s1))) %c1)
  ;:  weld
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core grade) 'status')))
    (expect-eq !>('operator-entrypoint-required') !>((json-text (peek-receipt core grade) 'reason')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core edit) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core grant) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core spend) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core start) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core login) 'status')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core import) 'status')))
    (expect-eq !>('ok') !>((json-text (peek-receipt core source) 'status')))
    (expect-eq !>(0) !>(`@`box.learn.item))
    (expect-eq !>(%.n) !>((~(has by questions:(peek-ai core)) %edit-grant)))
    (expect-eq !>(~) !>((peek-logins core)))
    (expect-eq !>(~) !>((peek-accounts core)))
  ==
::
::  System transitions come only from the ship's own responses; neither a
::  planner nor the operator can publish one through the poke boundary.
::
++  test-system-actions-are-never-accepted-from-pokes
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =/  shell  ~(. seer-agent %*(. bol sap /khan))
  =/  untrusted=agent:gall  +:(on-load:shell on-save:core)
  =/  planner  (command-for untrusted [%answer-card-question %q1 1 'Forged' ~ ~])
  =.  untrusted  (do-command untrusted planner)
  =/  operator  (command-for core [%answer-card-question %q1 1 'Forged' ~ ~])
  =.  core  (do-command core operator)
  =/  dispatch  (command-for core [%dispatch-work [%question ~zod %root %q1]])
  =.  core  (do-command core dispatch)
  =/  challenge  (command-for core [%post-login-challenge %login-codex 1 'https://auth.openai.com/codex/device' 'ABCD' 'dev' 5])
  =.  core  (do-command core challenge)
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  ;:  weld
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt untrusted planner) 'status')))
    (expect-eq !>('system-action-required') !>((json-text (peek-receipt untrusted planner) 'reason')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core operator) 'status')))
    (expect-eq !>('system-action-required') !>((json-text (peek-receipt core operator) 'reason')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core dispatch) 'status')))
    (expect-eq !>('system-action-required') !>((json-text (peek-receipt core dispatch) 'reason')))
    (expect-eq !>('unauthorized') !>((json-text (peek-receipt core challenge) 'status')))
    (expect-eq !>(%working) !>(status.question))
    (expect-eq !>(1) !>(attempt.question))
    (expect-eq !>('') !>(response.question))
  ==
::
::  A signed-in provider starts queued work as the ship's own request.
::
++  test-imported-account-dispatches-pending-question
  ^-  tang
  =/  started  connected-question
  =/  question  (~(got by questions:(peek-ai core.started)) %q1)
  =/  job  (need (peek-work core.started %question %root %q1))
  =/  request  (need (request-on cards.started (request-wire %question %q1 1)))
  =/  body  (body-json request)
  ;:  weld
    (expect-eq !>(%working) !>(status.question))
    (expect-eq !>(1) !>(attempt.question))
    (expect-eq !>(%.y) !>(?=(^ packet.question)))
    (expect-eq !>(%running) !>(execution.job))
    (expect-eq !>(1) !>(attempt.job))
    (expect-eq !>(`%codex) !>(provider.job))
    (expect-eq !>(%codex-test) !>(model-id.job))
    (expect-eq !>(%context-frozen) !>(checkpoint.job))
    (expect-eq !>(%'POST') !>(method.request))
    (expect-eq !>(codex-api-url:net) !>(url.request))
    (expect-eq !>(`'Bearer sk-test-codex-key') !>((header:net header-list.request 'authorization')))
    (expect-eq !>(`'test') !>((get-string:net body 'model')))
    (expect-eq !>(`%.y) !>((get-bool:net body 'stream')))
    (expect-eq !>(~) !>((get:net body 'tools')))
    (expect-eq !>(`(add fixed-now ~m3)) !>((wait-on cards.started (deadline-wire %question %q1 1))))
    (expect-eq !>(1) !>((lent (requests cards.started))))
  ==
::
::  Work that needs an expiring OAuth account waits for one refresh. The
::  rotation and the release of that work happen in one event, the new
::  bearer is what leaves the ship, and a stale rotation answer for a
::  replaced slot changes nothing.
::
++  test-renewal-rotates-and-releases-waiting-work
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =^  imported  core
    (run core [%import-account %claude %oauth 'old-access' 'old-refresh' 'acct' `(add fixed-now ~m3) 'user:inference'])
  =/  waiting-account  (~(got by (peek-accounts core)) %claude)
  =/  renew  (need (request-on imported /seer-renew/claude/1))
  =/  grant  (body-json renew)
  =/  token-body
    %-  en:json:html
    %-  json-object
    :~  ['access_token' s+'new-access']
        ['refresh_token' s+'new-refresh']
        ['expires_in' (numb:enjs:format 3.600)]
    ==
  =^  rotated  core  (arvo core /seer-renew/claude/1 (finished 200 ~ token-body))
  =/  account  (~(got by (peek-accounts core)) %claude)
  =/  catalog  (need (request-on rotated /seer-catalog/claude/1))
  =.  core  +:(arvo core /seer-catalog/claude/1 (finished 200 ~ (catalog-body 'claude-test' 'Claude Test')))
  =/  profile  (~(got by models:(peek-ai core)) %claude-claude-test)
  =^  asked  core  (run core [%ask-card %q1 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =/  request  (need (request-on asked (request-wire %question %q1 1)))
  =^  replaced  core
    (run core [%import-account %claude %oauth 'third-access' 'third-refresh' 'acct' `in-one-hour 'user:inference'])
  =^  stale  core  (arvo core /seer-renew/claude/1 (finished 200 ~ token-body))
  =/  after  (~(got by (peek-accounts core)) %claude)
  ;:  weld
    (expect-eq !>(%.y) !>(renewing.waiting-account))
    (expect-eq !>(~) !>((request-on imported /seer-catalog/claude/1)))
    (expect-eq !>(claude-token-url:oa) !>(url.renew))
    (expect-eq !>(`'refresh_token') !>((get-string:net grant 'grant_type')))
    (expect-eq !>(`'old-refresh') !>((get-string:net grant 'refresh_token')))
    (expect-eq !>(`(add fixed-now ~s30)) !>((wait-on imported /seer-renew-deadline/claude/1)))
    (expect-eq !>(%.n) !>(renewing.account))
    (expect-eq !>(`in-one-hour) !>(expires.account))
    (expect-eq !>(`'Bearer new-access') !>((header:net header-list.catalog 'authorization')))
    (expect-eq !>(`'Bearer new-access') !>((header:net header-list.request 'authorization')))
    (expect-eq !>(~) !>((find "old-access" (trip (en:json:html (body-json request))))))
    (expect-eq !>(~) !>((passes stale)))
    (expect-eq !>(`in-one-hour) !>(expires.after))
    (expect-eq !>(%.n) !>(renewing.after))
  ==
::
::  A completed stream stores the answer and its reported usage.
::
++  test-codex-answer-is-stored-with-usage
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =^  cards  core  (arvo core (request-wire %question %q1 1) (finished 200 ~ (codex-answer 'Because.' 10 5)))
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  =/  job  (need (peek-work core %question %root %q1))
  ;:  weld
    (expect-eq !>(%answered) !>(status.question))
    (expect-eq !>('Because.') !>(response.question))
    (expect-eq !>(1) !>(attempt.question))
    (expect-eq !>(%succeeded) !>(execution.job))
    (expect-eq !>(`15) !>(usage.job))
    (expect-eq !>(%.n) !>(retryable.job))
    (expect-eq !>(~) !>((requests cards)))
    (expect-eq !>(%.n) !>(=(~ artifacts.learning:(peek-ai core))))
  ==
::
::  Every provider failure is a named reason and leaves the work retryable.
::
++  test-provider-failures-are-named
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =/  status-of  |=(c=agent:gall status:(~(got by questions:(peek-ai c)) %q1))
  =/  reason-of  |=(c=agent:gall response:(~(got by questions:(peek-ai c)) %q1))
  =^  ignored  core  (arvo core (request-wire %question %q1 1) (finished 429 ~ 'slow down'))
  =/  limited  [(status-of core) (reason-of core)]
  =/  limited-job  (need (peek-work core %question %root %q1))
  =^  retry-one  core  (run core [%retry-card-question %q1])
  =/  second  (~(got by questions:(peek-ai core)) %q1)
  =/  tool-call  (sse-body ~[(json-object ~[['type' s+'response.output_item.done'] ['item' (json-object ~[['type' s+'function_call']])]]) (codex-completed 1 1)])
  =^  ignored  core  (arvo core (request-wire %question %q1 2) (finished 200 ~ tool-call))
  =/  tooled  [(status-of core) (reason-of core)]
  =^  retry-two  core  (run core [%retry-card-question %q1])
  =^  ignored  core  (arvo core (request-wire %question %q1 3) (finished 200 ~ (sse-body ~[(codex-message 'plain prose') (codex-completed 1 1)])))
  =/  prose  [(status-of core) (reason-of core)]
  =^  retry-three  core  (run core [%retry-card-question %q1])
  =^  ignored  core  (arvo core (request-wire %question %q1 4) (finished 503 ~ 'down'))
  =/  down  [(status-of core) (reason-of core)]
  =^  retry-four  core  (run core [%retry-card-question %q1])
  =^  ignored  core  (arvo core (request-wire %question %q1 5) cancelled)
  =/  gone  [(status-of core) (reason-of core)]
  =^  retry-five  core  (run core [%retry-card-question %q1])
  =^  ignored  core  (arvo core (request-wire %question %q1 6) (finished 401 ~ 'nope'))
  =/  refused  [(status-of core) (reason-of core)]
  ;:  weld
    (expect-eq !>([%failed 'provider-rate-limited']) !>(limited))
    (expect-eq !>(%.y) !>(retryable.limited-job))
    (expect-eq !>(%working) !>(status.second))
    (expect-eq !>(2) !>(attempt.second))
    (expect-eq !>(%.y) !>(?=(^ (request-on retry-one (request-wire %question %q1 2)))))
    (expect-eq !>([%failed 'invalid-provider-output']) !>(tooled))
    (expect-eq !>([%failed 'invalid-provider-output']) !>(prose))
    (expect-eq !>([%failed 'provider-unavailable']) !>(down))
    (expect-eq !>([%failed 'unreachable']) !>(gone))
    (expect-eq !>([%failed 'provider-unauthorized']) !>(refused))
    (expect-eq !>(6) !>(attempt:(~(got by questions:(peek-ai core)) %q1)))
  ==
::
::  Only the current attempt of running work can settle it.
::
++  test-stale-attempt-responses-are-ignored
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =/  before  (peek-ai core)
  =^  stale  core  (arvo core (request-wire %question %q1 2) (finished 200 ~ (codex-answer 'Wrong attempt' 1 1)))
  =/  unchanged  (peek-ai core)
  =^  early-deadline  core  (arvo core (deadline-wire %question %q1 2) wake)
  =/  still-working  (~(got by questions:(peek-ai core)) %q1)
  =^  answer  core  (arvo core (request-wire %question %q1 1) (finished 200 ~ (codex-answer 'Because.' 10 5)))
  =/  answered  (peek-ai core)
  =^  late  core  (arvo core (request-wire %question %q1 1) (finished 200 ~ (codex-answer 'Late answer' 1 1)))
  =/  after-late  (peek-ai core)
  =^  late-deadline  core  (arvo core (deadline-wire %question %q1 1) wake)
  =/  after-deadline  (~(got by questions:(peek-ai core)) %q1)
  ;:  weld
    (expect-eq !>(~) !>((passes stale)))
    (expect-eq !>(before) !>(unchanged))
    (expect-eq !>(~) !>((passes early-deadline)))
    (expect-eq !>(%working) !>(status.still-working))
    (expect-eq !>('Because.') !>(response:(~(got by questions.answered) %q1)))
    (expect-eq !>(~) !>((passes late)))
    (expect-eq !>(answered) !>(after-late))
    (expect-eq !>(~) !>((passes late-deadline)))
    (expect-eq !>(%answered) !>(status.after-deadline))
  ==
::
::  A deadline on running work is an unknown outcome: the provider may
::  have executed, so the record says so and the request is cancelled.
::
++  test-deadline-fails-working-question-as-unknown
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =^  cards  core  (arvo core (deadline-wire %question %q1 1) wake)
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  =/  job  (need (peek-work core %question %root %q1))
  ;:  weld
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>('timeout') !>(response.question))
    (expect-eq !>(%failed) !>(execution.job))
    (expect-eq !>(%unknown) !>(effect.job))
    (expect-eq !>(`%timeout) !>(stop-reason.job))
    (expect-eq !>(%.y) !>((cancel-on cards (request-wire %question %q1 1))))
    (expect-eq !>(~) !>((requests cards)))
  ==
::
::  Output past the byte cap is cancelled and named, never truncated.
::
::  A reload settles attempts whose deadline passed while the agent could
::  not receive wakes; an attempt still inside its window is untouched and
::  the late wake for the settled one is a no-op.
::
++  test-reload-settles-overdue-attempts
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =/  fresh  ~(. seer-agent bol)
  =^  early  fresh  (on-load:fresh on-save:core)
  =/  untouched  (~(got by questions:(peek-ai fresh)) %q1)
  =/  later  ~(. seer-agent %*(. bol now (add fixed-now ~h1)))
  =^  cards  later  (on-load:later on-save:core)
  =/  question  (~(got by questions:(peek-ai later)) %q1)
  =/  job  (need (peek-work later %question %root %q1))
  =^  late  later  (arvo later (deadline-wire %question %q1 1) wake)
  ;:  weld
    (expect-eq !>(%working) !>(status.untouched))
    (expect-eq !>(~) !>((cancels early)))
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>('timeout') !>(response.question))
    (expect-eq !>(%unknown) !>(effect.job))
    (expect-eq !>(%.y) !>((cancel-on cards (request-wire %question %q1 1))))
    (expect-eq !>(~) !>((cancels late)))
  ==
::  Cancelling running provider work cancels its request, records that the
::  provider may already have run, and fences the late answer.
::
++  test-cancel-work-fences-the-late-answer
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =^  cards  core  (run core [%cancel-work [%question ~zod %root %q1]])
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  =/  job  (need (peek-work core %question %root %q1))
  =^  late  core
    (arvo core (request-wire %question %q1 1) (finished 200 ~ '{"answer":"late","citations":[]}'))
  =/  after  (~(got by questions:(peek-ai core)) %q1)
  =/  repeat  (command-for core [%cancel-work [%question ~zod %root %q1]])
  =.  core  (do-command core repeat)
  ;:  weld
    (expect-eq !>(~[(request-wire %question %q1 1)]) !>((cancels cards)))
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>('cancelled') !>(response.question))
    (expect-eq !>(%cancelled) !>(execution.job))
    (expect-eq !>(%unknown) !>(effect.job))
    (expect-eq !>(`%cancelled) !>(stop-reason.job))
    (expect-eq !>(~) !>((passes late)))
    (expect-eq !>(%failed) !>(status.after))
    (expect-eq !>('cancelled') !>(response.after))
    (expect-eq !>('work-already-settled') !>((json-text (peek-receipt core repeat) 'reason')))
  ==
++  test-output-over-cap-is-cancelled-and-named
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =^  small  core  (arvo core (request-wire %question %q1 1) (progress 1.000))
  =/  still-working  (~(got by questions:(peek-ai core)) %q1)
  =^  cards  core  (arvo core (request-wire %question %q1 1) (progress 262.145))
  =/  question  (~(got by questions:(peek-ai core)) %q1)
  =/  job  (need (peek-work core %question %root %q1))
  ;:  weld
    (expect-eq !>(~) !>((passes small)))
    (expect-eq !>(%working) !>(status.still-working))
    (expect-eq !>(%failed) !>(status.question))
    (expect-eq !>('output-limit') !>(response.question))
    (expect-eq !>(%failed) !>(execution.job))
    (expect-eq !>(%.y) !>((cancel-on cards (request-wire %question %q1 1))))
  ==
::
::  Web sources are fetched by the ship under its destination policy;
::  redirects are re-issued by the agent and html is reduced to text.
::
++  test-web-sources-are-fetched-under-destination-policy
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =^  local-cards  core  (web-source core %local 'http://localhost/x')
  =^  numeric-cards  core  (web-source core %numeric 'http://10.0.0.1/')
  =^  cards  core  (web-source core %public 'https://example.com/page')
  =/  request  (need (request-on cards (request-wire %context %public 1)))
  =/  contexts  contexts:(peek-ai core)
  =^  moved  core  (arvo core (request-wire %context %public 1) (finished 301 ~[['Location' 'https://example.com/moved']] ''))
  =/  hop  (need (request-on moved (request-wire %context %public 1)))
  =/  job  (need (peek-work core %context %root %public))
  =/  html
    '<html><head><title>Moved</title><script>track()</script></head><body><h1>Title</h1><p>Hello &amp; welcome</p></body></html>'
  =^  done  core  (arvo core (request-wire %context %public 1) (finished 200 ~[['content-type' 'text/html; charset=utf-8']] html))
  =/  source  (~(got by contexts:(peek-ai core)) %public)
  =/  text  (snapshot-text core (need snapshot.source))
  ;:  weld
    (expect-eq !>(~) !>((requests local-cards)))
    (expect-eq !>(~) !>((requests numeric-cards)))
    (expect-eq !>(%failed) !>(status:(~(got by contexts) %local)))
    (expect-eq !>('private-host') !>(error:(~(got by contexts) %local)))
    (expect-eq !>(%failed) !>(status:(~(got by contexts) %numeric)))
    (expect-eq !>('ip-literal') !>(error:(~(got by contexts) %numeric)))
    (expect-eq !>(%working) !>(status:(~(got by contexts) %public)))
    (expect-eq !>(1) !>(attempt:(~(got by contexts) %public)))
    (expect-eq !>(%'GET') !>(method.request))
    (expect-eq !>('https://example.com/page') !>(url.request))
    (expect-eq !>(`(add fixed-now ~s20)) !>((wait-on cards (deadline-wire %context %public 1))))
    (expect-eq !>(%'GET') !>(method.hop))
    (expect-eq !>('https://example.com/moved') !>(url.hop))
    (expect-eq !>(1) !>(redirects.job))
    (expect-eq !>(`'https://example.com/moved') !>(external.job))
    (expect-eq !>(%ready) !>(status.source))
    (expect-eq !>('') !>(error.source))
    (expect-eq !>(%.y) !>(?=(^ (find "Title" text))))
    (expect-eq !>(%.y) !>(?=(^ (find "Hello & welcome" text))))
    (expect-eq !>(~) !>((find "track" text)))
    (expect-eq !>(~) !>((find "<" text)))
    (expect-eq !>(~) !>((requests done)))
  ==
::
++  test-web-fetch-failures-are-named
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =/  source-of  |=([c=agent:gall id=@tas] (~(got by contexts:(peek-ai c)) id))
  =/  outcome  |=([c=agent:gall id=@tas] =/(s (source-of c id) [status.s error.s]))
  =^  ignored  core  (web-source core %bounce 'https://example.com/bounce')
  =^  ignored  core  (arvo core (request-wire %context %bounce 1) (finished 302 ~[['location' 'http://localhost/secret']] ''))
  =/  bounced  (outcome core %bounce)
  =^  ignored  core  (web-source core %relative 'https://example.com/relative')
  =^  ignored  core  (arvo core (request-wire %context %relative 1) (finished 302 ~[['location' 'elsewhere']] ''))
  =/  relative  (outcome core %relative)
  =^  ignored  core  (web-source core %loop 'https://example.com/loop')
  =.  core
    =/  hops=@ud  6
    |-
    ?:  =(0 hops)  core
    =^  ignored  core  (arvo core (request-wire %context %loop 1) (finished 301 ~[['location' 'https://example.com/loop']] ''))
    $(hops (dec hops))
  =/  looped  (outcome core %loop)
  =^  ignored  core  (web-source core %missing 'https://example.com/missing')
  =^  ignored  core  (arvo core (request-wire %context %missing 1) (finished 404 ~ 'nothing'))
  =/  missing  (outcome core %missing)
  =^  retried  core  (run core [%retry-context-source %missing])
  =/  retrying  (source-of core %missing)
  =^  ignored  core  (arvo core (request-wire %context %missing 2) (finished 503 ~ 'down'))
  =/  down  (outcome core %missing)
  =^  ignored  core  (web-source core %slow 'https://example.com/slow')
  =^  slow-cards  core  (arvo core (deadline-wire %context %slow 1) wake)
  =/  slow  (outcome core %slow)
  =^  ignored  core  (web-source core %big 'https://example.com/big')
  =^  big-cards  core  (arvo core (request-wire %context %big 1) (progress 131.073))
  =/  big  (outcome core %big)
  =^  ignored  core  (web-source core %gone 'https://example.com/gone')
  =^  ignored  core  (arvo core (request-wire %context %gone 1) cancelled)
  =/  gone  (outcome core %gone)
  =^  ignored  core  (web-source core %empty 'https://example.com/empty')
  =^  ignored  core  (arvo core (request-wire %context %empty 1) (finished 200 ~[['content-type' 'text/html']] '<html><script>only()</script></html>'))
  =/  empty  (outcome core %empty)
  ;:  weld
    (expect-eq !>([%failed 'destination-rejected']) !>(bounced))
    (expect-eq !>([%failed 'invalid-redirect']) !>(relative))
    (expect-eq !>([%failed 'redirect-limit']) !>(looped))
    (expect-eq !>(5) !>(redirects:(need (peek-work core %context %root %loop))))
    (expect-eq !>([%failed 'fetch-failed']) !>(missing))
    (expect-eq !>(%working) !>(status.retrying))
    (expect-eq !>(2) !>(attempt.retrying))
    (expect-eq !>(%.y) !>(?=(^ (request-on retried (request-wire %context %missing 2)))))
    (expect-eq !>([%failed 'provider-unavailable']) !>(down))
    (expect-eq !>([%failed 'timeout']) !>(slow))
    (expect-eq !>(%.y) !>((cancel-on slow-cards (request-wire %context %slow 1))))
    (expect-eq !>([%failed 'output-limit']) !>(big))
    (expect-eq !>(%.y) !>((cancel-on big-cards (request-wire %context %big 1))))
    (expect-eq !>([%failed 'unreachable']) !>(gone))
    (expect-eq !>([%failed 'fetch-failed']) !>(empty))
  ==
::
::  Codex sign-in is the device flow, run entirely by the ship: usercode,
::  self-polling, exchange, and an account slot whose secrets no read shows.
::
++  test-codex-device-flow-runs-on-the-ship
  ^-  tang
  =/  core  ag
  =^  cards  core  (run core [%request-login %login-codex %codex])
  =/  usercode  (need (request-on cards (login-wire %login-codex %usercode 1)))
  =/  working  (~(got by (peek-logins core)) %login-codex)
  =^  challenged  core
    (arvo core (login-wire %login-codex %usercode 1) (finished 200 ~ '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH","interval":5}'))
  =/  challenge  (~(got by (peek-logins core)) %login-codex)
  =^  polled  core  (arvo core (poll-wire %login-codex 1) wake)
  =/  poll  (need (request-on polled (login-wire %login-codex %poll 1)))
  =^  pending  core  (arvo core (login-wire %login-codex %poll 1) (finished 202 ~ '{"status":"pending"}'))
  =^  polled-again  core  (arvo core (poll-wire %login-codex 1) wake)
  =^  coded  core
    (arvo core (login-wire %login-codex %poll 1) (finished 200 ~ '{"authorization_code":"code-1","code_verifier":"ver-1"}'))
  =/  exchanging  (~(got by (peek-logins core)) %login-codex)
  =/  exchange  (need (request-on coded (login-wire %login-codex %exchange 1)))
  =/  form  (trip q:(need body.exchange))
  =^  granted  core  (arvo core (login-wire %login-codex %exchange 1) (finished 200 ~ codex-token-body))
  =/  done  (~(got by (peek-logins core)) %login-codex)
  =/  account  (~(got by (peek-accounts core)) %codex)
  =/  catalog  (need (wire-headed granted %seer-catalog))
  =/  catalog-request  (need (request-on granted catalog))
  =/  context  (trip (en:json:html (peek-context core)))
  =/  signed-out  (do-noun core [%clear-account %codex])
  =/  removed-peek  (mule |.((on-peek:core /x/login-code)))
  ;:  weld
    (expect-eq !>(%'POST') !>(method.usercode))
    (expect-eq !>(codex-usercode-url:oa) !>(url.usercode))
    (expect-eq !>(%working) !>(status.working))
    (expect-eq !>(1) !>(attempt.working))
    (expect-eq !>(`(add fixed-now login-window:oa)) !>(deadline.working))
    (expect-eq !>(`(add fixed-now login-window:oa)) !>((wait-on cards (deadline-wire %login %login-codex 1))))
    (expect-eq !>(%challenge) !>(status.challenge))
    (expect-eq !>(codex-device-page:oa) !>(auth-url.challenge))
    (expect-eq !>('ABCD-EFGH') !>(user-code.challenge))
    (expect-eq !>('') !>(device-id.challenge))
    (expect-eq !>(5) !>(interval.challenge))
    (expect-eq !>(`(add fixed-now ~s5)) !>((wait-on challenged (poll-wire %login-codex 1))))
    (expect-eq !>(codex-poll-url:oa) !>(url.poll))
    (expect-eq !>(`'dev-1') !>((get-string:net (body-json poll) 'device_auth_id')))
    (expect-eq !>(`'ABCD-EFGH') !>((get-string:net (body-json poll) 'user_code')))
    (expect-eq !>(`(add fixed-now ~s5)) !>((wait-on pending (poll-wire %login-codex 1))))
    (expect-eq !>(%.y) !>(?=(^ (request-on polled-again (login-wire %login-codex %poll 1)))))
    (expect-eq !>(%working) !>(status.exchanging))
    (expect-eq !>('') !>(verifier.exchanging))
    (expect-eq !>(codex-token-url:oa) !>(url.exchange))
    (expect-eq !>(%.y) !>(?=(^ (find "code=code-1" form))))
    (expect-eq !>(%.y) !>(?=(^ (find "code_verifier=ver-1" form))))
    (expect-eq !>(%done) !>(status.done))
    (expect-eq !>('') !>(auth-url.done))
    (expect-eq !>('') !>(user-code.done))
    (expect-eq !>(~) !>(deadline.done))
    (expect-eq !>(%oauth) !>(method.account))
    (expect-eq !>('acct-1') !>(account.account))
    (expect-eq !>(`in-one-hour) !>(expires.account))
    (expect-eq !>(%.n) !>(renewing.account))
    (expect-eq !>(codex-catalog-oauth:net) !>(url.catalog-request))
    (expect-eq !>(`'acct-1') !>((header:net header-list.catalog-request 'chatgpt-account-id')))
    (expect-eq !>(`(cat 3 'Bearer ' codex-access-token)) !>((header:net header-list.catalog-request 'authorization')))
    (expect-eq !>(~) !>((find (trip codex-access-token) context)))
    (expect-eq !>(~) !>((find "codex-refresh-1" context)))
    (expect-eq !>(~) !>((peek-accounts signed-out)))
    (expect-eq !>(%.y) !>(?=(%| -.removed-peek)))
  ==
::
::  A device challenge dies at its deadline; a late poll answer cannot
::  revive it, and a retry starts a new attempt. Only a request that is
::  actually in flight is cancelled: iris rejects any other cancel.
::
++  test-codex-challenge-expires-and-cancels
  ^-  tang
  =/  core  ag
  =.  core  (do core [%request-login %login-codex %codex])
  =^  ignored  core
    (arvo core (login-wire %login-codex %usercode 1) (finished 200 ~ '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH","interval":5}'))
  =^  polling  core  (arvo core (poll-wire %login-codex 1) wake)
  =^  expired-cards  core  (arvo core (deadline-wire %login %login-codex 1) wake)
  =/  expired  (~(got by (peek-logins core)) %login-codex)
  =^  late  core
    (arvo core (login-wire %login-codex %poll 1) (finished 200 ~ '{"authorization_code":"code-1","code_verifier":"ver-1"}'))
  =/  still-expired  (~(got by (peek-logins core)) %login-codex)
  =^  retried  core  (run core [%retry-login %login-codex])
  =/  again  (~(got by (peek-logins core)) %login-codex)
  =^  cancel-cards  core  (run core [%cancel-login %login-codex])
  =/  cancelled-login  (~(got by (peek-logins core)) %login-codex)
  =.  core  (do core [%cancel-login %login-codex])
  ;:  weld
    (expect-eq !>(%failed) !>(status.expired))
    (expect-eq !>('expired') !>(message.expired))
    (expect-eq !>('') !>(user-code.expired))
    (expect-eq !>(~) !>(deadline.expired))
    (expect-eq !>(%.y) !>(?=(^ (request-on polling (login-wire %login-codex %poll 1)))))
    (expect-eq !>(~[(login-wire %login-codex %poll 1)]) !>((cancels expired-cards)))
    (expect-eq !>(~) !>((passes late)))
    (expect-eq !>(%failed) !>(status.still-expired))
    (expect-eq !>(%working) !>(status.again))
    (expect-eq !>(2) !>(attempt.again))
    (expect-eq !>(%.y) !>(?=(^ (request-on retried (login-wire %login-codex %usercode 2)))))
    (expect-eq !>(%failed) !>(status.cancelled-login))
    (expect-eq !>('cancelled') !>(message.cancelled-login))
    (expect-eq !>(~[(login-wire %login-codex %usercode 2)]) !>((cancels cancel-cards)))
    (expect-eq !>(~) !>((peek-logins core)))
    (expect-eq !>(~) !>((peek-accounts core)))
  ==
::
::  Claude sign-in is the paste-back flow: the ship holds the verifier and
::  state, rejects a code pasted with the wrong state, and exchanges the
::  right one itself.
::
++  test-claude-paste-back-verifies-state
  ^-  tang
  =/  core  ag
  =^  cards  core  (run core [%request-login %login-claude %claude])
  =/  challenge  (~(got by (peek-logins core)) %login-claude)
  =/  keys  (pkce:oa eny:bol)
  =/  link  (trip auth-url.challenge)
  =/  wrong  (command-for core [%submit-login-code %login-claude 'code-1#not-the-state'])
  =.  core  (do-command core wrong)
  =/  still  (~(got by (peek-logins core)) %login-claude)
  =^  exchanging  core  (run core [%submit-login-code %login-claude (rap 3 'code-1#' state.keys ~)])
  =/  working  (~(got by (peek-logins core)) %login-claude)
  =/  exchange  (need (request-on exchanging (login-wire %login-claude %exchange 1)))
  =/  body  (body-json exchange)
  =^  granted  core  (arvo core (login-wire %login-claude %exchange 1) (finished 200 ~ claude-token-body))
  =/  done  (~(got by (peek-logins core)) %login-claude)
  =/  account  (~(got by (peek-accounts core)) %claude)
  =/  context  (trip (en:json:html (peek-context core)))
  ;:  weld
    (expect-eq !>(~) !>((requests cards)))
    (expect-eq !>(%challenge) !>(status.challenge))
    (expect-eq !>(1) !>(attempt.challenge))
    (expect-eq !>(claude-authorize-url:oa) !>((crip (scag (lent (trip claude-authorize-url:oa)) link))))
    (expect-eq !>(%.y) !>(?=(^ (find (weld "code_challenge=" (trip challenge.keys)) link))))
    (expect-eq !>(%.y) !>(?=(^ (find (weld "state=" (trip state.keys)) link))))
    (expect-eq !>('') !>(user-code.challenge))
    (expect-eq !>('') !>(verifier.challenge))
    (expect-eq !>('') !>(nonce.challenge))
    (expect-eq !>(`(add fixed-now login-window:oa)) !>(deadline.challenge))
    (expect-eq !>('invalid') !>((json-text (peek-receipt core wrong) 'status')))
    (expect-eq !>('invalid-login-state') !>((json-text (peek-receipt core wrong) 'reason')))
    (expect-eq !>(%challenge) !>(status.still))
    (expect-eq !>(%working) !>(status.working))
    (expect-eq !>('') !>(pasted-code.working))
    (expect-eq !>(claude-token-url:oa) !>(url.exchange))
    (expect-eq !>(`'code-1') !>((get-string:net body 'code')))
    (expect-eq !>(`state.keys) !>((get-string:net body 'state')))
    (expect-eq !>(`verifier.keys) !>((get-string:net body 'code_verifier')))
    (expect-eq !>(%done) !>(status.done))
    (expect-eq !>('') !>(auth-url.done))
    (expect-eq !>(%oauth) !>(method.account))
    (expect-eq !>('user-1') !>(account.account))
    (expect-eq !>(`in-one-hour) !>(expires.account))
    (expect-eq !>('user:inference') !>(scopes.account))
    (expect-eq !>(~) !>((find "sk-ant-oat01-access" context)))
    (expect-eq !>(~) !>((find "sk-ant-ort01-refresh" context)))
    (expect-eq !>(~) !>((find (trip verifier.keys) context)))
  ==
::
::  Exact retained asks avoid a second invocation; changed inputs cannot reuse.
::
++  test-source-qualified-answer-reuse
  ^-  tang
  =/  started  connected-question
  =/  core  core.started
  =^  ignored  core  (arvo core (request-wire %question %q1 1) (finished 200 ~ (codex-answer 'Qualified explanation' 10 5)))
  =/  completed  (need (peek-work core %question %root %q1))
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =^  reused-cards  core  (run core [%ask-card %q2 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =/  reused  (~(got by questions:(peek-ai core)) %q2)
  =/  reused-work  (need (peek-work core %question %root %q2))
  =.  core  (do core [%edit-item ~zod %s1 %c1 'Card' *perm-config 'changed front' 'back'])
  =^  fresh-cards  core  (run core [%ask-card %q3 ~zod %s1 %c1 %ask profile 'Explain' ~ 65.536 32.768])
  =/  fresh  (~(got by questions:(peek-ai core)) %q3)
  ;:  weld
    (expect-eq !>(%succeeded) !>(execution.completed))
    (expect-eq !>(1) !>(attempt.completed))
    (expect-eq !>(%answered) !>(status.reused))
    (expect-eq !>('Qualified explanation') !>(response.reused))
    (expect-eq !>(0) !>(attempt.reused-work))
    (expect-eq !>(~) !>((requests reused-cards)))
    (expect-eq !>(%working) !>(status.fresh))
    (expect-eq !>(1) !>(attempt.fresh))
    (expect-eq !>(%.y) !>(?=(^ (request-on fresh-cards (request-wire %question %q3 1)))))
  ==
::
::  Attaching evidence never grants provider egress implicitly.
::
++  test-source-egress-requires-owner-grant
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (do core [%new-item ~zod ~zod %s1 %c1 'Card' *perm-config 'front' 'back'])
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =.  core  (do core [%add-context-source %source [%stack ~zod %s1 ~] %note 'Private note' '' 'Private evidence'])
  =/  selections=(list evidence-selection)  ~[[%source 0 ~ %.y %.y]]
  =^  denied-cards  core  (run core [%ask-card %denied ~zod %s1 %c1 %ask profile 'Explain' selections 65.536 32.768])
  =/  denied  (~(got by questions:(peek-ai core)) %denied)
  =/  denied-work  (need (peek-work core %question %root %denied))
  =.  core  (do core [%set-context-egress %source (silt ~[%codex])])
  =^  allowed-cards  core  (run core [%ask-card %allowed ~zod %s1 %c1 %ask profile 'Explain' selections 65.536 32.768])
  =/  allowed  (~(got by questions:(peek-ai core)) %allowed)
  ;:  weld
    (expect-eq !>(%failed) !>(status.denied))
    (expect-eq !>(0) !>(attempt.denied-work))
    (expect-eq !>(~) !>((requests denied-cards)))
    (expect-eq !>(%working) !>(status.allowed))
    (expect-eq !>(%.y) !>(?=(^ packet.allowed)))
    (expect-eq !>(%.y) !>(?=(^ (request-on allowed-cards (request-wire %question %allowed 1)))))
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
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =.  core  (do core [%ask-card %q1 ~zod %s1 %a %ask profile 'Explain' ~ 65.536 32.768])
  =.  core  (do core [%request-login %login-claude %claude])
  =/  query  read-query
  =/  metadata  (peek-read core query(kind %question, status `%working))
  =/  question  (snag 0 (json-rows metadata 'questions'))
  ?>  ?=(%o -.question)
  =/  detail  (peek-read core query(kind %question, id `%q1, projection %detail, limit 1, max-bytes 65.536))
  =/  answerable  (snag 0 (json-rows detail 'questions'))
  =/  logins  (peek-read core query(kind %login, projection %detail))
  =/  login  (snag 0 (json-rows logins 'logins'))
  ?>  ?=(%o -.login)
  =/  limited  (peek-read core query(kind %card, stack `%s1, id `%a, projection %detail, max-bytes 5.000))
  =/  tiny  (peek-read core query(max-bytes 1.024))
  =/  missing  (peek-read core query(kind %question, id `%not-found))
  ;:  weld
    (expect-eq !>(%.n) !>((~(has by p.question) 'front')))
    (expect-eq !>(%.n) !>((~(has by p.question) 'question')))
    (expect-eq !>(quotes) !>((json-text answerable 'front')))
    (expect-eq !>('Explain') !>((json-text answerable 'question')))
    (expect-eq !>(%.n) !>((~(has by p.login) 'verifier')))
    (expect-eq !>(%.n) !>((~(has by p.login) 'nonce')))
    (expect-eq !>(%.n) !>((~(has by p.login) 'auth_url')))
    (expect-eq !>('ok') !>((json-text limited 'status')))
    (expect-eq !>(~) !>((json-rows limited 'cards')))
    (expect-eq !>('row-too-large') !>((json-text (snag 0 (json-rows limited 'omissions')) 'reason')))
    (expect-eq !>(b+%.y) !>((json-field limited 'complete')))
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
++  test-unsent-change-can-be-discarded
  ^-  tang
  =/  core  (connect ag %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =.  core  (do core [%request-change %unsent %library profile 'Add a card' %.n])
  =/  discarded  (do core [%reject-change %unsent])
  =/  after-start  (do discarded [%start-change %unsent])
  ;:  weld
    (expect-eq !>(%draft) !>(status:(~(got by changes:(peek-ai core)) %unsent)))
    (expect-eq !>(%rejected) !>(status:(~(got by changes:(peek-ai discarded)) %unsent)))
    (expect-eq !>(%rejected) !>(status:(~(got by changes:(peek-ai after-start)) %unsent)))
  ==
::
++  test-activity-keeps-important-outcomes-visible
  ^-  tang
  =/  receipt
    %*  .  *operation-receipt
      authority  %operator
      status     %ok
      effect     %none
    ==
  =/  rows=(list operation-receipt)
    :~  receipt(id 'answer', action %answered-item)
        receipt(id 'queue', action %update-review)
        receipt(id 'create', action %new-stack)
        receipt(id 'cleanup', action %collect-retained)
        receipt(id 'system-cleanup', action %collect-retained, authority %system)
        receipt(id 'blocked-review', action %answered-item, status %blocked)
        receipt(id 'unknown-work', action %dispatch-work, authority %system, effect %unknown)
        receipt(id 'dispatch', action %dispatch-work, authority %system)
        receipt(id 'failed-dispatch', action %dispatch-work, authority %system, status %blocked)
        receipt(id 'catalog', action %replace-assistant-models, authority %system)
        receipt(id 'rotate', action %rotate-account, authority %system)
    ==
  =/  visible
    %+  turn  (skip rows operation-background)
    |=(record=operation-receipt id.record)
  (expect-eq !>(~['create' 'cleanup' 'blocked-review' 'unknown-work' 'failed-dispatch']) !>(visible))
::
++  test-browser-source-preparation-accepts-decimal-budgets
  ^-  tang
  =/  core  (connect ag %codex)
  =.  core  (do core [%begin-capture %cap 'Capture' 'Goal' 'Source' 'Owner'])
  =.  core  (do core [%add-context-source %source [%capture %cap] %note 'Note' '' 'Source'])
  =.  core  (do core [%set-context-egress %source (silt ~[%codex])])
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =/  act=action  [%prepare-capture %cap profile ~[[%source 0 ~ %.y %.y]] 32.768 8.192]
  =/  cmd  (make-command (slav %da (peek-epoch core)) 'web-prepare' act)
  =/  body
    (crip "capture=cap&model=codex-test&context-source=1&max-bytes=32768&excerpt-bytes=8192&idempotency-epoch={(trip (peek-epoch core))}&operation-id=web-prepare")
  =/  request=inbound-request:eyre
    %*  .  *inbound-request:eyre
      authenticated  %.y
      request  [%'POST' '/apps/seer/actions/prepare-capture' ~ `[(met 3 body) body]]
    ==
  =/  web-bowl  bol
  =/  shell  ~(. seer-agent web-bowl(sap /eyre))
  =/  browser  +:(on-load:shell on-save:core)
  =/  prepared  +:(on-poke:browser %handle-http-request !>(['web-check' request]))
  (expect-eq !>('ok') !>((json-text (peek-receipt prepared cmd) 'status')))
::
++  test-read-observation-dependencies
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'One' ~])
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
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
  =^  refresh  core  (run core [%refresh-catalog %codex])
  =^  ignored  core
    (arvo core (need (wire-headed refresh %seer-catalog)) (finished 200 ~ (catalog-body 'test' 'Changed definition')))
  =/  after  (peek-read core query(since `(json-text before 'watermark')))
  ;:  weld
    (expect-eq !>(b+%.y) !>((json-field row 'has_provenance')))
    (expect-eq !>(n+'0') !>((json-field (json-field (json-field overview 'counts') 'card') 'without_provenance')))
    (expect-eq !>('Changed definition') !>(label:(~(got by models:(peek-ai core)) %codex-test)))
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
::  A late response for an unlinked fetch changes nothing.
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
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
  =.  core  (do core [%add-context-source %note [%stack ~zod %shared ~] %note 'Note' '' 'Historical note'])
  =.  core  (do core [%add-context-source %file [%stack ~zod %shared `%c1] %file 'File' 'fixture.txt' 'Historical file'])
  =.  core  (do core [%add-context-source %clay [%stack ~zod %shared `%c1] %clay 'Clay' '/~nec/base/fixture/txt' ''])
  =/  clay  (~(got by contexts:(peek-ai core)) %clay)
  =.  core  (take-clay core %clay generation.clay 'Historical Clay')
  =.  core  (do core [%add-context-source %web-stack [%stack ~zod %shared ~] %web 'Stack web' 'https://example.invalid/stack' ''])
  =.  core  (do core [%add-context-source %web-card [%stack ~zod %shared `%c1] %web 'Card web' 'https://example.invalid/card' ''])
  =.  core  (do core [%add-context-source %sibling [%stack ~zod %shared `%c2] %note 'Sibling' '' 'Sibling evidence'])
  =.  core  (do core [%add-context-source %other [%stack ~zod %other ~] %note 'Other' '' 'Other evidence'])
  =.  core  (do core [%add-context-source %remote [%stack ~nec %shared ~] %note 'Remote' '' 'Remote evidence'])
  =.  core  (do core [%set-context-egress %note (silt ~[%codex])])
  =.  core  (do core [%set-context-egress %file (silt ~[%codex])])
  =.  core  (do core [%set-context-egress %clay (silt ~[%codex])])
  ::  Signed out, a question keeps its frozen packet and waits for a provider.
  =.  core  (do-noun core [%clear-account %codex])
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
  =.  core  (do core [%delete-item %shared %c1])
  =/  card-deleted  (peek-ai core)
  =.  core  (do core [%delete-stack ~zod %shared])
  =/  stack-deleted  (peek-ai core)
  =^  late-card  core  (arvo core (request-wire %context %web-card 1) (finished 200 ~ 'Late card bytes'))
  =^  late-stack  core  (arvo core (request-wire %context %web-stack 1) (finished 200 ~ 'Late stack bytes'))
  =.  core  (take-clay core %clay generation.clay 'Late Clay bytes')
  =/  after  (peek-ai core)
  =/  archived-work  (need (peek-work core %context %root %web-card))
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
    (expect-eq !>(%working) !>(status:(~(got by contexts.before) %web-stack)))
    (expect-eq !>(%working) !>(status:(~(got by contexts.before) %web-card)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %file)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %clay)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.card-deleted) %web-card)))
    (expect-eq !>((~(got by contexts.before) %note)) !>((~(got by contexts.card-deleted) %note)))
    (expect-eq !>((~(got by contexts.before) %web-stack)) !>((~(got by contexts.card-deleted) %web-stack)))
    (expect-eq !>((~(got by contexts.before) %sibling)) !>((~(got by contexts.card-deleted) %sibling)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %note)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %web-stack)))
    (expect-eq !>(%.n) !>(active:(~(got by contexts.after) %sibling)))
    (expect-eq !>((~(got by contexts.before) %other)) !>((~(got by contexts.after) %other)))
    (expect-eq !>((~(got by contexts.before) %remote)) !>((~(got by contexts.after) %remote)))
    (expect-eq !>(~) !>((passes late-card)))
    (expect-eq !>(~) !>((passes late-stack)))
    (expect-eq !>(~) !>(snapshot:(~(got by contexts.after) %web-card)))
    (expect-eq !>(~) !>(snapshot:(~(got by contexts.after) %web-stack)))
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
::  Rejection suppresses identical inputs, not the underlying factual claim.
::
++  test-proposal-rejection-deduplicates-without-disproof
  ^-  tang
  =/  core  (do ag [%new-stack %s1 'Stack' ~])
  =.  core  (connect core %codex)
  =/  profile  (~(got by models:(peek-ai core)) %codex-test)
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
