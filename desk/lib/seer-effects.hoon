/-  *seer
/+  *seer, ev=seer-evidence
|%
::  These constructors are shared by operator actions and approved plans.
++  clean-body
  |=  raw=@t
  ^-  @t
  =/  marker  (find ";>" (trip raw))
  ?~  marker  raw
  =/  start  (add 3 u.marker)
  (cut 3 [start (met 3 raw)] raw)
::
++  create-item
  ::  A filtered union can crash while bunting a gate's default sample.
  |=  [actor=@p now=@da act=action]
  ^-  item
  ?>  ?=(%new-item -.act)
  =/  front-matter=(map knot cord)
    %-  my
    :~  title+title.act
        author+(scot %p actor)
        date-created+(scot %da now)
        last-modified+(scot %da now)
    ==
  =/  front  (add-front-matter front-matter front.act)
  =/  back  (add-front-matter front-matter back.act)
  =/  new-content=content
    :*  actor
        title.act
        name.act
        now
        now
        %.y
        front
        back
        (form-snippet front)
        ~
        %.n
    ==
  (item new-content (learn [.2.5 0 0]) ~ name.act)
::
++  create-stack
  |=  [info=stack-info items=(map @tas item)]
  ^-  stack
  =|  sta=stack
  %=  sta
    info         [%.y info]
    name         filename.info
    last-update  last-modified.info
    items        (~(uni by items) items.sta)
  ==
::
++  edit-item
  |=  [actor=@p now=@da old=item title=@t front=@t back=@t]
  ^-  item
  =/  front-matter=(map knot cord)
    %-  my
    :~  title+title
        author+(scot %p actor)
        date-created+(scot %da date-created.content.old)
        last-modified+(scot %da now)
    ==
  =.  front  (add-front-matter front-matter front)
  =.  back  (add-front-matter front-matter back)
  old(content content.old(front front, back back, snippet (form-snippet front), title title, last-edit now))
::
++  operation-key
  |=  [our=@p op=state-operation]
  ^-  entity-key
  ?:  ?=(?(%create-stack %rename-stack %delete-stack) kind.op)
    [%stack our %root stack.op]
  [%card our stack.op card.op]
::
++  require-fence
  |=  [key=entity-key content=? review=? versions=(map entity-key entity-version) fences=(map entity-key entity-precondition)]
  ^-  (map entity-key entity-precondition)
  =/  old  (~(get by fences) key)
  =/  fence=entity-precondition
    :*  key
        (~(get by versions) key)
        ?~(old content ?|(content content.u.old))
        ?~(old review ?|(review review.u.old))
    ==
  (~(put by fences) key fence)
::
++  capture-preconditions
  |=  [our=@p versions=(map entity-key entity-version) ops=(list state-operation)]
  ^-  (list entity-precondition)
  =/  fences=(map entity-key entity-precondition)  ~
  |-
  ?~  ops  ~(val by fences)
  =/  op  i.ops
  =/  key  (operation-key our op)
  =/  review  ?=(?(%create-card %delete-card %queue-card %delete-stack) kind.op)
  =.  fences  (require-fence key %.y review versions fences)
  =?  fences  =(%card kind.key)
    (require-fence [%stack our %root stack.op] %.n %.n versions fences)
  $(ops t.ops)
::
++  target-id-valid
  |=  id=@tas
  ^-  ?
  ?.  ?&(!=(0 id) (lte (met 3 id) 128))  %.n
  =/  parsed  (slaw %tas id)
  ?~  parsed  %.n
  =(id u.parsed)
::
++  operation-shape-valid
  |=  op=state-operation
  ^-  ?
  ?.  ?&((target-id-valid stack.op) (lte (met 3 card.op) 128))
    %.n
  ?.  ?&  (utf8-valid:ev title.op)
          (utf8-valid:ev front.op)
          (utf8-valid:ev back.op)
          (utf8-valid:ev original-title.op)
          (utf8-valid:ev original-front.op)
          (utf8-valid:ev original-back.op)
      ==
    %.n
  ?-  kind.op
      %create-stack
    ?&  =(0 card.op)
        !=(0 title.op)
        =(['' '' '' '' ''] [front.op back.op original-title.op original-front.op original-back.op])
    ==
      %rename-stack
    ?&  =(0 card.op)
        !=(0 title.op)
        !=(0 original-title.op)
        =(['' '' '' ''] [front.op back.op original-front.op original-back.op])
    ==
      %delete-stack
    ?&  =(0 card.op)
        !=(0 original-title.op)
        =(['' '' '' '' ''] [title.op front.op back.op original-front.op original-back.op])
    ==
      %create-card
    ?&  (target-id-valid card.op)
        !=(0 title.op)
        !=(0 front.op)
        !=(0 back.op)
        =(['' '' ''] [original-title.op original-front.op original-back.op])
    ==
      %edit-card
    ?&  (target-id-valid card.op)
        !=(0 title.op)
        !=(0 front.op)
        !=(0 back.op)
        !=(0 original-title.op)
    ==
      %delete-card
    ?&  (target-id-valid card.op)
        !=(0 original-title.op)
        =(['' '' ''] [title.op front.op back.op])
    ==
      %queue-card
    ?&  (target-id-valid card.op)
        !=(0 original-title.op)
        =(['' '' ''] [title.op front.op back.op])
    ==
  ==
::
++  operation-bytes
  |=  op=state-operation
  ^-  @ud
  ;:  add
    (met 3 stack.op)
    (met 3 card.op)
    (met 3 title.op)
    (met 3 front.op)
    (met 3 back.op)
    (met 3 original-title.op)
    (met 3 original-front.op)
    (met 3 original-back.op)
  ==
::
++  operations-coherent
  |=  ops=(list state-operation)
  ^-  ?
  ?~  ops  %.y
  =/  op  i.ops
  =/  coherent
    =/  rest  t.ops
    |-
    ?~  rest  %.y
    =/  other  i.rest
    ?.  =(stack.op stack.other)  $(rest t.rest)
    ?:  =(card.op card.other)  %.n
    ?:  ?|  =(%delete-stack kind.op)
            =(%delete-stack kind.other)
        ==
      %.n
    ::  The only structural sequence is create-stack, then new cards.
    ?:  ?|  =(%create-stack kind.op)
            =(%create-stack kind.other)
        ==
      ?&  =(%create-stack kind.op)
          =(%create-card kind.other)
          $(rest t.rest)
      ==
    $(rest t.rest)
  ?&(coherent $(ops t.ops))
::
++  fence-matches
  |=  [fence=entity-precondition current=(unit entity-version)]
  ^-  ?
  ?~  seen.fence  ?=(~ current)
  ?~  current  %.n
  ?&  =(incarnation.u.seen.fence incarnation.u.current)
      =(present.u.seen.fence present.u.current)
      ?|  !content.fence
          =(content-revision.u.seen.fence content-revision.u.current)
      ==
      ?|  !review.fence
          =(review-revision.u.seen.fence review-revision.u.current)
      ==
  ==
::
++  entity-present
  |=  [key=entity-key stacks=(map @tas stack)]
  ^-  ?
  ?:  =(%stack kind.key)  (~(has by stacks) id.key)
  =/  parent  (~(get by stacks) scope.key)
  ?~  parent  %.n
  (~(has by items.u.parent) id.key)
::
++  item-text
  |=  card=item
  ^-  [title=@t front=@t back=@t]
  [title.content.card (clean-body front.content.card) (clean-body back.content.card)]
::
++  operation-text
  |=  [op=state-operation stacks=(map @tas stack)]
  ^-  (unit [title=@t front=@t back=@t])
  =/  parent  (~(get by stacks) stack.op)
  ?~  parent  ~
  ?:  ?=(?(%create-stack %rename-stack %delete-stack) kind.op)
    ?.  ?=(%.y -.info.u.parent)  ~
    `[title.p.info.u.parent '' '']
  =/  card  (~(get by items.u.parent) card.op)
  ?~  card  ~
  `(item-text u.card)
::
++  operation-error
  |=  [our=@p op=state-operation stacks=(map @tas stack)]
  ^-  (unit @tas)
  =/  parent  (~(get by stacks) stack.op)
  ?:  =(%create-stack kind.op)
    ?~(parent ~ `%stack-exists)
  ?~  parent  `%missing-stack
  ?.  ?=(%.y -.info.u.parent)  `%invalid-stack
  ?.  =(our owner.p.info.u.parent)  `%wrong-owner
  ?:  ?=(?(%rename-stack %delete-stack) kind.op)
    ?:  =(original-title.op title.p.info.u.parent)  ~
    `%original-mismatch
  =/  card  (~(get by items.u.parent) card.op)
  ?:  =(%create-card kind.op)
    ?~(card ~ `%card-exists)
  ?~  card  `%missing-card
  ?.  =([original-title.op original-front.op original-back.op] (item-text u.card))
    `%original-mismatch
  ~
::
++  apply-operation
  |=  [our=@p now=@da stacks=(map @tas stack) op=state-operation]
  ^-  (map @tas stack)
  ::  Called only after operation-error has checked this candidate.
  ?:  =(%create-stack kind.op)
    =/  info=stack-info  [our title.op stack.op *edit-config now now]
    (~(put by stacks) stack.op (create-stack info ~))
  ?:  =(%delete-stack kind.op)  (~(del by stacks) stack.op)
  =/  parent  (~(got by stacks) stack.op)
  =.  parent
    ?-  kind.op
      %create-stack  parent
      %delete-stack  parent
      %rename-stack
        ?>  ?=(%.y -.info.parent)
        =/  info  p.info.parent
        parent(info [%.y info(title title.op, last-modified now)], last-update now)
      %create-card
        =/  act=action
          [%new-item our our stack.op card.op title.op [*rule:clay *rule:clay] front.op back.op]
        =/  card  (create-item our now act)
        %=  parent
          items         (~(put by items.parent) card.op card)
          review-items  (~(put by review-items.parent) card.op card)
        ==
      %edit-card
        =/  old  (~(got by items.parent) card.op)
        =/  card  (edit-item our now old title.op front.op back.op)
        %=  parent
          items  (~(put by items.parent) card.op card)
          review-items
            ?:  (~(has by review-items.parent) card.op)
              (~(put by review-items.parent) card.op card)
            review-items.parent
        ==
      %delete-card
        %=  parent
          items         (~(del by items.parent) card.op)
          review-items  (~(del by review-items.parent) card.op)
        ==
      %queue-card
        =/  card  (~(got by items.parent) card.op)
        parent(review-items (~(put by review-items.parent) card.op card))
    ==
  (~(put by stacks) stack.op parent)
::
++  review-effect
  |=  [op=state-operation stacks=(map @tas stack)]
  ^-  $?(%unchanged %queued %removed)
  ?:  =(%create-card kind.op)  %queued
  =/  parent  (~(get by stacks) stack.op)
  ?~  parent  %unchanged
  ?:  =(%delete-stack kind.op)
    ?:(?=(~ review-items.u.parent) %unchanged %removed)
  =/  queued  (~(has by review-items.u.parent) card.op)
  ?:  =(%delete-card kind.op)  ?:(queued %removed %unchanged)
  ?:  =(%queue-card kind.op)  ?:(queued %unchanged %queued)
  %unchanged
::
++  operation-affected
  |=  [our=@p op=state-operation stacks=(map @tas stack) keys=(set entity-key)]
  ^-  (set entity-key)
  =.  keys  (~(put in keys) (operation-key our op))
  =.  keys  (~(put in keys) [%stack our %root stack.op])
  ?.  =(%delete-stack kind.op)  keys
  =/  parent  (~(get by stacks) stack.op)
  ?~  parent  keys
  =/  cards  ~(tap by items.u.parent)
  |-
  ?~  cards  keys
  =.  keys  (~(put in keys) [%card our stack.op p.i.cards])
  $(cards t.cards)
::
::  Stop counting once a deletion is known to exceed the admission limit.
++  bounded-item-count
  |=  [tree=(map @tas item) limit=@ud]
  ^-  @ud
  ?~  tree  0
  ?:  =(0 limit)  0
  =/  used  +($(tree l.tree))
  ?:  (gte used limit)  limit
  (add used $(tree r.tree, limit (sub limit used)))
::
++  deletion-diffs
  |=  [op=state-operation parent=stack diffs=(list plan-diff)]
  ^-  (list plan-diff)
  =/  cards  ~(tap by items.parent)
  |-
  ?~  cards  diffs
  =/  text  (item-text q.i.cards)
  =/  child=state-operation
    [%delete-card stack.op p.i.cards '' '' '' title.text front.text back.text]
  =/  effect  ?:((~(has by review-items.parent) p.i.cards) %removed %unchanged)
  =/  diff=plan-diff  [child `text ~ effect]
  $(cards t.cards, diffs [diff diffs])
::
++  validate-plan
  |=  [our=@p now=@da stacks=(map @tas stack) versions=(map entity-key entity-version) ops=(list state-operation) preconditions=(list entity-precondition)]
  ^-  plan-preview
  =/  base=plan-preview
    [%invalid %invalid-plan (shax (jam [our ops preconditions])) stacks ~ ~]
  ?.  (lte (lent (scag 65 ops)) 64)
    base(status %budget-exhausted, reason %operation-limit)
  ?:  =(~ ops)  base(reason %empty-plan)
  =/  text-bytes
    =/  remaining  ops
    =/  bytes=@ud  0
    |-
    ?~  remaining  bytes
    =.  bytes  (add bytes (operation-bytes i.remaining))
    ?:  (gth bytes 131.072)  bytes
    $(remaining t.remaining)
  ?:  (gth text-bytes 131.072)
    base(status %budget-exhausted, reason %operation-text-limit)
  ?.  (levy ops operation-shape-valid)  base(reason %operation-shape)
  ?.  (operations-coherent ops)  base(reason %ambiguous-operations)
  ?.  (lte (lent (scag 257 preconditions)) 256)
    base(status %budget-exhausted, reason %precondition-limit)
  =/  required  (capture-preconditions our versions ops)
  =/  supplied=(map entity-key entity-precondition)
    =/  rows  preconditions
    =/  result=(map entity-key entity-precondition)  ~
    |-
    ?~  rows  result
    $(rows t.rows, result (~(put by result) key.i.rows i.rows))
  ?.  =((lent preconditions) (lent ~(tap by supplied)))
    base(reason %duplicate-precondition)
  ?.  =((lent required) (lent preconditions))
    base(reason %missing-precondition)
  =/  fence-error=(unit @tas)
    =/  rows  required
    |-
    ?~  rows  ~
    =/  need-fence  i.rows
    =/  provided  (~(get by supplied) key.need-fence)
    ?~  provided  `%missing-precondition
    ?.  ?&  =(content.need-fence content.u.provided)
            =(review.need-fence review.u.provided)
        ==
      `%precondition-domain
    =/  current  (~(get by versions) key.need-fence)
    ?.  (fence-matches u.provided current)  `%stale-precondition
    ?.  =((entity-present key.need-fence stacks) ?~(current %.n present.u.current))
      `%unversioned-entity
    $(rows t.rows)
  ?^  fence-error
    base(status %conflict, reason u.fence-error)
  =/  candidate  stacks
  =/  affected=(set entity-key)  ~
  =/  diffs=(list plan-diff)  ~
  |-
  ?~  ops
    base(status %ok, reason %ok, candidate candidate, affected ~(tap in affected), diffs (flop diffs))
  =/  op  i.ops
  =/  error  (operation-error our op candidate)
  ?^  error  base(status %conflict, reason u.error)
  ::  A stack deletion is one op but can affect arbitrarily many cards.
  ?:  =(%delete-stack kind.op)
    =/  parent  (~(got by candidate) stack.op)
    ?:  (gth (bounded-item-count items.parent 256) 255)
      base(status %budget-exhausted, reason %affected-limit)
    =/  next-affected  (operation-affected our op candidate affected)
    ?:  (gth (lent ~(tap in next-affected)) 256)
      base(status %budget-exhausted, reason %affected-limit)
    =/  diff=plan-diff
      [op (operation-text op candidate) ~ (review-effect op candidate)]
    =.  diffs  (deletion-diffs op parent [diff diffs])
    $(ops t.ops, candidate (apply-operation our now candidate op), affected next-affected)
  =/  next-affected  (operation-affected our op candidate affected)
  ?:  (gth (lent ~(tap in next-affected)) 256)
    base(status %budget-exhausted, reason %affected-limit)
  =/  before  (operation-text op candidate)
  =/  effect  (review-effect op candidate)
  =.  candidate  (apply-operation our now candidate op)
  =/  diff=plan-diff  [op before (operation-text op candidate) effect]
  $(ops t.ops, affected next-affected, diffs [diff diffs])
::
++  proposal-operations
  |=  draft=proposal
  ^-  (list state-operation)
  ~[[%create-card stack.draft card.draft title.draft front.draft back.draft '' '' '']]
::
++  proposal-preview
  |=  [our=@p now=@da stacks=(map @tas stack) versions=(map entity-key entity-version) draft=proposal]
  ^-  plan-preview
  (validate-plan our now stacks versions (proposal-operations draft) preconditions.draft)
::
++  reference-json
  |=  key=entity-key
  ^-  json
  %-  pairs:enjs:format
  :~  ['kind' s+(scot %tas kind.key)]
      ['owner' s+(scot %p owner.key)]
      ['scope' s+(scot %tas scope.key)]
      ['id' s+(scot %tas id.key)]
  ==
::
++  text-json
  |=  text=(unit [title=@t front=@t back=@t])
  ^-  json
  ?~  text  ~
  %-  pairs:enjs:format
  :~  ['title' s+title.u.text]
      ['front' s+front.u.text]
      ['back' s+back.u.text]
  ==
::
++  text-bytes
  |=  text=(unit [title=@t front=@t back=@t])
  ^-  @ud
  ?~  text  0
  :(add (met 3 title.u.text) (met 3 front.u.text) (met 3 back.u.text))
::
++  diff-text-bytes
  |=  diff=plan-diff
  ^-  @ud
  (add (text-bytes before.diff) (text-bytes after.diff))
::
++  diff-json
  |=  diff=plan-diff
  ^-  json
  %-  pairs:enjs:format
  :~  ['operation' s+(scot %tas kind.operation.diff)]
      ['stack_id' s+(scot %tas stack.operation.diff)]
      ['card_id' s+(scot %tas card.operation.diff)]
      ['before' (text-json before.diff)]
      ['after' (text-json after.diff)]
      ['review_effect' s+(scot %tas review-effect.diff)]
      ['learning_state' s+?:(?=(~ after.diff) 'removed-with-entity' 'preserved')]
  ==
::
++  preview-envelope
  |=  [preview=plan-preview complete=? refs=(list json) diffs=(list json) omitted-refs=@ud omitted-diffs=@ud]
  ^-  json
  %-  pairs:enjs:format
  :~  ['schema_version' (numb:enjs:format 2)]
      ['status' s+?:(complete (scot %tas status.preview) 'limit-exceeded')]
      ['validation_status' s+(scot %tas status.preview)]
      ['reason' s+(scot %tas reason.preview)]
      ['digest' s+(scot %ux digest.preview)]
      ['detail_ref' s+(scot %ux digest.preview)]
      ['complete' b+complete]
      ['affected_count' (numb:enjs:format (lent affected.preview))]
      ['diff_count' (numb:enjs:format (lent diffs.preview))]
      ['affected' [%a refs]]
      ['diffs' [%a diffs]]
      ['omitted_affected' (numb:enjs:format omitted-refs)]
      ['omitted_diffs' (numb:enjs:format omitted-diffs)]
      ['learning_state' s+'preserved-for-surviving-cards']
      ['automatic_grades' (numb:enjs:format 0)]
  ==
::
++  preview-json
  |=  [preview=plan-preview max-bytes=@ud]
  ^-  json
  ::  Below the supported minimum even the proof envelope cannot fit.
  ?.  (gte max-bytes 1.024)
    (preview-envelope preview(reason %invalid-preview-limit) %.n ~ ~ (lent affected.preview) (lent diffs.preview))
  =.  max-bytes  (min 262.144 max-bytes)
  =/  refs  (turn affected.preview reference-json)
  =/  diffs  (turn diffs.preview diff-json)
  =/  full  (preview-envelope preview %.y refs diffs 0 0)
  =/  body-bytes
    %+  roll  diffs.preview
    |=  [diff=plan-diff sum=@ud]
    (add sum (diff-text-bytes diff))
  ?:  ?&  (lte body-bytes max-bytes)
          (lte (met 3 (en:json:html full)) max-bytes)
      ==
    full
  ::  Whole rows only. The digest remains available even if no row fits.
  =/  kept-refs=(list json)  ~
  =/  kept-diffs=(list json)  ~
  =/  omitted-refs  (lent refs)
  =/  omitted-diffs  (lent diffs)
  =/  result  (preview-envelope preview %.n ~ ~ omitted-refs omitted-diffs)
  =/  with-refs
    |-
    ?~  refs  [result kept-refs omitted-refs]
    =/  next
      (preview-envelope preview %.n (flop [i.refs kept-refs]) ~ (dec omitted-refs) omitted-diffs)
    ?.  (lte (met 3 (en:json:html next)) max-bytes)
      [result kept-refs omitted-refs]
    $(refs t.refs, kept-refs [i.refs kept-refs], omitted-refs (dec omitted-refs), result next)
  =.  result  -.with-refs
  =.  kept-refs  +<.with-refs
  =.  omitted-refs  +>.with-refs
  =/  remaining  diffs.preview
  |-
  ?~  diffs  result
  ?>  ?=(^ remaining)
  ?:  (gth (diff-text-bytes i.remaining) max-bytes)  result
  =/  next
    (preview-envelope preview %.n (flop kept-refs) (flop [i.diffs kept-diffs]) omitted-refs (dec omitted-diffs))
  ?.  (lte (met 3 (en:json:html next)) max-bytes)  result
  $(diffs t.diffs, remaining t.remaining, kept-diffs [i.diffs kept-diffs], omitted-diffs (dec omitted-diffs), result next)
::
++  operation-receipt-at
  |=  [control=agent-state epoch=@da id=@t expected=(unit @ux)]
  ^-  operation-receipt
  =/  missing  *operation-receipt
  =.  missing
    %=  missing
      epoch       epoch
      id          id
      digest      (fall expected 0x0)
      action      %unknown
      status      %outcome-unknown
      reason      %receipt-not-found
      effect      %unknown
      authority   %operator
      revision    revision.control
    ==
  =/  retained  (~(get by receipts.control) [epoch id])
  ::  Only the acknowledgement of retirement survives its old epoch.
  ?.  ?|  =(epoch epoch.control)
          ?~(retained %.n =(%retire-operation-epoch action.u.retained))
      ==
    missing(status %replay-expired, reason %operation-epoch-expired)
  ?~  retained
    ?:  (gte receipt-count.control 4.096)
      missing(status %budget-exhausted, reason %receipt-limit, effect %none)
    missing
  ?:  ?~(expected %.n !=(u.expected digest.u.retained))
    u.retained(status %conflict, reason %operation-digest-conflict, effect %none, before ~, after ~)
  u.retained
::
++  precondition-json
  |=  fence=entity-precondition
  ^-  json
  %-  pairs:enjs:format
  :~  ['ref' (reference-json key.fence)]
      ['version' ?~(seen.fence ~ (version-json:ev u.seen.fence))]
      ['content' b+content.fence]
      ['review' b+review.fence]
  ==
::
++  receipt-metadata
  |=  receipt=operation-receipt
  ^-  json
  =/  next=(list @t)  ~['seer/get-operation-result' 'seer/agent-context']
  =?  next  ?&(=(%budget-exhausted status.receipt) =(%receipt-limit reason.receipt))
    (weld next ~['seer/retire-operation-epoch'])
  %-  pairs:enjs:format
  :~  ['schema_version' (numb:enjs:format 2)]
      ['idempotency_epoch' s+(scot %da epoch.receipt)]
      ['operation_id' s+id.receipt]
      ['payload_digest' s+(scot %ux digest.receipt)]
      ['submission' s+(scot %ux submission.receipt)]
      ['action' s+action.receipt]
      ['status' s+status.receipt]
      ['reason' s+reason.receipt]
      ['effect' s+effect.receipt]
      ['authority' s+authority.receipt]
      ['work_ref' ?~(work.receipt ~ (reference-json u.work.receipt))]
      ['attempt' ?~(attempt.receipt ~ (numb:enjs:format u.attempt.receipt))]
      ['plan_digest' ?~(plan.receipt ~ s+(scot %ux u.plan.receipt))]
      ['revision' (numb:enjs:format revision.receipt)]
      ['observed_at' ?:(=(0 at.receipt) ~ s+(scot %da at.receipt))]
      ['before_count' (numb:enjs:format (lent before.receipt))]
      ['after_count' (numb:enjs:format (lent after.receipt))]
      ['retry_authorized' b+%.n]
      ['legal_next_actions' [%a (turn next |=(name=@t s+name))]]
  ==
::
++  receipt-envelope
  |=  [metadata=json before=(list json) after=(list json) omitted-before=@ud omitted-after=@ud]
  ^-  json
  =/  omissions=(list json)  ~
  =?  omissions  (gth omitted-after 0)
    :-  %-  pairs:enjs:format
        :~  ['field' s+'after']
            ['count' (numb:enjs:format omitted-after)]
            ['reason' s+'byte-limit']
        ==
    omissions
  =?  omissions  (gth omitted-before 0)
    :-  %-  pairs:enjs:format
        :~  ['field' s+'before']
            ['count' (numb:enjs:format omitted-before)]
            ['reason' s+'byte-limit']
        ==
    omissions
  =/  details
    %-  pairs:enjs:format
    :~  ['before' [%a before]]
        ['after' [%a after]]
        ['complete' b+?=(~ omissions)]
        ['omissions' [%a omissions]]
    ==
  ?>  ?&(?=(%o -.metadata) ?=(%o -.details))
  [%o (~(uni by p.details) p.metadata)]
::
++  receipt-limit-error
  |=  reason=@tas
  ^-  json
  %-  pairs:enjs:format
  :~  ['schema_version' (numb:enjs:format 2)]
      ['status' s+'invalid']
      ['reason' s+reason]
      ['complete' b+%.n]
      ['minimum_max_bytes' (numb:enjs:format 4.096)]
      ['maximum_max_bytes' (numb:enjs:format 262.144)]
      ['retry_authorized' b+%.n]
      ['legal_next_actions' [%a ~[[%s 'seer/get-operation-result']]]]
      ['omissions' [%a ~[[%s 'receipt']]]]
  ==
::
++  receipt-json
  |=  [receipt=operation-receipt max-bytes=@ud]
  ^-  json
  ::  An invalid limit cannot promise space even for the identity envelope.
  ?.  ?&((gte max-bytes 4.096) (lte max-bytes 262.144))
    (receipt-limit-error %invalid-receipt-limit)
  =/  metadata  (receipt-metadata receipt)
  =/  before=(list json)  ~
  =/  after=(list json)  ~
  =/  omitted-before  (lent before.receipt)
  =/  omitted-after  (lent after.receipt)
  =/  result  (receipt-envelope metadata before after omitted-before omitted-after)
  ?:  (gth (met 3 (en:json:html result)) max-bytes)
    (receipt-limit-error %receipt-metadata-limit)
  ::  Encode and measure whole rows; never cut a UTF-8 sequence or a fence.
  =/  rows  before.receipt
  =/  with-before
    |-
    ?~  rows  [result before omitted-before]
    =/  row  (precondition-json i.rows)
    =/  next
      (receipt-envelope metadata (flop [row before]) ~ (dec omitted-before) omitted-after)
    ?.  (lte (met 3 (en:json:html next)) max-bytes)
      [result before omitted-before]
    $(rows t.rows, before [row before], omitted-before (dec omitted-before), result next)
  =.  result  -.with-before
  =.  before  +<.with-before
  =.  omitted-before  +>.with-before
  =.  rows  after.receipt
  |-
  ?~  rows  result
  =/  row  (precondition-json i.rows)
  =/  next
    (receipt-envelope metadata (flop before) (flop [row after]) omitted-before (dec omitted-after))
  ?.  (lte (met 3 (en:json:html next)) max-bytes)  result
  $(rows t.rows, after [row after], omitted-after (dec omitted-after), result next)
--
