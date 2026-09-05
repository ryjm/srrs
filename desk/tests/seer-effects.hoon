/-  *seer
/+  *test, effects=seer-effects
|%
++  fixed-now  ~2026.9.2
++  stack-key  ^-  entity-key  [%stack ~zod %root %s1]
++  card-key  ^-  entity-key  [%card ~zod %s1 %c1]
++  new-stack
  ^-  state-operation
  [%create-stack %s1 '' 'Stack' '' '' '' '' '']
++  new-card
  ^-  state-operation
  [%create-card %s1 %c1 'A' 'front' 'back' '' '' '']
++  edit-card
  ^-  state-operation
  [%edit-card %s1 %c1 'B' 'new front' 'new back' 'A' 'front' 'back']
++  initial-versions
  ^-  (map entity-key entity-version)
  (my ~[[stack-key [1 1 1 %.y]] [card-key [2 1 1 %.y]]])
++  initial-stacks
  ^-  (map @tas stack)
  =/  ops  ~[new-stack new-card]
  =/  fences  (capture-preconditions:effects ~zod ~ ops)
  candidate:(validate-plan:effects ~zod fixed-now ~ ~ ops fences)
++  json-field
  |=  [value=json key=@t]
  ^-  json
  ?>  ?=(%o -.value)
  (~(got by p.value) key)
::
++  recorded-receipt
  ^-  operation-receipt
  =/  receipt  *operation-receipt
  %=  receipt
    epoch       fixed-now
    id          'edit-1'
    digest      0x1234
    submission  0xabcd
    action      %apply-change
    status      %ok
    reason      %ok
    effect      %committed
    authority   %operator
    plan        `0x5678
    before      (capture-preconditions:effects ~zod initial-versions ~[edit-card])
    after       (capture-preconditions:effects ~zod (~(put by initial-versions) card-key [2 2 1 %.y]) ~[edit-card])
    revision    3
    at          fixed-now
  ==
::
++  receipt-control
  ^-  agent-state
  =/  control  *agent-state
  %=  control
    epoch          fixed-now
    receipts       (my ~[[[fixed-now 'edit-1'] recorded-receipt]])
    receipt-count  1
    revision       3
  ==
::
++  receipt-omission-count
  |=  [value=json field=@t]
  ^-  @ud
  =/  omissions  (json-field value 'omissions')
  ?>  ?=(%a -.omissions)
  =/  matching
    %+  skim  p.omissions
    |=(row=json =([%s field] (json-field row 'field')))
  ?~  matching  0
  =/  count  (json-field i.matching 'count')
  ?>  ?=(%n -.count)
  (need (slaw %ud p.count))
::
++  test-ordered-stack-and-cards
  ^-  tang
  =/  ops  ~[new-stack new-card]
  =/  fences  (capture-preconditions:effects ~zod ~ ops)
  =/  result  (validate-plan:effects ~zod fixed-now ~ ~ ops fences)
  =/  parent  (~(got by candidate.result) %s1)
  =/  card  (~(got by items.parent) %c1)
  ;:  weld
    (expect-eq !>(%ok) !>(status.result))
    (expect-eq !>('front') !>((clean-body:effects front.content.card)))
    (expect-eq !>(card) !>((~(got by review-items.parent) %c1)))
    (expect-eq !>(~) !>(last-review.card))
    (expect-eq !>((silt ~[stack-key card-key])) !>((silt affected.result)))
  ==
::
++  test-failed-intermediate-is-atomic
  ^-  tang
  =/  bad  %*(. new-card stack %missing)
  =/  ops  ~[new-stack new-card bad]
  =/  fences  (capture-preconditions:effects ~zod ~ ops)
  =/  result  (validate-plan:effects ~zod fixed-now ~ ~ ops fences)
  ;:  weld
    (expect-eq !>(%missing-stack) !>(reason.result))
    (expect-eq !>(*(map @tas stack)) !>(candidate.result))
    (expect-eq !>(~) !>(affected.result))
    (expect-eq !>(~) !>(diffs.result))
  ==
::
++  test-content-aba-conflicts
  ^-  tang
  ::  Content has returned to A, but two intervening edits advanced its fence.
  =/  ops  ~[edit-card]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  versions  (~(put by initial-versions) card-key [2 3 1 %.y])
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks versions ops fences)
  ;:  weld
    (expect-eq !>(%stale-precondition) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
    (expect-eq !>(~) !>(diffs.result))
  ==
::
++  test-recreated-incarnation-conflicts
  ^-  tang
  =/  ops  ~[edit-card]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  versions  (~(put by initial-versions) card-key [3 1 1 %.y])
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks versions ops fences)
  ;:  weld
    (expect-eq !>(%stale-precondition) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
  ==
::
++  test-negative-incarnation-conflicts
  ^-  tang
  ::  Absent -> created -> deleted must not satisfy the original absence.
  =/  ops  ~[new-stack new-card]
  =/  fences  (capture-preconditions:effects ~zod ~ ops)
  =/  versions  (my ~[[stack-key [1 3 3 %.n]]])
  =/  result  (validate-plan:effects ~zod fixed-now ~ versions ops fences)
  ;:  weld
    (expect-eq !>(%stale-precondition) !>(reason.result))
    (expect-eq !>(*(map @tas stack)) !>(candidate.result))
  ==
::
++  test-grade-survives-editorial-change
  ^-  tang
  =/  ops  ~[edit-card]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  parent  (~(got by initial-stacks) %s1)
  =/  old  (~(got by items.parent) %c1)
  =.  old  old(learn [.2.7 ~d4 3], last-review `fixed-now)
  =.  parent  parent(items (~(put by items.parent) %c1 old), review-items ~)
  =/  stacks  (~(put by initial-stacks) %s1 parent)
  =/  versions  (~(put by initial-versions) card-key [2 1 9 %.y])
  =.  versions  (~(put by versions) stack-key [1 1 9 %.y])
  =/  later=@da  (add fixed-now ~h1)
  =/  result  (validate-plan:effects ~zod later stacks versions ops fences)
  =/  after  (~(got by candidate.result) %s1)
  =/  card  (~(got by items.after) %c1)
  ;:  weld
    (expect-eq !>(%ok) !>(status.result))
    (expect-eq !>('B') !>(title.content.card))
    (expect-eq !>(learn.old) !>(learn.card))
    (expect-eq !>(last-review.old) !>(last-review.card))
    (expect-eq !>(~) !>(review-items.after))
    (expect-eq !>(later) !>(last-edit.content.card))
  ==
::
++  test-queue-requires-review-fence
  ^-  tang
  =/  op=state-operation
    [%queue-card %s1 %c1 '' '' '' 'A' 'front' 'back']
  =/  ops  ~[op]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  versions  (~(put by initial-versions) card-key [2 1 2 %.y])
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks versions ops fences)
  ;:  weld
    (expect-eq !>(%stale-precondition) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
  ==
::
++  test-duplicate-target-and-missing-fence
  ^-  tang
  =/  ops  ~[edit-card edit-card]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  duplicate  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ops fences)
  =/  missing  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ~[edit-card] ~)
  ?>  ?=(^ fences)
  =/  repeated  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ~[edit-card] [i.fences fences])
  ;:  weld
    (expect-eq !>(%ambiguous-operations) !>(reason.duplicate))
    (expect-eq !>(%missing-precondition) !>(reason.missing))
    (expect-eq !>(%duplicate-precondition) !>(reason.repeated))
    (expect-eq !>(initial-stacks) !>(candidate.duplicate))
    (expect-eq !>(initial-stacks) !>(candidate.missing))
    (expect-eq !>(initial-stacks) !>(candidate.repeated))
  ==
::
++  test-stack-deletion-discloses-cascade
  ^-  tang
  =/  op=state-operation
    [%delete-stack %s1 '' '' '' '' 'Stack' '' '']
  =/  ops  ~[op]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ops fences)
  =/  children
    %+  skim  diffs.result
    |=(diff=plan-diff =(%delete-card kind.operation.diff))
  ?>  ?=(^ children)
  =/  child  i.children
  ;:  weld
    (expect-eq !>(%ok) !>(status.result))
    (expect-eq !>(*(map @tas stack)) !>(candidate.result))
    (expect-eq !>((silt ~[stack-key card-key])) !>((silt affected.result)))
    (expect-eq !>(`['A' 'front' 'back']) !>(before.child))
    (expect-eq !>(~) !>(after.child))
    (expect-eq !>(%removed) !>(review-effect.child))
  ==
::
++  test-preview-omissions-keep-proof
  ^-  tang
  =/  long=@t  (crip (reap 2.048 'x'))
  =/  ops  ~[new-stack %*(. new-card front long)]
  =/  fences  (capture-preconditions:effects ~zod ~ ops)
  =/  result  (validate-plan:effects ~zod fixed-now ~ ~ ops fences)
  =/  projection  (preview-json:effects result 1.024)
  ;:  weld
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html projection)) 1.024)))
    (expect-eq !>([%b %.n]) !>((json-field projection 'complete')))
    (expect-eq !>([%s 'limit-exceeded']) !>((json-field projection 'status')))
    (expect-eq !>([%s (scot %ux digest.result)]) !>((json-field projection 'digest')))
    (expect-eq !>(%.n) !>(=([%n '0'] (json-field projection 'omitted_diffs'))))
  ==
::
++  test-unused-fields-cannot-hide-an-operation
  ^-  tang
  =/  op=state-operation
    [%queue-card %s1 %c1 '' 'silently ignored edit' '' 'A' 'front' 'back']
  =/  ops  ~[op]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ops fences)
  ;:  weld
    (expect-eq !>(%invalid) !>(status.result))
    (expect-eq !>(%operation-shape) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
    (expect-eq !>(~) !>(affected.result))
    (expect-eq !>(~) !>(diffs.result))
  ==
::
++  test-invalid-target-and-utf8-are-atomic
  ^-  tang
  =/  malformed  %*(. new-card card 'bad/id')
  =/  invalid-text  %*(. new-card front (@t 0xc0))
  =/  malformed-ops  ~[new-stack malformed]
  =/  invalid-ops  ~[new-stack invalid-text]
  =/  target
    (validate-plan:effects ~zod fixed-now ~ ~ malformed-ops (capture-preconditions:effects ~zod ~ malformed-ops))
  =/  text
    (validate-plan:effects ~zod fixed-now ~ ~ invalid-ops (capture-preconditions:effects ~zod ~ invalid-ops))
  ;:  weld
    (expect-eq !>(%operation-shape) !>(reason.target))
    (expect-eq !>(%operation-shape) !>(reason.text))
    (expect-eq !>(*(map @tas stack)) !>(candidate.target))
    (expect-eq !>(*(map @tas stack)) !>(candidate.text))
    (expect-eq !>(~) !>(diffs.target))
    (expect-eq !>(~) !>(diffs.text))
  ==
::
++  test-required-content-domain-cannot-be-weakened
  ^-  tang
  =/  ops  ~[edit-card]
  =/  fences
    %+  turn  (capture-preconditions:effects ~zod initial-versions ops)
    |=(fence=entity-precondition fence(content %.n))
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks initial-versions ops fences)
  ;:  weld
    (expect-eq !>(%precondition-domain) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
    (expect-eq !>(~) !>(diffs.result))
  ==
::
++  test-unversioned-content-is-not-a-negative-observation
  ^-  tang
  =/  versions  (~(del by initial-versions) card-key)
  =/  ops  ~[edit-card]
  =/  fences  (capture-preconditions:effects ~zod versions ops)
  =/  result  (validate-plan:effects ~zod fixed-now initial-stacks versions ops fences)
  ;:  weld
    (expect-eq !>(%unversioned-entity) !>(reason.result))
    (expect-eq !>(initial-stacks) !>(candidate.result))
    (expect-eq !>(~) !>(diffs.result))
  ==
::
++  test-cascade-admission-boundary
  ^-  tang
  =/  parent  (~(got by initial-stacks) %s1)
  =/  card  (~(got by items.parent) %c1)
  =/  cards=(map @tas item)
    =/  index=@ud  1
    =|  out=(map @tas item)
    |-
    ?:  (gth index 256)  out
    =/  id=@tas  (cat 3 'c' (scot %ud index))
    $(index +(index), out (~(put by out) id card(name id, content content.card(filename id))))
  =/  over  (~(put by initial-stacks) %s1 parent(items cards, review-items cards))
  =/  bounded  (~(del by cards) %c256)
  =/  under  (~(put by initial-stacks) %s1 parent(items bounded, review-items bounded))
  =/  op=state-operation  [%delete-stack %s1 '' '' '' '' 'Stack' '' '']
  =/  ops  ~[op]
  =/  fences  (capture-preconditions:effects ~zod initial-versions ops)
  =/  rejected  (validate-plan:effects ~zod fixed-now over initial-versions ops fences)
  =/  admitted  (validate-plan:effects ~zod fixed-now under initial-versions ops fences)
  ;:  weld
    (expect-eq !>(%affected-limit) !>(reason.rejected))
    (expect-eq !>(%budget-exhausted) !>(status.rejected))
    (expect-eq !>(over) !>(candidate.rejected))
    (expect-eq !>(~) !>(affected.rejected))
    (expect-eq !>(~) !>(diffs.rejected))
    (expect-eq !>(%ok) !>(status.admitted))
    (expect-eq !>(256) !>((lent affected.admitted)))
    (expect-eq !>(*(map @tas stack)) !>(candidate.admitted))
  ==
::
++  test-proposal-never-creates-or-rebases-stack
  ^-  tang
  =/  draft  *proposal
  =.  draft  draft(stack %s1, card %c2, title 'New', front 'question', back 'answer')
  =/  ops  (proposal-operations:effects draft)
  =.  draft  draft(preconditions (capture-preconditions:effects ~zod initial-versions ops))
  =/  admitted  (proposal-preview:effects ~zod fixed-now initial-stacks initial-versions draft)
  =/  replacement  (~(put by initial-versions) stack-key [9 1 1 %.y])
  =/  stale  (proposal-preview:effects ~zod fixed-now initial-stacks replacement draft)
  =.  draft  draft(preconditions (capture-preconditions:effects ~zod ~ ops))
  =/  absent  (proposal-preview:effects ~zod fixed-now ~ ~ draft)
  ;:  weld
    (expect-eq !>(%ok) !>(status.admitted))
    (expect-eq !>(%stale-precondition) !>(reason.stale))
    (expect-eq !>(initial-stacks) !>(candidate.stale))
    (expect-eq !>(%missing-stack) !>(reason.absent))
    (expect-eq !>(*(map @tas stack)) !>(candidate.absent))
    (expect-eq !>(~) !>(diffs.absent))
  ==
::
++  test-receipt-replay-and-conflicting-digest
  ^-  tang
  =/  recorded  recorded-receipt
  =/  replay  (operation-receipt-at:effects receipt-control fixed-now 'edit-1' `0x1234)
  =/  conflict  (operation-receipt-at:effects receipt-control fixed-now 'edit-1' `0x9999)
  ;:  weld
    (expect-eq !>(recorded-receipt) !>(replay))
    (expect-eq !>(%conflict) !>(status.conflict))
    (expect-eq !>(%none) !>(effect.conflict))
    (expect-eq !>(digest.recorded) !>(digest.conflict))
    (expect-eq !>(submission.recorded) !>(submission.conflict))
    (expect-eq !>(~) !>(before.conflict))
    (expect-eq !>(~) !>(after.conflict))
  ==
::
++  test-receipt-missing-full-and-retired
  ^-  tang
  =/  control  receipt-control
  =/  missing  (operation-receipt-at:effects receipt-control fixed-now 'missing' `0x5555)
  =/  full  (operation-receipt-at:effects control(receipt-count 4.096) fixed-now 'missing' `0x5555)
  =/  next  (add fixed-now ~s1)
  =/  retired  control(epoch next)
  =/  expired  (operation-receipt-at:effects retired fixed-now 'edit-1' `0x1234)
  =/  unknown  (operation-receipt-at:effects receipt-control next 'missing' `0x5555)
  =/  ack  recorded-receipt
  =.  action.ack  %retire-operation-epoch
  =.  retired  retired(receipts (my ~[[[fixed-now 'edit-1'] ack]]))
  =/  acknowledged  (operation-receipt-at:effects retired fixed-now 'edit-1' `0x1234)
  ;:  weld
    (expect-eq !>(%outcome-unknown) !>(status.missing))
    (expect-eq !>(%unknown) !>(effect.missing))
    (expect-eq !>(%budget-exhausted) !>(status.full))
    (expect-eq !>(%none) !>(effect.full))
    (expect-eq !>(%replay-expired) !>(status.expired))
    (expect-eq !>(%replay-expired) !>(status.unknown))
    (expect-eq !>(ack) !>(acknowledged))
  ==
::
++  test-receipt-bounds-preserve-reconciliation-proof
  ^-  tang
  =/  fence=entity-precondition  [card-key `[2 1 1 %.y] %.y %.y]
  =/  fences
    %+  turn  (gulf 1 32)
    |=  index=@ud
    =/  id=@tas  (cat 3 'c' (scot %ud index))
    fence(key key.fence(id id))
  =/  id=@t  (rap 3 (reap 32 'é\22\5c'))
  =/  receipt  recorded-receipt
  =.  receipt  receipt(id id, before fences, after fences)
  =/  projection  (receipt-json:effects receipt 4.096)
  =/  before  (json-field projection 'before')
  =/  after  (json-field projection 'after')
  ?>  ?&(?=(%a -.before) ?=(%a -.after))
  ;:  weld
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html projection)) 4.096)))
    (expect-eq !>([%b %.n]) !>((json-field projection 'complete')))
    (expect-eq !>([%s 'ok']) !>((json-field projection 'status')))
    (expect-eq !>([%s id]) !>((json-field projection 'operation_id')))
    (expect-eq !>([%s (scot %da epoch.receipt)]) !>((json-field projection 'idempotency_epoch')))
    (expect-eq !>([%s (scot %ux digest.receipt)]) !>((json-field projection 'payload_digest')))
    (expect-eq !>([%s (scot %ux submission.receipt)]) !>((json-field projection 'submission')))
    (expect-eq !>(32) !>((add (lent p.before) (receipt-omission-count projection 'before'))))
    (expect-eq !>(32) !>((add (lent p.after) (receipt-omission-count projection 'after'))))
    (expect-eq !>([%b %.n]) !>((json-field projection 'retry_authorized')))
  ==
::
++  test-receipt-complete-and-invalid-budget
  ^-  tang
  =/  full  (receipt-json:effects recorded-receipt 32.768)
  =/  invalid  (receipt-json:effects recorded-receipt 1.024)
  ;:  weld
    (expect-eq !>([%b %.y]) !>((json-field full 'complete')))
    (expect-eq !>([%a ~]) !>((json-field full 'omissions')))
    (expect-eq !>([%s 'invalid']) !>((json-field invalid 'status')))
    (expect-eq !>([%b %.n]) !>((json-field invalid 'complete')))
    (expect-eq !>([%b %.n]) !>((json-field invalid 'retry_authorized')))
  ==
--
