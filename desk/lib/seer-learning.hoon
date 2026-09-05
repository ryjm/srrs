/-  *seer
/+  ev=seer-evidence, effects=seer-effects
|%
::  Exact editorial identity, not semantic similarity. Only CRLF and the
::  existing serialized front matter are removed; code whitespace survives.
++  normalize
  |=  text=@t
  ^-  @t
  =/  chars  (trip text)
  =/  out=tape  ~
  |-
  ?~  chars  (crip (flop out))
  ?:  ?&(=(13 i.chars) ?=(^ t.chars))
    ?:  =(10 i.t.chars)  $(chars t.chars)
    $(chars t.chars, out [i.chars out])
  $(chars t.chars, out [i.chars out])
::
++  card-body
  |=  raw=@t
  ^-  @t
  =/  text  (normalize raw)
  ::  The editorial helper strips at the first marker. Invoke it only at
  ::  a serializer boundary, never at a literal ;> inside code or a title.
  ?:  =(';>\0a' (cut 3 [0 3] text))  (clean-body:effects text)
  ?.  =(':-  :~\0a' (cut 3 [0 7] text))  text
  =/  marker  (find "\0a    ==\0a;>\0a" (trip text))
  ?~  marker  text
  (clean-body:effects (cut 3 [(add u.marker 8) (met 3 text)] text))
::
++  card-fingerprint
  |=  [owner=@p stack=@tas title=@t front=@t back=@t]
  ^-  learning-key
  :-  owner
  :-  stack
  %-  shax
  %-  jam
  [(normalize title) (card-body front) (card-body back)]
::
++  index-card
  |=  [key=entity-key old=(unit item) current=(unit item) store=learning-state]
  ^-  learning-state
  ?.  =(%card kind.key)  store
  =?  store  ?=(^ old)
    ?>  ?=(^ old)
    =/  mark
      (card-fingerprint owner.key scope.key title.content.u.old front.content.u.old back.content.u.old)
    =/  bucket  (fall (~(get by library-index.store) mark) *(set entity-key))
    =.  bucket  (~(del in bucket) key)
    store(library-index ?~(bucket (~(del by library-index.store) mark) (~(put by library-index.store) mark bucket)))
  ?~  current  store
  =/  mark
    (card-fingerprint owner.key scope.key title.content.u.current front.content.u.current back.content.u.current)
  =/  bucket  (fall (~(get by library-index.store) mark) *(set entity-key))
  store(library-index (~(put by library-index.store) mark (~(put in bucket) key)))
::
::  A dispatchable historical packet is not necessarily current retrieval.
++  packet-current-error
  |=  [packet=context-packet provider=ai-provider sources=(map @tas context-source) store=evidence-state]
  ^-  (unit @tas)
  ?.  =(provider provider.profile.request.packet)  `%provider-mismatch
  =/  error  (packet-egress-error:ev packet sources store)
  ?^  error  error
  =/  entries  entries.packet
  |-
  ?~  entries  ~
  =/  entry  i.entries
  ?.  (included:ev entry)  $(entries t.entries)
  =/  source  (~(get by sources) source.entry)
  ?~  source  `%missing-source
  ?.  active.u.source  `%archived
  ?.  =(%ready status.u.source)  `%source-not-ready
  ?.  =(snapshot.entry snapshot.u.source)  `%stale-snapshot
  =/  snapshot  (~(get by snapshots.store) (need snapshot.entry))
  ?~  snapshot  `%purged
  ?.  =(generation.u.source generation.u.snapshot)  `%stale-generation
  $(entries t.entries)
::
::  Deliberately omit request identity, attempt, observation time and capture
::  ID. Keep exact model, subject, goal, source revisions and excerpt choices.
++  packet-signature
  |=  packet=context-packet
  ^-  @ux
  =/  req  request.packet
  %-  shax
  %-  jam
  :*  ?~(subject.req ~ `u.subject.req(review-revision.version 0))
      [id.profile.req provider.profile.req role.profile.req selector.profile.req model.profile.req]
      mode.req
      objective.req
      [title.req front.req back.req]
      entries.packet
      [max-bytes.req excerpt-bytes.req]
      [prompt-version.packet schema-version.packet]
  ==
::
++  citation-bytes
  |=  citations=(list evidence-citation)
  ^-  @ud
  =/  bytes=@ud  0
  |-
  ?~  citations  bytes
  $(citations t.citations, bytes (add bytes (met 3 quote.i.citations)))
::
++  proposal-bytes
  |=  draft=proposal
  ^-  @ud
  ;:  add
    (met 3 title.draft)
    (met 3 front.draft)
    (met 3 back.draft)
    (met 3 rationale.draft)
    (met 3 source.draft)
    (met 3 objective.draft)
    (met 3 claim.draft)
    (met 3 why-new.draft)
    (met 3 caveat.draft)
    (citation-bytes citations.draft)
  ==
::
++  artifact-bytes
  |=  artifact=learning-artifact
  ^-  @ud
  ::  Generated UTF-8 payloads only; compact unavailable refs cost no body
  ::  bytes. Quotes stored both on a draft and its artifact count both.
  ;:  add
    (met 3 objective.artifact)
    (met 3 text.artifact)
    ?~(reason.artifact 0 (met 3 u.reason.artifact))
    ?~(draft.artifact 0 (proposal-bytes u.draft.artifact))
    (citation-bytes citations.artifact)
  ==
::
++  admission-error
  |=  [artifact=learning-artifact store=learning-state]
  ^-  (unit @tas)
  ?:  (gte artifact-count.store 4.096)  `%artifact-limit
  =/  bytes  (artifact-bytes artifact)
  ?:  ?|((gth bytes 65.536) (gth (met 3 (jam artifact)) 65.536))
    `%artifact-too-large
  ?:  (gth (add stored-bytes.store bytes) 16.777.216)  `%learning-storage-limit
  ?:  (~(has by artifacts.store) id.artifact)  `%artifact-conflict
  ~
::
++  insert-artifact
  |=  [artifact=learning-artifact store=learning-state]
  ^-  learning-state
  =/  bucket  (fall (~(get by scope-index.store) scope.artifact) *(set @ux))
  %=  store
    artifacts      (~(put by artifacts.store) id.artifact artifact)
    signatures     (~(put by signatures.store) signature.artifact id.artifact)
    scope-index    (~(put by scope-index.store) scope.artifact (~(put in bucket) id.artifact))
    artifact-count  +(artifact-count.store)
    stored-bytes   (add stored-bytes.store (artifact-bytes artifact))
  ==
::
++  latest-artifact
  |=  [ids=(set @ux) store=learning-state]
  ^-  (unit @ux)
  =/  rest  ~(tap in ids)
  =/  chosen=(unit learning-artifact)  ~
  |-
  ?~  rest  ?~(chosen ~ `id.u.chosen)
  =/  next  (~(get by artifacts.store) i.rest)
  ?~  next  $(rest t.rest)
  =?  chosen
      ?~  chosen  %.y
      ?|  (gth created-at.u.next created-at.u.chosen)
          ?&(=(created-at.u.next created-at.u.chosen) (gth id.u.next id.u.chosen))
      ==
    next
  $(rest t.rest)
::
++  proposal-shape-error
  |=  draft=proposal
  ^-  (unit @tas)
  ?.  ?&(!=(0 objective.draft) (bounded-text:ev objective.draft 4.096))
    `%missing-learning-objective
  ?.  ?&(!=(0 claim.draft) (bounded-text:ev claim.draft 16.384))
    `%missing-supported-claim
  ?.  ?&(!=(0 why-new.draft) (bounded-text:ev why-new.draft 4.096))
    `%missing-why-new
  ?.  (bounded-text:ev caveat.draft 4.096)  `%caveat-too-large
  ?.  ?&  !=(0 stack.draft)
          !=(0 card.draft)
          !=(0 title.draft)
          !=(0 front.draft)
          !=(0 back.draft)
          (bounded-text:ev id.draft 128)
          (bounded-text:ev stack.draft 128)
          (bounded-text:ev card.draft 128)
          (bounded-text:ev title.draft 4.096)
          (bounded-text:ev front.draft 65.536)
          (bounded-text:ev back.draft 65.536)
          (bounded-text:ev rationale.draft 4.096)
          (bounded-text:ev source.draft 4.096)
          (lte (lent (scag 65 preconditions.draft)) 64)
      ==
    `%invalid-proposal
  ~
::
++  stage-artifact
  |=  $:  our=@p
          now=@da
          capture-id=@tas
          session=capture
          draft=proposal
          store=learning-state
          evidence=evidence-state
          sources=(map @tas context-source)
      ==
  ^-  [draft=proposal store=learning-state error=(unit @tas) reused=(unit @ux)]
  =/  error  (proposal-shape-error draft)
  ?^  error  [draft store error ~]
  ?.  ?&(=(capture-id id.session) =(%open status.session))
    [draft store `%capture-mismatch ~]
  ?.  ?&(!=(0 goal.session) (bounded-text:ev goal.session 131.072))
    [draft store `%missing-capture-goal ~]
  ?~  packet.session  [draft store `%missing-packet ~]
  ?.  =(packet.draft packet.session)  [draft store `%packet-mismatch ~]
  =/  packet  (~(get by packets.evidence) u.packet.session)
  ?~  packet  [draft store `%missing-packet ~]
  =/  req  request.u.packet
  ?.  ?&(=(our owner.work.req) =(%capture mode.req) =(goal.session objective.req))
    [draft store `%packet-mismatch ~]
  ?.  ?|  =(scope.req [%capture capture-id])
          =(scope.req [%stack our stack.draft ~])
      ==
    [draft store `%out-of-scope ~]
  =/  error  (packet-current-error u.packet provider.profile.req sources evidence)
  ?^  error  [draft store error ~]
  ?~  citations.draft  [draft store `%uncited-proposal ~]
  =/  error  (validate-citations:ev u.packet citations.draft evidence)
  ?^  error  [draft store error ~]
  =/  mark  (card-fingerprint our stack.draft title.draft front.draft back.draft)
  =/  live  (fall (~(get by library-index.store) mark) *(set entity-key))
  ?^  live
    [draft store(duplicate-count +(duplicate-count.store)) `%duplicate-live-card ~]
  ::  Rewording a rationale/caveat or renaming the proposed slug is not new
  ::  evidence. Those fields and exact commit fences remain on the draft,
  ::  but cannot resurrect the same card under the same goal and packet.
  =/  signature=@ux
    %-  shax
    %-  jam
    :*  %proposal
        mark
        goal.session
        objective.draft
        (packet-signature u.packet)
    ==
  =/  prior  (~(get by signatures.store) signature)
  ?^  prior
    =/  old  (~(get by artifacts.store) u.prior)
    ?~  old  [draft store `%artifact-index-conflict ~]
    =.  draft  draft(artifact prior)
    =.  duplicate-count.store  +(duplicate-count.store)
    ?.  available.u.old  [draft store `%artifact-unavailable prior]
    ?:  =(%rejected decision.u.old)  [draft store `%rejected-identical prior]
    ?:  =(%superseded decision.u.old)  [draft store `%superseded-identical prior]
    [draft store(reuse-count +(reuse-count.store)) `%duplicate-proposal prior]
  =/  candidates  (fall (~(get by candidate-index.store) mark) *(set @ux))
  =/  prior  (latest-artifact candidates store)
  =/  id=@ux  (shax (jam [our signature]))
  =/  staged  draft(artifact `id)
  ::  Account/worker labels are not retained generation metadata.
  =/  retained  staged(created-by provider.profile.req)
  =/  artifact=learning-artifact
    %*  .  *learning-artifact
      id            id
      kind          %proposal
      owner         our
      scope         [%stack our stack.draft ~]
      objective     objective.draft
      fingerprint   content.mark
      signature     signature
      packet        packet.draft
      input-digest  `input-digest.u.packet
      subject       subject.req
      draft         `retained
      citations     citations.draft
      prior         prior
      decision      %proposed
      available     %.y
      created-at    now
    ==
  =/  error  (admission-error artifact store)
  ?^  error  [draft store error ~]
  =.  store  (insert-artifact artifact store)
  =.  candidate-index.store
    (~(put by candidate-index.store) mark (~(put in candidates) id))
  [staged store ~ ~]
::
++  decide-artifact
  |=  [our=@p now=@da id=@ux decision=$?(%approved %rejected %superseded) reason=(unit @t) store=learning-state]
  ^-  [store=learning-state error=(unit @tas)]
  =/  artifact  (~(get by artifacts.store) id)
  ?~  artifact  [store `%missing-artifact]
  ?.  =(our owner.u.artifact)  [store `%wrong-owner]
  ?.  ?~(reason %.y (bounded-text:ev u.reason 4.096))
    [store `%decision-reason-too-large]
  ?:  =(decision decision.u.artifact)  [store ~]
  ?.  =(%proposed decision.u.artifact)  [store `%decision-conflict]
  ?.  available.u.artifact  [store `%artifact-unavailable]
  =/  next
    u.artifact(decision decision, decision-by `our, decision-at `now, reason reason)
  =/  size  (artifact-bytes next)
  ?:  ?|((gth size 65.536) (gth (met 3 (jam next)) 65.536))
    [store `%artifact-too-large]
  =/  bytes  (add (sub stored-bytes.store (artifact-bytes u.artifact)) size)
  ?:  (gth bytes 16.777.216)  [store `%learning-storage-limit]
  [store(artifacts (~(put by artifacts.store) id next), stored-bytes bytes) ~]
::
++  record-explanation
  |=  $:  our=@p
          now=@da
          packet=context-packet
          response=@t
          citations=(list evidence-citation)
          kind=$?(%explanation %correction)
          store=learning-state
          evidence=evidence-state
          sources=(map @tas context-source)
      ==
  ^-  [store=learning-state id=(unit @ux) error=(unit @tas)]
  ?.  ?&(!=(0 response) (bounded-text:ev response 65.536))
    [store ~ `%invalid-explanation]
  ?.  =(our owner.work.request.packet)  [store ~ `%wrong-owner]
  ?.  =(`packet (~(get by packets.evidence) id.packet))
    [store ~ `%packet-mismatch]
  =/  error  (packet-current-error packet provider.profile.request.packet sources evidence)
  ?^  error  [store ~ error]
  =/  error  (validate-citations:ev packet citations evidence)
  ?^  error  [store ~ error]
  =/  fingerprint=@ux  (shax response)
  =/  signature=@ux
    (shax (jam [our scope.request.packet kind fingerprint citations (packet-signature packet)]))
  =/  prior  (~(get by signatures.store) signature)
  ?^  prior
    =/  old  (~(get by artifacts.store) u.prior)
    ?~  old  [store ~ `%artifact-index-conflict]
    ?.  available.u.old  [store prior `%artifact-unavailable]
    [store(reuse-count +(reuse-count.store)) prior ~]
  =/  bucket  (fall (~(get by scope-index.store) scope.request.packet) *(set @ux))
  =/  related=(set @ux)
    %-  silt
    %+  skim  ~(tap in bucket)
    |=  id=@ux
    =/  old  (~(get by artifacts.store) id)
    ?~  old  %.n
    ?&  !=(%proposal kind.u.old)
        =(objective.request.packet objective.u.old)
        =(subject.request.packet subject.u.old)
    ==
  =/  id=@ux  (shax (jam [our signature]))
  =/  artifact=learning-artifact
    %*  .  *learning-artifact
      id            id
      kind          kind
      owner         our
      scope         scope.request.packet
      objective     objective.request.packet
      fingerprint   fingerprint
      signature     signature
      packet        `id.packet
      input-digest  `input-digest.packet
      subject       subject.request.packet
      text          response
      citations     citations
      prior         (latest-artifact related store)
      decision      %proposed
      available     %.y
      created-at    now
    ==
  =/  error  (admission-error artifact store)
  ?^  error  [store ~ error]
  =.  store  (insert-artifact artifact store)
  =.  input-index.store
    (~(put by input-index.store) [scope.request.packet kind input-digest.packet] id)
  [store `id ~]
::
++  observation-newer
  |=  [a=learner-observation b=learner-observation]
  ^-  ?
  ?:  !=(at.a at.b)  (gth at.a at.b)
  (gor a b)
::
++  drop-oldest-observation
  |=  store=learning-state
  ^-  learning-state
  =/  rows  ~(tap by observations.store)
  =/  chosen=(unit [key=entity-key at=@da])  ~
  |-
  ?~  rows
    ?~  chosen  store
    =/  values  (~(got by observations.store) key.u.chosen)
    =/  kept  (scag (dec (lent values)) values)
    %=  store
      observations
        ?~  kept  (~(del by observations.store) key.u.chosen)
        (~(put by observations.store) key.u.chosen kept)
      observation-count  (dec observation-count.store)
    ==
  ?~  q.i.rows  $(rows t.rows)
  =/  oldest  (rear q.i.rows)
  =?  chosen
      ?~  chosen  %.y
      ?|  (lth at.oldest at.u.chosen)
          ?&(=(at.oldest at.u.chosen) (gor p.i.rows key.u.chosen))
      ==
    `[p.i.rows at.oldest]
  $(rows t.rows)
::
++  record-grade
  |=  [our=@p now=@da key=entity-key version=entity-version grade=recall-grade store=learning-state]
  ^-  learning-state
  ?.  ?&(=(our owner.key) =(%card kind.key) present.version)  store
  =/  previous  (fall (~(get by observations.store) key) *(list learner-observation))
  =/  observation=learner-observation  [[key version] grade our now]
  =/  values  (sort [observation previous] observation-newer)
  =/  kept  (scag 32 values)
  =.  observation-count.store
    (add (sub observation-count.store (lent previous)) (lent kept))
  =.  observations.store  (~(put by observations.store) key kept)
  ?:  (lte observation-count.store 4.096)  store
  (drop-oldest-observation store)
::
++  artifact-error
  |=  [artifact=learning-artifact provider=ai-provider sources=(map @tas context-source) evidence=evidence-state versions=(map entity-key entity-version)]
  ^-  (unit @tas)
  ?.  available.artifact  `%purged
  ?~  packet.artifact  `%missing-packet
  =/  packet  (~(get by packets.evidence) u.packet.artifact)
  ?~  packet  `%missing-packet
  ?.  =(input-digest.artifact `input-digest.u.packet)  `%packet-mismatch
  =/  error  (packet-current-error u.packet provider sources evidence)
  ?^  error  error
  ?~  subject.artifact  ~
  =/  subject  u.subject.artifact
  =/  current  (~(get by versions) key.subject)
  ?~  current  `%missing-subject
  ?.  present.u.current  `%deleted-subject
  ?.  ?&  =(incarnation.version.subject incarnation.u.current)
          =(content-revision.version.subject content-revision.u.current)
      ==
    `%stale-subject
  ~
::
++  find-reusable
  |=  $:  packet=context-packet
          sources=(map @tas context-source)
          evidence=evidence-state
          versions=(map entity-key entity-version)
          store=learning-state
      ==
  ^-  (unit learning-artifact)
  ::  Repeating an authorized read may reuse an answer, never an edit.
  ?.  =(%ask mode.request.packet)  ~
  =/  error  (packet-current-error packet provider.profile.request.packet sources evidence)
  ?^  error  ~
  =/  id
    (~(get by input-index.store) [scope.request.packet %explanation input-digest.packet])
  ?~  id  ~
  =/  artifact  (~(get by artifacts.store) u.id)
  ?~  artifact  ~
  ?.  ?&  =(%explanation kind.u.artifact)
          =(input-digest.u.artifact `input-digest.packet)
          =(scope.u.artifact scope.request.packet)
          !?=(?(%rejected %superseded) decision.u.artifact)
      ==
    ~
  ?^  (artifact-error u.artifact provider.profile.request.packet sources evidence versions)  ~
  ?^  (validate-citations:ev packet citations.u.artifact evidence)  ~
  artifact
::
++  citation-json
  |=  citation=evidence-citation
  ^-  json
  %-  pairs:enjs:format
  :~  ['snapshot_ref' s+(scot %ux snapshot.citation)]
      ['start' (numb:enjs:format start.citation)]
      ['end' (numb:enjs:format end.citation)]
      ['quote' s+quote.citation]
  ==
::
++  artifact-body-json
  |=  artifact=learning-artifact
  ^-  json
  %-  pairs:enjs:format
  :~  ['objective' s+objective.artifact]
      ['text' s+text.artifact]
      ['reason' ?~(reason.artifact ~ s+u.reason.artifact)]
      ['citations' a+(turn citations.artifact citation-json)]
      :-  'draft'
      ?~  draft.artifact  ~
      =/  draft  u.draft.artifact
      %-  pairs:enjs:format
      :~  ['stack_id' s+stack.draft]
          ['card_id' s+card.draft]
          ['title' s+title.draft]
          ['front' s+front.draft]
          ['back' s+back.draft]
          ['claim' s+claim.draft]
          ['why_new' s+why-new.draft]
          ['caveat' s+caveat.draft]
          ['rationale' s+rationale.draft]
      ==
  ==
::
++  artifact-row-json
  |=  [artifact=learning-artifact error=(unit @tas) include-body=? evidence=evidence-state]
  ^-  json
  =/  packet=(unit context-packet)
    ?~  packet.artifact  ~
    (~(get by packets.evidence) u.packet.artifact)
  %-  pairs:enjs:format
  :~  ['artifact_ref' s+(scot %ux id.artifact)]
      ['kind' s+kind.artifact]
      ['fingerprint' s+(scot %ux fingerprint.artifact)]
      ['signature' s+(scot %ux signature.artifact)]
      ['packet_ref' ?~(packet.artifact ~ s+(scot %ux u.packet.artifact))]
      ['input_digest' ?~(input-digest.artifact ~ s+(scot %ux u.input-digest.artifact))]
      ['prior_ref' ?~(prior.artifact ~ s+(scot %ux u.prior.artifact))]
      ['decision' s+decision.artifact]
      ['decision_by' ?~(decision-by.artifact ~ s+(scot %p u.decision-by.artifact))]
      ['decision_at' ?~(decision-at.artifact ~ s+(scot %da u.decision-at.artifact))]
      ['created_at' s+(scot %da created-at.artifact)]
      ['eligible' b+?=(~ error)]
      ['unavailable_reason' ?~(error ~ s+u.error)]
      ['body_omitted' b+?&(?=(~ error) !include-body)]
      ['quote_status' s+?~(error ?~(citations.artifact 'unsupported-generated-claim' 'exact-quotes-not-entailment') 'unavailable')]
      ['body' ?:(!include-body ~ ?~(error (artifact-body-json artifact) ~))]
      :-  'subject'
      ?~  subject.artifact  ~
      %-  pairs:enjs:format
      :~  ['ref' (key-json:ev key.u.subject.artifact)]
          ['version' (version-json:ev version.u.subject.artifact)]
      ==
      :-  'model'
      ?~  packet  ~
      =/  profile  profile.request.u.packet
      %-  pairs:enjs:format
      :~  ['profile_id' s+id.profile]
          ['provider' s+provider.profile]
          ['role' s+role.profile]
          ['selector' s+selector.profile]
          ['model' s+model.profile]
      ==
  ==
::
++  lookup-envelope
  |=  [rows=(list json) matched=@ud body-omissions=@ud max-bytes=@ud error=(unit @tas)]
  ^-  json
  =/  omitted  (sub matched (lent rows))
  %-  pairs:enjs:format
  :~  ['schema_version' (numb:enjs:format 2)]
      ['artifacts' a+rows]
      ['matched' (numb:enjs:format matched)]
      ['returned' (numb:enjs:format (lent rows))]
      ['omitted' (numb:enjs:format omitted)]
      ['body_omissions' (numb:enjs:format body-omissions)]
      ['complete' b+?&(?=(~ error) =(0 omitted) =(0 body-omissions))]
      ['blocked_reason' ?~(error ~ s+u.error)]
      ['max_bytes' (numb:enjs:format max-bytes)]
      ['qualification' s+'Generated claims, not primary evidence. Exact quotes do not prove truth; approval and recall are not truth. Rejection is not factual disproof.']
      ['reuse_requirement' s+'Match exact packet input and model separately before skipping a provider invocation.']
  ==
::
++  lookup-artifacts
  |=  $:  scope=context-scope
          objective=@t
          provider=ai-provider
          limit=@ud
          max-bytes=@ud
          sources=(map @tas context-source)
          evidence=evidence-state
          versions=(map entity-key entity-version)
          store=learning-state
      ==
  ^-  json
  ?.  ?&((gte limit 1) (lte limit 32) (gte max-bytes 1.024) (lte max-bytes 262.144))
    (lookup-envelope ~ 0 0 max-bytes `%invalid-budget)
  ?.  ?&((scope-valid:ev scope) (bounded-text:ev objective 131.072))
    (lookup-envelope ~ 0 0 max-bytes `%invalid-scope)
  =/  ids  (fall (~(get by scope-index.store) scope) *(set @ux))
  =/  matched
    %+  skim  (sort ~(tap in ids) lth)
    |=  id=@ux
    =/  artifact  (~(get by artifacts.store) id)
    ?~  artifact  %.n
    ?|(=(0 objective) =(objective objective.u.artifact) !available.u.artifact)
  =/  total  (lent matched)
  =/  chosen=(list [artifact=learning-artifact error=(unit @tas)])  ~
  =/  rows=(list json)  ~
  =/  omissions=@ud  0
  ::  Admit bounded metadata before spending bytes on any generated body.
  =/  rest  matched
  =/  selected
    |-
    ?:  ?|(?=(~ rest) =(limit (lent chosen)))  [chosen rows omissions]
    =/  artifact  (~(got by artifacts.store) i.rest)
    =/  error  (artifact-error artifact provider sources evidence versions)
    =/  next  (weld rows ~[(artifact-row-json artifact error %.n evidence)])
    =/  omitted  (add omissions ?~(error 1 0))
    =/  candidate  (lookup-envelope next total omitted max-bytes ~)
    ?:  (gth (met 3 (en:json:html candidate)) max-bytes)
      $(rest t.rest)
    $(rest t.rest, chosen (weld chosen ~[[artifact error]]), rows next, omissions omitted)
  =.  chosen  -.selected
  =.  rows  +<.selected
  =.  omissions  +>.selected
  =/  before=(list json)  ~
  |-
  ?~  chosen  (lookup-envelope (flop before) total omissions max-bytes ~)
  ?>  ?=(^ rows)
  ?^  error.i.chosen
    $(chosen t.chosen, rows t.rows, before [i.rows before])
  =/  full  (artifact-row-json artifact.i.chosen ~ %.y evidence)
  =/  candidate
    (lookup-envelope (weld (flop before) [full t.rows]) total (dec omissions) max-bytes ~)
  ?:  (lte (met 3 (en:json:html candidate)) max-bytes)
    $(chosen t.chosen, rows t.rows, before [full before], omissions (dec omissions))
  $(chosen t.chosen, rows t.rows, before [i.rows before])
::
++  packet-snapshots
  |=  packet=context-packet
  ^-  (set @ux)
  =/  ids=(set @ux)  ~
  =/  entries  entries.packet
  |-
  ?~  entries  ids
  ?~  snapshot.i.entries  $(entries t.entries)
  $(entries t.entries, ids (~(put in ids) u.snapshot.i.entries))
::
++  artifact-snapshots
  |=  [artifact=learning-artifact evidence=evidence-state]
  ^-  (set @ux)
  =/  ids=(set @ux)
    ?~  packet.artifact  ~
    =/  packet  (~(get by packets.evidence) u.packet.artifact)
    ?~  packet  ~
    (packet-snapshots u.packet)
  =/  citations  citations.artifact
  |-
  ?~  citations  ids
  $(citations t.citations, ids (~(put in ids) snapshot.i.citations))
::
++  retire-packet
  |=  [packet=context-packet reason=@tas]
  ^-  context-packet
  =/  req  request.packet
  ::  Preserve digest, source/range identity and exact model; erase cached
  ::  objective/card bodies. This is application retention, not log erasure.
  =.  req
    req(objective '', title '', front '', back '', profile profile.req(label '', description '', worker '', registered-at *@da))
  packet(request req, blocked ?:(=(`%purged blocked.packet) blocked.packet `reason))
::
++  purge-snapshots
  |=  [ids=(set @ux) evidence=evidence-state store=learning-state]
  ^-  [evidence=evidence-state store=learning-state cleared=(set @ux)]
  =/  remaining  ~(tap in ids)
  =/  cleared=(set @ux)  ~
  =/  changed
    |-
    ?~  remaining  [evidence cleared]
    =/  snapshot  (~(get by snapshots.evidence) i.remaining)
    ?~  snapshot  $(remaining t.remaining)
    ?.  available.u.snapshot  $(remaining t.remaining)
    =/  blob  blob.u.snapshot
    =/  refs  (fall (~(get by blob-refs.evidence) blob) 0)
    =/  text  (~(get by blobs.evidence) blob)
    =.  snapshots.evidence
      (~(put by snapshots.evidence) i.remaining u.snapshot(available %.n))
    =.  cleared  (~(put in cleared) i.remaining)
    ?:  (gth refs 1)
      =.  blob-refs.evidence  (~(put by blob-refs.evidence) blob (dec refs))
      $(remaining t.remaining)
    =.  blob-refs.evidence  (~(del by blob-refs.evidence) blob)
    =.  blobs.evidence  (~(del by blobs.evidence) blob)
    =.  stored-bytes.evidence
      (sub stored-bytes.evidence (min stored-bytes.evidence ?~(text 0 (met 3 u.text))))
    $(remaining t.remaining)
  =.  evidence  -.changed
  =.  cleared  +.changed
  ::  Match the requested IDs, including already-purged dependencies, so
  ::  replay also clears any dependent generated text retained elsewhere.
  =/  artifacts  ~(tap by artifacts.store)
  =/  next-store
    |-
    ?~  artifacts  store
    =/  artifact  q.i.artifacts
    =/  deps  (artifact-snapshots artifact evidence)
    ?:  ?=(~ (~(int in deps) ids))  $(artifacts t.artifacts)
    =/  quotes
      (turn citations.artifact |=(citation=evidence-citation citation(quote '')))
    =/  next
      artifact(available %.n, objective '', draft ~, text '', citations quotes, reason ~)
    =.  stored-bytes.store
      (add (sub stored-bytes.store (artifact-bytes artifact)) (artifact-bytes next))
    =.  artifacts.store  (~(put by artifacts.store) id.artifact next)
    $(artifacts t.artifacts)
  =.  store  next-store
  =/  packets  ~(tap by packets.evidence)
  |-
  ?~  packets  [evidence store cleared]
  =/  packet  q.i.packets
  =/  deps  (packet-snapshots packet)
  ?:  ?=(~ (~(int in deps) ids))  $(packets t.packets)
  =.  packets.evidence
    (~(put by packets.evidence) id.packet (retire-packet packet %purged))
  $(packets t.packets)
::
++  collect-unused
  |=  $:  now=@da
          retain-after=@da
          keep-packets=(set @ux)
          keep-snapshots=(set @ux)
          evidence=evidence-state
          store=learning-state
      ==
  ^-  [evidence=evidence-state store=learning-state]
  ::  Explicit maintenance only. Future cutoffs cannot retire current work.
  =.  retain-after  (min now retain-after)
  =/  artifacts  ~(val by artifacts.store)
  =/  reachable
    |-
    ?~  artifacts  [keep-packets keep-snapshots]
    =/  artifact  i.artifacts
    ?.  available.artifact  $(artifacts t.artifacts)
    =?  keep-packets  ?=(^ packet.artifact)
      (~(put in keep-packets) (need packet.artifact))
    =.  keep-snapshots
      (~(uni in keep-snapshots) (artifact-snapshots artifact evidence))
    $(artifacts t.artifacts)
  =.  keep-packets  -.reachable
  =.  keep-snapshots  +.reachable
  =/  packets  ~(tap by packets.evidence)
  =/  retained
    |-
    ?~  packets  [evidence keep-snapshots]
    =/  packet  q.i.packets
    ?:  ?|  (~(has in keep-packets) id.packet)
            (gte created-at.packet retain-after)
        ==
      =.  keep-snapshots
        (~(uni in keep-snapshots) (packet-snapshots packet))
      $(packets t.packets)
    =.  packets.evidence
      (~(put by packets.evidence) id.packet (retire-packet packet %retired))
    $(packets t.packets)
  =.  evidence  -.retained
  =.  keep-snapshots  +.retained
  =/  snapshots  ~(val by snapshots.evidence)
  =/  ids=(set @ux)  ~
  |-
  ?~  snapshots
    =/  result  (purge-snapshots ids evidence store)
    [evidence.result store.result]
  =/  snapshot  i.snapshots
  =?  ids
      ?&  available.snapshot
          (lth retrieved-at.snapshot retain-after)
          !(~(has in keep-snapshots) id.snapshot)
      ==
    (~(put in ids) id.snapshot)
  $(snapshots t.snapshots)
--
