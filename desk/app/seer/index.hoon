/-  *seer
/+  seer, ev=seer-evidence, effects=seer-effects, memory=seer-learning
::
::  seer's browser ui is deliberately server-rendered. htmx is the only
::  client-side runtime: links and forms ask the agent for fresh html and
::  replace #seer-app. everything still works as ordinary html without it.
::
|%
+$  page
  $%  [%review ~]
      [%inbox ~]
      [%stacks ~]
      [%subscriptions ~]
      [%stack owner=@p name=@tas]
      [%stack-browse owner=@p name=@tas desk=@t q=@t pick=@t remote=@t]
  ==
::
+$  picker-data
  [%files dek=@tas total=@ud files=(list path)]
::
++  clay-results
  |=  [our=@p ret=tape dek=@tas total=@ud hits=(list path)]
  ^-  manx
  =/  shown=(list path)  (scag 200 hits)
  ::  directories implied by the matching files: every proper prefix
  ::  of a hit (mark segment dropped). picking one attaches every
  ::  text file beneath it.
  ::
  =/  dirs=(list path)
    %+  scag  50
    %+  sort
      %~  tap  in
      %+  roll  hits
      |=  [pax=path acc=(set path)]
      =/  stem=path  (snip `path`pax)
      =/  k=@ud  1
      |-  ^-  (set path)
      ?:  (gte k (lent stem))  acc
      $(acc (~(put in acc) (scag k stem)), k +(k))
    aor
  =/  meta=tape
    ;:  weld
      "showing {<(lent shown)>} of {<(lent hits)>} matches"
      " · {<total>} files in {(trip dek)}"
    ==
  ;ul.clay-results
    ;li.clay-results-meta
      ; {meta}
    ==
    ;+  ?~  hits  ;span.hidden;
        =/  desk-loc=tape
          "/{(trip (scot %p our))}/{(trip dek)}"
        =/  desk-href=tape
          ?:  =("" ret)  "#"
          "{ret}?pick={desk-loc}"
        ;li
          ;a.clay-file.clay-dir
            =href          desk-href
            =data-locator  desk-loc
            =hx-boost      "false"
            ;+  ;/  "whole desk · {<total>} files as a listing"
          ==
        ==
    ;+  ?^  hits  ;span.hidden;
        ;li.clay-results-meta
          ; no files match
        ==
    ;*  %+  turn  dirs
        |=  dir=path
        ^-  manx
        =/  loc=tape
          "/{(trip (scot %p our))}/{(trip dek)}{(spud dir)}"
        =/  pick-href=tape
          ?:  =("" ret)  "#"
          "{ret}?pick={loc}"
        ;li
          ;a.clay-file.clay-dir
            =href          pick-href
            =data-locator  loc
            =hx-boost      "false"
            ;+  ;/  "{(spud dir)}/"
          ==
        ==
    ;*  %+  turn  shown
        |=  pax=path
        ^-  manx
        =/  loc=tape
          "/{(trip (scot %p our))}/{(trip dek)}{(spud pax)}"
        =/  pick-href=tape
          ?:  =("" ret)  "#"
          "{ret}?pick={loc}"
        ;li
          ;a.clay-file
            =href          pick-href
            =data-locator  loc
            =hx-boost      "false"
            ;+  ;/  (spud pax)
          ==
        ==
  ==
++  render
  |=  $:  our=@p
          stacks=(map @tas stack)
          subscriptions=(map [@p @tas] stack)
          captures=(map @tas capture)
          questions=(map @tas card-question)
          contexts=(map @tas context-source)
          evidence=evidence-state
          models=(map @tas assistant-model)
          changes=(map @tas change-request)
          logins=(map @tas login-request)
          reviews=(list review)
          =page
          notice=(unit @t)
          picker=(unit picker-data)
          shared=(map path shared-entry)
          remotes=(map @p remote-manifest)
          recents=(list @t)
          stale=(map @tas ?(%stale %gone))
          desks=(list @tas)
          control=agent-state
          learning=learning-state
      ==
  ^-  manx
  =/  stack-count=@ud  (lent ~(tap by stacks))
  =/  subscription-count=@ud  (lent ~(tap by subscriptions))
  =/  pending-count=@ud
    =/  tree=(map @tas capture)  captures
    |-
    ?~  tree  0
    ;:  add
      (lent ~(tap by proposals.q.n.tree))
      $(tree l.tree)
      $(tree r.tree)
    ==
  =/  open-change-count=@ud
    =/  rows=(list [@tas change-request])  ~(tap by changes)
    |-
    ?~  rows  0
    =/  open=?
      ?|  =(%pending status.+.i.rows)
          =(%working status.+.i.rows)
          =(%ready status.+.i.rows)
          =(%failed status.+.i.rows)
          =(%draft status.+.i.rows)
      ==
    (add ?:(open 1 0) $(rows t.rows))
  =/  inbox-count=@ud  (add pending-count open-change-count)
  =/  library-active=?
    ?|  ?=(%stacks -.page)
        ?=(%stack -.page)
    ==
  =/  review-active=?  ?=(%review -.page)
  =/  inbox-active=?  ?=(%inbox -.page)
  =/  shared-active=?  ?=(%subscriptions -.page)
  =<  (identify-posts document)
  |%
  ++  identify-posts
    |=  tree=manx
    ^-  manx
    =/  post=?
      ?&  =(%form n.g.tree)
          %+  lien  a.g.tree
          |=  attr=[n=mane v=tape]
          ?&  =(%method n.attr)
              ?|(=("post" v.attr) =("POST" v.attr))
          ==
      ==
    ?.  post
      tree(c (turn c.tree identify-posts))
    =/  operation=tape
      (scow %ux (shax (jam [epoch.control receipt-count.control revision.control tree])))
    =/  identity=(list manx)
      :~
        ;input(type "hidden", name "operation-id", value operation);
        ;input(type "hidden", name "idempotency-epoch", value (scow %da epoch.control));
      ==
    tree(c (weld (turn c.tree identify-posts) identity))
  ::
  ++  json-tree
    |=  value=json
    ^-  manx
    ?~  value  ;span.muted: not available
    ?-  -.value
      %s  ;div.proposal-answer: {(trip p.value)}
      %n  ;span: {(trip p.value)}
      %b  ;span: {?:(p.value "yes" "no")}
      %a
        ;ol
          ;*  %+  turn  p.value
              |=  entry=json
              ;li
                ;+  (json-tree entry)
              ==
        ==
      %o
        ;dl
          ;*  %+  turn  ~(tap by p.value)
              |=  [key=@t entry=json]
              ;div
                ;dt
                  ;strong: {(trip key)}
                ==
                ;dd
                  ;+  (json-tree entry)
                ==
              ==
        ==
    ==
  ::
  ++  projection-complete
    |=  value=json
    ^-  ?
    ?~  value  %.n
    ?.  ?=(%o -.value)  %.n
    =/  complete  (~(get by p.value) 'complete')
    ?~  complete  %.n
    =(u.complete [%b %.y])
  ::
  ++  effect-panel
    |=  [preview=plan-preview projection=json]
    ^-  manx
    ;div.provenance
      ;p
        ;strong: Source-validated effects · {(trip status.preview)}
      ==
      ;p: {(trip reason.preview)} · {<(lent affected.preview)>} affected entities
      ;+  ?:  =(%ok status.preview)  ;span.hidden;
          ;p.proposal-conflict: No effect is authorized. Reject this plan and review a newly generated diff; Seer will not rebase a stale approval.
      ;+  ?:  (projection-complete projection)  ;span.hidden;
          ;p.proposal-conflict: This bounded preview omits effects. Approval is unavailable; split the plan into a smaller reviewable change.
      ;p.muted: Approval is owner-only and binds this digest. Surviving cards keep learning state; no automatic recall grades are recorded.
      ;p.muted: Changed card content follows the stack's existing sharing rules. Attached source material is not published to subscribers.
      ;details.reveal
        ;summary: Inspect exact before/after, review effects, and revision-bound digest
        ;+  (json-tree projection)
      ==
    ==
  ::
  ++  packet-panel
    |=  [ref=(unit @ux) citations=(list evidence-citation)]
    ^-  manx
    ?~  ref
      ;p.muted: No frozen evidence packet. Generated text is not source evidence.
    =/  packet  (~(get by packets.evidence) u.ref)
    ?~  packet
      ;p.proposal-conflict: The recorded packet is unavailable. Do not infer support from generated text.
    =/  frozen  u.packet
    =/  projection  (packet-projection:ev frozen contexts evidence 262.144)
    =/  blocked  (packet-egress-error:ev frozen contexts evidence)
    =/  quote-error  (validate-citations:ev frozen citations evidence)
    ;details.reveal
      =data-persist  "packet|{(scow %ux u.ref)}"
      ;summary: Inspect outgoing packet · {(trip provider.profile.request.frozen)} · {<prompt-bytes.frozen>} bytes
      ;div.provenance
        ;p: Exact provider/model: {(trip provider.profile.request.frozen)} / {(trip model.profile.request.frozen)}
        ;p.muted: Only canonical_prompt below is provider-bound. It includes the frozen request and explicitly selected excerpts, not today's live source bodies.
        ;p.muted: Source material leaves this ship only for the authorized provider. It is not shared with stack subscribers. Generated card content may be shared under existing stack permissions.
        ;+  ?~  blocked  ;span.hidden;
            ;p.proposal-conflict: Dispatch blocked · {(trip u.blocked)}. Restore source authorization if appropriate, then prepare a new packet; do not silently replace this one.
        ;+  ?:  (projection-complete projection)  ;span.hidden;
            ;p.muted: Coverage is incomplete. Inspect exclusions and bounded omissions below; absent evidence must not be treated as included.
        ;p.muted: Included ranges are UTF-8 byte offsets. Excluded, partial, listing-only, budget-omitted, and purged material is qualified in the source projection; a listing is not file contents.
        ;+  (json-tree projection)
        ;h4: Citation support
        ;+  ?~  citations
              ;p.muted: No citations. This is an unsupported generated claim, not verified source evidence.
            ?^  quote-error
              ;p.proposal-conflict: Citation support unavailable · {(trip u.quote-error)}
            ;p.muted: Exact quoted bytes match the frozen selected evidence. This does not establish truth or that the evidence supports every generated claim.
        ;+  (json-tree (citations-json:seer citations))
      ==
    ==
  ::
  ++  learning-panel
    |=  [scope=context-scope objective=@t provider=ai-provider]
    ^-  manx
    =/  projection
      %:  lookup-artifacts:memory
        scope  objective  provider  16  32.768
        contexts  evidence  versions.control  learning
      ==
    ;details.reveal
      ;summary: Prior learning · {(trip provider)} · inspect source qualification
      ;p.muted: Generated memory is not primary evidence. Approval, rejection, and your recall grades describe decisions and learning, not factual truth.
      ;p.muted: Reuse must match the exact packet and model. Unavailable or omitted bodies are not permission to reconstruct them from memory.
      ;+  (json-tree projection)
    ==
  ::
  ++  scope-learning-panel
    |=  scope=context-scope
    ^-  manx
    ;details.reveal
      ;summary: Review existing learning before a new request
      ;+  (learning-panel scope '' %codex)
      ;+  (learning-panel scope '' %claude)
      ;+  ?.  ?=(%stack -.scope)  ;span.hidden;
          ?~  card.scope  ;span.hidden;
          (observation-panel [%card owner.scope stack.scope u.card.scope])
    ==
  ::
  ++  observation-panel
    |=  key=entity-key
    ^-  manx
    =/  observations
      (fall (~(get by observations.learning) key) *(list learner-observation))
    ;details.reveal
      ;summary: Recorded recall observations · {<(lent observations)>}
      ;p.muted: Only your actual grading actions are recorded. A grade measures recall of that card revision, not whether a generated claim is true.
      ;p.muted: Showing up to 20 observations; no grades are inferred from approval, generated text, or provider usage.
      ;*  %+  turn  (scag 20 observations)
          |=  observation=learner-observation
          ;div.provenance
            ;p: {(trip grade.observation)} · {(scow %p actor.observation)} · {(scow %da at.observation)}
            ;+  (json-tree (version-json:ev version.subject.observation))
          ==
    ==
  ::
  ++  work-panel
    |=  [key=entity-key return=@t]
    ^-  manx
    =/  record  (~(get by jobs.control) key)
    ?~  record  ;span.hidden;
    =/  work  u.record
    ;div.provenance
      ;p
        ;strong: Execution · {(trip execution.work)} / effect · {(trip effect.work)}
      ==
      ;p: Attempt {<attempt.work>} · checkpoint {(trip checkpoint.work)}
      ;+  ?~  stop-reason.work  ;span.hidden;
          ;p.proposal-conflict: Stop reason · {(trip u.stop-reason.work)}
      ;+  ?.  =(%unknown effect.work)  ;span.hidden;
          ;p.proposal-conflict: External outcome unknown. Cancellation cannot undo provider work or charges. Reconcile this receipt with the paired worker before authorizing a potentially billable new attempt.
      ;details.reveal
        ;summary: Inspect deadline, lease, budget, and recovery
        ;p: Worker · {(trip worker.work)}
        ;p: Lease until · {?~(lease-until.work "not leased" (scow %da u.lease-until.work))}
        ;p: Hard deadline · {?~(deadline.work "not started" (scow %da u.deadline.work))}
        ;p: Invocations · {<invocations.work>} / {<max-invocations.work>}
        ;p: Input bytes · {<input-bytes.work>} / {<max-input-bytes.work>}
        ;p: Output bytes · {<consumed-output-bytes.work>} / {<max-output-bytes.work>}
        ;p: Operation budget · {<max-operations.work>}
        ;p: Provider usage · {?~(usage.work "unknown" (scow %ud u.usage.work))}
        ;p: Cost · {?~(cost.work "unknown" (scow %ud u.cost.work))}
        ;p: Model · {(trip model-id.work)} · definition revision {<model-revision.work>}
        ;p: Packet digest · {?~(packet-digest.work "not frozen" (scow %ux u.packet-digest.work))}
        ;p: Policy {<policy-version.work>} · prompt {<prompt-version.work>} · schema {<schema-version.work>}
        ;p: Retryable · {?:(retryable.work "yes, by explicit new attempt" "no")}
        ;p.muted: The source clock controls expiry. Only the paired worker can recover an expired lease; before provider start it may requeue, afterward it must preserve an unknown external outcome. There is no automatic provider retry.
      ==
      ;+  ?.  ?|  =(%queued execution.work)
                  =(%running execution.work)
                  =(%blocked execution.work)
              ==
            ;span.hidden;
          ;form.inline
            =method   "post"
            =action   "/apps/seer/actions/cancel-work"
            =hx-post  "/apps/seer/actions/cancel-work"
            ;input(type "hidden", name "work-kind", value (trip kind.key));
            ;input(type "hidden", name "work-owner", value (scow %p owner.key));
            ;input(type "hidden", name "work-scope", value (trip scope.key));
            ;input(type "hidden", name "work-id", value (trip id.key));
            ;input(type "hidden", name "return", value (trip return));
            ;button.danger(type "submit"): Cancel future work · does not undo charges
          ==
    ==
  ::
  ++  receipt-panel
    ^-  manx
    =/  rows
      %+  sort  ~(val by receipts.control)
      |=  [a=operation-receipt b=operation-receipt]
      ?:  =(at.a at.b)  (gth revision.a revision.b)
      (gth at.a at.b)
    ;details.reveal
      =data-persist  "operation-receipts"
      ;summary: Operation receipts · {<receipt-count.control>} retained
      ;p.muted: These are source receipts, not request acknowledgements. A missing receipt or lost connection does not prove failure or permission to retry. Refresh to reconcile before starting a new operation.
      ;p: Current replay epoch · {(scow %da epoch.control)}
      ;a.button.secondary(href "/apps/seer/inbox"): Refresh and reconcile
      ;form
        =method    "get"
        =action    "/apps/seer/operation-result"
        =hx-boost  "false"
        ;label
          ;span: operation ID to reconcile
          ;input(name "operation-id", required "", maxlength "128");
        ==
        ;label
          ;span: idempotency epoch
          ;input(name "idempotency-epoch", required "", value (scow %da epoch.control));
        ==
        ;label
          ;span: expected payload digest · optional
          ;input(name "digest");
        ==
        ;button.secondary(type "submit"): Inspect authoritative receipt
      ==
      ;p.muted: Showing the latest {<(min 20 (lent rows))>} receipts.
      ;*  %+  turn  (scag 20 rows)
          |=  receipt=operation-receipt
          (receipt-row receipt)
    ==
  ::
  ++  receipt-row
    |=  receipt=operation-receipt
    ^-  manx
    ;details.reveal
      ;summary: {(trip action.receipt)} · {(trip status.receipt)} · effect {(trip effect.receipt)}
      ;p: Reason · {(trip reason.receipt)}
      ;p: Authority · {(trip authority.receipt)} · revision {<revision.receipt>}
      ;p: Operation ID · {(trip id.receipt)}
      ;p: Epoch · {(scow %da epoch.receipt)}
      ;p: Payload digest · {(scow %ux digest.receipt)}
      ;p: Plan digest · {?~(plan.receipt "none" (scow %ux u.plan.receipt))}
      ;p: Attempt · {?~(attempt.receipt "not applicable" (scow %ud u.attempt.receipt))}
      ;p: Observed · {(scow %da at.receipt)}
      ;+  ?~  work.receipt  ;span.hidden;
          (json-tree (key-json:ev u.work.receipt))
      ;+  ?.  =(%conflict status.receipt)  ;span.hidden;
          ;p.proposal-conflict: This operation made no changes. Review the current diff; a stale approval cannot be rebased or reused.
      ;+  ?.  =(%unknown effect.receipt)  ;span.hidden;
          ;p.proposal-conflict: External outcome is unknown. Inspect the work checkpoint and reconcile with the worker; a new attempt may repeat billable work.
      ;details.reveal
        ;summary: Inspect observed before/after revisions
        ;h4: Before
        ;*  (turn before.receipt precondition-row)
        ;h4: After
        ;*  (turn after.receipt precondition-row)
      ==
    ==
  ::
  ++  precondition-row
    |=  fence=entity-precondition
    ^-  manx
    ;div.provenance
      ;+  (json-tree (key-json:ev key.fence))
      ;p: Content fence · {?:(content.fence "yes" "no")} / review fence · {?:(review.fence "yes" "no")}
      ;+  ?~  seen.fence  ;p: Not observed as present
          (json-tree (version-json:ev u.seen.fence))
    ==
  ::
  ++  work-context-panel
    |=  scope=context-scope
    ^-  manx
    ?>  ?=(?(%capture %change) -.scope)
    =/  rows
      %+  skim  ~(tap by contexts)
      |=  [id=@tas source=context-source]
      ?&(active.source =(scope scope.source))
    ;details.context-panel
      =data-persist  "work-context|{(trip -.scope)}|{(trip id.scope)}"
      ;summary.context-summary
        ;span.context-title: Work-scoped sources · {<(lent rows)>}
      ==
      ;div.context-body
        ;p.muted: Only this {(trip -.scope)} can select these sources. Attach, inspect, and authorize provider egress before freezing a packet. Changes here never rewrite an existing packet.
        ;a.button.secondary(href "/apps/seer/inbox"): Refresh source acquisition status
        ;*  %+  turn  rows
            |=  [id=@tas source=context-source]
            (context-source-row id source *(set @t))
        ;form.context-form
          =method   "post"
          =action   "/apps/seer/actions/add-context-source"
          =hx-post  "/apps/seer/actions/add-context-source"
          ;input(type "hidden", name "scope-kind", value (trip -.scope));
          ;input(type "hidden", name "scope-id", value (trip id.scope));
          ;input(type "hidden", name "return", value "inbox");
          ;label
            ;span: source type
            ;select(name "kind")
              ;option(value "note"): Pasted note or local text
              ;option(value "clay"): Ship file
              ;option(value "web"): Public web page
            ==
          ==
          ;label
            ;span: name · optional
            ;input(name "label", maxlength "240");
          ==
          ;label
            ;span: text · for a note
            ;textarea(name "content", maxlength "131072");
          ==
          ;label
            ;span: ship file path · for a ship file
            ;input(name "locator", maxlength "2048");
          ==
          ;label
            ;span: public URL · for a web page
            ;input(name "web-locator", type "url", maxlength "2048");
          ==
          ;p.muted: Native form: paste local text as a note. Web acquisition uses the paired bridge; provider egress is a separate authorization below each source.
          ;button(type "submit"): Attach source
        ==
      ==
    ==
  ::
  ++  capture-packet-form
    |=  capture-id=@tas
    ^-  manx
    =/  available  ordered-assistant-models
    ?~  available  ;p.muted: Connect an available model before freezing a capture packet.
    =/  rows
      %+  skim  ~(tap by contexts)
      |=  [id=@tas source=context-source]
      ?&(active.source =(scope.source [%capture capture-id]))
    ;details.reveal
      ;summary: Select evidence and freeze capture packet
      ;form
        =method   "post"
        =action   "/apps/seer/actions/prepare-capture"
        =hx-post  "/apps/seer/actions/prepare-capture"
        ;input(type "hidden", name "capture", value (trip capture-id));
        ;label
          ;span: exact provider/model
          ;select(name "model", required "")
            ;*  %+  turn  available
                |=  [id=@tas profile=assistant-model]
                ;option(value (trip id)): {(model-option-label profile)}
          ==
        ==
        ;+  (context-picker rows)
        ;+  packet-budget-fields
        ;p.muted: Freezing records the outgoing evidence, not a generated answer. Inspect the immutable packet before asking an MCP client to stage proposals from it.
        ;button(type "submit"): Freeze selected packet
      ==
    ==
  ::
  ++  packet-budget-fields
    ^-  manx
    ;div.context-type-row
      ;label
        ;span: maximum prompt bytes
        ;input(type "number", name "max-bytes", min "1024", max "131072", value "32768", required "");
      ==
      ;label
        ;span: maximum bytes per excerpt
        ;input(type "number", name "excerpt-bytes", min "1", max "131072", value "8192", required "");
      ==
    ==
  ::
  ++  context-return-fields
    |=  scope=context-scope
    ^-  (list manx)
    ?:  ?=(%stack -.scope)
      :~
        ;input(type "hidden", name "owner", value (scow %p owner.scope));
        ;input(type "hidden", name "stack", value (trip stack.scope));
      ==
    :~
      ;input(type "hidden", name "scope-kind", value (trip -.scope));
      ;input(type "hidden", name "scope-id", value (trip id.scope));
      ;input(type "hidden", name "return", value "inbox");
    ==
  ::
  ++  context-policy
    |=  source=context-source
    ^-  manx
    ;details.reveal
      ;summary: Inspect source snapshot and provider permissions
      ;p.muted: This is retrieved source evidence, not an assistant summary. Retrieval does not assert that the live origin is unchanged or factually correct.
      ;+  ?~  snapshot.source
            ;p.muted: No immutable snapshot is available yet.
          =/  snap  (~(get by snapshots.evidence) u.snapshot.source)
          ?~  snap  ;p.proposal-conflict: Snapshot unavailable.
          (json-tree (snapshot-projection:ev u.snapshot.source 0 bytes.u.snap 32.768 evidence))
      ;p: Provider policy revision · {<policy-revision.source>}
      ;form
        =method   "post"
        =action   "/apps/seer/actions/set-context-egress"
        =hx-post  "/apps/seer/actions/set-context-egress"
        ;input(type "hidden", name "context-id", value (trip id.source));
        ;*  (context-return-fields scope.source)
        ;fieldset.context-picker
          ;legend: Allow this source to leave the ship for
          ;*  %+  turn  ^-((list ai-provider) ~[%codex %claude])
              |=  provider=ai-provider
              =/  attrs=mart
                :~  [%type "checkbox"]
                    [%name (trip provider)]
                    [%value "1"]
                ==
              =?  attrs  (~(has in egress.source) provider)
                [[%checked ""] attrs]
              ;label.context-choice
                ;+  [[%input attrs] ~]
                ;span: {(trip provider)}
              ==
        ==
        ;p.muted: Neither checked means no provider egress. Changing this policy fences previously frozen packets; it cannot recall bytes already sent externally.
        ;button.secondary(type "submit"): Save provider permissions
      ==
      ;form
        =method   "post"
        =action   "/apps/seer/actions/rename-context-source"
        =hx-post  "/apps/seer/actions/rename-context-source"
        ;input(type "hidden", name "context-id", value (trip id.source));
        ;*  (context-return-fields scope.source)
        ;label
          ;span: source label
          ;input(name "label", value (trip label.source), maxlength "240", required "");
        ==
        ;button.secondary(type "submit"): Rename source link
      ==
      ;p.muted: Removing this link excludes future selection but retains historical evidence. Use Inbox privacy maintenance for explicit irreversible purge.
    ==
  ::
  ++  scope-exists
    |=  scope=context-scope
    ^-  ?
    ?-  -.scope
      %capture  (~(has by captures) id.scope)
      %change   (~(has by changes) id.scope)
      %stack
        =/  stack  (lookup-stack owner.scope stack.scope)
        ?~  stack  %.n
        ?~  card.scope  %.y
        (~(has by items.u.stack) u.card.scope)
    ==
  ::
  ++  maintenance-panel
    ^-  manx
    =/  orphans
      %+  skim  ~(tap by contexts)
      |=  [id=@tas source=context-source]
      ?&(active.source !(scope-exists scope.source))
    ;details.reveal
      =data-persist  "source-maintenance"
      ;summary: Source privacy and orphan maintenance · {<(lent orphans)>} orphan links
      ;p.muted: Unlinking or archiving excludes a source from future selection but retains historical evidence. Purging irreversibly removes retained bytes and invalidates dependent generated support; approved-card dependencies can block it.
      ;*  %+  turn  (scag 20 orphans)
          |=  [id=@tas source=context-source]
          ;p: {(trip id)} · {(trip label.source)} · {(trip -.scope.source)} scope
      ;p.muted: Showing up to 20 orphan links. Archive scans all active sources whose owning card, stack, capture, or change no longer exists; no selection means the full deterministic sweep, not deletion.
      ;form.inline
        =method   "post"
        =action   "/apps/seer/actions/archive-orphan-contexts"
        =hx-post  "/apps/seer/actions/archive-orphan-contexts"
        ;button.secondary(type "submit"): Archive all orphan links
      ==
      ;form.inline
        =method   "post"
        =action   "/apps/seer/actions/collect-retained"
        =hx-post  "/apps/seer/actions/collect-retained"
        ;button.secondary(type "submit"): Collect unreferenced retained evidence
      ==
      ;details.reveal
        ;summary: Purge a retained snapshot
        ;form
          =method   "post"
          =action   "/apps/seer/actions/purge-evidence"
          =hx-post  "/apps/seer/actions/purge-evidence"
          ;label
            ;span: exact snapshot reference · from the packet
            ;input(name "snapshot-ref", required "", placeholder "0x…");
          ==
          ;label.context-choice
            ;input(type "checkbox", required "");
            ;span: I understand this permanently removes evidence bytes, not just the source link.
          ==
          ;button.danger(type "submit"): Purge snapshot bytes
        ==
      ==
      ;details.reveal
        ;summary: Retire the current operation replay epoch
        ;p.muted: Do this only after reconciling outstanding requests. Old operation identities will return replay-expired and never execute; old forms must be refreshed.
        ;form
          =method   "post"
          =action   "/apps/seer/actions/retire-operation-epoch"
          =hx-post  "/apps/seer/actions/retire-operation-epoch"
          ;label.context-choice
            ;input(type "checkbox", required "");
            ;span: Outstanding operations have been reconciled.
          ==
          ;button.danger(type "submit"): Retire replay epoch
        ==
      ==
    ==
  ::
  ++  document
    ^-  manx
    =/  viewport=tape
      "width=device-width, initial-scale=1, viewport-fit=cover"
    =/  light-scheme=tape  "(prefers-color-scheme: light)"
    =/  dark-scheme=tape   "(prefers-color-scheme: dark)"
    =/  status-attrs=mart
      :~  [%id "request-status"]
          [%class "request-status"]
          [%role "status"]
          [%aria-label "Loading"]
      ==
    :-  [%html ~]
    :~
      ;head
        ;meta(charset "utf-8");
        ;meta(name "viewport", content viewport);
        ;meta(name "theme-color", content "#f7f7f6", media light-scheme);
        ;meta(name "theme-color", content "#111110", media dark-scheme);
        ;link(rel "icon", type "image/png", href "/apps/seer/tile.png");
        ;title: Seer
        ;script(src "/apps/seer/htmx-min.js");
        ;script:'''
                (function () {
                  "use strict";
                  var done = 0;
                  var open = {};
                  var prefix = "";
                  var prefixTimer = null;
                  var lastTargetKey = "";
                  var mq =
                    window.matchMedia("(prefers-reduced-motion: reduce)");
                  var TARGETS = [
                    ".item-summary",
                    ".stack-link",
                    "details > summary",
                    "[data-review-card]",
                    ".form-panel form",
                    ".compose-body form",
                    ".ai-form",
                    ".command-form"
                  ].join(",");
                  function move() { return mq.matches ? "auto" : "smooth"; }
                  function q(s) { return document.querySelector(s); }
                  function qa(s) {
                    return Array.prototype.slice.call(
                      document.querySelectorAll(s)
                    );
                  }
                  function root() { return q("[data-review]"); }
                  function flip() { return q("[data-review] details.flip"); }
                  function typing(t) {
                    var tag = t && t.tagName ? t.tagName : "";
                    return tag === "INPUT" || tag === "TEXTAREA"
                      || tag === "SELECT" || (t && t.isContentEditable);
                  }
                  function actionable(t) {
                    return t && t.closest
                      ? t.closest("button, a, summary")
                      : null;
                  }
                  function visible(el) {
                    if (!el || el.hidden || el.closest("[hidden]")) {
                      return false;
                    }
                    var r = el.getBoundingClientRect();
                    return r.width > 0 && r.height > 0;
                  }
                  function targets() {
                    var seen = new Set();
                    return qa(TARGETS).filter(function (el) {
                      if (!visible(el) || seen.has(el)) { return false; }
                      seen.add(el);
                      return true;
                    });
                  }
                  function activeTarget() {
                    var ae = document.activeElement;
                    if (ae && ae.closest) {
                      var found = ae.closest(TARGETS);
                      if (found) { return found; }
                    }
                    return q("[data-vim-active]");
                  }
                  function targetKey(el) {
                    if (!el) { return ""; }
                    var persistent = el.closest("[data-persist]");
                    if (persistent) {
                      return "persist:"
                        + persistent.getAttribute("data-persist");
                    }
                    var link = el.closest("a[href]");
                    return link ? "href:" + link.getAttribute("href") : "";
                  }
                  function findTarget(key) {
                    if (!key) { return null; }
                    var all = targets();
                    for (var i = 0; i < all.length; i++) {
                      if (targetKey(all[i]) === key) { return all[i]; }
                    }
                    return null;
                  }
                  function clearTarget() {
                    qa("[data-vim-active]").forEach(function (old) {
                      old.removeAttribute("data-vim-active");
                    });
                    qa("[data-vim-selected]").forEach(function (old) {
                      old.removeAttribute("data-vim-selected");
                    });
                  }
                  function focusTarget(el) {
                    if (!el) { return; }
                    clearTarget();
                    el.setAttribute("data-vim-active", "");
                    var card = el.matches(".item-summary")
                      ? el.closest(".item")
                      : null;
                    if (card) { card.setAttribute("data-vim-selected", ""); }
                    if (!el.hasAttribute("tabindex")
                      && !el.matches(
                        "a, button, input, textarea, select, summary")) {
                      el.tabIndex = -1;
                    }
                    el.focus({ preventScroll: true });
                    el.scrollIntoView({ block: "nearest", behavior: move() });
                    lastTargetKey = targetKey(el);
                  }
                  function moveTarget(step) {
                    var cards = qa(".item-list .item-summary").filter(visible);
                    if (cards.length) {
                      var cardIndex = cards.indexOf(activeTarget());
                      cardIndex = cardIndex < 0
                        ? (step > 0 ? 0 : cards.length - 1)
                        : (cardIndex + step + cards.length) % cards.length;
                      focusTarget(cards[cardIndex]);
                      return;
                    }
                    var all = targets();
                    if (!all.length) {
                      window.scrollBy({ top: step * 140, behavior: move() });
                      return;
                    }
                    var current = activeTarget();
                    var index = all.indexOf(current);
                    if (index < 0) {
                      var anchor = window.innerHeight * .34;
                      index = all.reduce(function (best, el, i) {
                        return Math.abs(
                          el.getBoundingClientRect().top - anchor
                        ) < Math.abs(
                          all[best].getBoundingClientRect().top - anchor
                        ) ? i : best;
                      }, 0);
                    } else {
                      index =
                        Math.max(0, Math.min(all.length - 1, index + step));
                    }
                    focusTarget(all[index]);
                  }
                  function focusedDetails() {
                    var target = activeTarget();
                    if (!target) { return null; }
                    if (target.matches("summary")) {
                      return target.parentElement;
                    }
                    return target.closest("details");
                  }
                  function setFold(mode) {
                    var d = focusedDetails();
                    if (!d) { return false; }
                    var next = mode === "toggle" ? !d.open : mode === "open";
                    if (d.open === next) { return false; }
                    d.open = next;
                    var summary = d.querySelector(":scope > summary");
                    if (summary) { focusTarget(summary); }
                    return true;
                  }
                  function setAllFolds(opened) {
                    qa("main details").filter(visible).forEach(function (d) {
                      d.open = opened;
                    });
                  }
                  function focusForm() {
                    var target = activeTarget();
                    if (!target) { return false; }
                    var form = target.matches("form")
                      ? target
                      : target.closest("form");
                    if (!form) { return false; }
                    var field = form.querySelector(
                      "textarea, input:not([type=hidden]), select, button"
                    );
                    if (field) { field.focus(); return true; }
                    return false;
                  }
                  function openAssistant() {
                    var assistant = q("[data-review] details.assistant");
                    if (assistant) { assistant.open = true; }
                    var scope = assistant || q(".item[open]")
                      || (activeTarget() && activeTarget().closest(".item"));
                    if (scope && scope.matches && scope.matches(".item")) {
                      scope.open = true;
                    }
                    var field = scope && scope.querySelector
                      ? scope.querySelector(".ai-form textarea")
                      : null;
                    if (field) { field.focus(); return true; }
                    if (assistant) {
                      var summary = assistant.querySelector(":scope > summary");
                      if (summary) { focusTarget(summary); }
                      return true;
                    }
                    return false;
                  }
                  function grade(n) {
                    var f = flip();
                    if (!f || !f.open) { return; }
                    var b = document.querySelectorAll(
                      "[data-review] .grade-row button"
                    );
                    if (b[n] && !b[n].disabled) { b[n].click(); }
                  }
                  function help(opened) {
                    var d = q("[data-key-help]");
                    if (!d) { return; }
                    if (opened === false) { d.close(); }
                    else if (!d.open) { d.showModal(); }
                  }
                  function go(path) {
                    var links = qa("a[href]");
                    var link = links.find(function (a) {
                      return a.getAttribute("href") === path;
                    });
                    if (link) { link.click(); }
                    else { window.location.href = path; }
                  }
                  function chordText(kind) {
                    return kind === "g"
                      ? "g · r Review · i Inbox · l Library · s Shared · "
                        + "g Top · b Bottom · a Assistant · ? Help"
                      : "z · a Toggle · o Open · c Close · "
                        + "R Open all · M Close all";
                  }
                  function clearPrefix() {
                    prefix = "";
                    clearTimeout(prefixTimer);
                    prefixTimer = null;
                    var hud = q("[data-key-chord]");
                    if (hud) { hud.remove(); }
                  }
                  function startPrefix(next) {
                    clearPrefix();
                    prefix = next;
                    var hud = document.createElement("div");
                    hud.className = "vim-chord";
                    hud.setAttribute("data-key-chord", "");
                    hud.setAttribute("role", "status");
                    hud.textContent = chordText(next);
                    document.body.appendChild(hud);
                    prefixTimer = setTimeout(clearPrefix, 1_600);
                  }
                  function runPrefix(kind, key) {
                    if (kind === "g") {
                      if (key === "r") { go("/apps/seer/review"); return; }
                      if (key === "i") { go("/apps/seer/inbox"); return; }
                      if (key === "l") { go("/apps/seer/stacks"); return; }
                      if (key === "s") {
                        go("/apps/seer/subscriptions");
                        return;
                      }
                      if (key === "g") {
                        window.scrollTo({ top: 0, behavior: move() });
                        return;
                      }
                      if (key === "b") {
                        window.scrollTo({
                          top: document.body.scrollHeight,
                          behavior: move()
                        });
                        return;
                      }
                      if (key === "a") { openAssistant(); return; }
                      if (key === "?") { help(true); }
                      return;
                    }
                    if (key === "a") { setFold("toggle"); return; }
                    if (key === "o") { setFold("open"); return; }
                    if (key === "c") { setFold("close"); return; }
                    if (key === "R") { setAllFolds(true); return; }
                    if (key === "M") { setAllFolds(false); }
                  }
                  function fuzzyScore(n, h) {
                    n = n.toLowerCase(); h = h.toLowerCase();
                    var s = 0, prev = -2, hi = 0;
                    for (var i = 0; i < n.length; i++) {
                      var idx = h.indexOf(n[i], hi);
                      if (idx < 0) { return -1; }
                      s += 1;
                      if (idx === prev + 1) { s += 2; }
                      if (idx === 0 || h[idx - 1] === "/") { s += 3; }
                      prev = idx; hi = idx + 1;
                    }
                    return s;
                  }
                  function fuzzFilter(input) {
                    var box = input.closest(".clay-picker");
                    if (!box) { return; }
                    var list = box.querySelector(".clay-results");
                    if (!list) { return; }
                    var q = input.value.trim();
                    var rows = Array.prototype.slice
                      .call(list.querySelectorAll("li"))
                      .filter(function (li) {
                        return !li.classList.contains("clay-results-meta");
                      });
                    var scored = rows.map(function (li) {
                      var a = li.querySelector("a.clay-file");
                      var loc = a ? (a.getAttribute("data-locator") || "") : "";
                      return [q ? fuzzyScore(q, loc) : 0, loc.length, li];
                    });
                    scored.sort(function (x, y) {
                      return (y[0] - x[0]) || (x[1] - y[1]);
                    });
                    var shown = 0;
                    scored.forEach(function (p) {
                      var vis = p[0] >= 0 && shown < 100;
                      p[2].hidden = !vis;
                      if (vis) { shown += 1; list.appendChild(p[2]); }
                    });
                    var meta = list.querySelector(".clay-results-meta");
                    if (meta && q) {
                      meta.textContent =
                        shown + " of " + rows.length + " loaded files match";
                    }
                  }
                  function contextFormStatus(form, message, state) {
                    var status =
                      form.querySelector("[data-context-file-status]");
                    if (!status) { return; }
                    status.textContent = message || "";
                    if (state) { status.setAttribute("data-state", state); }
                    else { status.removeAttribute("data-state"); }
                  }
                  function syncContextForm(form) {
                    var select = form.querySelector("[data-context-type]");
                    if (!select) { return; }
                    var kind = select.value || "note";
                    form.querySelectorAll(
                      "[data-context-kind]"
                    ).forEach(function (section) {
                      var active =
                        section.getAttribute("data-context-kind") === kind;
                      section.hidden = !active;
                      section.querySelectorAll(
                        "input, textarea, select"
                      ).forEach(function (field) {
                        field.disabled = !active;
                      });
                    });
                    var button = form.querySelector("[data-context-submit]");
                    if (button) {
                      var labels = {
                        note: "Add note",
                        clay: "Attach ship file",
                        file: "Attach local file",
                        web: "Fetch web page"
                      };
                      button.textContent = labels[kind] || "Add context";
                      var content =
                        form.querySelector("[data-context-file-content]");
                      button.disabled =
                        kind === "file" && !(content && content.value);
                    }
                    var pickerHost = form.closest("details.context-add");
                    if (pickerHost) {
                      var pickerBlock =
                        pickerHost.querySelector("[data-clay-picker]");
                      if (pickerBlock) { pickerBlock.hidden = kind !== "clay"; }
                    }
                  }
                  function syncContextForms() {
                    qa("[data-context-form]").forEach(syncContextForm);
                  }
                  async function loadContextFile(input) {
                    var form = input.closest("[data-context-form]");
                    var file = input.files && input.files[0];
                    if (!form || !file) { return; }
                    var content =
                      form.querySelector("[data-context-file-content]");
                    var locator =
                      form.querySelector("[data-context-file-locator]");
                    var label = form.querySelector("input[name=label]");
                    if (content) { content.value = ""; }
                    syncContextForm(form);
                    if (file.size > 131072) {
                      contextFormStatus(
                        form,
                        "Choose a text file smaller than 128 KB.",
                        "error"
                      );
                      return;
                    }
                    contextFormStatus(
                      form, "Reading " + file.name + "…", "working"
                    );
                    try {
                      var text = await file.text();
                      if (new TextEncoder().encode(text).length > 131072) {
                        throw new Error(
                          "Choose a text file smaller than 128 KB."
                        );
                      }
                      if (text.indexOf("\u0000") >= 0) {
                        throw new Error("That file is not plain text.");
                      }
                      if (!text.trim()) {
                        throw new Error("That file is empty.");
                      }
                      if (content) { content.value = text; }
                      if (locator) { locator.value = file.name; }
                      if (label && !label.value.trim()) {
                        label.value = file.name;
                      }
                      contextFormStatus(
                        form,
                        file.name + " · "
                          + Math.max(1, Math.ceil(file.size / 1024))
                          + " KB ready",
                        "ready"
                      );
                      syncContextForm(form);
                    } catch (error) {
                      if (content) { content.value = ""; }
                      contextFormStatus(
                        form,
                        error.message || "That file could not be read.",
                        "error"
                      );
                      syncContextForm(form);
                    }
                  }
                  function sync() {
                    document.documentElement.classList.add("kb");
                    syncContextForms();
                    var r = root();
                    if (r) {
                      var left =
                        parseInt(r.getAttribute("data-remaining") || "0", 10);
                      var total = done + left;
                      var bar = q("[data-progress]");
                      var fill = q("[data-progress-fill]");
                      if (bar && fill && total > 0) {
                        bar.hidden = false;
                        fill.style.width =
                          String(Math.round(100 * done / total)) + "%";
                      }
                      var tally = q("[data-done]");
                      if (tally && done > 0) {
                        tally.hidden = false;
                        tally.textContent = String(done) + " down · ";
                      }
                      var fresh = q("[data-fresh]");
                      var full = q("[data-complete]");
                      if (fresh && full && left === 0 && done > 0) {
                        fresh.hidden = true;
                        full.hidden = false;
                        var line = q("[data-complete-line]");
                        if (line) {
                          var noun = done === 1 ? " card" : " cards";
                          line.textContent = String(done) + noun
                            + " reviewed. Missed cards return here in moments.";
                        }
                      }
                    } else {
                      done = 0;
                    }
                    qa("details[data-persist]").forEach(function (d) {
                      var key = d.getAttribute("data-persist");
                      if (open[key] !== undefined) { d.open = open[key]; }
                    });
                  }
                  document.addEventListener("toggle", function (e) {
                    var t = e.target;
                    if (t && t.matches && t.matches("details[data-persist]")) {
                      open[t.getAttribute("data-persist")] = t.open;
                    }
                  }, true);
                  document.addEventListener("click", function (e) {
                    var summary = e.target && e.target.closest
                      ? e.target.closest(".item-summary")
                      : null;
                    if (summary) { focusTarget(summary); }
                    var b = e.target && e.target.closest
                      ? e.target.closest("[data-help-open]")
                      : null;
                    if (b) { help(true); }
                    var pick = e.target && e.target.closest
                      ? e.target.closest("a.clay-file")
                      : null;
                    if (pick) {
                      var pickScope =
                        pick.closest("details.context-add") || document;
                      var pickForm =
                        pickScope.querySelector("[data-context-form]");
                      if (pickForm) {
                        e.preventDefault();
                        var locator = pickForm.querySelector(
                          '[data-context-kind="clay"] input[name="locator"]'
                        );
                        if (locator) {
                          locator.value =
                            pick.getAttribute("data-locator") || "";
                        }
                        var kindSelect =
                          pickForm.querySelector("[data-context-type]");
                        if (kindSelect) { kindSelect.value = "clay"; }
                        syncContextForm(pickForm);
                      }
                    }
                  });
                  document.addEventListener("input", function (e) {
                    if (e.target && e.target.matches
                      && e.target.matches('.clay-search input[name="q"]')) {
                      fuzzFilter(e.target);
                    }
                  });
                  function maybeAutoLoad(scope) {
                    if (!scope) { return; }
                    var picker = scope.querySelector("[data-clay-picker]");
                    if (!picker || picker.hidden) { return; }
                    var form = picker.querySelector("form.clay-search");
                    var desk =
                      form && form.querySelector('select[name="desk"]');
                    var box = picker.querySelector("#clay-results-box")
                      || picker.querySelector("[id^=clay-results]");
                    if (!form || !desk || !desk.value) { return; }
                    if (box && box.querySelector("a.clay-file")) { return; }
                    if (form.dataset.loading) { return; }
                    form.dataset.loading = "1";
                    form.requestSubmit();
                  }
                  document.addEventListener("toggle", function (e) {
                    if (e.target && e.target.matches
                      && e.target.matches("details.context-add")
                      && e.target.open) {
                      maybeAutoLoad(e.target);
                    }
                  }, true);
                  document.addEventListener("htmx:afterSwap", function (e) {
                    if (e.target && e.target.id === "clay-results-box") {
                      var picker = e.target.closest(".clay-picker");
                      var form =
                        picker && picker.querySelector("form.clay-search");
                      if (form) { delete form.dataset.loading; }
                      var q = picker
                        && picker.querySelector('.clay-search input[name="q"]');
                      if (q && q.value.trim()) { fuzzFilter(q); }
                    }
                  });
                  document.addEventListener("change", function (e) {
                    if (e.target && e.target.matches
                      && e.target.matches("[data-context-type]")) {
                      var host = e.target.closest("[data-context-form]");
                      syncContextForm(host);
                      if (e.target.value === "clay") {
                        maybeAutoLoad(e.target.closest("details.context-add"));
                      }
                    }
                    if (e.target && e.target.matches
                      && e.target.matches("[data-context-file]")) {
                      loadContextFile(e.target);
                    }
                  });
                  document.addEventListener("htmx:beforeRequest", function (e) {
                    var el = e.detail ? e.detail.elt : null;
                    lastTargetKey = targetKey(activeTarget()) || lastTargetKey;
                    if (el && el.hasAttribute
                      && el.hasAttribute("data-grade")) {
                      done += 1;
                    }
                  });
                  document.addEventListener("htmx:responseError", function (e) {
                    var el = e.detail ? e.detail.elt : null;
                    if (el && el.hasAttribute
                      && el.hasAttribute("data-grade") && done > 0) {
                      done -= 1;
                    }
                  });
                  document.addEventListener("htmx:afterSwap", function () {
                    sync();
                    requestAnimationFrame(function () {
                      var restored = findTarget(lastTargetKey);
                      if (restored) { focusTarget(restored); return; }
                      var card = q("[data-review-card]");
                      if (card && (document.activeElement === null
                        || document.activeElement === document.body)) {
                        focusTarget(card);
                      }
                    });
                  });
                  document.addEventListener("keydown", function (e) {
                    if (e.ctrlKey || e.metaKey || e.altKey) { return; }
                    var t = e.target;
                    if (typing(t)) {
                      if (e.key === "Escape") {
                        var form = t.closest("form");
                        t.blur();
                        if (form && form.matches(TARGETS)) {
                          focusTarget(form);
                        }
                      }
                      return;
                    }
                    var dlg = q("[data-key-help]");
                    if (dlg && dlg.open) {
                      if (e.key === "?") { e.preventDefault(); help(false); }
                      return;
                    }
                    var key = e.key;
                    if (prefix) {
                      e.preventDefault();
                      var activePrefix = prefix;
                      clearPrefix();
                      runPrefix(activePrefix, key);
                      return;
                    }
                    if (e.repeat
                      && !["j", "k", "J", "K", "d", "u", "G"].includes(key)) {
                      if (key === " ") { e.preventDefault(); }
                      return;
                    }
                    if (key === "g") {
                      e.preventDefault();
                      startPrefix("g");
                      return;
                    }
                    if (key === "z") {
                      e.preventDefault();
                      startPrefix("z");
                      return;
                    }
                    if (key === "?") { e.preventDefault(); help(true); return; }
                    if (key === "j") {
                      e.preventDefault();
                      moveTarget(1);
                      return;
                    }
                    if (key === "k") {
                      e.preventDefault();
                      moveTarget(-1);
                      return;
                    }
                    if (key === "J") {
                      e.preventDefault();
                      window.scrollBy({ top: 140, behavior: move() });
                      return;
                    }
                    if (key === "K") {
                      e.preventDefault();
                      window.scrollBy({ top: -140, behavior: move() });
                      return;
                    }
                    if (key === "d") {
                      e.preventDefault();
                      window.scrollBy({
                        top: window.innerHeight / 2,
                        behavior: move()
                      });
                      return;
                    }
                    if (key === "u") {
                      e.preventDefault();
                      window.scrollBy({
                        top: -(window.innerHeight / 2),
                        behavior: move()
                      });
                      return;
                    }
                    if (key === "G") {
                      e.preventDefault();
                      window.scrollTo({
                        top: document.body.scrollHeight,
                        behavior: move()
                      });
                      return;
                    }
                    if (key === "o") {
                      if (setFold("toggle")) { e.preventDefault(); }
                      return;
                    }
                    if (key === "l") {
                      if (setFold("open")) { e.preventDefault(); return; }
                      var reveal = flip();
                      if (reveal && !reveal.open) {
                        e.preventDefault();
                        reveal.open = true;
                      }
                      return;
                    }
                    if (key === "h") {
                      if (setFold("close")) { e.preventDefault(); return; }
                      var shown = flip();
                      if (shown && shown.open) {
                        e.preventDefault();
                        shown.open = false;
                      }
                      return;
                    }
                    if (key === "Escape") {
                      if (setFold("close")) { e.preventDefault(); }
                      else {
                        var selected = q("[data-vim-active]");
                        if (selected) { clearTarget(); selected.blur(); }
                      }
                      return;
                    }
                    if (key === "Enter" && activeTarget()
                      && activeTarget().matches("form")) {
                      e.preventDefault();
                      focusForm();
                      return;
                    }
                    if (key === "i") {
                      if (focusForm()) { e.preventDefault(); return; }
                      if (openAssistant()) { e.preventDefault(); }
                      return;
                    }
                    if (key === " ") {
                      var f = flip();
                      if (!f || actionable(e.target)) { return; }
                      e.preventDefault();
                      if (f.open) { grade(2); } else { f.open = true; }
                      return;
                    }
                    if (key === "1" || key === "2"
                      || key === "3" || key === "4") {
                      if (root()) {
                        e.preventDefault();
                        grade(parseInt(key, 10) - 1);
                      }
                    }
                  });
                  if (document.readyState === "loading") {
                    document.addEventListener("DOMContentLoaded", sync);
                  } else {
                    sync();
                  }
                })();
                '''
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
                 --ok: #1a7f37;
                 --warn: #8a5800;
                 --success-bg: #e8f4e9;
                 --success-line: #9fc5a3;
                 --chrome: rgba(247, 247, 246, .92);
                 --shadow: 0 1px 2px rgba(25, 25, 24, .05),
                   0 8px 24px rgba(25, 25, 24, .04);
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
                   --ok: #7ec488;
                   --warn: #d9a94e;
                   --success-bg: #18271a;
                   --success-line: #46694a;
                   --chrome: rgba(17, 17, 16, .92);
                   --shadow: 0 1px 2px rgba(0, 0, 0, .28),
                     0 8px 24px rgba(0, 0, 0, .16);
                 }
               }
               * { box-sizing: border-box; }
               ::selection { background: var(--ink); color: var(--bg); }
               [hidden] { display: none !important; }
               html {
                 background: var(--bg);
                 color: var(--ink);
                 font-family: Inter, ui-sans-serif, system-ui, -apple-system,
                   BlinkMacSystemFont, "Segoe UI", sans-serif;
                 font-size: 15px;
               }
               body {
                 margin: 0;
                 min-height: 100vh;
                 -webkit-font-smoothing: antialiased;
               }
               a { color: inherit; }
               button, input, textarea { font: inherit; }
               button, .button {
                 align-items: center;
                 background: var(--ink);
                 border: 1px solid var(--ink);
                 border-radius: 4px;
                 color: var(--bg);
                 cursor: pointer;
                 display: inline-flex;
                 font-size: .86rem;
                 font-weight: 650;
                 justify-content: center;
                 min-height: 2.6rem;
                 padding: .62rem .9rem;
                 text-decoration: none;
               }
               button:hover, .button:hover { filter: invert(12%); }
               button:focus-visible,
               .button:focus-visible,
               input:focus-visible,
               textarea:focus-visible,
               summary:focus-visible,
               a:focus-visible {
                 outline: 2px solid var(--focus);
                 outline-offset: 2px;
               }
               button.secondary, .button.secondary {
                 background: var(--surface);
                 border-color: var(--line);
                 color: var(--ink);
               }
               button.danger {
                 background: transparent;
                 border-color: var(--line);
                 color: var(--danger);
               }
               input, textarea, select {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 caret-color: var(--focus);
                 color: var(--ink);
                 max-width: 100%;
                 min-width: 0;
                 padding: .72rem .78rem;
                 width: 100%;
               }
               input:hover, textarea:hover, select:hover {
                 border-color: var(--line-strong);
               }
               textarea {
                 field-sizing: content;
                 line-height: 1.5;
                 max-height: min(32rem, 60vh);
                 min-height: 7.5rem;
                 resize: vertical;
               }
               label {
                 color: var(--muted);
                 display: grid;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .75rem;
                 gap: .4rem;
                 min-width: 0;
               }
               form { display: grid; gap: .85rem; min-width: 0; }
               h1, h2, h3, p { margin: 0; }
               h1 {
                 font-size: clamp(1.8rem, 4vw, 2.45rem);
                 font-weight: 650;
                 letter-spacing: -.035em;
                 line-height: 1.08;
               }
               h2 {
                 font-size: 1.05rem;
                 font-weight: 650;
                 letter-spacing: -.015em;
               }
               h3 { font-size: .95rem; font-weight: 650; }
               .app-shell {
                 display: grid;
                 grid-template-columns: 15.5rem minmax(0, 1fr);
                 min-height: 100vh;
               }
               .sidebar {
                 background: var(--surface-2);
                 border-right: 1px solid var(--line);
                 display: flex;
                 flex-direction: column;
                 min-height: 100vh;
                 padding: 1.2rem .75rem;
                 position: sticky;
                 top: 0;
               }
               .brand {
                 display: block;
                 font-size: 1.05rem;
                 font-weight: 700;
                 padding: .65rem .75rem 1.4rem;
                 text-decoration: none;
               }
               .brand-sub {
                 color: var(--muted);
                 display: block;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 font-weight: 400;
                 margin-top: .25rem;
               }
               .primary-nav {
                 border-top: 1px solid var(--line);
                 display: grid;
               }
               .nav-link {
                 align-items: center;
                 border-bottom: 1px solid var(--line);
                 color: var(--muted);
                 display: flex;
                 gap: .75rem;
                 justify-content: space-between;
                 padding: .8rem .75rem;
                 text-decoration: none;
               }
               .nav-link:hover {
                 background: var(--surface);
                 color: var(--ink);
               }
               .nav-link.active {
                 box-shadow: inset 2px 0 0 var(--ink);
                 color: var(--ink);
               }
               .nav-label {
                 align-items: center;
                 display: inline-flex;
                 gap: .45rem;
                 min-width: 0;
               }
               .nav-key {
                 background: transparent;
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 color: var(--soft);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .58rem;
                 font-weight: 500;
                 letter-spacing: .025em;
                 line-height: 1;
                 padding: .18rem .28rem;
                 white-space: nowrap;
               }
               .nav-link:hover .nav-key, .nav-link.active .nav-key {
                 border-color: var(--line-strong);
                 color: var(--muted);
               }
               .nav-count {
                 color: var(--soft);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .72rem;
               }
               .sidebar-foot {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .7rem;
                 margin-top: auto;
                 padding: 1rem .75rem 0;
               }
               .workspace { min-width: 0; position: relative; }
               .request-status {
                 background: var(--ink);
                 height: 3px;
                 left: 0;
                 opacity: 0;
                 position: absolute;
                 right: 0;
                 top: 0;
                 transition: opacity .15s ease .12s;
                 z-index: 2;
               }
               .request-status.htmx-request { opacity: 1; }
               .content {
                 margin: 0 auto;
                 max-width: 980px;
                 padding: 3.4rem 3.5rem 7rem;
               }
               .page-head {
                 align-items: end;
                 border-bottom: 1px solid var(--line);
                 display: flex;
                 gap: 2rem;
                 justify-content: space-between;
                 margin-bottom: 1.5rem;
                 padding-bottom: 1.35rem;
               }
               .page-copy { display: grid; gap: .45rem; }
               .kicker, .eyebrow {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .7rem;
                 letter-spacing: .06em;
                 text-transform: uppercase;
               }
               .muted { color: var(--muted); line-height: 1.5; }
               .stat { min-width: 5rem; text-align: right; }
               .count {
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: 1.8rem;
                 line-height: 1;
               }
               .meta {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .7rem;
               }
               .section { margin-top: 1.5rem; }
               .panel, .card {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 4px;
                 padding: 1.15rem;
               }
               .form-panel { display: grid; gap: 1rem; margin-top: 1.5rem; }
               .form-head { display: grid; gap: .25rem; }
               .two {
                 display: grid;
                 gap: .8rem;
                 grid-template-columns:
                   repeat(auto-fit, minmax(min(100%, 14rem), 1fr));
               }
               .stack-list {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 4px;
                 overflow: hidden;
               }
               .stack-row + .stack-row { border-top: 1px solid var(--line); }
               .stack-link {
                 align-items: center;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
                 min-height: 4.6rem;
                 padding: 1rem 1.1rem;
                 text-decoration: none;
               }
               .stack-link:hover { background: var(--surface-2); }
               .stack-name { display: grid; gap: .28rem; min-width: 0; }
               .row-end {
                 align-items: end;
                 color: var(--muted);
                 display: grid;
                 flex: none;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .7rem;
                 gap: .25rem;
                 text-align: right;
               }
               .flash {
                 background: var(--success-bg);
                 border: 1px solid var(--success-line);
                 border-radius: 3px;
                 margin-bottom: 1rem;
                 padding: .8rem 1rem;
               }
               .empty {
                 background: var(--surface);
                 border: 1px dashed var(--line-strong);
                 color: var(--muted);
                 display: grid;
                 gap: .55rem;
                 padding: 2.2rem 1.4rem;
                 text-align: center;
               }
               .pill {
                 border: 1px solid var(--line);
                 border-radius: 999px;
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 padding: .25rem .5rem;
                 white-space: nowrap;
               }
               .prompt { white-space: pre-wrap; }
               details.reveal {
                 border-top: 1px solid var(--line);
                 min-width: 0;
                 overflow-wrap: anywhere;
               }
               details.reveal > summary {
                 cursor: pointer;
                 font-size: .86rem;
                 font-weight: 650;
                 list-style-position: inside;
                 padding: 1rem 1.2rem;
               }
               .answer { white-space: pre-wrap; }
               .review-session { margin: 0 auto; max-width: 720px; }
               .session-bar {
                 align-items: baseline;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
               }
               .session-title {
                 font-size: 1.02rem;
                 font-weight: 650;
                 letter-spacing: -.01em;
                 line-height: 1.2;
               }
               .session-tally {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .72rem;
                 font-variant-numeric: tabular-nums;
               }
               .tally-done { color: var(--ink); }
               .session-progress {
                 background: var(--line);
                 border-radius: 999px;
                 height: 3px;
                 margin-top: .7rem;
                 overflow: hidden;
               }
               .session-progress-fill {
                 background: var(--ink);
                 border-radius: 999px;
                 height: 100%;
                 transition: width .45s cubic-bezier(.22, .9, .3, 1);
                 width: 0;
               }
               .review-card {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 6px;
                 box-shadow: var(--shadow);
                 margin-top: 1.1rem;
                 outline: none;
                 overflow: hidden;
               }
               .review-top {
                 align-items: center;
                 border-bottom: 1px solid var(--line);
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
                 padding: .85rem 1.15rem;
               }
               .review-origin { display: grid; gap: .3rem; min-width: 0; }
               .review-title {
                 font-size: .92rem;
                 font-weight: 650;
                 letter-spacing: -.01em;
                 line-height: 1.3;
                 overflow-wrap: anywhere;
               }
               .review-stack {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 overflow-wrap: anywhere;
               }
               .review-prompt {
                 display: flex;
                 flex-direction: column;
                 font-family: Georgia, "Times New Roman", serif;
                 font-size: clamp(1.3rem, 2.2vw, 1.6rem);
                 justify-content: center;
                 line-height: 1.5;
                 min-height: clamp(12rem, 30vh, 18rem);
                 overflow-wrap: anywhere;
                 padding: 2.2rem max(2rem, calc((100% - 40rem) / 2));
                 text-align: center;
                 white-space: pre-wrap;
               }
               details.flip > .flip-bar {
                 align-items: center;
                 background: var(--ink);
                 color: var(--bg);
                 cursor: pointer;
                 display: flex;
                 font-size: .92rem;
                 font-weight: 650;
                 gap: .6rem;
                 justify-content: center;
                 list-style: none;
                 min-height: 3.3rem;
                 padding: .8rem 1.2rem;
                 text-align: center;
               }
               details.flip > .flip-bar::-webkit-details-marker {
                 display: none;
               }
               details.flip > .flip-bar:hover { filter: invert(12%); }
               details.flip > .flip-bar .key-hint {
                 border-color: var(--line-strong);
                 color: var(--bg);
                 opacity: .8;
               }
               details.flip .flip-hide { display: none; }
               details.flip[open] > .flip-bar {
                 background: transparent;
                 border-bottom: 1px solid var(--line);
                 color: var(--muted);
                 font-size: .78rem;
                 font-weight: 550;
                 min-height: 2.5rem;
                 padding: .45rem 1.2rem;
               }
               details.flip[open] > .flip-bar:hover {
                 color: var(--ink);
                 filter: none;
               }
               details.flip[open] > .flip-bar .flip-show { display: none; }
               details.flip[open] > .flip-bar .flip-hide { display: inline; }
               details.flip[open] > .flip-bar .key-hint { display: none; }
               .review-answer {
                 font-family: Georgia, "Times New Roman", serif;
                 font-size: 1.06rem;
                 line-height: 1.65;
                 max-height: 46vh;
                 overflow: auto;
                 overflow-wrap: anywhere;
                 padding: 1.7rem max(2rem, calc((100% - 40rem) / 2));
                 scrollbar-color: var(--line-strong) transparent;
                 scrollbar-width: thin;
                 text-align: center;
                 white-space: pre-wrap;
               }
               .review-answer::-webkit-scrollbar { width: 8px; }
               .review-answer::-webkit-scrollbar-thumb {
                 background: var(--line-strong);
                 border-radius: 4px;
               }
               .grade-row {
                 background: var(--line);
                 border-top: 1px solid var(--line);
                 display: grid;
                 gap: 1px;
                 grid-template-columns: repeat(4, minmax(0, 1fr));
               }
               .grade-row form { display: block; margin: 0; min-width: 0; }
               details.flip > .flip-bar:focus-visible,
               .grade-btn:focus-visible {
                 outline-offset: -3px;
               }
               .grade-btn {
                 background: var(--surface);
                 border: 0;
                 border-radius: 0;
                 color: var(--ink);
                 display: grid;
                 gap: .1rem;
                 min-height: 3.4rem;
                 padding: .55rem .3rem;
                 place-items: center;
                 position: relative;
                 width: 100%;
               }
               .grade-btn:hover { background: var(--surface-2); filter: none; }
               .grade-btn:disabled { cursor: default; opacity: .55; }
               .grade-btn:active { transform: translateY(1px); }
               .grade-name { font-size: .84rem; font-weight: 650; }
               .grade-again:hover .grade-name { color: var(--danger); }
               .grade-hard:hover .grade-name { color: var(--warn); }
               .grade-easy:hover .grade-name { color: var(--ok); }
               .grade-good { background: var(--ink); color: var(--bg); }
               .grade-good:hover {
                 background: var(--ink);
                 filter: invert(12%);
               }
               .grade-btn .key-hint {
                 position: absolute;
                 right: .5rem;
                 top: .45rem;
               }
               .grade-good .key-hint {
                 border-color: var(--line-strong);
                 color: var(--bg);
                 opacity: .75;
               }
               details.flip[open] > .review-answer {
                 animation: seer-reveal .34s cubic-bezier(.19, .85, .3, 1) both;
               }
               details.flip[open] > .grade-row {
                 animation: seer-reveal .34s cubic-bezier(.19, .85, .3, 1) .04s
                   both;
               }
               @keyframes seer-reveal {
                 from {
                   filter: blur(3px);
                   opacity: 0;
                   transform: translateY(5px);
                 }
               }
               details.assistant {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 6px;
                 margin-top: 1rem;
                 overflow: hidden;
               }
               .assistant-bar {
                 align-items: center;
                 cursor: pointer;
                 display: flex;
                 gap: .8rem;
                 justify-content: space-between;
                 list-style: none;
                 min-height: 3.1rem;
                 padding: .7rem 1.15rem;
               }
               .assistant-bar::-webkit-details-marker { display: none; }
               .assistant-bar:hover { background: var(--surface-2); }
               .assistant-label { font-size: .88rem; font-weight: 650; }
               .assistant-body {
                 border-top: 1px solid var(--line);
                 padding: 1.15rem;
               }
               .assistant-body .ai-card {
                 border-top: 0;
                 margin-top: 0;
                 padding-top: 0;
               }
               .key-hint {
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 color: var(--muted);
                 display: none;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .6rem;
                 line-height: 1;
                 padding: .18rem .32rem;
               }
               .key-line {
                 color: var(--muted);
                 display: none;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 gap: .45ch;
                 justify-content: center;
                 margin-top: 1rem;
               }
               .linkish {
                 background: none;
                 border: 0;
                 color: var(--muted);
                 cursor: pointer;
                 font: inherit;
                 min-height: 0;
                 padding: 0;
                 text-decoration: underline;
                 text-underline-offset: 3px;
               }
               .linkish:hover { color: var(--ink); filter: none; }
               @media (hover: hover) and (pointer: fine) {
                 html.kb .key-hint { display: inline-block; }
                 html.kb .key-line { display: flex; }
               }
               dialog.key-help {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 8px;
                 box-shadow: var(--shadow);
                 color: var(--ink);
                 padding: 1.5rem;
                 width: min(22rem, calc(100vw - 2rem));
               }
               dialog.key-help::backdrop {
                 backdrop-filter: blur(2px);
                 background: rgba(17, 17, 16, .35);
               }
               .key-title { font-size: 1rem; }
               .key-list { display: grid; gap: .6rem; margin: 1.1rem 0 1.3rem; }
               .key-row {
                 align-items: baseline;
                 display: flex;
                 flex-direction: row-reverse;
                 gap: 1rem;
                 justify-content: space-between;
               }
               .key-row dt { display: flex; flex: none; gap: .3rem; }
               .key-row dd {
                 color: var(--muted);
                 font-size: .84rem;
                 line-height: 1.4;
                 margin: 0;
               }
               kbd.key {
                 background: var(--surface-2);
                 border: 1px solid var(--line);
                 border-bottom-width: 2px;
                 border-radius: 4px;
                 color: var(--ink);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 font-weight: 600;
                 line-height: 1;
                 padding: .28rem .42rem;
               }
               .key-close button { width: 100%; }
               .review-done { padding: 4rem 1rem 2rem; text-align: center; }
               .done-block { display: grid; gap: .8rem; justify-items: center; }
               .done-title {
                 font-family: Georgia, "Times New Roman", serif;
                 font-size: 1.5rem;
                 font-weight: 400;
                 letter-spacing: -.01em;
               }
               .done-copy {
                 color: var(--muted);
                 line-height: 1.55;
                 max-width: 26rem;
               }
               .done-block .button { margin-top: .6rem; }
               '''
        ;style:'''
               .stack-head {
                 align-items: start;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
               }
               .breadcrumb {
                 color: var(--muted);
                 display: inline-block;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .72rem;
                 margin-bottom: 1rem;
                 text-decoration: none;
               }
               .breadcrumb:hover { color: var(--ink); }
               .action-row { display: flex; flex-wrap: wrap; gap: .55rem; }
               .stack-layout {
                 align-items: start;
                 display: grid;
                 gap: 1rem;
                 grid-template-columns: minmax(0, 1fr) minmax(17rem, 21rem);
                 margin-top: 1.5rem;
               }
               .editor-column { display: grid; gap: 1rem; min-width: 0; }
               .editor-column .section { margin-top: 0; }
               .item-list {
                 align-items: start;
                 display: grid;
                 gap: .75rem;
                 grid-template-columns: repeat(auto-fill, minmax(13rem, 1fr));
                 min-width: 0;
               }
               .item {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 4px;
                 min-width: 0;
                 overflow: hidden;
                 position: relative;
                 transition: border-color 160ms cubic-bezier(.16, 1, .3, 1),
                   box-shadow 160ms cubic-bezier(.16, 1, .3, 1),
                   transform 160ms cubic-bezier(.16, 1, .3, 1);
               }
               .item:hover, .item[open] { border-color: var(--line-strong); }
               .item[open] {
                 grid-column: 1 / -1;
                 min-width: 0;
                 box-shadow: var(--shadow);
               }
               .item[data-vim-selected] {
                 border-color: var(--line-strong);
                 box-shadow: var(--shadow);
                 transform: translateY(-1px);
               }
               .item[data-vim-selected]::before {
                 background: var(--focus);
                 content: "";
                 inset: .8rem auto .8rem .35rem;
                 position: absolute;
                 width: 1px;
                 z-index: 2;
               }
               .item[data-vim-selected] > .item-summary {
                 background: var(--surface-2);
               }
               .item[data-vim-selected] .item-id { color: var(--ink); }
               .item[data-vim-selected] .item-toggle {
                 background: var(--ink);
                 border-color: var(--ink);
                 color: var(--bg);
               }
               .item-summary {
                 align-items: start;
                 cursor: pointer;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
                 list-style: none;
                 min-height: 7.25rem;
                 padding: 1rem;
               }
               .item-summary::-webkit-details-marker { display: none; }
               .item-summary:hover { background: var(--surface-2); }
               .item[open] .item-summary { min-height: 0; }
               .item-copy { display: grid; gap: .55rem; min-width: 0; }
               .item-id {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .66rem;
                 overflow-wrap: anywhere;
               }
               .item-title {
                 font-size: .98rem;
                 font-weight: 650;
                 letter-spacing: -.01em;
                 line-height: 1.35;
                 overflow-wrap: anywhere;
               }
               .item-toggle {
                 align-items: center;
                 border: 1px solid var(--line);
                 border-radius: 50%;
                 color: var(--muted);
                 display: inline-flex;
                 flex: none;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 height: 1.55rem;
                 justify-content: center;
                 line-height: 1;
                 width: 1.55rem;
               }
               .item-toggle::before { content: "+"; }
               .item[open] .item-toggle::before { content: "−"; }
               .item-detail {
                 border-top: 1px solid var(--line);
                 display: grid;
                 gap: 1rem;
                 min-width: 0;
                 padding: clamp(.9rem, 2vw, 1.3rem);
               }
               .item-detail > .ai-card, .item-detail > .item-actions {
                 margin-top: 0;
               }
               .card-content {
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 display: grid;
                 grid-template-columns: repeat(2, minmax(0, 1fr));
                 min-width: 0;
                 overflow: hidden;
               }
               .card-face {
                 align-content: start;
                 display: grid;
                 gap: .65rem;
                 min-width: 0;
                 overflow-wrap: anywhere;
                 padding: 1rem;
               }
               .card-face + .card-face { border-left: 1px solid var(--line); }
               .item .prompt {
                 display: block;
                 font-family: inherit;
                 font-size: 1rem;
                 line-height: 1.55;
                 min-height: 0;
                 padding: 0;
               }
               .item .answer {
                 border: 0;
                 font-family: inherit;
                 font-size: .9rem;
                 line-height: 1.55;
                 padding: 0;
               }
               .item-actions {
                 align-items: center;
                 display: flex;
                 flex-wrap: wrap;
                 gap: .5rem;
                 margin-top: .9rem;
               }
               .ai-card {
                 border-top: 1px solid var(--line);
                 container-type: inline-size;
                 display: grid;
                 gap: .85rem;
                 margin-top: 1rem;
                 min-width: 0;
                 padding-top: 1rem;
               }
               .ai-head {
                 align-items: center;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
               }
               .ai-history { display: grid; gap: .75rem; }
               .ai-turn {
                 background: var(--surface-2);
                 border-radius: 3px;
                 display: grid;
                 gap: .55rem;
                 padding: .85rem;
               }
               .ai-question { font-weight: 650; line-height: 1.45; }
               .ai-answer {
                 border-top: 1px solid var(--line);
                 line-height: 1.55;
                 padding-top: .55rem;
                 white-space: pre-wrap;
               }
               .ai-revision {
                 border-top: 1px solid var(--line);
                 padding-top: .55rem;
               }
               .ai-revision > summary {
                 color: var(--muted);
                 cursor: pointer;
                 font-size: .78rem;
                 font-weight: 650;
               }
               .ai-diff {
                 display: grid;
                 gap: .65rem;
                 grid-template-columns: repeat(2, minmax(0, 1fr));
                 padding-top: .75rem;
               }
               .ai-version {
                 border-left: 2px solid var(--line-strong);
                 display: grid;
                 gap: .4rem;
                 padding-left: .7rem;
               }
               .ai-version p {
                 font-size: .82rem;
                 line-height: 1.5;
                 margin: 0;
                 white-space: pre-wrap;
               }
               .ai-waiting {
                 align-items: center;
                 color: var(--muted);
                 display: flex;
                 font-size: .82rem;
                 gap: .65rem;
                 line-height: 1.45;
                 min-height: 1.25rem;
               }
               .thinking-dots {
                 align-items: center;
                 display: inline-flex;
                 flex: none;
                 gap: 3px;
                 height: .8rem;
               }
               .thinking-dots span {
                 animation: seer-thinking-dot 1.55s ease-in-out infinite;
                 background: currentColor;
                 border-radius: 50%;
                 height: 4px;
                 opacity: .22;
                 width: 4px;
               }
               .thinking-dots span:nth-child(2) { animation-delay: .16s; }
               .thinking-dots span:nth-child(3) { animation-delay: .32s; }
               .is-thinking { overflow: hidden; position: relative; }
               .is-thinking::before {
                 animation: seer-thinking-line 2.8s ease-in-out infinite;
                 background: linear-gradient(90deg, transparent,
                   var(--line-strong), transparent);
                 content: "";
                 height: 1px;
                 left: 0;
                 opacity: .7;
                 position: absolute;
                 right: 0;
                 top: 0;
                 transform: translateX(-75%);
                 width: 58%;
                 z-index: 1;
               }
               .thinking-pill {
                 align-items: center;
                 display: inline-flex;
                 gap: .4rem;
               }
               .thinking-pill::before {
                 animation: seer-thinking-orb 1.8s ease-in-out infinite;
                 background: currentColor;
                 border-radius: 50%;
                 content: "";
                 height: 5px;
                 opacity: .35;
                 width: 5px;
               }
               @keyframes seer-thinking-dot {
                 0%, 70%, 100% { opacity: .2; transform: translateY(0); }
                 35% { opacity: .85; transform: translateY(-1px); }
               }
               @keyframes seer-thinking-line {
                 0% { opacity: 0; transform: translateX(-100%); }
                 18% { opacity: .55; }
                 72% { opacity: .55; }
                 100% { opacity: 0; transform: translateX(245%); }
               }
               @keyframes seer-thinking-orb {
                 0%, 100% { opacity: .28; transform: scale(.85); }
                 50% { opacity: .8; transform: scale(1); }
               }
               .ai-form {
                 background: transparent;
                 display: grid;
                 gap: .7rem;
                 min-width: 0;
               }
               .ai-form-row {
                 align-items: end;
                 display: grid;
                 gap: .65rem;
                 grid-template-columns: minmax(6rem, .35fr) minmax(12rem, 1fr)
                   minmax(10rem, .75fr) auto;
                 min-width: 0;
               }
               .ai-form-row > * { min-width: 0; }
               .ai-form textarea {
                 max-height: min(24rem, 55vh);
                 min-height: 3rem;
               }
               .ai-model-empty {
                 border: 1px dashed var(--line-strong);
                 color: var(--muted);
                 font-size: .84rem;
                 line-height: 1.5;
                 padding: .8rem;
               }
               .inline { display: inline; }
               .inline button { width: auto; }
               .danger-zone { background: transparent; }
               .capture-list { display: grid; gap: 1rem; }
               .capture-history { margin-top: 2.2rem; }
               .capture {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 4px;
                 overflow: hidden;
               }
               .capture-head {
                 align-items: start;
                 border-bottom: 1px solid var(--line);
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
                 padding: 1.15rem;
               }
               .capture-copy { display: grid; gap: .35rem; min-width: 0; }
               .capture-meta {
                 align-items: center;
                 color: var(--muted);
                 display: flex;
                 flex-wrap: wrap;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .68rem;
                 gap: .4rem .7rem;
               }
               .proposal { padding: 1.15rem; }
               .proposal + .proposal { border-top: 1px solid var(--line); }
               .proposal-head {
                 align-items: start;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
               }
               .proposal-body { display: grid; gap: .9rem; margin-top: 1rem; }
               .proposal-prompt {
                 font-family: Georgia, "Times New Roman", serif;
                 font-size: 1.15rem;
                 line-height: 1.5;
                 white-space: pre-wrap;
               }
               .proposal-answer {
                 background: var(--surface-2);
                 border-left: 2px solid var(--line-strong);
                 line-height: 1.55;
                 padding: .85rem 1rem;
                 white-space: pre-wrap;
               }
               .provenance {
                 border-top: 1px solid var(--line);
                 color: var(--muted);
                 display: grid;
                 font-size: .82rem;
                 gap: .4rem;
                 padding-top: .8rem;
               }
               .decision-row {
                 align-items: center;
                 display: flex;
                 flex-wrap: wrap;
                 gap: .55rem;
                 justify-content: flex-end;
               }
               .decision-row form { display: block; }
               .proposal-conflict {
                 color: var(--danger);
                 font-size: .82rem;
                 line-height: 1.45;
               }
               .command-panel { display: grid; gap: 1rem; }
               .command-form {
                 border-top: 1px solid var(--line);
                 padding-top: 1rem;
               }
               .command-controls {
                 align-items: end;
                 display: grid;
                 gap: .7rem;
                 grid-template-columns: minmax(9rem, .6fr)
                   minmax(16rem, 1.4fr) auto;
               }
               .change-list { display: grid; gap: .75rem; }
               .change-body { padding: 1rem 1.15rem 1.15rem; }
               .operation-list { display: grid; gap: .55rem; }
               .operation {
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 display: grid;
                 gap: .65rem;
                 padding: .8rem;
               }
               .operation-head {
                 align-items: center;
                 display: flex;
                 gap: .6rem;
                 justify-content: space-between;
               }
               .operation p { line-height: 1.5; }
               .mobile-only { display: none; }
               .compose-trigger { cursor: pointer; }
               .compose-body { display: grid; gap: 1rem; }
               .hidden { display: none; }
               .app-footer {
                 border-top: 1px solid var(--line);
                 margin-top: 3rem;
                 padding-top: 1rem;
               }
               [data-vim-active] {
                 outline: 2px solid var(--focus);
                 outline-offset: 3px;
               }
               .item-summary[data-vim-active] { outline: none; }
               form[data-vim-active] { border-radius: 4px; }
               .vim-chord {
                 backdrop-filter: blur(12px);
                 -webkit-backdrop-filter: blur(12px);
                 background: var(--ink);
                 border: 1px solid var(--line-strong);
                 border-radius: 5px;
                 bottom: 1.25rem;
                 box-shadow: var(--shadow);
                 color: var(--bg);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .7rem;
                 left: 50%;
                 max-width: calc(100vw - 2rem);
                 padding: .55rem .75rem;
                 position: fixed;
                 transform: translateX(-50%);
                 white-space: nowrap;
                 z-index: 80;
               }
               .form-panel, .command-panel, .compose-body {
                 container-type: inline-size;
                 min-width: 0;
               }
               @container (max-width: 44rem) {
                 .ai-form-row {
                   grid-template-columns: repeat(2, minmax(0, 1fr));
                 }
                 .ai-form-row > label:nth-child(2) {
                   grid-column: 1 / -1;
                   grid-row: 1;
                 }
                 .ai-form-row > label:nth-child(1) {
                   grid-column: 1;
                   grid-row: 2;
                 }
                 .ai-form-row > label:nth-child(3) {
                   grid-column: 2;
                   grid-row: 2;
                 }
                 .ai-form-row > button { grid-column: 1 / -1; }
                 .command-controls {
                   grid-template-columns: repeat(2, minmax(0, 1fr));
                 }
                 .command-controls > label:nth-child(2),
                 .command-controls > button {
                   grid-column: 1 / -1;
                 }
               }
               @container (max-width: 30rem) {
                 .ai-form-row, .command-controls { grid-template-columns: 1fr; }
                 .ai-form-row > *, .command-controls > * {
                   grid-column: 1 !important;
                   grid-row: auto !important;
                 }
               }
               @media (prefers-reduced-motion: reduce) {
                 .thinking-dots span,
                 .thinking-pill::before,
                 .is-thinking::before {
                   animation: none;
                 }
                 .thinking-dots span { opacity: .55; transform: none; }
                 .is-thinking::before { display: none; }
                 details.flip[open] > .review-answer,
                 details.flip[open] > .grade-row {
                   animation: none;
                 }
                 .session-progress-fill { transition: none; }
                 .item { transition: none; }
                 .item[data-vim-selected] { transform: none; }
               }
               @media (max-width: 850px) {
                 .app-shell { grid-template-columns: 12.5rem minmax(0, 1fr); }
                 .content { padding-left: 2rem; padding-right: 2rem; }
                 .stack-layout { grid-template-columns: 1fr; }
               }
               @media (max-width: 650px) {
                 * { -webkit-tap-highlight-color: transparent; }
                 html { font-size: 16px; }
                 body { overscroll-behavior-y: none; }
                 .app-shell {
                   display: block;
                   min-height: 100dvh;
                   padding-bottom: calc(4.45rem + env(safe-area-inset-bottom));
                 }
                 .sidebar { display: contents; }
                 .brand {
                   align-items: center;
                   backdrop-filter: blur(18px);
                   -webkit-backdrop-filter: blur(18px);
                   background: var(--chrome);
                   border-bottom: 1px solid var(--line);
                   display: flex;
                   height: calc(3.65rem + env(safe-area-inset-top));
                   justify-content: space-between;
                   left: 0;
                   padding: calc(.7rem + env(safe-area-inset-top)) 1rem .7rem;
                   position: fixed;
                   right: 0;
                   top: 0;
                   z-index: 30;
                 }
                 .brand-sub { display: block; font-size: .62rem; margin: 0; }
                 .primary-nav {
                   backdrop-filter: blur(18px);
                   -webkit-backdrop-filter: blur(18px);
                   background: var(--chrome);
                   border: 0;
                   border-top: 1px solid var(--line);
                   bottom: 0;
                   display: grid;
                   grid-template-columns: repeat(4, minmax(0, 1fr));
                   left: 0;
                   padding-bottom: env(safe-area-inset-bottom);
                   position: fixed;
                   right: 0;
                   z-index: 30;
                 }
                 .nav-link {
                   border: 0;
                   border-right: 1px solid var(--line);
                   color: var(--muted);
                   display: grid;
                   gap: .15rem;
                   justify-items: center;
                   min-height: 4.4rem;
                   padding: .72rem .25rem .62rem;
                   position: relative;
                 }
                 .nav-link:last-child { border-right: 0; }
                 .nav-link.active {
                   background: var(--surface);
                   box-shadow: inset 0 2px 0 var(--ink);
                 }
                 .nav-count { font-size: .62rem; line-height: 1; }
                 .nav-label { gap: .3rem; }
                 .nav-label > span { font-size: .88rem; }
                 .nav-key { font-size: .5rem; padding: .15rem .22rem; }
                 .sidebar-foot { display: none; }
                 .workspace { min-height: 100dvh; }
                 .request-status { position: fixed; z-index: 40; }
                 .content {
                   max-width: none;
                   padding: calc(5rem + env(safe-area-inset-top)) 1rem
                     calc(6.5rem + env(safe-area-inset-bottom));
                 }
                 .page-head {
                   align-items: end;
                   gap: 1rem;
                   margin-bottom: 1.25rem;
                   padding-bottom: 1.1rem;
                 }
                 .page-copy { gap: .35rem; min-width: 0; }
                 .page-copy .muted { font-size: .9rem; }
                 h1 { font-size: 1.65rem; letter-spacing: -.04em; }
                 h2 { font-size: 1rem; }
                 .kicker, .eyebrow {
                   font-size: .62rem;
                   letter-spacing: .075em;
                 }
                 .count { font-size: 1.55rem; }
                 .stat { min-width: 4.2rem; }
                 .meta { font-size: .65rem; }
                 button, .button {
                   border-radius: 6px;
                   font-size: .88rem;
                   min-height: 3rem;
                   touch-action: manipulation;
                 }
                 input, textarea, select {
                   border-radius: 6px;
                   font-size: 1rem;
                   min-height: 3rem;
                   padding: .8rem .85rem;
                 }
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
                 .empty {
                   border-style: solid;
                   border-radius: 9px;
                   padding: 2rem 1.1rem;
                 }
                 .mobile-compose {
                   background: var(--surface);
                   border: 1px solid var(--line);
                   margin-top: 1rem;
                   overflow: hidden;
                 }
                 .compose-trigger {
                   align-items: center;
                   display: flex;
                   justify-content: space-between;
                   list-style: none;
                   min-height: 4.4rem;
                   padding: .85rem 1rem;
                 }
                 .compose-trigger::-webkit-details-marker { display: none; }
                 .compose-trigger:hover { background: var(--surface-2); }
                 .compose-title { display: grid; gap: .2rem; }
                 .compose-trigger::after {
                   color: var(--muted);
                   content: "+";
                   font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                     Consolas, monospace;
                   font-size: 1.15rem;
                   font-weight: 400;
                   line-height: 1;
                 }
                 details[open] > .compose-trigger::after { content: "−"; }
                 .compose-body {
                   border-top: 1px solid var(--line);
                   padding: 1rem;
                 }
                 .two { grid-template-columns: 1fr; }
                 .flash {
                   border-radius: 7px; font-size: .86rem; margin-bottom: 1rem;
                   padding: .75rem .85rem;
                 }
                 .review-session { max-width: none; }
                 .session-title { font-size: 1rem; }
                 .review-card { border-radius: 9px; margin-top: .9rem; }
                 .review-top { padding: .8rem 1rem; }
                 .review-prompt {
                   font-size: 1.28rem;
                   min-height: clamp(9rem, 24vh, 13rem);
                   padding: 1.6rem 1.1rem;
                 }
                 details.flip > .flip-bar {
                   font-size: .95rem;
                   min-height: 3.6rem;
                 }
                 details.flip[open] > .flip-bar { min-height: 2.6rem; }
                 .review-answer {
                   font-size: 1.02rem;
                   max-height: 38vh;
                   padding: 1.35rem 1.1rem;
                 }
                 .grade-btn { min-height: 3.9rem; }
                 .grade-name { font-size: .8rem; }
                 details.assistant { border-radius: 9px; }
                 .assistant-bar { min-height: 3.5rem; }
                 .review-done { padding: 3.2rem .5rem 1rem; }
                 details.reveal > summary {
                   min-height: 3.4rem;
                   padding: 1rem;
                   touch-action: manipulation;
                 }
                 .stack-head { display: grid; gap: 1rem; }
                 .breadcrumb {
                   display: block;
                   margin-bottom: .8rem;
                   overflow: hidden;
                   text-overflow: ellipsis;
                   white-space: nowrap;
                 }
                 .action-row { width: 100%; }
                 .action-row form, .action-row button { width: 100%; }
                 .stack-layout {
                   gap: 1rem;
                   grid-template-columns: 1fr;
                   margin-top: 1rem;
                 }
                 .item-list {
                   gap: .6rem;
                   grid-template-columns: repeat(2, minmax(0, 1fr));
                 }
                 .item { border-radius: 9px; box-shadow: var(--shadow); }
                 .item-summary { min-height: 8rem; padding: .85rem; }
                 .item-detail { padding: .85rem; }
                 .card-content { grid-template-columns: 1fr; }
                 .card-face { padding: .85rem; }
                 .card-face + .card-face {
                   border-left: 0;
                   border-top: 1px solid var(--line);
                 }
                 .item-actions {
                   display: grid;
                   grid-template-columns: 1fr auto;
                 }
                 .ai-form-row { grid-template-columns: 1fr; }
                 .ai-form-row button { width: 100%; }
                 .ai-diff { grid-template-columns: 1fr; }
                 .item-actions form:first-child,
                 .item-actions form:first-child button {
                   width: 100%;
                 }
                 .editor-column { gap: 1rem; }
                 .settings-disclosure { box-shadow: none; }
                 .settings-disclosure .compose-trigger { min-height: 3.7rem; }
                 .danger-zone { margin-top: 0; }
                 .capture { border-radius: 9px; box-shadow: var(--shadow); }
                 .capture-head { padding: 1rem; }
                 .proposal { padding: 1rem; }
                 .proposal-head { display: grid; gap: .6rem; }
                 .decision-row {
                   display: grid;
                   grid-template-columns: 1fr 1fr;
                   width: 100%;
                 }
                 .decision-row form, .decision-row button { width: 100%; }
                 .command-controls { grid-template-columns: 1fr; }
                 .command-controls button { width: 100%; }
                 .app-footer { display: none; }
               }
               @media (max-width: 650px) {
                 .vim-chord { display: none; }
               }
               @media (max-width: 430px) {
                 .item-list { grid-template-columns: 1fr; }
               }
               '''
        ;style:'''
               .context-panel {
                 background: var(--surface);
                 border: 1px solid var(--line);
                 border-radius: 4px;
                 min-width: 0;
                 overflow: hidden;
               }
               .context-panel[open] { border-color: var(--line-strong); }
               .context-summary {
                 align-items: center;
                 cursor: pointer;
                 display: flex;
                 gap: 1rem;
                 justify-content: space-between;
                 list-style: none;
                 min-height: 3.4rem;
                 padding: .8rem 1rem;
               }
               .context-summary::-webkit-details-marker,
               .context-add > summary::-webkit-details-marker {
                 display: none;
               }
               .context-summary:hover, .context-add > summary:hover {
                 background: var(--surface-2);
               }
               .context-summary-copy {
                 display: grid;
                 gap: .18rem;
                 min-width: 0;
               }
               .context-title {
                 font-size: .9rem;
                 font-weight: 650;
                 letter-spacing: -.01em;
               }
               .context-purpose {
                 color: var(--muted);
                 font-size: .76rem;
                 line-height: 1.4;
               }
               .context-count {
                 color: var(--muted);
                 flex: none;
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .66rem;
                 font-variant-numeric: tabular-nums;
               }
               .context-body {
                 border-top: 1px solid var(--line);
                 display: grid;
                 gap: 1rem;
                 padding: 1rem;
               }
               .context-list { display: grid; }
               .context-source {
                 align-items: start;
                 display: flex;
                 gap: .8rem;
                 justify-content: space-between;
                 min-width: 0;
                 padding: .72rem 0;
               }
               .context-source + .context-source {
                 border-top: 1px solid var(--line);
               }
               .context-source-copy { display: grid; gap: .3rem; min-width: 0; }
               .context-source-head {
                 align-items: baseline;
                 display: flex;
                 flex-wrap: wrap;
                 gap: .45rem;
               }
               .context-source-title {
                 font-size: .84rem;
                 font-weight: 650;
                 overflow-wrap: anywhere;
               }
               .context-kind, .context-scope {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .6rem;
                 text-transform: uppercase;
               }
               .context-locator {
                 color: var(--muted);
                 font-size: .72rem;
                 line-height: 1.4;
                 overflow-wrap: anywhere;
               }
               .context-source-status {
                 color: var(--muted);
                 font-size: .72rem;
                 line-height: 1.4;
               }
               .context-source-status[data-status="ready"] { color: var(--ok); }
               .context-source-status[data-status="working"],
               .context-source-status[data-status="pending"] {
                 color: var(--warn);
               }
               .context-source-status[data-status="failed"],
               [data-context-file-status][data-state="error"] {
                 color: var(--danger);
               }
               .context-source-actions {
                 align-items: center;
                 display: flex;
                 flex: none;
                 gap: .4rem;
               }
               .context-source-actions button {
                 min-height: 2rem;
                 padding: .35rem .55rem;
               }
               .icon-button {
                 align-items: center;
                 background: var(--surface-2);
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 color: var(--muted);
                 cursor: pointer;
                 display: inline-flex;
                 font: inherit;
                 font-size: .9rem;
                 justify-content: center;
                 line-height: 1;
                 min-height: 2rem;
                 min-width: 2rem;
                 padding: 0;
               }
               .icon-button:hover {
                 border-color: var(--danger);
                 color: var(--danger);
               }
               .icon-button:focus-visible {
                 outline: 2px solid var(--danger);
                 outline-offset: 1px;
               }
               .context-members {
                 border-top: 1px dashed var(--line);
                 margin-top: .5rem;
                 padding-top: .45rem;
               }
               .context-members-summary {
                 color: var(--muted);
                 cursor: pointer;
                 font-size: .72rem;
                 list-style: none;
               }
               .context-members-summary:hover {
                 color: var(--ink);
               }
               .context-member-list {
                 display: grid;
                 gap: .2rem;
                 margin-top: .45rem;
                 max-height: 14rem;
                 overflow-y: auto;
               }
               .context-member {
                 align-items: center;
                 display: flex;
                 gap: .5rem;
                 justify-content: space-between;
                 min-width: 0;
               }
               .context-member-path {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                 font-size: .72rem;
                 overflow-wrap: anywhere;
               }
               .context-member-on {
                 color: var(--ok);
                 flex: none;
                 font-size: .66rem;
               }
               .context-empty {
                 color: var(--muted);
                 font-size: .78rem;
                 line-height: 1.5;
                 padding: .2rem 0;
               }
               .context-add { border-top: 1px solid var(--line); }
               .context-add > summary {
                 cursor: pointer;
                 font-size: .8rem;
                 font-weight: 650;
                 list-style: none;
                 padding: .75rem 0 0;
               }
               .context-form { display: grid; gap: .8rem; padding-top: .9rem; }
               .context-type-row {
                 align-items: end;
                 display: grid;
                 gap: .65rem;
                 grid-template-columns: minmax(8rem, .7fr) minmax(0, 1.3fr);
               }
               .context-fields { display: grid; gap: .65rem; }
               .context-fields textarea { min-height: 6rem; }
               .context-file-input {
                 border: 1px dashed var(--line-strong);
                 border-radius: 3px;
                 display: grid;
                 gap: .45rem;
                 padding: .75rem;
               }
               .context-file-input input[type="file"] {
                 border: 0;
                 min-height: 0;
                 padding: 0;
               }
               .clay-picker { font-size: .82rem; margin-top: .2rem; }
               .clay-recents {
                 display: flex;
                 flex-wrap: wrap;
                 gap: .35rem .7rem;
                 margin: .3rem 0;
               }
               .clay-remote {
                 border-top: 1px dashed var(--line);
                 margin-top: .6rem;
                 padding-top: .6rem;
               }
               .context-stale {
                 color: var(--muted);
                 display: block;
                 font-size: .72rem;
                 font-style: italic;
                 margin-top: .15rem;
               }
               .clay-remote-loading p { margin: .3rem 0; }
               .clay-results {
                 list-style: none;
                 margin: .3rem 0 0;
                 padding: 0;
               }
               .clay-results li { margin: .12rem 0; }
               .clay-results a { text-decoration: none; }
               .clay-results a:hover { text-decoration: underline; }
               .clay-results-meta { color: var(--muted); font-size: .72rem; }
               a.clay-file.clay-dir { color: var(--ink); font-weight: 600; }
               #clay-results-box { max-height: 16rem; overflow-y: auto; }
               .clay-search {
                 align-items: end;
                 display: flex;
                 flex-wrap: wrap;
                 gap: .55rem;
               }
               .clay-search label { display: grid; gap: .2rem; }
               a.clay-file {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .78rem;
               }
               .context-file-input input[type="file"]::file-selector-button {
                 background: var(--surface-2);
                 border: 1px solid var(--line);
                 border-radius: 3px;
                 color: var(--ink);
                 cursor: pointer;
                 font: inherit;
                 margin-right: .6rem;
                 padding: .45rem .6rem;
               }
               [data-context-file-status] {
                 color: var(--muted);
                 font-size: .72rem;
                 line-height: 1.4;
                 min-height: 1rem;
               }
               .context-picker {
                 border: 0;
                 border-top: 1px solid var(--line);
                 display: grid;
                 gap: .55rem;
                 margin: 0;
                 min-width: 0;
                 padding: .75rem 0 0;
               }
               .context-picker legend {
                 color: var(--muted);
                 font-family: ui-monospace, SFMono-Regular, Menlo, Monaco,
                   Consolas, monospace;
                 font-size: .66rem;
                 padding: 0 .35rem 0 0;
               }
               .context-choice-list {
                 display: flex;
                 flex-wrap: wrap;
                 gap: .4rem;
               }
               .context-choice {
                 align-items: center;
                 border: 1px solid var(--line);
                 border-radius: 999px;
                 color: var(--muted);
                 cursor: pointer;
                 display: inline-flex;
                 font-family: inherit;
                 font-size: .72rem;
                 gap: .4rem;
                 line-height: 1.2;
                 padding: .38rem .55rem;
               }
               .context-choice:has(input:checked) {
                 background: var(--surface-2);
                 border-color: var(--line-strong);
                 color: var(--ink);
               }
               .context-choice input {
                 accent-color: var(--focus);
                 min-height: 0;
                 padding: 0;
                 width: auto;
               }
               .context-choice .context-scope { font-size: .55rem; }
               .item-detail > .context-panel {
                 border-left: 0;
                 border-radius: 0;
                 border-right: 0;
               }
               .editor-tools { display: grid; gap: 1rem; min-width: 0; }
               @media (max-width: 650px) {
                 .context-panel { border-radius: 9px; }
                 .context-summary { min-height: 3.8rem; padding: .85rem 1rem; }
                 .context-body { padding: 1rem; }
                 .stack-layout > .editor-column { display: contents; }
                 .stack-layout > .editor-column > .context-panel { order: -1; }
                 .stack-layout > .editor-column > .editor-tools { order: 1; }
                 .context-source { display: grid; justify-content: stretch; }
                 .context-source-actions { justify-content: end; width: 100%; }
                 .context-type-row { grid-template-columns: 1fr; }
                 .item-detail > .context-panel { border-radius: 0; }
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
                =class         ?:(review-active "nav-link active" "nav-link")
                =aria-current  ?:(review-active "page" "false")
                =href          "/apps/seer/review"
                ;span.nav-label
                  ;span: Review
                  ;kbd.nav-key(aria-hidden "true"): g r
                ==
                ;span.nav-count: {<(lent reviews)>}
              ==
              ;a
                =class         ?:(inbox-active "nav-link active" "nav-link")
                =aria-current  ?:(inbox-active "page" "false")
                =href          "/apps/seer/inbox"
                ;span.nav-label
                  ;span: Inbox
                  ;kbd.nav-key(aria-hidden "true"): g i
                ==
                ;span.nav-count: {<inbox-count>}
              ==
              ;a
                =class         ?:(library-active "nav-link active" "nav-link")
                =aria-current  ?:(library-active "page" "false")
                =href          "/apps/seer/stacks"
                ;span.nav-label
                  ;span: Library
                  ;kbd.nav-key(aria-hidden "true"): g l
                ==
                ;span.nav-count: {<stack-count>}
              ==
              ;a
                =class         ?:(shared-active "nav-link active" "nav-link")
                =aria-current  ?:(shared-active "page" "false")
                =href          "/apps/seer/subscriptions"
                ;span.nav-label
                  ;span: Shared
                  ;kbd.nav-key(aria-hidden "true"): g s
                ==
                ;span.nav-count: {<subscription-count>}
              ==
            ==
            ;div.sidebar-foot: {(scow %p our)}
          ==
          ;div.workspace
            ;+  [[%div status-attrs] ~]
            ;div.content
              ;+
              ?~  notice
                ;div.hidden;
              ;div.flash(role "status"): {(trip u.notice)}
              ;+  receipt-panel
              ;+  page-body
              ;footer.app-footer.meta
                ;p: Server-rendered by %seer
              ==
            ==
          ==
          ;+  key-help
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
      %stack-browse   (stack-page owner.page name.page)
    ==
  ::
  ++  inbox-captures
    ::  Walk the map without materializing completed history. Only active
    ::  captures and the twenty most recent completed rows are retained.
    ::
    =/  tree=(map @tas capture)  captures
    =/  active=(list [@tas capture])  ~
    =/  recent=(list [@tas capture])  ~
    =/  completed=@ud  0
    |-
    ^-  [active=(list [@tas capture]) recent=(list [@tas capture]) completed=@ud]
    ?~  tree  [active recent completed]
    =/  right  $(tree r.tree)
    =.  active  active.right
    =.  recent  recent.right
    =.  completed  completed.right
    ?:  =(%open status.q.n.tree)
      $(tree l.tree, active [n.tree active])
    $(tree l.tree, recent (retain-recent-capture n.tree recent 20), completed +(completed))
  ::
  ++  retain-recent-capture
    |=  [row=[@tas capture] rows=(list [@tas capture]) limit=@ud]
    ^-  (list [@tas capture])
    ?:  =(0 limit)  ~
    ?~  rows  ~[row]
    ::  Captures have no updated-at: use created-at, then alphabetical ID.
    ::
    =/  before=?
      ?:  =(created-at.+.row created-at.+.i.rows)
        (aor -.row -.i.rows)
      (gth created-at.+.row created-at.+.i.rows)
    ?:  before  [row (scag (dec limit) ^-((list [@tas capture]) rows))]
    [i.rows $(rows t.rows, limit (dec limit))]
  ::
  ++  inbox-page
    ^-  manx
    =/  selected  inbox-captures
    =/  shown=@ud  (lent recent.selected)
    =/  omitted=@ud  (sub completed.selected shown)
    =/  requests=(list [@tas change-request])  ~(tap by changes)
    =/  available-models=(list [@tas assistant-model])  ordered-assistant-models
    =/  waiting=?  (changes-waiting requests)
    =/  request-copy=tape
      "Describe the required result. Seer submits a plan or brief for review."
    =/  target-copy=tape
      ;:  weld
        "Library requests produce typed operations. Desk requests "
        "produce implementation briefs and cannot change code."
      ==
    =/  prompt-hint=tape
      "Rename my MCP stack. Update the approval-boundary card."
    =/  capture-copy=tape
      ;:  weld
        "AI clients add card proposals here. Approval creates a card "
        "and adds it to the review queue."
      ==
    =/  history-copy=tape
      ;:  weld
        "Older completed captures remain available through bounded MCP "
        "inspection with seer/list-captures. Approved cards retain their source records."
      ==
    ;section
      ;div.page-head
        ;div.page-copy
          ;div.kicker: change request
          ;h1: Change Seer
          ;p.muted: {request-copy}
        ==
        ;div.stat
          ;div.count: {<open-change-count>}
          ;div.meta: open plans
        ==
      ==
      ;section.panel.command-panel
        ;div.form-head
          ;div.kicker: request → review
          ;h2: What should change?
          ;p.muted: {target-copy}
        ==
        ;+  (login-panel 'inbox')
        ;+
        ?~  available-models
          ;div.hidden;
        ;form.command-form
          =method   "post"
          =action   "/apps/seer/actions/request-change"
          =hx-post  "/apps/seer/actions/request-change"
          ;input(type "hidden", name "start", value "false");
          ;label
            ;span: instruction
            ;textarea(name "prompt", required "", placeholder prompt-hint);
          ==
          ;div.command-controls
            ;label
              ;span: target
              ;select(name "target")
                ;option(value "library"): My library
                ;option(value "desk"): Seer itself · brief only
              ==
            ==
            ;label
              ;span: plan with
              ;select(name "model", required "")
                ;*
                %+  turn  available-models
                |=  [model-id=@tas profile=assistant-model]
                ;option
                  =value  (tas-tape model-id)
                  =title  (trip description.profile)
                  ;+  ;/  (model-option-label profile)
                ==
              ==
            ==
            ;button(type "submit"): Create draft · attach sources next
          ==
        ==
      ==
      ;section#change-requests.change-list.section
        =hx-get      "/apps/seer/inbox"
        =hx-trigger  ?:(waiting "every 2s" "none")
        =hx-target   "#change-requests"
        =hx-select   "#change-requests"
        =hx-swap     "outerHTML"
        ;+
        ?~  requests
          ;div.hidden;
        ;div.change-list
          ;div.form-head
            ;div.kicker: review queue
            ;h2: Change requests
          ==
          ;*
          %+  turn  requests
          |=  [change-id=@tas request=change-request]
          (change-row change-id request)
        ==
      ==
      ;section.capture-history
        ;div.form-head
          ;div.kicker: card captures
          ;h2: Capture inbox
          ;p.muted: {capture-copy}
        ==
        ;details.reveal
          ;summary: Start a capture before generating proposals
          ;form
            =method   "post"
            =action   "/apps/seer/actions/begin-capture"
            =hx-post  "/apps/seer/actions/begin-capture"
            ;label
              ;span: capture title
              ;input(name "title", required "", maxlength "1024");
            ==
            ;label
              ;span: learning goal
              ;textarea(name "goal", required "", maxlength "131072");
            ==
            ;label
              ;span: source description · not evidence
              ;input(name "source", maxlength "1024");
            ==
            ;button(type "submit"): Create capture · attach evidence next
          ==
        ==
        ;+
        ?~  active.selected
          ;div.empty
            ;h2: Your inbox is clear
            ;p: Create a capture, attach sources, and freeze the packet before asking an MCP client to stage proposals.
            ;a.button.secondary(href "/apps/seer/stacks"): Open library
          ==
        ;div.capture-list
          ;*
          %+  turn  active.selected
          |=  [capture-id=@tas session=capture]
          (capture-section capture-id session)
        ==
      ==
      ;+
      ?:  =(0 completed.selected)
        ;div.hidden;
      ;section.capture-history
        ;div.form-head
          ;div.kicker: capture history
          ;h2: Recent captures
          ;p.muted: Showing {<shown>} of {<completed.selected>} completed captures · {<omitted>} omitted.
          ;p.muted: {history-copy}
        ==
        ;div.stack-list.section
          ;*
          %+  turn  recent.selected
          |=  [capture-id=@tas session=capture]
          (capture-history-row capture-id session)
        ==
      ==
      ;+  maintenance-panel
    ==
  ::
  ++  change-row
    |=  [change-id=@tas request=change-request]
    ^-  manx
    =/  active=?
      ?|  =(%pending status.request)
          =(%working status.request)
      ==
    =/  eyebrow=tape
      ?:  =(0 id.profile.request)
        "{(trip target.request)} · planner-submitted · no provider recorded"
      ;:  weld
        "{(trip target.request)} · "
        "{(role-name role.profile.request)} · "
        "{(trip label.profile.request)}"
      ==
    =/  change-tape=tape  (tas-tape change-id)
    =/  row-class=tape
      ?:  active
        "capture change-request is-thinking"
      "capture change-request"
    ;article
      =class  row-class
      ;div.capture-head
        ;div.capture-copy
          ;div.eyebrow
            ;+  ;/  eyebrow
          ==
          ;h3: {(trip prompt.request)}
          ;div.capture-meta
            ;span: {(tas-tape change-id)}
            ;span: {<(lent operations.request)>} operations
          ==
        ==
        ;span(class ?:(active "pill thinking-pill" "pill"))
          ;+  ;/  (trip status.request)
        ==
      ==
      ;div.proposal-body.change-body
        ;+  (work-panel [%change our %root change-id] 'inbox')
        ;+  (packet-panel packet.request citations.request)
        ;+  ?:  =(0 id.profile.request)  ;span.hidden;
            (learning-panel [%change change-id] prompt.request provider.profile.request)
        ;+
        ?-  status.request
          %draft
            ;div
              ;p.muted: Attach and authorize sources before generation. No provider invocation has started.
              ;+  (work-context-panel [%change change-id])
              ;form.inline
                =method   "post"
                =action   "/apps/seer/actions/start-change"
                =hx-post  "/apps/seer/actions/start-change"
                ;input(type "hidden", name "change-id", value change-tape);
                ;button(type "submit"): Generate plan · potentially billable
              ==
            ==
          %pending
            %-  thinking-indicator
            "Wait for the local bridge to claim this request."
          %working
            %-  thinking-indicator
            "Wait while {(trip label.profile.request)} creates a plan."
          %ready
            (change-ready change-id request)
          %failed
            ;div
              ;div.proposal-conflict: {(trip response.request)}
              ;p.muted: First reconcile the receipt and external outcome below. A new attempt is not a replay and may incur another charge.
              ;+  (work-context-panel [%change change-id])
              ;div.decision-row
                ;form.inline
                  =method   "post"
                  =action   "/apps/seer/actions/retry-change"
                  =hx-post  "/apps/seer/actions/retry-change"
                  ;input(type "hidden", name "change-id", value change-tape);
                  ;button.secondary(type "submit"): Start new attempt · potentially billable
                ==
                ;form.inline
                  =method   "post"
                  =action   "/apps/seer/actions/reject-change"
                  =hx-post  "/apps/seer/actions/reject-change"
                  ;input(type "hidden", name "change-id", value change-tape);
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
  ++  change-ready
    |=  [change-id=@tas request=change-request]
    ^-  manx
    =/  preview
      %:  validate-plan:effects
        our  updated-at.request  stacks  versions.control
        operations.request  preconditions.request
      ==
    =/  projection  (preview-json:effects preview 262.144)
    ;div
      ;p.meta: Proposed summary · awaiting operator review, not applied
      ;div.proposal-answer: {(trip summary.request)}
      ;+
      ?:  =(%desk target.request)
        ;div.provenance
          ;p: Implementation brief only. No code is changed, installed, or deployed.
          ;details.reveal
            ;summary: Inspect implementation brief
            ;div.proposal-answer: {(trip artifact.request)}
          ==
        ==
      (effect-panel preview projection)
      ;+  ?.  ?&  =(%library target.request)
                  !=(plan.request `digest.preview)
              ==
            ;span.hidden;
          ;p.proposal-conflict: The stored plan digest does not match this preview. No effect is authorized; reject and request a new plan.
      ;div.decision-row
        ;form.inline
          =method   "post"
          =action   "/apps/seer/actions/reject-change"
          =hx-post  "/apps/seer/actions/reject-change"
          ;input(type "hidden", name "change-id", value (tas-tape change-id));
          ;button.danger(type "submit"): Reject
        ==
        ;+
        ?.  ?&  =(%library target.request)
                =(%ok status.preview)
                =(plan.request `digest.preview)
                (projection-complete projection)
            ==
          ;span.pill: no library effect authorized
        ;form.inline
          =method   "post"
          =action   "/apps/seer/actions/apply-change"
          =hx-post  "/apps/seer/actions/apply-change"
          ;input(type "hidden", name "change-id", value (tas-tape change-id));
          ;input(type "hidden", name "digest", value (scow %ux digest.preview));
          ;button(type "submit"): Approve this exact diff
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
    =/  clear-confirm=tape
      "Reject every remaining proposal in this capture?"
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
        ;form.inline
          =hx-confirm  clear-confirm
          =method      "post"
          =action      "/apps/seer/actions/discard-capture"
          =hx-post     "/apps/seer/actions/discard-capture"
          ;input(type "hidden", name "capture", value (tas-tape capture-id));
          ;button.danger(type "submit"): Clear
        ==
      ==
      ;+  (work-context-panel [%capture capture-id])
      ;+  (scope-learning-panel [%capture capture-id])
      ;+  (capture-packet-form capture-id)
      ;+  (packet-panel packet.session ~)
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
    =/  preview
      (proposal-preview:effects our created-at.draft stacks versions.control draft)
    =/  projection  (preview-json:effects preview 262.144)
    =/  conflict=?
      ?|(!=(%ok status.preview) !(projection-complete projection))
    =/  proposal-tape=tape  (tas-tape proposal-id)
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
          ;p: Generated rationale · {(trip rationale.draft)}
          ;p: Declared source · {(trip source.draft)}
          ;p: Learning objective · {(trip objective.draft)}
          ;p: Generated claim · {(trip claim.draft)}
          ;p: Why a new card · {(trip why-new.draft)}
          ;p: Caveat · {(trip caveat.draft)}
        ==
        ;+  (packet-panel packet.draft citations.draft)
        ;+  (effect-panel preview projection)
        ;+  ?~  packet.draft  ;div.hidden;
            =/  packet  (~(get by packets.evidence) u.packet.draft)
            ?~  packet  ;div.hidden;
            (learning-panel [%capture capture-id] objective.draft provider.profile.request.u.packet)
        ;div.decision-row
          ;form.inline
            =method   "post"
            =action   "/apps/seer/actions/reject-proposal"
            =hx-post  "/apps/seer/actions/reject-proposal"
            ;input(type "hidden", name "capture", value (tas-tape capture-id));
            ;input(type "hidden", name "proposal", value proposal-tape);
            ;label
              ;span: rejection reason · optional
              ;input(name "reason", maxlength "1024");
            ==
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
            ;input(type "hidden", name "proposal", value proposal-tape);
            ;input(type "hidden", name "digest", value (scow %ux digest.preview));
            ;button(type "submit"): Approve card
          ==
        ==
      ==
    ==
  ::
  ++  capture-history-row
    |=  [capture-id=@tas session=capture]
    ^-  manx
    =/  history-meta=tape
      ;:  weld
        "{(tas-tape capture-id)} · "
        "{(trip created-by.session)} · "
        "{(trip source.session)}"
      ==
    ;article.stack-row
      ;div.stack-link
        ;div.stack-name
          ;h3: {(trip title.session)}
          ;div.meta: {history-meta}
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
    ?~  reviews
      review-empty
    ;section.review-session
      =data-review     ""
      =data-remaining  "{<total>}"
      ;header.session-bar
        ;h1.session-title: Review
        ;p.session-tally
          ;span.tally-done(data-done "", hidden "");
          ;span.tally-left: {<total>} to go
        ==
      ==
      ;div.session-progress(data-progress "", hidden "", aria-hidden "true")
        ;div.session-progress-fill(data-progress-fill "");
      ==
      ;+  (review-card i.reviews)
      ;p.key-line
        ;span: space to flip · 1–4 to grade ·
        ;button.linkish(type "button", data-help-open ""): ? shortcuts
      ==
    ==
  ::
  ++  review-empty
    ^-  manx
    =/  fresh-copy=tape
      ;:  weld
        "Every card is scheduled. Cards you miss return here "
        "on their own."
      ==
    ;section.review-session
      =data-review     ""
      =data-remaining  "0"
      =hx-get          "/apps/seer/review"
      =hx-trigger      "every 5s"
      =hx-target       "#seer-app"
      =hx-select       "#seer-app"
      =hx-swap         "outerHTML"
      ;header.session-bar
        ;h1.session-title: Review
      ==
      ;div.review-done
        ;div.done-block(data-fresh "")
          ;h2.done-title: Nothing to review
          ;p.done-copy: {fresh-copy}
          ;a.button.secondary(href "/apps/seer/stacks"): Open library
        ==
        ;div.done-block(data-complete "", hidden "")
          ;h2.done-title: Session complete
          ;p.done-copy(data-complete-line "");
          ;a.button.secondary(href "/apps/seer/stacks"): Open library
        ==
      ==
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
    =/  card-key=tape
      ;:  weld
        "{(scow %p who.rev)}|"
        "{(tas-tape stack.rev)}|"
        "{(tas-tape item.rev)}"
      ==
    =/  origin=tape
      ?:  =(who.rev our)
        (stack-title u.maybe-stack)
      "{(stack-title u.maybe-stack)} · {(scow %p who.rev)}"
    ;div
      ;article.review-card
        =data-review-card  ""
        =tabindex          "-1"
        =aria-label        (trip title.content.current)
        ;header.review-top
          ;div.review-origin
            ;strong.review-title: {(trip title.content.current)}
            ;span.review-stack: {origin}
          ==
          ;span.pill: box {<box.learn.current>}
        ==
        ;div.review-prompt: {(trip (body-text front.content.current))}
        ;details.flip
          =data-persist  "reveal|{card-key}"
          ;summary.flip-bar
            ;span.flip-show: Show answer
            ;span.flip-hide: Hide answer
            ;kbd.key-hint: space
          ==
          ;div.review-answer: {(trip (body-text back.content.current))}
          ;div.grade-row
            ;+  (grade-form rev "again" "Again" "1")
            ;+  (grade-form rev "hard" "Hard" "2")
            ;+  (grade-form rev "good" "Good" "3")
            ;+  (grade-form rev "easy" "Easy" "4")
          ==
        ==
      ==
      ;+  (review-assistant rev)
    ==
  ::
  ++  review-assistant
    |=  rev=review
    ^-  manx
    =/  rows=(list [@tas card-question])
      (card-questions who.rev stack.rev item.rev)
    =/  waiting=?  (questions-waiting rows)
    =/  card-key=tape
      ;:  weld
        "{(scow %p who.rev)}|"
        "{(tas-tape stack.rev)}|"
        "{(tas-tape item.rev)}"
      ==
    =/  attrs=mart
      :*  [%class "assistant"]
          [%data-persist "assist|{card-key}"]
          ?:(?=(^ rows) [[%open ""] ~] ~)
      ==
    :-  [%details attrs]
    :~
      ;summary.assistant-bar
        ;span.assistant-label: Assistant
        ;+  ?:  waiting
              ;span.pill.thinking-pill: thinking
            ?:  ?=(^ rows)
              ;span.pill: {<(lent rows)>} asked
            ;kbd.key-hint: i
      ==
      ;div.assistant-body
        ;+
        %:  question-panel
          who.rev
          stack.rev
          item.rev
          "/apps/seer/review"
          'review'
          %.n
        ==
      ==
    ==
  ::
  ++  key-help
    ^-  manx
    ;dialog.key-help
      =data-key-help  ""
      =aria-label     "Keyboard shortcuts"
      ;h2.key-title: Keyboard
      ;dl.key-list
        ;div.key-row
          ;dt
            ;kbd.key: space
          ==
          ;dd: Show the answer, then grade Good
        ==
        ;div.key-row
          ;dt
            ;kbd.key: 1
            ;kbd.key: 2
            ;kbd.key: 3
            ;kbd.key: 4
          ==
          ;dd: Again · Hard · Good · Easy
        ==
        ;div.key-row
          ;dt
            ;kbd.key: j
            ;kbd.key: k
          ==
          ;dd: Next · previous item or disclosure
        ==
        ;div.key-row
          ;dt
            ;kbd.key: l
            ;kbd.key: h
            ;kbd.key: o
          ==
          ;dd: Open · close · toggle focused disclosure
        ==
        ;div.key-row
          ;dt
            ;kbd.key: J
            ;kbd.key: K
            ;kbd.key: d
            ;kbd.key: u
          ==
          ;dd: Scroll line · half page
        ==
        ;div.key-row
          ;dt
            ;kbd.key: g g
            ;kbd.key: g b
            ;kbd.key: G
          ==
          ;dd: Jump to top · bottom
        ==
        ;div.key-row
          ;dt
            ;kbd.key: g r
            ;kbd.key: g i
            ;kbd.key: g l
            ;kbd.key: g s
          ==
          ;dd: Review · Inbox · Library · Shared
        ==
        ;div.key-row
          ;dt
            ;kbd.key: z a
            ;kbd.key: z o
            ;kbd.key: z c
            ;kbd.key: z R
            ;kbd.key: z M
          ==
          ;dd: Toggle · open · close · expand all · collapse all
        ==
        ;div.key-row
          ;dt
            ;kbd.key: i
            ;kbd.key: g a
          ==
          ;dd: Enter focused form · open Assistant
        ==
        ;div.key-row
          ;dt
            ;kbd.key: esc
          ==
          ;dd: Hide answer · leave a field
        ==
        ;div.key-row
          ;dt
            ;kbd.key: ?
          ==
          ;dd: Open · close this help
        ==
      ==
      ;form.key-close(method "dialog")
        ;button.secondary(type "submit"): Close
      ==
    ==
  ::
  ++  login-panel
    |=  return=@t
    ^-  manx
    =/  codex-request=(unit login-request)
      %+  choose-login-request
        (~(get by logins) %login-codex)
      (~(get by logins) %logout-codex)
    =/  claude-request=(unit login-request)
      %+  choose-login-request
        (~(get by logins) %login-claude)
      (~(get by logins) %logout-claude)
    =/  polling=?
      ?|  (login-request-active codex-request)
          (login-request-active claude-request)
      ==
    =/  poll-url=tape
      ?:  =('inbox' return)
        "/apps/seer/inbox"
      "/apps/seer/review"
    ;section.panel.form-panel.login-panel
      =hx-get      poll-url
      =hx-trigger  ?:(polling "every 2s" "none")
      =hx-target   "#seer-app"
      =hx-select   "#seer-app"
      =hx-swap     "outerHTML"
      ;div.form-head
        ;h3: Connect an assistant
        ;p.muted: Provider credentials stay on the local bridge machine.
      ==
      ;div.two
        ;+  (login-provider %codex "Codex" %login-codex codex-request return)
        ;+
        %:  login-provider
          %claude
          "Claude Code"
          %login-claude
          claude-request
          return
        ==
      ==
    ==
  ::
  ++  login-provider
    |=  $:  provider=ai-provider
            label=tape
            login-id=@tas
            request=(unit login-request)
            return=@t
        ==
    ^-  manx
    =/  connected=?  (provider-connected provider)
    ?~  request
      ?:  connected
        (login-connected-card provider label)
      (login-start-card provider label return)
    =/  req=login-request  u.request
    ?+  status.req
      ?:  connected
        (login-connected-card provider label)
      ?:  =(%failed status.req)
        (login-failed-card label req return (trip message.req))
      (login-start-card provider label return)
        %pending
      %:  login-status-card
        label
        req
        return
        "Waiting for the local bridge to claim this sign-in."
      ==
        %working
      %:  login-status-card
        label
        req
        return
        "The bridge is starting provider authorization."
      ==
        %challenge
      (login-challenge-card label req return)
    ==
  ::
  ++  login-start-card
    |=  [provider=ai-provider label=tape return=@t]
    ^-  manx
    ;form
      =method   "post"
      =action   "/apps/seer/actions/request-login"
      =hx-post  "/apps/seer/actions/request-login"
      =hx-swap  "outerHTML"
      ;input(type "hidden", name "provider", value (trip provider));
      ;input(type "hidden", name "return", value (trip return));
      ;button(type "submit"): Sign in to {label}
    ==
  ++  login-request-active
    |=  request=(unit login-request)
    ^-  ?
    ?~  request  %.n
    ?|  =(%pending status.u.request)
        =(%working status.u.request)
        =(%challenge status.u.request)
    ==
  ::
  ++  choose-login-request
    |=  [login=(unit login-request) logout=(unit login-request)]
    ^-  (unit login-request)
    ?:  (login-request-active login)  login
    ?:  (login-request-active logout)  logout
    ?:  ?=(^ logout)  logout
    login
  ::
  ++  provider-connected
    |=  wanted=ai-provider
    ^-  ?
    %+  lien  ~(val by models)
    |=  profile=assistant-model
    =(wanted provider.profile)
  ::
  ++  login-connected-card
    |=  [provider=ai-provider label=tape]
    ^-  manx
    ;article.panel
      ;h3: {label}
      ;p.muted: Connected through the local bridge.
      ;form
        =method   "post"
        =action   "/apps/seer/actions/request-logout"
        =hx-post  "/apps/seer/actions/request-logout"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "provider", value (trip provider));
        ;button.secondary(type "submit"): Sign out
      ==
    ==
  ::
  ++  login-status-card
    |=  [label=tape req=login-request return=@t message=tape]
    ^-  manx
    ;article.panel
      ;h3: {label}
      ;p.muted: {message}
      ;form
        =method   "post"
        =action   "/apps/seer/actions/cancel-login"
        =hx-post  "/apps/seer/actions/cancel-login"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;button.secondary(type "submit"): Cancel
      ==
    ==
  ::
  ++  login-failed-card
    |=  [label=tape req=login-request return=@t message=tape]
    ^-  manx
    ;article.panel
      ;h3: {label}
      ;p.muted: {message}
      ;form
        =method   "post"
        =action   "/apps/seer/actions/retry-login"
        =hx-post  "/apps/seer/actions/retry-login"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;button(type "submit"): Try again
      ==
      ;form
        =method   "post"
        =action   "/apps/seer/actions/cancel-login"
        =hx-post  "/apps/seer/actions/cancel-login"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;button.secondary(type "submit"): Cancel
      ==
    ==
  ::
  ++  login-challenge-card
    |=  [label=tape req=login-request return=@t]
    ^-  manx
    ?:  =(%claude provider.req)
      (claude-login-challenge label req return)
    (codex-login-challenge label req return)
  ::
  ++  codex-login-challenge
    |=  [label=tape req=login-request return=@t]
    ^-  manx
    ;article.panel
      ;h3: {label}
      ;p.muted: Open the provider page, then enter this one-time code.
      ;a.button.secondary
        =href    (trip auth-url.req)
        =target  "_blank"
        =rel     "noopener noreferrer"
        Open secure sign-in
      ==
      ;div.meta: {(trip user-code.req)}
      ;form
        =method   "post"
        =action   "/apps/seer/actions/cancel-login"
        =hx-post  "/apps/seer/actions/cancel-login"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;button.secondary(type "submit"): Cancel
      ==
    ==
  ::
  ++  claude-login-challenge
    |=  [label=tape req=login-request return=@t]
    ^-  manx
    =/  authorize-copy=tape
      ;:  weld
        "Open Anthropic sign-in, authorize the account, "
        "then paste the one-time code."
      ==
    =/  code-attrs=mart
      :~  [%name "code"]
          [%id (weld "login-code-" (trip id.req))]
          [%hx-preserve "true"]
          [%required ""]
          [%autocomplete "off"]
          [%spellcheck "false"]
          [%placeholder "Paste the one-time code"]
      ==
    ;article.panel
      ;h3: {label}
      ;p.muted: {authorize-copy}
      ;a.button.secondary
        =href    (trip auth-url.req)
        =target  "_blank"
        =rel     "noopener noreferrer"
        Open secure sign-in
      ==
      ;form
        =method   "post"
        =action   "/apps/seer/actions/submit-login-code"
        =hx-post  "/apps/seer/actions/submit-login-code"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;label
          ;span: authorization code
          ;+  [[%input code-attrs] ~]
        ==
        ;button(type "submit"): Send code to bridge
      ==
      ;form
        =method   "post"
        =action   "/apps/seer/actions/cancel-login"
        =hx-post  "/apps/seer/actions/cancel-login"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "login-id", value (trip id.req));
        ;input(type "hidden", name "return", value (trip return));
        ;button.secondary(type "submit"): Cancel
      ==
    ==
  ::
  ++  grade-form
    |=  [rev=review value=tape label=tape key=tape]
    ^-  manx
    ;form.grade
      =method           "post"
      =action           "/apps/seer/actions/answer"
      =hx-post          "/apps/seer/actions/answer"
      =hx-target        "#seer-app"
      =hx-select        "#seer-app"
      =hx-swap          "outerHTML show:top"
      =hx-disabled-elt  ".grade-row button"
      =data-grade       value
      ;input(type "hidden", name "owner", value (scow %p who.rev));
      ;input(type "hidden", name "stack", value (tas-tape stack.rev));
      ;input(type "hidden", name "item", value (tas-tape item.rev));
      ;input(type "hidden", name "answer", value value);
      ;button(type "submit", class (weld "grade-btn grade-" value))
        ;span.grade-name: {label}
        ;kbd.key-hint: {key}
      ==
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
            ;h2: No stacks
            ;p: Create a stack below to add cards.
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
          ;p.muted: Enter a stable stack ID and display name.
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
          ;p.muted: Enter a stable stack ID and display name.
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
      %+  sort  ~(tap by `(map @tas item)`items.stack)
      |=  [a=[@tas item] b=[@tas item]]
      (aor -.a -.b)
    ?~  rows
      ;div.empty: This stack has no cards.
    ;div.item-list
      ;*
      %+  turn  rows
      |=  [item-name=@tas =item]
      (item-row owner name item-name item)
    ==
  ::
  ++  shared-clay-panel
    |=  [owner=@p stack-name=@tas]
    ^-  manx
    =/  rows=(list [pax=path entry=shared-entry])  ~(tap by shared)
    =/  count=@ud  (lent rows)
    =/  owner-tape=tape  (scow %p owner)
    =/  stack-tape=tape  (tas-tape stack-name)
    =/  empty-copy=tape
      ;:  weld
        "Nothing shared yet. Share a desk-first path like "
        "/base/doc/notes/md."
      ==
    =/  path-attrs=mart
      :~  [%name "path"]
          [%maxlength "2048"]
          [%placeholder "/base/doc/notes/md"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;details.context-panel.shared-panel
      ;summary.context-summary
        ;span.context-summary-copy
          ;span.context-title: Shared with other ships
          ;span.context-purpose: Files any ship can read.
        ==
        ;span.context-count: {<count>} shared
      ==
      ;div.context-body
        ;+  ?~  rows
              ;p.context-empty: {empty-copy}
            ;ul.clay-browse
              ;*  %+  turn  rows
                  |=  [pax=path entry=shared-entry]
                  ^-  manx
                  ;li
                    ;span.clay-file: {(trip label.entry)}
                    ;form.inline
                      =method   "post"
                      =action   "/apps/seer/actions/unshare-clay-context"
                      =hx-post  "/apps/seer/actions/unshare-clay-context"
                      ;input(type "hidden", name "owner", value owner-tape);
                      ;input(type "hidden", name "stack", value stack-tape);
                      ;input(type "hidden", name "path", value (spud pax));
                      ;button.secondary(type "submit"): Unshare
                    ==
                  ==
            ==
        ;form.context-form
          =method   "post"
          =action   "/apps/seer/actions/share-clay-context"
          =hx-post  "/apps/seer/actions/share-clay-context"
          ;input(type "hidden", name "owner", value owner-tape);
          ;input(type "hidden", name "stack", value stack-tape);
          ;label
            ;span: desk-first path
            ;+  [[%input path-attrs] ~]
          ==
          ;button(type "submit"): Share publicly
        ==
      ==
    ==
  ::
  ++  stack-editor
    |=  [owner=@p name=@tas has-cards=?]
    ^-  manx
    ;div.editor-column
      ;+  (context-panel owner name ~)
      ;+
      ?.  =(owner our)
        ;div.hidden;
      (shared-clay-panel owner name)
      ;+
      ?.  =(owner our)
        ;div.hidden;
      ;div.editor-tools
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
          ;p.muted: Enter one prompt and the answer to remember.
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
    =/  name-attrs=mart
      :~  [%name "name"]
          [%required ""]
          [%pattern "[a-z0-9][a-z0-9-]*"]
          [%placeholder "urbit-basics"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;form
      =method   "post"
      =action   "/apps/seer/actions/new-stack"
      =hx-post  "/apps/seer/actions/new-stack"
      ;div.two
        ;label
          ;span: stack ID
          ;+  [[%input name-attrs] ~]
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
    =/  ship-attrs=mart
      :~  [%name "ship"]
          [%required ""]
          [%pattern "~[a-z-]+"]
          [%placeholder "~sampel-palnet"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    =/  stack-attrs=mart
      :~  [%name "stack"]
          [%required ""]
          [%pattern "[a-z0-9][a-z0-9-]*"]
          [%placeholder "urbit-basics"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;form
      =method   "post"
      =action   "/apps/seer/actions/import"
      =hx-post  "/apps/seer/actions/import"
      ;div.two
        ;label
          ;span: ship
          ;+  [[%input ship-attrs] ~]
        ==
        ;label
          ;span: stack
          ;+  [[%input stack-attrs] ~]
        ==
      ==
      ;button(type "submit"): Follow stack
    ==
  ::
  ++  add-card-form
    |=  name=@tas
    ^-  manx
    =/  card-attrs=mart
      :~  [%name "name"]
          [%required ""]
          [%pattern "[a-z0-9][a-z0-9-]*"]
          [%placeholder "what-is-nock"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;form
      =method   "post"
      =action   "/apps/seer/actions/new-item"
      =hx-post  "/apps/seer/actions/new-item"
      ;input(type "hidden", name "stack", value (tas-tape name));
      ;div.two
        ;label
          ;span: card ID
          ;+  [[%input card-attrs] ~]
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
    |=  [owner=@p stack-name=@tas item-name=@tas =item]
    ^-  manx
    =/  card-key=tape
      ;:  weld
        "{(scow %p owner)}|"
        "{(tas-tape stack-name)}|"
        "{(tas-tape item-name)}"
      ==
    ;details.item
      =data-persist  "card|{card-key}"
      ;summary.item-summary
        ;span.item-copy
          ;span.item-id: /{(tas-tape item-name)}
          ;span.item-title: {(trip title.content.item)}
        ==
        ;span.item-toggle(aria-hidden "true");
      ==
      ;div.item-detail
        ;div.card-content
          ;section.card-face
            ;div.eyebrow: front
            ;div.prompt: {(trip (body-text front.content.item))}
          ==
          ;section.card-face
            ;div.eyebrow: back
            ;div.answer: {(trip (body-text back.content.item))}
          ==
        ==
        ;+  (context-panel owner stack-name `item-name)
        ;+
        %:  question-panel
          owner
          stack-name
          item-name
          (stack-url owner stack-name)
          'stack'
          %.y
        ==
        ;+  (item-actions owner stack-name item-name)
      ==
    ==
  ::
  ++  context-panel
    |=  [owner=@p stack-name=@tas card=(unit @tas)]
    ^-  manx
    =/  rows=(list [@tas context-source])
      (scope-contexts owner stack-name card %.y)
    =/  waiting=?  (contexts-waiting rows)
    =/  scope-key=tape
      ?~(card "stack" "card|{(tas-tape u.card)}")
    =/  persist-key=tape
      "context|{(scow %p owner)}|{(tas-tape stack-name)}|{scope-key}"
    ?:  waiting
      ;details.context-panel
        =data-persist  persist-key
        =hx-get        (stack-url owner stack-name)
        =hx-trigger    "every 2s"
        =hx-target     "#seer-app"
        =hx-select     "#seer-app"
        =hx-swap       "outerHTML"
        ;*  (context-panel-body owner stack-name card rows)
      ==
    ;details.context-panel
      =data-persist  persist-key
      ;*  (context-panel-body owner stack-name card rows)
    ==
  ::
  ++  context-panel-body
    |=  $:  owner=@p
            stack-name=@tas
            card=(unit @tas)
            rows=(list [@tas context-source])
        ==
    ^-  (list manx)
    =/  card-scope=?  ?=(^ card)
    =/  count=@ud  (lent rows)
    =/  panel-title=tape  ?:(card-scope "Card context" "Stack context")
    =/  purpose=tape
      ?:  card-scope
        "Available only to prompts for this card."
      "Available to every card prompt in this stack."
    =/  empty-copy=tape
      ;:  weld
        "No context attached yet. Add a note, ship file, "
        "local file, or web page."
      ==
    =/  source-word=tape  ?:(=(count 1) "source" "sources")
    =/  attached=(set @t)
      %-  silt
      %+  turn  rows
      |=  [context-id=@tas source=context-source]
      ^-  @t
      locator.source
    :~
      ;summary.context-summary
        ;span.context-summary-copy
          ;span.context-title: {panel-title}
          ;span.context-purpose: {purpose}
        ==
        ;span.context-count: {<count>} {source-word}
      ==
      ;div.context-body
        ;+
        ?~  rows
          ;p.context-empty: {empty-copy}
        ;div.context-list
          ;*
          %+  turn  rows
          |=  [context-id=@tas source=context-source]
          (context-source-row context-id source attached)
        ==
        ;+  (context-source-form owner stack-name card)
      ==
    ==
  ::
  ++  context-source-row
    |=  [context-id=@tas source=context-source attached=(set @t)]
    ^-  manx
    =/  body  (context-body:seer source evidence)
    =/  members=(list @t)
      ?.  ?=(%stack -.scope.source)  ~
      ?~(body ~ (manifest-members u.body))
    =/  context-tape=tape  (tas-tape context-id)
    =/  gone-copy=tape  "source file removed · snapshot kept"
    =/  stale-copy=tape  "desk updated · refresh to re-read"
    =/  remove-confirm=tape  "Remove this source from future prompts?"
    =/  remove-label=tape  "Remove {(trip label.source)}"
    ;article.context-source
      ;div.context-source-copy
        ;div.context-source-head
          ;strong.context-source-title: {(trip label.source)}
          ;span.context-kind: {(context-kind-name kind.source)}
        ==
        ;+
        ?:  =(0 (met 3 locator.source))
          ;span.hidden;
        ;div.context-locator: {(trip locator.source)}
        ;div.context-source-status
          =data-status  (trip status.source)
          ;span: {(context-status-name status.source)}
        ==
        ;+  =/  badge  (~(get by stale) context-id)
            ?~  badge  ;span.hidden;
            ?:  =(%gone u.badge)
              ;span.context-stale(data-stale "gone"): {gone-copy}
            ;span.context-stale(data-stale "stale"): {stale-copy}
        ;+
        ?:  ?&  =(%failed status.source)
                !=(0 (met 3 error.source))
            ==
          ;div.context-source-status(data-status "failed")
            ;+  ;/  (trip error.source)
          ==
        ;span.hidden;
        ;+  ?~  members  ;span.hidden;
            (member-list source attached members)
        ;+  (context-policy source)
        ;+  (work-panel [%context our %root context-id] 'inbox')
      ==
      ;div.context-source-actions
        ;+  ?.  =(%failed status.source)  ;span.hidden;
            ;form.inline
              =method   "post"
              =action   "/apps/seer/actions/retry-context-source"
              =hx-post  "/apps/seer/actions/retry-context-source"
              ;input(type "hidden", name "context-id", value context-tape);
              ;*  (context-return-fields scope.source)
              ;button.secondary(type "submit"): Start new acquisition attempt
            ==
        ;+  ?.  ?&  =(%clay kind.source)
                    !=(%pending status.source)
                ==
              ;span.hidden;
            ;form.inline
              =method   "post"
              =action   "/apps/seer/actions/refresh-context-source"
              =hx-post  "/apps/seer/actions/refresh-context-source"
              ;input(type "hidden", name "context-id", value context-tape);
              ;*  (context-return-fields scope.source)
              ;button.secondary(type "submit"): Refresh
            ==
        ;form.inline
          =hx-confirm  remove-confirm
          =method      "post"
          =action      "/apps/seer/actions/remove-context-source"
          =hx-post     "/apps/seer/actions/remove-context-source"
          ;input(type "hidden", name "context-id", value context-tape);
          ;*  (context-return-fields scope.source)
          ;button.icon-button
            =type        "submit"
            =title       "Remove this source"
            =aria-label  remove-label
            ;+  ;/  "×"
          ==
        ==
      ==
    ==
  ::
  ::  +manifest-members: the paths a listing source names. a listing
  ::  carries no file bodies, so each path is offered for attachment.
  ::
  ++  manifest-members
    |=  content=@t
    ^-  (list @t)
    =/  lines=(list @t)  (to-wain:format content)
    ?~  lines  ~
    ?.  =('=== listing ' (end [3 12] i.lines))  ~
    %+  skim  t.lines
    |=  line=@t
    =('/' (end 3 line))
  ::
  ++  member-list
    |=  [source=context-source attached=(set @t) members=(list @t)]
    ^-  manx
    =/  total=@ud  (lent members)
    =/  shown=(list @t)  (scag 200 `(list @t)`members)
    =/  summary-copy=tape
      ?:  =(total (lent shown))
        "{<total>} files · attach the ones you need"
      "{<(lent shown)>} of {<total>} files · attach the ones you need"
    ;details.context-members
      ;summary.context-members-summary
        ;+  ;/  summary-copy
      ==
      ;div.context-member-list
        ;*  %+  turn  shown
            |=  member=@t
            (member-row source attached member)
      ==
    ==
  ::
  ++  member-row
    |=  [source=context-source attached=(set @t) member=@t]
    ^-  manx
    ?>  ?=(%stack -.scope.source)
    =/  loc=@t  (cat 3 locator.source member)
    =/  card-value=tape  ?~(card.scope.source "" (tas-tape u.card.scope.source))
    ;div.context-member
      ;span.context-member-path: {(trip member)}
      ;+  ?:  (~(has in attached) loc)
            ;span.context-member-on: attached
          ;form.inline
            =method   "post"
            =action   "/apps/seer/actions/add-context-source"
            =hx-post  "/apps/seer/actions/add-context-source"
            ;input(type "hidden", name "owner", value (scow %p owner.scope.source));
            ;input(type "hidden", name "stack", value (tas-tape stack.scope.source));
            ;input(type "hidden", name "card", value card-value);
            ;input(type "hidden", name "kind", value "clay");
            ;input(type "hidden", name "locator", value (trip loc));
            ;button.icon-button
              =type        "submit"
              =title       "Attach this file"
              =aria-label  "Attach {(trip member)}"
              ;+  ;/  "+"
            ==
          ==
    ==
  ::
  ++  clay-picker-block
    |=  $:  card=(unit @tas)
            clay-active=?
            page-base=tape
            owner=@p
            stack-name=@tas
        ==
    ^-  manx
    ?^  card  ;span.hidden;
    =/  sel-desk=@t
      =/  from-page=@t
        ?:  ?=(%stack-browse -.page)
          desk.page
        ''
      ?.  =('' from-page)  from-page
      ?~  recents  ''
      =/  segs=(unit path)
        %+  rush  i.recents
        ;~(pfix fas (more fas (cook crip (star ;~(less fas prn)))))
      ?~  segs  ''
      ?.  ?=([@ @ *] u.segs)  ''
      `@t`i.t.u.segs
    =/  q-val=tape
      ?:(?=(%stack-browse -.page) (trip q.page) "")
    =/  search-attrs=mart
      :~  [%name "q"]
          [%value q-val]
          [%placeholder "type to filter"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;div.clay-picker
      =data-clay-picker  ""
      ;form.clay-search
        =method      "get"
        =action      page-base
        =hx-get      "/apps/seer/clay-browse"
        =hx-target   "#clay-results-box"
        =hx-swap     "innerHTML"
        =hx-select   "ul.clay-results"
        =hx-trigger  "submit, change from:find select"
        ;input(type "hidden", name "return", value page-base);
        ;label
          ;span: desk
          ;select(name "desk")
            ;option(value ""): choose a desk
            ;*  %+  turn  desks
                |=  dek=@tas
                ^-  manx
                ?:  =(sel-desk dek)
                  ;option(value (trip dek), selected ""): {(trip dek)}
                ;option(value (trip dek)): {(trip dek)}
          ==
        ==
        ;label
          ;span: search
          ;+  [[%input search-attrs] ~]
        ==
        ;noscript
          ;button.secondary(type "submit"): Load files
        ==
      ==
      ;div#clay-results-box
        ;+  ?~  picker  ;span.hidden;
            (clay-results our page-base [dek total files]:u.picker)
      ==
      ;+  (remote-clay-panel clay-active page-base owner stack-name)
    ==
  ::
  ++  remote-clay-panel
    |=  [clay-active=? page-base=tape owner=@p stack-name=@tas]
    ^-  manx
    =/  remote-value=tape
      ?:  &(clay-active ?=(%stack-browse -.page))
        (trip remote.page)
      ""
    =/  rship=(unit @p)
      ?:  =("" remote-value)  ~
      (slaw %p (crip remote-value))
    =/  unreachable-copy=tape
      ;:  weld
        "{remote-value} shares nothing there, or it could not "
        "be reached. Try again in a moment."
      ==
    =/  ship-attrs=mart
      :~  [%name "ship"]
          [%value remote-value]
          [%placeholder "~sampel-palnet"]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    ;div.clay-remote
      ;form.inline
        =method   "post"
        =action   "/apps/seer/actions/browse-remote-manifest"
        =hx-post  "/apps/seer/actions/browse-remote-manifest"
        ;input(type "hidden", name "owner", value (scow %p owner));
        ;input(type "hidden", name "stack", value (tas-tape stack-name));
        ;label
          ;span: another ship's shared files
          ;+  [[%input ship-attrs] ~]
        ==
        ;button.secondary(type "submit"): Browse ship
      ==
      ;+  ?~  rship  ;span.hidden;
          =/  entry  (~(get by remotes) u.rship)
          =/  poll-url=tape  "{page-base}?remote={remote-value}"
          ?:  ?|  ?=(~ entry)
                  &(=(0 rev.u.entry) =(*@da at.u.entry))
              ==
            ;p.muted: {unreachable-copy}
          ?:  =(0 rev.u.entry)
            ;div.clay-remote-loading
              =hx-get      poll-url
              =hx-trigger  "every 2s"
              =hx-target   "#seer-app"
              =hx-select   "#seer-app"
              =hx-swap     "outerHTML"
              ;p.muted
                ; Asking {remote-value} for its shared files...
                ;a(href poll-url): Check again
              ==
            ==
          ?~  entries.u.entry
            ;p.muted: {remote-value} shares nothing right now.
          ;ul.clay-browse
            ;*  %+  turn  entries.u.entry
                |=  [pax=path label=@t mark=@tas size=@ud]
                ^-  manx
                =/  loc=tape  "/{remote-value}{(spud pax)}"
                ;li
                  ;a.clay-file
                    =href          "{page-base}?pick={loc}"
                    =data-locator  loc
                    =hx-boost      "false"
                    ;+  ;/  (trip label)
                  ==
                ==
          ==
    ==
  ::
  ++  context-source-form
    |=  [owner=@p stack-name=@tas card=(unit @tas)]
    ^-  manx
    =/  card-value=tape  ?~(card "" (tas-tape u.card))
    =/  clay-active=?
      ?&  ?=(%stack-browse -.page)
          ?=(~ card)
          =(owner owner.page)
          =(stack-name name.page)
      ==
    =/  pick-value=tape
      ?:  &(clay-active ?=(%stack-browse -.page))
        (trip pick.page)
      ""
    =/  page-base=tape
      "/apps/seer/stack/{(trip (scot %p owner))}/{(tas-tape stack-name)}"
    =/  clay-example=tape
      "/{(trip (scot %p our))}/base/gen/hood/hi/hoon"
    =/  owner-tape=tape  (scow %p owner)
    =/  stack-tape=tape  (tas-tape stack-name)
    =/  note-attrs=mart
      :~  [%name "content"]
          [%maxlength "131072"]
          :-  %placeholder
          ;:  weld
            "Paste the facts, constraints, examples, or background "
            "this assistant should carry."
          ==
      ==
    =/  locator-attrs=mart
      :~  [%name "locator"]
          [%maxlength "2048"]
          [%value pick-value]
          [%placeholder clay-example]
          [%autocomplete "off"]
          [%autocapitalize "none"]
          [%spellcheck "false"]
      ==
    =/  accept-types=tape
      ;:  weld
        ".txt,.md,.markdown,.org,.json,.csv,.tsv,.html,.htm,"
        ".xml,.hoon,.js,.mjs,.ts,.tsx,.jsx,.py,.rs,.go,.toml,"
        ".yaml,.yml,text/*,application/json"
      ==
    =/  file-attrs=mart
      :~  [%type "file"]
          [%data-context-file ""]
          [%disabled ""]
          [%accept accept-types]
      ==
    =/  noscript-copy=tape
      ;:  weld
        "Local file upload needs the inline script. "
        "Use Note or Ship file instead."
      ==
    =/  hidden-locator-attrs=mart
      :~  [%type "hidden"]
          [%name "locator"]
          [%disabled ""]
          [%data-context-file-locator ""]
      ==
    =/  hidden-content-attrs=mart
      :~  [%name "content"]
          [%hidden ""]
          [%disabled ""]
          [%data-context-file-content ""]
      ==
    =/  web-attrs=mart
      :~  [%type "url"]
          [%name "web-locator"]
          [%maxlength "2048"]
          [%placeholder "https://example.com/reference"]
      ==
    =/  web-copy=tape
      ;:  weld
        "The paired bridge fetches readable text and stores "
        "the snapshot on this ship."
      ==
    =/  form-body=manx
      ;form.context-form
        =data-context-form  ""
        =method             "post"
        =action             "/apps/seer/actions/add-context-source"
        =hx-post            "/apps/seer/actions/add-context-source"
        ;input(type "hidden", name "owner", value owner-tape);
        ;input(type "hidden", name "stack", value stack-tape);
        ;input(type "hidden", name "card", value card-value);
        ;div.context-type-row
          ;label
            ;span: source
            ;select
              =name               "kind"
              =data-context-type  ""
              ;option(value "note"): Note
              ;+  ?.  clay-active
                    ;option(value "clay"): Ship file
                  ;option(value "clay", selected ""): Ship file
              ;option(value "file"): Local file
              ;option(value "web"): Web page
            ==
          ==
          ;label
            ;span: name · optional
            ;input(name "label", maxlength "240", placeholder "Research notes");
          ==
        ==
        ;div.context-fields(data-context-kind "note")
          ;label
            ;span: context
            ;+  [[%textarea note-attrs] ~]
          ==
        ==
        ;div.context-fields
          =data-context-kind  "clay"
          ;label
            ;span: ship file path
            ;+  [[%input locator-attrs] ~]
          ==
          ;+  ?~  recents  ;span.hidden;
              ;div.clay-recents
                ;*  %+  turn  recents
                    |=  loc=@t
                    ^-  manx
                    ;a.clay-file
                      =href          "{page-base}?pick={(trip loc)}"
                      =data-locator  (trip loc)
                      =hx-boost      "false"
                      ;+  ;/  (trip loc)
                    ==
              ==
          ;p.muted: Attach a text file from any desk on this ship.
        ==
        ;div.context-fields
          =data-context-kind  "file"
          =hidden             ""
          ;label.context-file-input
            ;span: local text file · 128 KB max
            ;+  [[%input file-attrs] ~]
            ;span(data-context-file-status "", aria-live "polite");
          ==
          ;noscript
            ;p.muted: {noscript-copy}
          ==
          ;+  [[%input hidden-locator-attrs] ~]
          ;+  [[%textarea hidden-content-attrs] ~]
        ==
        ;div.context-fields
          =data-context-kind  "web"
          ;label
            ;span: public URL
            ;+  [[%input web-attrs] ~]
          ==
          ;p.muted: {web-copy}
        ==
        ;button(type "submit", data-context-submit ""): Add note
      ==
    ?:  clay-active
      ;details.context-add
        =open  ""
        ;summary: Add source
        ;+  form-body
        ;+  (clay-picker-block card clay-active page-base owner stack-name)
      ==
    ;details.context-add
      ;summary: Add source
      ;+  form-body
      ;+  (clay-picker-block card clay-active page-base owner stack-name)
    ==
  ::
  ++  question-panel
    |=  $:  owner=@p
            stack-name=@tas
            item-name=@tas
            poll-url=tape
            return=@t
            chrome=?
        ==
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
        ;+  (question-panel-body owner stack-name item-name return rows chrome)
      ==
    ;section.ai-card
      ;+  (question-panel-body owner stack-name item-name return rows chrome)
    ==
  ::
  ++  question-panel-body
    |=  $:  owner=@p
            stack-name=@tas
            item-name=@tas
            return=@t
            rows=(list [@tas card-question])
            chrome=?
        ==
    ^-  manx
    =/  available-models=(list [@tas assistant-model])
      ordered-assistant-models
    =/  prompt-sources=(list [@tas context-source])
      (prompt-contexts owner stack-name item-name)
    =/  no-model-copy=tape
      ;:  weld
        "No assistant model is available. "
        "Open Review to connect a provider."
      ==
    =/  question-attrs=mart
      :~  [%name "question"]
          [%required ""]
          [%placeholder "Enter a question or edit instruction."]
          [%id (weld "ask-" (tas-tape item-name))]
          [%hx-preserve "true"]
      ==
    ;div
      ;+
      ?.  chrome
        ;div.hidden;
      ;div.ai-head
        ;div
          ;div.eyebrow: assistant
          ;h3: Card assistant
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
      ;+  (scope-learning-panel [%stack owner stack-name `item-name])
      ;+
      ?~  available-models
        ?:  =('review' return)
          ;div
            ;+  (login-panel 'review')
          ==
        ;div.ai-model-empty.section: {no-model-copy}
      ;form.ai-form.section
        =method   "post"
        =action   "/apps/seer/actions/ask-card"
        =hx-post  "/apps/seer/actions/ask-card"
        =hx-swap  "outerHTML"
        ;input(type "hidden", name "owner", value (scow %p owner));
        ;input(type "hidden", name "stack", value (tas-tape stack-name));
        ;input(type "hidden", name "item", value (tas-tape item-name));
        ;input(type "hidden", name "return", value (trip return));
        ;+  (context-picker prompt-sources)
        ;+  packet-budget-fields
        ;p.muted: The selected provider receives the frozen card, request, and authorized excerpts. Ask is read-only; Edit authorizes one revision-fenced change to this card, not a plan awaiting approval.
        ;p.muted: A provider invocation may be billable. Unsupported provider adapters fail closed; account sign-in alone does not establish safe generation support.
        ;div.ai-form-row
          ;label
            ;span: action
            ;select(name "mode")
              ;option(value "ask"): Ask
              ;+
              ?:  =(owner our)
                ;option(value "edit"): Edit
              ;option(value "edit", disabled ""): Edit · local cards only
            ==
          ==
          ;label
            ;span: request
            ;+  [[%textarea question-attrs] ~]
          ==
          ;label
            ;span: answer with
            ;select(name "model", required "")
              ;*
              %+  turn  available-models
              |=  [model-id=@tas profile=assistant-model]
              ;option
                =value  (tas-tape model-id)
                =title  (trip description.profile)
                ;+  ;/  (model-option-label profile)
              ==
            ==
          ==
          ;button(type "submit"): Send · potentially billable
        ==
      ==
    ==
  ::
  ++  context-picker
    |=  rows=(list [@tas context-source])
    ^-  manx
    ?~  rows
      ;div.hidden;
    =/  count=@ud  (lent rows)
    ;fieldset.context-picker
      ;legend: Select evidence · {<count>} available sources
      ;div.context-choice-list
        ;*
        %+  turn  rows
        |=  [context-id=@tas source=context-source]
        =/  scope=tape
          ?.  ?=(%stack -.scope.source)  (trip -.scope.source)
          ?~(card.scope.source "stack" "card")
        =/  choice-attrs=mart
          :~  [%type "checkbox"]
              [%name (weld "context-" (tas-tape context-id))]
              [%value "1"]
              [%checked ""]
          ==
        ;label.context-choice(title (trip locator.source))
          ;+  [[%input choice-attrs] ~]
          ;span: {(trip label.source)}
          ;span.context-scope: {scope}
          ;span.context-scope: {(context-status-name status.source)}
        ==
      ==
    ==
  ::
  ++  question-row
    |=  [question-id=@tas job=card-question return=@t]
    ^-  manx
    =/  active=?
      ?|  =(%pending status.job)
          =(%working status.job)
      ==
    =/  packet=(unit context-packet)
      ?~  packet.job  ~
      (~(get by packets.evidence) u.packet.job)
    =/  context-count=@ud  ?~(packet 0 (lent entries.u.packet))
    =/  question-tape=tape  (tas-tape question-id)
    =/  context-meta=tape
      ?:  =(context-count 0)  ""
      ?:  =(context-count 1)
        " · 1 source"
      " · {<context-count>} sources"
    =/  head-meta=tape
      ;:  weld
        "{(trip mode.job)} · "
        "{(role-name role.profile.job)} · "
        "{(trip label.profile.job)}"
        context-meta
      ==
    ;article
      =class  ?:(active "ai-turn is-thinking" "ai-turn")
      ;div.ai-head
        ;div.meta: {head-meta}
        ;span(class ?:(active "pill thinking-pill" "pill")): {?:(=(%answered status.job) "answer-ready · inspect receipt for effects" (trip status.job))}
      ==
      ;div.ai-question: {(trip prompt.job)}
      ;+  (work-panel [%question our %root question-id] return)
      ;+  (packet-panel packet.job citations.job)
      ;+  (learning-panel [%stack owner.job stack.job `card.job] prompt.job provider.profile.job)
      ;+
      ?-  status.job
        %pending
          (thinking-indicator "Wait for the local bridge.")
        %working
          ?:  =(%edit mode.job)
            %-  thinking-indicator
            "Wait while {(trip label.profile.job)} revises this card."
          %-  thinking-indicator
          "Wait while {(trip label.profile.job)} prepares an answer."
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
            ;p.muted: Reconcile the receipt first. A new attempt is not a replay and may repeat billable work when the external outcome is unknown.
            ;div.item-actions
              ;form.inline
                =method   "post"
                =action   "/apps/seer/actions/retry-card-question"
                =hx-post  "/apps/seer/actions/retry-card-question"
                =hx-swap  "outerHTML"
                ;input(type "hidden", name "question-id", value question-tape);
                ;input(type "hidden", name "owner", value (scow %p owner.job));
                ;input(type "hidden", name "stack", value (tas-tape stack.job));
                ;input(type "hidden", name "return", value (trip return));
                ;button.secondary(type "submit"): Start new attempt · potentially billable
              ==
              ;form.inline
                =method   "post"
                =action   "/apps/seer/actions/delete-card-question"
                =hx-post  "/apps/seer/actions/delete-card-question"
                =hx-swap  "outerHTML"
                ;input(type "hidden", name "question-id", value question-tape);
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
  ++  thinking-indicator
    |=  message=tape
    ^-  manx
    ;div.ai-waiting(role "status", aria-live "polite")
      ;span.thinking-dots(aria-hidden "true")
        ;span;
        ;span;
        ;span;
      ==
      ;span: {message}
    ==
  ::
  ++  scope-contexts
    |=  [owner=@p stack-name=@tas card=(unit @tas) exact=?]
    ^-  (list [@tas context-source])
    =/  matched=(list [@tas context-source])
      %+  skim  ~(tap by contexts)
      |=  [context-id=@tas source=context-source]
      ?.  ?=(%stack -.scope.source)  %.n
      ?&  active.source
          ?:  exact
            =([%stack owner stack-name card] scope.source)
          (scope-applies:ev scope.source [%stack owner stack-name card])
      ==
    %+  sort  matched
    |=  [a=[@tas context-source] b=[@tas context-source]]
    ?:  =(created-at.+.a created-at.+.b)
      (gth -.a -.b)
    (gth created-at.+.a created-at.+.b)
  ::
  ++  prompt-contexts
    |=  [owner=@p stack-name=@tas item-name=@tas]
    ^-  (list [@tas context-source])
    (scope-contexts owner stack-name `item-name %.n)
  ::
  ++  contexts-waiting
    |=  rows=(list [@tas context-source])
    ^-  ?
    ?~  rows  %.n
    ?|  =(%pending status.+.i.rows)
        =(%working status.+.i.rows)
        $(rows t.rows)
    ==
  ::
  ++  context-kind-name
    |=  kind=context-kind
    ^-  tape
    ?-  kind
      %note  "note"
      %clay  "ship"
      %file  "file"
      %web   "web"
    ==
  ::
  ++  context-status-name
    |=  status=context-status
    ^-  tape
    ?-  status
      %pending  "Waiting for bridge"
      %working  "Fetching source…"
      %ready    "Ready"
      %failed   "Needs attention"
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
