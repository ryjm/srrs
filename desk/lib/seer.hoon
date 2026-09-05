/-  *seer
|%
::
++  seer-schema-version  2
::
++  make-command
  |=  [epoch=@da operation=@t act=action]
  ^-  command
  [seer-schema-version epoch operation (shax (jam act)) (shax (jam [epoch operation act])) act]
::
++  command-vase
  |=  [epoch=@da operation=@t act=action]
  ^-  vase
  !>((make-command epoch operation act))
::
++  decimal-text
  |=  value=@ud
  ^-  @t
  (crip (skip (scow %ud value) |=(c=@t =('.' c))))
::
++  citation-fields
  |=  citations=(list evidence-citation)
  ^-  (list @t)
  :-  (decimal-text (lent citations))
  %-  zing
  %+  turn  citations
  |=  citation=evidence-citation
  :~  (scot %ux snapshot.citation)
      (decimal-text start.citation)
      (decimal-text end.citation)
      quote.citation
  ==
::
++  citations-json
  |=  citations=(list evidence-citation)
  ^-  json
  :-  %a
  %+  turn  citations
  |=  citation=evidence-citation
  %-  pairs:enjs:format
  :~  ['snapshot_ref' s+(scot %ux snapshot.citation)]
      ['start' (numb:enjs:format start.citation)]
      ['end' (numb:enjs:format end.citation)]
      ['quote' s+quote.citation]
  ==
::
++  context-body
  |=  [source=context-source store=evidence-state]
  ^-  (unit @t)
  ?~  snapshot.source  ~
  =/  found  (~(get by snapshots.store) u.snapshot.source)
  ?~  found  ~
  ?.  available.u.found  ~
  (~(get by blobs.store) blob.u.found)
::
::  Signed fields for the worker actions that do not carry native proofs.
::  The Node adapter uses this exact order and the existing HMAC framing.
::
++  bool-text
  |=  value=?
  ^-  @t
  ?:(value 'true' 'false')
::
++  key-fields
  |=  key=entity-key
  ^-  (list @t)
  ~[(scot %tas kind.key) (scot %p owner.key) (scot %tas scope.key) (scot %tas id.key)]
::
++  precondition-fields
  |=  fences=(list entity-precondition)
  ^-  (list @t)
  :-  (decimal-text (lent fences))
  %-  zing
  %+  turn  fences
  |=  fence=entity-precondition
  =/  version-fields=(list @t)
    ?~  seen.fence  ~['none']
    :~  'some'
        (decimal-text incarnation.u.seen.fence)
        (decimal-text content-revision.u.seen.fence)
        (decimal-text review-revision.u.seen.fence)
        (bool-text present.u.seen.fence)
    ==
  :(weld (key-fields key.fence) version-fields ~[(bool-text content.fence) (bool-text review.fence)])
::
++  selection-fields
  |=  selections=(list evidence-selection)
  ^-  (list @t)
  :-  (decimal-text (lent selections))
  %-  zing
  %+  turn  selections
  |=  selection=evidence-selection
  :~  (scot %tas source.selection)
      (decimal-text start.selection)
      ?~(end.selection '' (decimal-text u.end.selection))
      (bool-text include.selection)
      (bool-text mandatory.selection)
  ==
::
++  operation-fields
  |=  operations=(list state-operation)
  ^-  (list @t)
  :-  (decimal-text (lent operations))
  %-  zing
  %+  turn  operations
  |=  op=state-operation
  :~  (scot %tas kind.op)
      (scot %tas stack.op)
      (scot %tas card.op)
      title.op
      front.op
      back.op
      original-title.op
      original-front.op
      original-back.op
  ==
::
++  profile-fields
  |=  profiles=(list assistant-model)
  ^-  (list @t)
  :-  (decimal-text (lent profiles))
  %-  zing
  %+  turn  profiles
  |=  profile=assistant-model
  :~  (scot %tas id.profile)
      (scot %tas provider.profile)
      (scot %tas role.profile)
      selector.profile
      model.profile
      label.profile
      description.profile
  ==
::
++  work-key
  |=  [our=@p act=action]
  ^-  (unit entity-key)
  ?+  act  ~
    [?(%ask-card %claim-card-question %answer-card-question %apply-card-edit %fail-card-question) *]
      `[%question our %root id.act]
    [?(%retry-card-question %delete-card-question) *]
      `[%question our %root id.act]
    [?(%request-change %prepare-change-packet %propose-change %claim-change %finish-change %fail-change %apply-change) *]
      `[%change our %root id.act]
    [?(%start-change %reject-change %retry-change %delete-change) *]
      `[%change our %root id.act]
    [?(%add-context-source %set-context-egress %rename-context-source %claim-context-source %finish-context-source %fail-context-source) *]
      `[%context our %root id.act]
    [?(%remove-context-source %retry-context-source %refresh-context-source) *]
      `[%context our %root id.act]
    [?(%request-login %claim-login %post-login-challenge %submit-login-code %finish-login %fail-login %consume-login-code) *]
      `[%login our %root id.act]
    [?(%retry-login %cancel-login) *]
      `[%login our %root id.act]
    [?(%checkpoint-work %heartbeat-work %recover-work) *]
      `work.act
    [%cancel-work *]
      `work.act
  ==
::
++  claim-action
  |=  act=action
  ^-  ?
  ?=([?(%claim-card-question %claim-change %claim-context-source %claim-login) *] act)
::
++  worker-request
  |=  act=action
  ^-  (unit [id=@tas worker=@t fields=(list @t)])
  ?+  act  ~
      [?(%claim-card-question %claim-change %claim-context-source %claim-login %finish-login) *]
    `[id.act worker.act ~['2']]
      [%answer-card-question *]
    `[id.act worker.act (weld ~['2' response.act] (citation-fields citations.act))]
      [%apply-card-edit *]
    `[id.act worker.act (weld ~['2' title.act front.act back.act response.act] (citation-fields citations.act))]
      [?(%fail-card-question %fail-change) *]
    `[id.act worker.act ~['2' response.act]]
      [%prepare-change-packet *]
    :-  ~
    :*  id.act
        worker.act
        ;:  weld
          ~['2']
          (precondition-fields observations.act)
          ~[read-report.act]
          (selection-fields selections.act)
          ~[(decimal-text max-bytes.act) (decimal-text excerpt-bytes.act)]
        ==
    ==
      [%finish-change *]
    `[id.act worker.act :(weld ~['2' summary.act artifact.act] (operation-fields operations.act) (citation-fields citations.act))]
      [%finish-context-source *]
    `[id.act worker.act ~['2' label.act content.act final-locator.act]]
      [%fail-context-source *]
    `[id.act worker.act ~['2' error.act]]
      [%post-login-challenge *]
    `[id.act worker.act ~['2' auth-url.act user-code.act]]
      [%fail-login *]
    `[id.act worker.act ~['2' message.act]]
      [%consume-login-code *]
    `[id.act worker.act ~['2' (decimal-text content-revision.act)]]
      [%replace-assistant-models *]
    `[%catalog worker.act ['2' (profile-fields profiles.act)]]
      [%checkpoint-work *]
    `[id.work.act worker.act :(weld ~['2'] (key-fields work.act) ~[(scot %tas stage.act)])]
      [?(%heartbeat-work %recover-work) *]
    `[id.work.act worker.act ['2' (key-fields work.act)]]
  ==
:::
::  Projections contain only one entity, never a serialized agent state.
::
+$  agent-work
  $:  execution=$?(%queued %running %blocked %succeeded %failed %cancelled)
      effect=$?(%none %staged %committed %unknown)
      worker=@t
  ==
+$  agent-subject
  [body=(unit *) review=* work=(unit agent-work)]
:::
++  agent-stack
  |=  [owner=@p who=@p id=@tas view=agent-view]
  ^-  (unit stack)
  ?:  =(owner who)
    (~(get by stacks.data.view) id)
  (~(get by subscribed.view) [who id])
:::
++  agent-subject-at
  |=  [owner=@p key=entity-key view=agent-view]
  ^-  agent-subject
  ?-  kind.key
      %stack
    =/  found  (agent-stack owner owner.key id.key view)
    ?~  found  [~ ~ ~]
    =/  stk  u.found
    [`[info.stk name.stk contributors.stk subscribers.stk] ~ ~]
      %card
    =/  found  (agent-stack owner owner.key scope.key view)
    ?~  found  [~ ~ ~]
    =/  itm  (~(get by items.u.found) id.key)
    ?~  itm  [~ ~ ~]
    =/  provenance
      ?:  !=(owner owner.key)  ~
      (~(get by provenance.data.view) [scope.key id.key])
    :*  `[content.u.itm name.u.itm provenance]
        [learn.u.itm last-review.u.itm (~(has by review-items.u.found) id.key)]
        ~
    ==
      %capture
    =/  found  (~(get by captures.data.view) id.key)
    ?~  found  [~ ~ ~]
    =/  cap  u.found
    =/  effect
      ?:  !=(0 approved.cap)  %committed
      ?:(=(~ proposals.cap) %none %staged)
    :*  `[id.cap title.cap goal.cap source.cap created-by.cap packet.cap created-at.cap status.cap approved.cap rejected.cap]
        ~
        `[?:(=(%complete status.cap) %succeeded %blocked) effect '']
    ==
      %proposal
    =/  cap  (~(get by captures.data.view) scope.key)
    ?~  cap  [~ ~ ~]
    =/  found  (~(get by proposals.u.cap) id.key)
    ?~  found  [~ ~ ~]
    [`u.found ~ `[%blocked %staged '']]
      %question
    =/  found  (~(get by questions.data.view) id.key)
    ?~  found  [~ ~ ~]
    =/  job  u.found
    =/  execution
      ?-  status.job
        %pending   %queued
        %working   %running
        %answered  %succeeded
        %failed    %failed
      ==
    =/  effect
      ?:  ?&(=(%answered status.job) =(%edit mode.job))
        %committed
      %none
    [`job ~ `[execution effect worker.job]]
      %change
    =/  found  (~(get by changes.data.view) id.key)
    ?~  found  [~ ~ ~]
    =/  job  u.found
    =/  execution
      ?-  status.job
        %draft     %blocked
        %pending   %queued
        %working   %running
        %ready     %succeeded
        %applied   %succeeded
        %rejected  %cancelled
        %failed    %failed
      ==
    =/  effect
      ?:  =(%applied status.job)  %committed
      ?:  ?|(!=(~ operations.job) !=('' artifact.job))  %staged
      %none
    [`job ~ `[execution effect worker.job]]
      %context
    =/  found  (~(get by contexts.data.view) id.key)
    ?~  found  [~ ~ ~]
    =/  job  u.found
    ?.  active.job  [`job ~ ~]
    =/  execution
      ?-  status.job
        %pending  %queued
        %working  %running
        %ready    %succeeded
        %failed   %failed
      ==
    [`job ~ `[execution ?:(=(%ready status.job) %committed %none) worker.job]]
      %login
    =/  found  (~(get by logins.view) id.key)
    ?~  found  [~ ~ ~]
    =/  job  u.found
    =/  execution
      ?-  status.job
        %pending    %queued
        %working    %running
        %challenge  %running
        %done       %succeeded
        %failed     %failed
      ==
    ::  Provider success is reported by the worker, not a ship-side edit.
    [`job ~ `[execution %none worker.job]]
      %model
    =/  found  (~(get by models.data.view) id.key)
    ?~  found  [~ ~ ~]
    =/  profile  u.found
    [`[id.profile provider.profile role.profile selector.profile model.profile label.profile description.profile] ~ ~]
  ==
::::
::  Read indexes contain identities and counters, never body copies. Changes
::  update both old and new scopes; empty indexes retain deletion watermarks.
::
++  agent-read-summary-at
  |=  [owner=@p key=entity-key view=agent-view]
  ^-  (unit agent-read-summary)
  =/  subject  (agent-subject-at owner key view)
  ?~  body.subject  ~
  =/  row=agent-read-summary  [owner.key ~ ~ ~ %.n %.n %.n]
  ?-  kind.key
      %stack
    `row(stack `id.key)
      %card
    =/  stk  (need (agent-stack owner owner.key scope.key view))
    =/  gap
      ?|  !=(owner owner.key)
          !(~(has by provenance.data.view) [scope.key id.key])
      ==
    `row(stack `scope.key, card `id.key, queued (~(has by review-items.stk) id.key), evidence-gap gap)
      %capture
    =/  cap  (~(got by captures.data.view) id.key)
    `row(status `status.cap, open =(%open status.cap))
      %proposal
    `row(stack `scope.key, open %.y)
      %question
    =/  job  (~(got by questions.data.view) id.key)
    `row(owner owner.job, stack `stack.job, card `card.job, status `status.job, open !=(%answered status.job))
      %context
    =/  source  (~(got by contexts.data.view) id.key)
    =/  row
      row(status `?:(active.source status.source %archived), open ?&(active.source !=(%ready status.source)))
    ?.  ?=(%stack -.scope.source)  `row
    `row(owner owner.scope.source, stack `stack.scope.source, card card.scope.source)
      %change
    =/  job  (~(got by changes.data.view) id.key)
    `row(status `status.job, open ?=(?(%draft %pending %working %ready %failed) status.job))
      %login
    =/  job  (~(got by logins.view) id.key)
    `row(status `status.job, open !=(%done status.job))
      %model
    =/  profile  (~(got by models.data.view) id.key)
    `row(status `provider.profile)
  ==
::::
++  agent-read-scopes
  |=  [kind=entity-kind row=agent-read-summary]
  ^-  (set agent-read-scope)
  =/  kinds=(list agent-read-kind)  ~[kind %orientation]
  =/  owners=(list (unit @p))  ~[~ `owner.row]
  =/  parents=(list [stack=(unit @tas) card=(unit @tas)])
    ~[[~ ~]]
  =?  parents  ?=(^ stack.row)  [[stack.row ~] parents]
  =?  parents  ?=(^ card.row)  [[stack.row card.row] parents]
  =/  statuses=(list (unit @tas))  ~[~]
  =?  statuses  ?=(^ status.row)  [status.row statuses]
  =?  statuses  open.row  [`%open statuses]
  =/  result=(set agent-read-scope)  ~
  |-
  ?~  kinds  result
  =.  result
    =/  who  owners
    |-
    ?~  who  result
    =.  result
      =/  par  parents
      |-
      ?~  par  result
      =.  result
        =/  stat  statuses
        |-
        ?~  stat  result
        =.  result
          (~(put in result) [i.kinds i.who stack.i.par card.i.par i.stat])
        $(stat t.stat)
      $(par t.par)
    $(who t.who)
  $(kinds t.kinds)
::::
++  agent-reindex
  |=  [key=entity-key next=(unit agent-read-summary) now=@da control=agent-state]
  ^-  agent-state
  =/  old  (~(get by read-summaries.control) key)
  =.  read-indexes.control
    ?~  old  read-indexes.control
    =/  scopes  ~(tap in (agent-read-scopes kind.key u.old))
    =/  indexes  read-indexes.control
    |-
    ?~  scopes  indexes
    =/  idx  (~(got by indexes) i.scopes)
    ?>  (~(has in keys.idx) key)
    =.  idx
      %=  idx
        revision       revision.control
        updated-at     now
        total          (dec total.idx)
        queued         (sub queued.idx ?:(queued.u.old 1 0))
        evidence-gaps  (sub evidence-gaps.idx ?:(evidence-gap.u.old 1 0))
        keys           (~(del in keys.idx) key)
      ==
    $(scopes t.scopes, indexes (~(put by indexes) i.scopes idx))
  ?~  next
    control(read-summaries (~(del by read-summaries.control) key))
  =.  read-indexes.control
    =/  scopes  ~(tap in (agent-read-scopes kind.key u.next))
    =/  indexes  read-indexes.control
    |-
    ?~  scopes  indexes
    =/  idx  (fall (~(get by indexes) i.scopes) *agent-read-index)
    ?>  !(~(has in keys.idx) key)
    =.  idx
      %=  idx
        revision       revision.control
        updated-at     now
        total          +(total.idx)
        queued         (add queued.idx ?:(queued.u.next 1 0))
        evidence-gaps  (add evidence-gaps.idx ?:(evidence-gap.u.next 1 0))
        keys           (~(put in keys.idx) key)
      ==
    $(scopes t.scopes, indexes (~(put by indexes) i.scopes idx))
  control(read-summaries (~(put by read-summaries.control) key u.next))
::::
++  agent-read-error
  |=  query=agent-read
  ^-  (unit @t)
  ?.  ?&((gte limit.query 1) (lte limit.query 100) (gte max-bytes.query 1.024) (lte max-bytes.query 262.144))
    `'read limit outside supported bounds'
  ?.  ?~(owner.query %.y (lte (met 0 u.owner.query) 128))
    `'invalid owner ship'
  =/  ids=(list (unit @tas))  ~[stack.query card.query id.query status.query]
  ?.  (levy ids |=(id=(unit @tas) ?~(id %.y &((gth (met 3 u.id) 0) (lte (met 3 u.id) 128)))))
    `'read IDs must contain 1..128 bytes'
  =/  tokens=(list (unit @t))  ~[cursor.query since.query]
  ?.  (levy tokens |=(token=(unit @t) ?~(token %.y &((gth (met 3 u.token) 0) (lte (met 3 u.token) 4.096)))))
    `'read cursors must contain 1..4096 bytes'
  ?:  &(?=(^ cursor.query) ?=(^ since.query))
    `'cursor and since cannot be combined'
  ?:  &(?=(^ card.query) ?=(~ stack.query))
    `'card_id requires stack_id'
  ?:  &(?=(?(%card %proposal) kind.query) ?=(~ stack.query))
    `'missing parent scope'
  ?:  ?&  ?=(^ stack.query)
          !?=(?(%card %proposal %question %context) kind.query)
      ==
    `'stack scope is unsupported for this read kind'
  ?:  &(?=(^ card.query) !?=(?(%question %context) kind.query))
    `'card scope is unsupported for this read kind'
  ?:  &(?=(^ id.query) =(%orientation kind.query))
    `'orientation does not select an entity ID'
  ?:  &(=(%orientation kind.query) !=(%metadata projection.query))
    `'orientation supports metadata only'
  =/  context-error=(unit @t)
    ?~  context.query  ~
    ?.  ?&(=(%context kind.query) ?=(~ owner.query) ?=(~ stack.query) ?=(~ card.query))
      `'context scope cannot be combined with parent filters'
    =/  scope  u.context.query
    ?:  ?=(%stack -.scope)
      ?.  ?&  (lte (met 0 owner.scope) 128)
              (gth (met 3 stack.scope) 0)
              (lte (met 3 stack.scope) 128)
              ?~(card.scope %.y ?&((gth (met 3 u.card.scope) 0) (lte (met 3 u.card.scope) 128)))
          ==
        `'invalid context scope'
      ~
    ?.  ?&((gth (met 3 id.scope) 0) (lte (met 3 id.scope) 128))
      `'invalid context scope'
    ~
  ?^  context-error  context-error
  ?~  status.query  ~
  =/  status  u.status.query
  =/  valid
    ?+  kind.query  %.n
      %capture   ?=(?(%open %complete) status)
      %context   ?=(?(%pending %working %ready %failed %archived) status)
      %question  ?=(?(%pending %working %answered %failed) status)
      %change    ?=(?(%draft %pending %working %ready %applied %rejected %failed) status)
      %login     ?=(?(%pending %working %challenge %done %failed) status)
    ==
  ?:(valid ~ `'unsupported status for read kind')
:::
::  +one is also usable for a known subject changed by an asynchronous
::  subscription or timer. +whole-stack is reserved for bulk stack updates.
::
++  agent-tracker
  |=  [owner=@p now=@da before=agent-view after=agent-view control=agent-state]
  |%
  ++  stamp
    |=  [key=entity-key content-changed=? review-changed=? present=?]
    ^-  agent-state
    =/  old  (~(get by versions.control) key)
    =/  rev  +(revision.control)
    =/  fresh  ?~(old present ?&(!present.u.old present))
    =/  incarnation
      ?:  fresh  next-incarnation.control
      ?~(old 0 incarnation.u.old)
    =/  ver=entity-version
      :*  incarnation
          ?:  ?|(fresh content-changed)  rev
          ?~(old 0 content-revision.u.old)
          ?:  ?|(fresh review-changed)  rev
          ?~(old 0 review-revision.u.old)
          present
      ==
    =.  control
      %=  control
        revision          rev
        next-incarnation  ?:(fresh +(next-incarnation.control) next-incarnation.control)
        versions          (~(put by versions.control) key ver)
        jobs              ?:(fresh (~(del by jobs.control) key) jobs.control)
        changed           (~(put in changed.control) key)
      ==
    (agent-reindex key (agent-read-summary-at owner key after) now control)
  ++  context-index
    |=  [key=entity-key next-control=agent-state]
    ^-  agent-state
    =/  previous  (~(get by contexts.data.before) id.key)
    =/  current  (~(get by contexts.data.after) id.key)
    =/  old-summary  (agent-read-summary-at owner key before)
    =/  new-summary  (agent-read-summary-at owner key after)
    =/  scopes=(set context-scope)  ~
    =?  scopes  ?=(^ previous)  (~(put in scopes) scope.u.previous)
    =?  scopes  ?=(^ current)  (~(put in scopes) scope.u.current)
    =/  rows  ~(tap in scopes)
    |-
    ?~  rows  next-control
    =/  scope  i.rows
    =/  old
      ?~(previous ~ ?:(=(scope scope.u.previous) old-summary ~))
    =/  new
      ?~(current ~ ?:(=(scope scope.u.current) new-summary ~))
    =/  idx  (fall (~(get by context-index.next-control) scope) *agent-read-index)
    =.  idx
      %=  idx
        revision    revision.next-control
        updated-at  now
        total       (add (sub total.idx ?~(old 0 1)) ?~(new 0 1))
        queued      (add (sub queued.idx ?~(old 0 ?:(queued.u.old 1 0))) ?~(new 0 ?:(queued.u.new 1 0)))
        evidence-gaps
          (add (sub evidence-gaps.idx ?~(old 0 ?:(evidence-gap.u.old 1 0))) ?~(new 0 ?:(evidence-gap.u.new 1 0)))
        keys
          ?~  new  (~(del in keys.idx) key)
          (~(put in keys.idx) key)
      ==
    =.  context-index.next-control
      (~(put by context-index.next-control) scope idx)
    $(rows t.rows)
  ++  claim-work
    |=  [key=entity-key job=work-record]
    ^-  work-record
    =/  inputs=[profile=(unit assistant-model) packet=(unit @ux)]
      ?+  kind.key  [~ ~]
        %question
          =/  req  (~(get by questions.data.after) id.key)
          ?~(req [~ ~] [`profile.u.req packet.u.req])
        %change
          =/  req  (~(get by changes.data.after) id.key)
          ?~(req [~ ~] [`profile.u.req packet.u.req])
      ==
    =/  packet=(unit context-packet)
      ?~  packet.inputs  ~
      (~(get by packets.evidence.data.after) u.packet.inputs)
    =/  model-version=(unit entity-version)
      ?~  profile.inputs  ~
      (~(get by versions.control) [%model owner %root id.u.profile.inputs])
    =/  provider=(unit ai-provider)
      ?^  profile.inputs  `provider.u.profile.inputs
      ?.  =(%login kind.key)  ~
      =/  login  (~(get by logins.after) id.key)
      ?~(login ~ `provider.u.login)
    =/  attempt  +(attempt.job)
    %=  job
      attempt                attempt
      lease                  (shax (jam [epoch.control secret-revision.control key attempt now]))
      lease-until            `(add now ~m2)
      deadline               `(add now ~m3)
      secret-revision        secret-revision.control
      checkpoint             ?~(packet %none %context-frozen)
      provider               provider
      model-id               ?~(profile.inputs %none id.u.profile.inputs)
      model-revision         ?~(model-version 0 content-revision.u.model-version)
      packet                 packet.inputs
      packet-digest          ?~(packet ~ `prompt-digest.u.packet)
      policy-version         1
      prompt-version         ?~(packet 0 prompt-version.u.packet)
      schema-version         seer-schema-version
      max-invocations        1
      invocations            0
      input-bytes            ?~(packet 0 prompt-bytes.u.packet)
      max-input-bytes        131.072
      max-output-bytes       65.536
      max-operations        64
      consumed-output-bytes  0
      usage                  ~
      cost                   ~
      stop-reason            ~
      retryable              %.n
      external               ~
    ==
  ++  one
    |=  key=entity-key
    ^-  agent-state
    =/  prev  (agent-subject-at owner key before)
    =/  next  (agent-subject-at owner key after)
    =/  content-changed
      ?|(!=(body.prev body.next) !=(work.prev work.next))
    =/  review-changed  !=(review.prev review.next)
    ?.  ?|(content-changed review-changed)  control
    =.  control  (stamp key content-changed review-changed ?=(^ body.next))
    =?  control  =(%context kind.key)
      (context-index key control)
    ?~  work.next
      =/  old  (~(get by jobs.control) key)
      ?~  old  control
      ::  Preserve already settled effects when an entity is removed.
      =/  job  u.old
      =?  execution.job
          ?=(?(%queued %running %blocked) execution.job)
        %cancelled
      =.  updated-at.job  now
      control(jobs (~(put by jobs.control) key job))
    =/  next-work  u.work.next
    =/  old  (~(get by jobs.control) key)
    =/  claimed
      ?&  =(%running execution.next-work)
          ?~  work.prev  %.n
          =(%queued execution.u.work.prev)
      ==
    =/  job  (fall old *work-record)
    =.  job
      %=  job
        execution   execution.next-work
        effect      effect.next-work
        worker      worker.next-work
        updated-at  now
      ==
    =?  job  claimed  (claim-work key job)
    =?  job  ?=(?(%succeeded %failed %cancelled) execution.job)
      %=  job
        lease-until  ~
        retryable    =(%failed execution.job)
        checkpoint
          ?:  =(%committed effect.job)  %effect-committed
          ?:  =(%succeeded execution.job)  %result-published
          checkpoint.job
        stop-reason
          ?:  =(%failed execution.job)  `%worker-failed
          ?:  =(%cancelled execution.job)  `%cancelled
          stop-reason.job
      ==
    =?  job  ?&(!claimed =(%blocked execution.job))
      job(lease-until ~)
    control(jobs (~(put by jobs.control) key job))
  ++  card
    |=  [who=@p stak=@tas id=@tas]
    ^-  agent-state
    =/  key=entity-key  [%card who stak id]
    =/  prev  (agent-subject-at owner key before)
    =/  next  (agent-subject-at owner key after)
    =.  control  (one key)
    =/  content-changed  !=(body.prev body.next)
    =/  review-changed  !=(review.prev review.next)
    ?.  ?|(content-changed review-changed)  control
    ::  Propagate each axis separately to the aggregate stack version.
    =/  parent=entity-key  [%stack who %root stak]
    =/  exists  (agent-stack owner who stak after)
    ?~  exists  control
    (stamp parent content-changed review-changed %.y)
  ++  whole-stack
    |=  [who=@p id=@tas]
    ^-  agent-state
    =.  control  (one [%stack who %root id])
    =/  prev  (agent-stack owner who id before)
    =/  next  (agent-stack owner who id after)
    =/  old-items=items  ?~(prev ~ items.u.prev)
    =/  new-items=items  ?~(next ~ items.u.next)
    =/  rows  ~(tap by (~(uni by old-items) new-items))
    |-
    ?~  rows  control
    =.  control  (card who id p.i.rows)
    $(rows t.rows)
  ++  touch-proposal
    |=  [capture=@tas id=@tas]
    ^-  agent-state
    =/  key=entity-key  [%proposal owner capture id]
    =/  prev  (agent-subject-at owner key before)
    =/  next  (agent-subject-at owner key after)
    =.  control  (one key)
    ?:  =(body.prev body.next)  control
    =/  exists  (~(get by captures.data.after) capture)
    ?~  exists  control
    (stamp [%capture owner %root capture] %.y %.n %.y)
  ++  whole-capture
    |=  id=@tas
    ^-  agent-state
    =.  control  (one [%capture owner %root id])
    =/  prev  (~(get by captures.data.before) id)
    =/  next  (~(get by captures.data.after) id)
    =/  old-proposals=(map @tas proposal)  ?~(prev ~ proposals.u.prev)
    =/  new-proposals=(map @tas proposal)  ?~(next ~ proposals.u.next)
    =/  rows  ~(tap by (~(uni by old-proposals) new-proposals))
    |-
    ?~  rows  control
    =.  control  (touch-proposal id p.i.rows)
    $(rows t.rows)
  --
:::
++  track-agent-state
  |=  [owner=@p now=@da act=action before=agent-view after=agent-view control=agent-state]
  ^-  agent-state
  =/  tracker  (agent-tracker owner now before after control)
  ?-  -.act
      %new-stack
    (whole-stack:tracker owner name.act)
      %copy-stack
    (whole-stack:tracker owner stak.act)
      %delete-stack
    (whole-stack:tracker who.act stak.act)
      %edit-stack
    (one:tracker [%stack owner %root name.act])
      %new-item
    ::  Adding a remote card creates/updates a local stack in this agent.
    =.  control.tracker  (one:tracker [%stack owner %root stak.act])
    (card:tracker owner stak.act name.act)
      %edit-item
    (card:tracker owner stak.act name.act)
      %delete-item
    (card:tracker owner stak.act item.act)
      %raise-item
    (card:tracker owner stak.act item.act)
      %answered-item
    (card:tracker owner.act stak.act item.act)
      %review-stack
    (whole-stack:tracker who.act stak.act)
      %begin-capture
    (one:tracker [%capture owner %root id.act])
      %prepare-capture
    (one:tracker [%capture owner %root id.act])
      %stage-card
    =.  control.tracker  (one:tracker [%capture owner %root capture.act])
    (touch-proposal:tracker capture.act proposal.act)
      %approve-proposal
    ::  The nested new-item runs before approval attaches provenance.
    =.  control.tracker  (one:tracker [%capture owner %root capture.act])
    =.  control.tracker  (touch-proposal:tracker capture.act proposal.act)
    =/  key=entity-key  [%proposal owner capture.act proposal.act]
    =/  old  (agent-subject-at owner key before)
    =/  next  (agent-subject-at owner key after)
    ?.  ?&(?=(^ body.old) ?=(~ body.next))  control.tracker
    =/  job  (~(get by jobs.control.tracker) key)
    ?~  job  control.tracker
    =/  settled  u.job(execution %succeeded, effect %committed, updated-at now)
    =.  control.tracker
      control.tracker(jobs (~(put by jobs.control.tracker) key settled))
    =/  draft  (need ((soft proposal) u.body.old))
    (card:tracker owner stack.draft card.draft)
      %reject-proposal
    =.  control.tracker  (one:tracker [%capture owner %root capture.act])
    (touch-proposal:tracker capture.act proposal.act)
      %discard-capture
    (whole-capture:tracker capture.act)
      %delete-capture
    (whole-capture:tracker capture.act)
      %add-context-source
    (one:tracker [%context owner %root id.act])
      %set-context-egress
    (one:tracker [%context owner %root id.act])
      %rename-context-source
    (one:tracker [%context owner %root id.act])
      %archive-orphan-contexts
    =/  rows  ~(tap by contexts.data.before)
    |-
    ?~  rows  control.tracker
    =.  control.tracker  (one:tracker [%context owner %root p.i.rows])
    $(rows t.rows)
      %remove-context-source
    (one:tracker [%context owner %root id.act])
      %claim-context-source
    (one:tracker [%context owner %root id.act])
      %finish-context-source
    (one:tracker [%context owner %root id.act])
      %fail-context-source
    (one:tracker [%context owner %root id.act])
      %retry-context-source
    (one:tracker [%context owner %root id.act])
      %refresh-context-source
    (one:tracker [%context owner %root id.act])
      %ask-card
    (one:tracker [%question owner %root id.act])
      %claim-card-question
    (one:tracker [%question owner %root id.act])
      %answer-card-question
    (one:tracker [%question owner %root id.act])
      %apply-card-edit
    ::  The nested edit-item owns the card and parent-stack revisions.
    (one:tracker [%question owner %root id.act])
      %fail-card-question
    (one:tracker [%question owner %root id.act])
      %retry-card-question
    (one:tracker [%question owner %root id.act])
      %delete-card-question
    (one:tracker [%question owner %root id.act])
      %request-change
    (one:tracker [%change owner %root id.act])
      %start-change
    (one:tracker [%change owner %root id.act])
      %propose-change
    (one:tracker [%change owner %root id.act])
      %claim-change
    (one:tracker [%change owner %root id.act])
      %prepare-change-packet
    (one:tracker [%change owner %root id.act])
      %finish-change
    (one:tracker [%change owner %root id.act])
      %fail-change
    (one:tracker [%change owner %root id.act])
      %apply-change
    ::  Each nested operation is stamped individually, including A->B->A.
    (one:tracker [%change owner %root id.act])
      %reject-change
    (one:tracker [%change owner %root id.act])
      %retry-change
    (one:tracker [%change owner %root id.act])
      %delete-change
    (one:tracker [%change owner %root id.act])
      %request-login
    ::  This operation replaces a request and removes its provider's
    ::  settled requests. A reused request ID is a new incarnation.
    =/  prev  (~(get by logins.before) id.act)
    =/  next  (~(get by logins.after) id.act)
    ?:  =(prev next)  control
    =/  rows  ~(tap by logins.before)
    =.  tracker
      |-
      ?~  rows  tracker
      =?  control.tracker
          ?&(=(provider.act provider.q.i.rows) !=(id.act p.i.rows))
        (one:tracker [%login owner %root p.i.rows])
      $(rows t.rows)
    =.  control.tracker
      ?~  prev  control.tracker
      =/  deletion  tracker
      =.  logins.after.deletion  (~(del by logins.after) id.act)
      (one:deletion [%login owner %root id.act])
    =.  logins.before.tracker  (~(del by logins.before) id.act)
    (one:tracker [%login owner %root id.act])
      %claim-login
    (one:tracker [%login owner %root id.act])
      %post-login-challenge
    (one:tracker [%login owner %root id.act])
      %submit-login-code
    (one:tracker [%login owner %root id.act])
      %finish-login
    (one:tracker [%login owner %root id.act])
      %fail-login
    (one:tracker [%login owner %root id.act])
      %retry-login
    (one:tracker [%login owner %root id.act])
      %cancel-login
    =.  control.tracker  (one:tracker [%login owner %root id.act])
    =/  prev  (~(get by logins.before) id.act)
    =/  next  (~(get by logins.after) id.act)
    ?:  =(prev next)  control.tracker
    =/  key=entity-key  [%login owner %root id.act]
    =/  job  (~(get by jobs.control.tracker) key)
    ?~  job  control.tracker
    ?~  next  control.tracker
    =/  cancelled  u.job(execution %cancelled, updated-at now)
    control.tracker(jobs (~(put by jobs.control.tracker) key cancelled))
      %consume-login-code
    (one:tracker [%login owner %root id.act])
      %import
    (whole-stack:tracker who.act stack.act)
      %replace-assistant-models
    =/  ids  (~(uni in ~(key by models.data.before)) ~(key by models.data.after))
    =/  rows  ~(tap in ids)
    |-
    ?~  rows  control.tracker
    =.  control.tracker  (one:tracker [%model owner %root i.rows])
    $(rows t.rows)
    ::  These actions either emit requests, change untracked configuration,
    ::  or are currently domain no-ops. bridge-action dispatches its payload
    ::  through the same action wrapper; import-file emits a later new-stack.
      %schedule-item          control
      %read                   control
      %update-review          control
      %import-file            control
      %issue-bridge-nonce      control
      %share-clay-context      control
      %unshare-clay-context    control
      %fetch-remote-manifest   control
      %bridge-action          control
      %checkpoint-work         control
      %heartbeat-work          control
      %recover-work            control
      %cancel-work             control
      %set-bridge-capability    control
      %collect-retained        control
      %retire-operation-epoch   control
      %purge-evidence
    =/  context-rows  ~(key by contexts.data.before)
    =/  question-rows  ~(key by questions.data.before)
    =/  change-rows  ~(key by changes.data.before)
    =/  capture-rows  ~(tap by captures.data.before)
    =/  keys=(list entity-key)
      ;:  weld
        (turn ~(tap in context-rows) |=(id=@tas ^-(entity-key [%context owner %root id])))
        (turn ~(tap in question-rows) |=(id=@tas ^-(entity-key [%question owner %root id])))
        (turn ~(tap in change-rows) |=(id=@tas ^-(entity-key [%change owner %root id])))
      ==
    =.  control.tracker
      |-
      ?~  keys  control.tracker
      =.  control.tracker  (one:tracker i.keys)
      $(keys t.keys)
    |-
    ?~  capture-rows  control.tracker
    =.  control.tracker  (whole-capture:tracker p.i.capture-rows)
    $(capture-rows t.capture-rows)
  ==
::
++  form-snippet
  |=  file=@t
  ^-  @t
  =/  front-id     (add 3 (need (find ";>" (trip file))))
  =/  front-matter  (cat 3 (end [3 front-id] file) 'dummy text\0a')
  =/  body  (cut 3 [front-id (met 3 file)] file)
  (of-wain:format (scag 1 (to-wain:format body)))
::
++  add-front-matter
  |=  [fro=(map knot cord) udon=@t]
  ^-  @t
  %-  of-wain:format
  =/  tum  (trip udon)
  =/  id  (find ";>" tum)
  ?~  id
    %+  weld  (front-to-wain fro)
    (to-wain:format (crip :(weld ";>\0a" tum)))
  %+  weld  (front-to-wain fro)
  (to-wain:format (crip (slag u.id tum)))
::
++  front-to-wain
  |=  a=(map knot cord)
  ^-  wain
  =/  entries=wain
    %+  turn  ~(tap by a)
    |=  b=[knot cord]
    =/  c=[term cord]  (,[term cord] b)
    (crip "  [{<-.c>} {<+.c>}]")
  ::
  ?~  entries  ~
  ;:  weld
    [':-  :~' ~]
    entries
    ['    ==' ~]
  ==
::
++  time-to-atom
  |=  time=@d
  ^-  @
  (yule (yell time))
::
++  time-to-rs
  |=  time=@d
  ^-  @rs
  (sun:rs (time-to-atom time))
::
++  rs-to-time
  |=  time=@rs
  ^-  @dr
  (abs:si (need (toi:rs time)))
::
++  string-to-symbol
  |=  tap=tape
  ^-  @tas
  %-  crip
  %+  turn  tap
  |=  a=@
  ?:  ?|  &((gte a 'a') (lte a 'z'))
          &((gte a '0') (lte a '9'))
      ==
    a
  ?:  &((gte a 'A') (lte a 'Z'))
    (add 32 a)
  '-'
--
