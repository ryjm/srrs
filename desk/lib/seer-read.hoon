/-  *seer
/+  *seer, mcp=seer-mcp, ev=seer-evidence
|%
+$  read-position
  [epoch=@da revision=@ud fingerprint=@ux after=entity-key]
::
++  decode-read
  |=  raw=@t
  ^-  (unit agent-read)
  ?.  (lte (met 3 raw) 16.384)  ~
  %-  mole
  |.  (need ((soft agent-read) (cue (need (slaw %uv raw)))))
::
++  index-page
  |=  [tree=(set entity-key) after=(unit entity-key) limit=@ud]
  ^-  (list entity-key)
  ?:  =(0 limit)  ~
  ?~  tree  ~
  ?:  ?&(?=(^ after) ?|(=(n.tree u.after) (gor n.tree u.after)))
    $(tree r.tree)
  =/  left  $(tree l.tree)
  =/  remaining  (sub limit (lent left))
  ?:  =(0 remaining)  left
  (weld left [n.tree $(tree r.tree, after ~, limit (dec remaining))])
::
++  select-json
  |=  [value=json fields=(list @t)]
  ^-  json
  ?>  ?=(%o -.value)
  :-  %o
  =/  result=(map @t json)  ~
  |-
  ?~  fields  result
  =/  entry  (~(get by p.value) i.fields)
  =?  result  ?=(^ entry)  (~(put by result) i.fields u.entry)
  $(fields t.fields)
::
++  merge-json
  |=  [base=json extra=json]
  ^-  json
  ?>  ?&(?=(%o -.base) ?=(%o -.extra))
  [%o (~(uni by p.base) p.extra)]
::
++  short-label
  |=  value=@t
  ^-  @t
  ?:((lte (met 3 value) 256) value '')
::
++  agent-reader
  |=  [our=@p now=@da view=agent-view control=agent-state query=agent-read]
  =?  owner.query
      ?&(?=(~ owner.query) ?=(?(%stack %card) kind.query))
    `our
  =/  normalized  query(cursor ~, since ~)
  =/  fingerprint  (shax (jam normalized))
  =/  scope=agent-read-scope
    [kind.query owner.query stack.query card.query status.query]
  =/  index=agent-read-index
    ?~  context.query
      (fall (~(get by read-indexes.control) scope) *agent-read-index)
    (fall (~(get by context-index.control) u.context.query) *agent-read-index)
  =/  page-index=agent-read-index
    ?:  ?=(^ context.query)
      ?~  status.query  index
      ?:  (gth total.index 64)  index
      =/  selected
        %+  skim  ~(tap in keys.index)
        |=  key=entity-key
        =/  source  (~(get by contexts.data.view) id.key)
        ?~  source  %.n
        =(u.status.query status.u.source)
      index(keys (silt selected), total (lent selected))
    ?.  =(%orientation kind.query)  index
    %-  fall
    :_  *agent-read-index
    (~(get by read-indexes.control) scope(status `%open))
  =/  exact-key=(unit entity-key)
    ?~  id.query  ~
    ?:  =(%orientation kind.query)  ~
    =/  kind  (need ((soft entity-kind) kind.query))
    =/  owner  ?:(?=(?(%stack %card) kind) (fall owner.query our) our)
    =/  parent=@tas
      ?:  ?=(?(%card %proposal) kind)  (fall stack.query %root)
      %root
    `[kind owner parent u.id.query]
  =/  scope-revision=@ud
    ?:  ?=(^ context.query)  revision.index
    ?~  exact-key  revision.index
    =/  ver  (~(get by versions.control) u.exact-key)
    ?~  ver  0
    (max content-revision.u.ver review-revision.u.ver)
  =?  scope-revision  =(%orientation kind.query)
    =/  catalog
      (fall (~(get by read-indexes.control) [%model ~ ~ ~ ~]) *agent-read-index)
    (max scope-revision revision.catalog)
  =/  watermark=@t
    (scot %uv (jam [epoch.control scope-revision fingerprint]))
  =/  collection=@t
    ?-  kind.query
      %orientation  'work'
      %stack        'stacks'
      %card         'cards'
      %capture      'captures'
      %proposal     'proposals'
      %question     'questions'
      %change       'changes'
      %context      'contexts'
      %login        'logins'
      %model        'models'
    ==
  |%
  ++  count-at
    |=  key=agent-read-scope
    ^-  agent-read-index
    (fall (~(get by read-indexes.control) key) *agent-read-index)
  ++  counts
    ^-  json
    =/  kinds=(list agent-read-kind)
      ~[%stack %card %capture %proposal %question %change %context %login %model]
    %-  pairs:enjs:format
    %+  turn  kinds
    |=  kind=agent-read-kind
    =/  idx  (count-at [kind owner.query ~ ~ ~])
    :-  (scot %tas kind)
    %-  pairs:enjs:format
    :~  ['total' (numb:enjs:format total.idx)]
        ['review_queued' (numb:enjs:format queued.idx)]
        ['without_provenance' (numb:enjs:format evidence-gaps.idx)]
    ==
  ++  capabilities
    ^-  json
    %-  pairs:enjs:format
    :~  ['capabilities_revision' (numb:enjs:format seer-schema-version)]
        ['authority' s+'owner-trusted']
        ['scoped_delegation' b+%.n]
        ['worker_authority' s+'paired-proof-seer-bridge-v2']
        ['mutation_receipts' b+%.y]
        ['leased_execution' b+%.y]
        ['atomic_catalog_replacement' b+%.y]
        ['source_authored_packets' b+%.y]
        ['atomic_plan_preview' b+%.y]
        ['learning_lookup' b+%.y]
        ['automatic_truth_promotion' b+%.n]
        ['provider_execution' s+'Runtime capability must be checked; catalog presence is not proof of supported isolation.']
        ['receipt_retention' (numb:enjs:format 4.096)]
        ['mutation_identity' s+'schema_version=2, idempotency_epoch, operation_id']
        ['recovery_policy' s+'Source-time lease expiry only; unknown external outcome requires explicit new authorization.']
        ['metadata_first' b+%.y]
        ['bounded_reads' b+%.y]
        ['cursor_policy' s+'scope-revision-bound; refresh explicitly after snapshot-expired']
        :-  'navigation'
        %-  pairs:enjs:format
        :~  ['library' s+'seer/list-stacks']
            ['card_detail' s+'seer/learning-context']
            ['captures' s+'seer/list-captures']
            ['questions' s+'seer/list-card-questions']
            ['changes' s+'seer/list-change-requests']
            ['evidence' s+'seer/list-context-sources']
            ['models' s+'seer/list-assistant-models']
            ['packets' s+'seer/get-context-packet']
            ['snapshots' s+'seer/get-evidence-snapshot']
            ['change_preview' s+'seer/preview-change']
            ['proposal_preview' s+'seer/preview-proposal']
            ['operation_receipt' s+'seer/get-operation-result']
            ['learning' s+'seer/lookup-learning']
            ['operator' s+'/apps/seer/review']
        ==
    ==
  ++  envelope
    |=  [status=@t rows=(list json) complete=? cursor=(unit @t) omissions=(list json)]
    ^-  json
    =/  result
      %-  pairs:enjs:format
      :~  ['schema_version' (numb:enjs:format seer-schema-version)]
          ['status' s+status]
          ['ship' s+(scot %p our)]
          ['observation_basis' s+'local-state-and-cached-imports']
          ['observed_at' s+(scot %da now)]
          ['state_revision' (numb:enjs:format revision.control)]
          ['scope_revision' (numb:enjs:format scope-revision)]
          ['idempotency_epoch' s+(scot %da epoch.control)]
          ['watermark' s+watermark]
          ['projection' s+projection.query]
          ['complete' b+complete]
          ['next_cursor' ?~(cursor ~ s+u.cursor)]
          ['omissions' [%a omissions]]
          [collection [%a rows]]
          :-  'scope'
          ?:  !?|(=('ok' status) =('unchanged' status))  ~
          %-  pairs:enjs:format
          :~  ['owner' ?~(owner.query ~ s+(scot %p u.owner.query))]
              ['stack_id' ?~(stack.query ~ s+u.stack.query)]
              ['card_id' ?~(card.query ~ s+u.card.query)]
              ['id' ?~(id.query ~ s+u.id.query)]
              ['status' ?~(status.query ~ s+u.status.query)]
              ['context' ?~(context.query ~ (scope-json:ev u.context.query))]
          ==
          :-  'limits'
          %-  pairs:enjs:format
          :~  ['limit' (numb:enjs:format limit.query)]
              ['max_bytes' (numb:enjs:format max-bytes.query)]
              ['default_limit' (numb:enjs:format 20)]
              ['maximum_limit' (numb:enjs:format 100)]
              ['default_max_bytes' (numb:enjs:format 32.768)]
              ['maximum_max_bytes' (numb:enjs:format 262.144)]
              ['source_bytes' (numb:enjs:format 131.072)]
              ['change_operations' (numb:enjs:format 64)]
          ==
      ==
    ?.  ?&(=(%orientation kind.query) =('ok' status))  result
    =.  result  (merge-json result capabilities)
    %+  merge-json  result
    %-  pairs:enjs:format
    :~  ['counts' counts]
        :-  'evidence_gaps'
        %-  pairs:enjs:format
        :~  ['meaning' s+'Cards without recorded approved provenance; not a claim that attached sources are true.']
            ['detail_tool' s+'seer/learning-context']
        ==
        :-  'providers'
        :-  %a
        %+  turn
          ^-  (list ai-provider)
          ~[%codex %claude]
        |=  provider=ai-provider
        =/  idx  (count-at [%model ~ ~ ~ `provider])
        %-  pairs:enjs:format
        :~  ['provider' s+provider]
            ['catalog_models' (numb:enjs:format total.idx)]
            ['catalog_observed_at' ?:(=(0 revision.idx) ~ s+(scot %da updated-at.idx))]
            ['authentication' s+'not-observed']
        ==
    ==
  ++  fits
    |=  value=json
    ^-  ?
    (lte (met 3 (en:json:html value)) max-bytes.query)
  ++  omission
    |=  [reason=@t key=(unit entity-key)]
    ^-  json
    %-  pairs:enjs:format
    :~  ['reason' s+reason]
        ['ref' ?~(key ~ (reference u.key))]
    ==
  ++  error
    |=  message=@t
    ^-  json
    (envelope message ~ %.n ~ ~[(omission message ~)])
  ++  reference
    |=  key=entity-key
    ^-  json
    =/  ver  (fall (~(get by versions.control) key) *entity-version)
    =/  tool=@t
      ?-  kind.key
        %stack     'seer/list-stacks'
        %card      'seer/learning-context'
        %capture   'seer/list-captures'
        %proposal  'seer/list-captures'
        %question  'seer/list-card-questions'
        %change    'seer/list-change-requests'
        %context   'seer/list-context-sources'
        %login     'seer/list-login-requests'
        %model     'seer/list-assistant-models'
      ==
    =/  args
      %-  pairs:enjs:format
      :~  ['id' s+id.key]
          ['projection' s+'detail']
      ==
    =?  args  =(%card kind.key)
      %+  merge-json  args
      %-  pairs:enjs:format
      :~  ['owner' s+(scot %p owner.key)]
          ['stack_id' s+scope.key]
      ==
    =?  args  =(%proposal kind.key)
      (merge-json args (pairs:enjs:format ~[['capture_id' s+scope.key]]))
    =?  args  =(%stack kind.key)
      (merge-json args (pairs:enjs:format ~[['owner' s+(scot %p owner.key)]]))
    %-  pairs:enjs:format
    :~  ['kind' s+kind.key]
        ['owner' s+(scot %p owner.key)]
        ['scope' s+scope.key]
        ['id' s+id.key]
        ['incarnation' (numb:enjs:format incarnation.ver)]
        ['content_revision' (numb:enjs:format content-revision.ver)]
        ['review_revision' (numb:enjs:format review-revision.ver)]
        ['present' b+present.ver]
        ['tool' s+tool]
        ['arguments' args]
    ==
  ++  row
    |=  key=entity-key
    ^-  (unit json)
    ?.  &((lte (met 3 id.key) 128) (lte (met 3 scope.key) 128))  ~
    =/  detail  =(%detail projection.query)
    =/  content  (row-body key detail)
    ?~  content  ~
    =/  work  (~(get by jobs.control) key)
    =/  extra
      %-  pairs:enjs:format
      :~  ['ref' (reference key)]
          ['work' ?~(work ~ (work-record-json u.work))]
          :-  'legal_next_actions'
          :-  %a
          %+  turn  (next-actions key)
          |=(name=@t [%s name])
      ==
    `(merge-json u.content extra)
  ++  work-record-json
    |=  work=work-record
    ^-  json
    %-  pairs:enjs:format
    :~  ['attempt' (numb:enjs:format attempt.work)]
        ['execution' s+execution.work]
        ['effect' s+effect.work]
        ['worker' s+worker.work]
        ['lease' s+(scot %ux lease.work)]
        ['lease_until' (maybe-date-json:mcp lease-until.work)]
        ['lease_until_ms' (epoch-milliseconds lease-until.work)]
        ['deadline' (maybe-date-json:mcp deadline.work)]
        ['deadline_ms' (epoch-milliseconds deadline.work)]
        ['updated_at' s+(scot %da updated-at.work)]
        ['checkpoint' s+checkpoint.work]
        ['secret_revision' (numb:enjs:format secret-revision.work)]
        ['provider' ?~(provider.work ~ s+u.provider.work)]
        ['model_id' s+model-id.work]
        ['model_revision' (numb:enjs:format model-revision.work)]
        ['packet_ref' ?~(packet.work ~ s+(scot %ux u.packet.work))]
        ['packet_digest' ?~(packet-digest.work ~ s+(scot %ux u.packet-digest.work))]
        ['policy_version' (numb:enjs:format policy-version.work)]
        ['prompt_version' (numb:enjs:format prompt-version.work)]
        ['schema_version' (numb:enjs:format schema-version.work)]
        ['max_invocations' (numb:enjs:format max-invocations.work)]
        ['invocations' (numb:enjs:format invocations.work)]
        ['input_bytes' (numb:enjs:format input-bytes.work)]
        ['max_input_bytes' (numb:enjs:format max-input-bytes.work)]
        ['max_output_bytes' (numb:enjs:format max-output-bytes.work)]
        ['max_operations' (numb:enjs:format max-operations.work)]
        ['consumed_output_bytes' (numb:enjs:format consumed-output-bytes.work)]
        ['usage' ?~(usage.work ~ (numb:enjs:format u.usage.work))]
        ['cost' ?~(cost.work ~ (numb:enjs:format u.cost.work))]
        ['stop_reason' ?~(stop-reason.work ~ s+u.stop-reason.work)]
        ['retryable' b+retryable.work]
    ==
  ++  epoch-milliseconds
    |=  date=(unit @da)
    ^-  json
    ?~  date  ~
    ?.  (gte u.date ~1970.1.1)  ~
    (numb:enjs:format (div (mul (sub u.date ~1970.1.1) 1.000) ~s1))
  ++  next-actions
    |=  key=entity-key
    ^-  (list @t)
    =/  work  (~(get by jobs.control) key)
    ?:  ?&(?=(^ work) =(%running execution.u.work))
      ?:  ?&(?=(^ lease-until.u.work) (lte u.lease-until.u.work now))
        ~['seer/recover-work' 'seer/cancel-work']
      ~['seer/checkpoint-work' 'seer/heartbeat-work' 'seer/cancel-work']
    ?:  ?&(?=(^ work) =(%unknown effect.u.work))
      ~['seer/cancel-work' '/apps/seer/review']
    ?+  kind.key  ~
      %stack     ~['seer/get-stack']
      %card      ~['seer/learning-context' '/apps/seer/review']
      %proposal  ~['seer/preview-proposal' '/apps/seer/inbox']
      %capture   ~['seer/prepare-capture' 'seer/stage-card' 'seer/lookup-learning' '/apps/seer/inbox']
      %context
        =/  job  (~(got by contexts.data.view) id.key)
        ?.  active.job  ~
        ?:  =(%failed status.job)  ~['/apps/seer/review']
        ?:  ?&(=(%pending status.job) =(%web kind.job))  ~['seer/claim-context-source']
        ~
      %question
        =/  job  (~(got by questions.data.view) id.key)
        ?:  =(%pending status.job)  ~['seer/claim-card-question']
        ?:  =(%failed status.job)  ~['/apps/seer/review']
        ~
      %change
        =/  job  (~(got by changes.data.view) id.key)
        ?:  =(%draft status.job)  ~['seer/attach-context-source' 'seer/start-change']
        ?:  =(%pending status.job)  ~['seer/claim-change']
        ?:  =(%ready status.job)  ~['seer/preview-change' '/apps/seer/review']
        ?:  =(%failed status.job)  ~['/apps/seer/review']
        ~
      %login
        =/  job  (~(got by logins.view) id.key)
        ?:  =(%pending status.job)  ~['seer/claim-login']
        ~
    ==
  ++  text-fits
    |=  values=(list @t)
    ^-  ?
    =/  bytes  0
    |-
    ?~  values  %.y
    =.  bytes  (add bytes (met 3 i.values))
    ?.  (lte bytes max-bytes.query)  %.n
    $(values t.values)
  ++  row-body
    |=  [key=entity-key detail=?]
    ^-  (unit json)
    ?-  kind.key
        %stack
      =/  stk  (need (agent-stack our owner.key id.key view))
      =/  title  (stack-title:mcp stk)
      ?.  ?|(!detail (text-fits ~[title]))  ~
      =/  idx  (count-at [%card `owner.key `id.key ~ ~])
      %-  some
      %-  pairs:enjs:format
      :~  ['stack_id' s+id.key]
          ['owner' s+(scot %p owner.key)]
          ['title' s+?:(detail title (short-label title))]
          ['title_omitted' b+?&(!detail (gth (met 3 title) 256))]
          ['card_count' (numb:enjs:format total.idx)]
          ['review_count' (numb:enjs:format queued.idx)]
          ['evidence_gap_count' (numb:enjs:format evidence-gaps.idx)]
          ['card_tool' s+'seer/get-stack']
      ==
        %card
      =/  stk  (need (agent-stack our owner.key scope.key view))
      =/  itm  (~(got by items.stk) id.key)
      =/  origin  (~(get by provenance.data.view) [scope.key id.key])
      =?  origin  !=(our owner.key)  ~
      =/  title  title.content.itm
      ?.  ?|(!detail (text-fits ~[title front.content.itm back.content.itm]))  ~
      =/  base
        %-  pairs:enjs:format
        :~  ['card_id' s+id.key]
            ['stack_id' s+scope.key]
            ['owner' s+(scot %p owner.key)]
            ['title' s+?:(detail title (short-label title))]
            ['title_omitted' b+?&(!detail (gth (met 3 title) 256))]
            ['box' (numb:enjs:format box.learn.itm)]
            ['queued' b+(~(has by review-items.stk) id.key)]
            ['has_provenance' b+?=(^ origin)]
        ==
      ?.  detail  `base
      ?.  ?~(origin %.y (text-fits ~[source.u.origin rationale.u.origin created-by.u.origin]))  ~
      ?.  ?~(origin %.y (lte (lent (scag 33 citations.u.origin)) 32))  ~
      ?.  ?~(origin %.y (text-fits (turn citations.u.origin |=(cite=evidence-citation quote.cite))))  ~
      :-  ~
      %+  merge-json  base
      %-  pairs:enjs:format
      :~  ['front' s+(clean-body:mcp front.content.itm)]
          ['back' s+(clean-body:mcp back.content.itm)]
          ['ease' s+(scot %rs ease.learn.itm)]
          ['interval' s+(scot %dr interval.learn.itm)]
          ['last_review' (maybe-date-json:mcp last-review.itm)]
          ['provenance' (provenance-json:mcp origin)]
      ==
        %capture
      =/  cap  (~(got by captures.data.view) id.key)
      ?.  ?|(!detail (text-fits ~[title.cap goal.cap source.cap created-by.cap]))  ~
      =/  idx  (count-at [%proposal `our `id.key ~ ~])
      =/  value
        %+  capture-json:mcp  id.key
        %=  cap
          title      ?:(detail title.cap (short-label title.cap))
          goal       ?:(detail goal.cap '')
          source     ?:(detail source.cap '')
          created-by  ?:(detail created-by.cap (short-label created-by.cap))
          proposals  ~
        ==
      =/  fields=(list @t)
        ~['capture_id' 'title' 'created_by' 'created_at' 'status' 'approved_count' 'rejected_count' 'packet_ref' 'packet_tool']
      =?  fields  detail  (weld fields ~['goal' 'source'])
      :-  ~
      %+  merge-json  (select-json value fields)
      %-  pairs:enjs:format
      :~  ['proposal_count' (numb:enjs:format total.idx)]
          ['proposal_tool' s+'seer/list-captures']
          ['proposal_arguments' (pairs:enjs:format ~[['capture_id' s+id.key]])]
      ==
        %proposal
      =/  cap  (~(got by captures.data.view) scope.key)
      =/  draft  (~(got by proposals.cap) id.key)
      ?.  ?|(!detail (text-fits ~[title.draft front.draft back.draft rationale.draft source.draft created-by.draft objective.draft claim.draft why-new.draft caveat.draft]))  ~
      ?.  ?|(!detail (lte (lent (scag 33 citations.draft)) 32))  ~
      ?.  ?|(!detail (lte (lent (scag 257 preconditions.draft)) 256))  ~
      ?.  ?|(!detail (text-fits (turn citations.draft |=(cite=evidence-citation quote.cite))))  ~
      =/  value
        %+  proposal-json:mcp  id.key
        %=  draft
          title      ?:(detail title.draft (short-label title.draft))
          front      ?:(detail front.draft '')
          back       ?:(detail back.draft '')
          rationale  ?:(detail rationale.draft '')
          source     ?:(detail source.draft '')
          created-by  ?:(detail created-by.draft (short-label created-by.draft))
          objective  ?:(detail objective.draft '')
          claim      ?:(detail claim.draft '')
          why-new    ?:(detail why-new.draft '')
          caveat     ?:(detail caveat.draft '')
          citations  ?:(detail citations.draft ~)
          preconditions  ?:(detail preconditions.draft ~)
        ==
      ?:  detail  `value
      `(select-json value ~['proposal_id' 'stack_id' 'card_id' 'title' 'created_by' 'created_at' 'packet_ref' 'artifact_ref' 'preview_tool'])
        %question
      =/  job  (~(got by questions.data.view) id.key)
      ?.  (text-fits ~[worker.job id.profile.job])  ~
      ?.  ?|(!detail (text-fits ~[worker.job id.profile.job selector.profile.job model.profile.job label.profile.job title.job front.job back.job prompt.job response.job result-title.job result-front.job result-back.job]))  ~
      ?.  ?|(!detail (lte (lent (scag 33 citations.job)) 32))  ~
      ?.  ?|(!detail (text-fits (turn citations.job |=(cite=evidence-citation quote.cite))))  ~
      =/  value
        %+  question-json:mcp  id.key
          %=  job
            title         ?:(detail title.job (short-label title.job))
            front         ?:(detail front.job '')
            back          ?:(detail back.job '')
            prompt        ?:(detail prompt.job '')
            response      ?:(detail response.job '')
            result-title  ?:(detail result-title.job '')
            result-front  ?:(detail result-front.job '')
            result-back   ?:(detail result-back.job '')
            citations     ?:(detail citations.job ~)
          ==
      ?.  detail
        `(select-json value ~['question_id' 'owner' 'stack_id' 'card_id' 'title' 'mode' 'provider' 'model_id' 'status' 'worker_id' 'created_at' 'updated_at' 'packet_ref' 'packet_tool'])
      `value
        %change
      =/  job  (~(got by changes.data.view) id.key)
      ?.  (text-fits ~[worker.job id.profile.job])  ~
      ?.  ?|(!detail (lte (lent (scag 65 operations.job)) 64))  ~
      ?.  ?|(!detail (lte (lent (scag 33 citations.job)) 32))  ~
      ?.  ?|(!detail (lte (lent (scag 257 preconditions.job)) 256))  ~
      ?.  ?|(!detail (lte (lent (scag 129 scope-preconditions.job)) 128))  ~
      ?.  ?|(!detail (text-fits (turn citations.job |=(cite=evidence-citation quote.cite))))  ~
      ?.  ?|  !detail
              %-  text-fits
              %+  welp
                ~[worker.job id.profile.job selector.profile.job model.profile.job label.profile.job prompt.job summary.job artifact.job response.job]
              %-  zing
              %+  turn  operations.job
              |=  op=state-operation
              ^-  (list @t)
              ~[title.op front.op back.op original-title.op original-front.op original-back.op]
          ==
        ~
      =/  value
        %+  change-json:mcp  id.key
        %=  job
          prompt      ?:(detail prompt.job '')
          summary     ?:(detail summary.job '')
          artifact    ?:(detail artifact.job '')
          response    ?:(detail response.job '')
          operations  ?:(detail operations.job ~)
          citations  ?:(detail citations.job ~)
          preconditions  ?:(detail preconditions.job ~)
          scope-preconditions  ?:(detail scope-preconditions.job ~)
        ==
      ?:  detail  `value
      `(select-json value ~['change_id' 'target' 'provider' 'model_id' 'status' 'worker_id' 'created_at' 'updated_at' 'packet_ref' 'packet_tool' 'plan_digest' 'preview_tool'])
        %context
      =/  source  (~(got by contexts.data.view) id.key)
      ?.  (text-fits ~[worker.source])  ~
      ?.  ?|(!detail (text-fits ~[worker.source label.source locator.source error.source]))  ~
      =/  value
        %-  context-source-json:mcp
        %=  source
          label    ?:(detail label.source (short-label label.source))
          locator  ?:(detail locator.source '')
          error    ?:(detail error.source '')
        ==
      ?:  detail  `value
      `(select-json value ~['context_id' 'owner' 'stack_id' 'card_id' 'scope' 'kind' 'label' 'snapshot_ref' 'generation' 'policy_revision' 'status' 'acquisition_status' 'worker_id' 'active' 'created_at' 'updated_at'])
        %login
      =/  job  (~(got by logins.view) id.key)
      ?.  (text-fits ~[worker.job])  ~
      =/  value
        %+  login-json:mcp  id.key
        job(auth-url '', user-code '', message '')
      `(select-json value ~['login_id' 'provider' 'status' 'worker_id' 'created_at' 'updated_at' 'code_ready'])
        %model
      =/  profile  (~(got by models.data.view) id.key)
      ?.  (text-fits ~[selector.profile model.profile label.profile worker.profile])  ~
      ?.  ?|(!detail (text-fits ~[description.profile]))  ~
      =/  value  (assistant-model-json:mcp profile(description ?:(detail description.profile '')))
      ?:  detail  `value
      `(select-json value ~['model_id' 'provider' 'role' 'selector' 'model' 'label' 'worker_id' 'registered_at'])
    ==
  ++  page
    ^-  json
    ?.  ?=(~ (agent-read-error query))
      (error 'invalid-query')
    ?:  ?&(?=(^ context.query) (gth total.index 64))
      (error 'limit-exceeded')
    ?:  ?&  =(%card kind.query)
            ?=(~ (agent-stack our (fall owner.query our) (need stack.query) view))
        ==
      (error 'not-found')
    ?:  ?&  =(%proposal kind.query)
            !(~(has by captures.data.view) (need stack.query))
        ==
      (error 'not-found')
    =/  decoded=(unit read-position)
      ?~  cursor.query  ~
      %-  mole
      |.  (need ((soft read-position) (cue (need (slaw %uv u.cursor.query)))))
    ?:  ?&(?=(^ cursor.query) ?=(~ decoded))  (error 'invalid-query')
    ?.  ?~  decoded  %.y
        ?&  =(epoch.control epoch.u.decoded)
            =(scope-revision revision.u.decoded)
            =(fingerprint fingerprint.u.decoded)
        ==
      (error 'snapshot-expired')
    ?.  ?~(decoded %.y (~(has in keys.page-index) after.u.decoded))
      (error 'invalid-query')
    =/  after=(unit entity-key)  ?~(decoded ~ `after.u.decoded)
    ?:  =(`watermark since.query)
      =/  unchanged  (envelope 'unchanged' ~ %.y ~ ~)
      ?:  (fits unchanged)  unchanged
      (error 'limit-exceeded')
    =/  candidates=(list entity-key)
      ?~  exact-key
        (index-page keys.page-index after +(limit.query))
      =/  key  u.exact-key
      ?:  ?=(^ context.query)
        ?:((~(has in keys.page-index) key) ~[key] ~)
      =/  summary  (~(get by read-summaries.control) key)
      ?~  summary  ~
      =/  scopes  (agent-read-scopes kind.key u.summary)
      ?.  (~(has in scopes) scope)  ~
      ~[key]
    ?:  ?&(?=(^ exact-key) ?=(~ candidates))  (error 'not-found')
    =/  rows=(list json)  ~
    =/  last=(unit entity-key)  after
    =/  row-bytes=@ud  0
    |-
    ?~  candidates
      =/  result  (envelope 'ok' (flop rows) %.y ~ ~)
      ?:  (fits result)  result
      (error 'limit-exceeded')
    =/  cursor=(unit @t)
      ?~  last  ~
      `(scot %uv (jam [epoch.control scope-revision fingerprint u.last]))
    ?:  =(limit.query (lent rows))
      (envelope 'ok' (flop rows) %.n cursor ~)
    =/  value  (row i.candidates)
    ?~  value
      ?:  ?=(~ rows)
        (error 'limit-exceeded')
      (envelope 'ok' (flop rows) %.n cursor ~)
    =/  next-rows  [u.value rows]
    =/  next-cursor=(unit @t)
      ?:  ?=(~ t.candidates)  ~
      `(scot %uv (jam [epoch.control scope-revision fingerprint i.candidates]))
    =/  next-bytes  (add row-bytes (met 3 (en:json:html u.value)))
    =/  empty  (envelope 'ok' ~ ?=(~ next-cursor) next-cursor ~)
    ?.  (lte (add (met 3 (en:json:html empty)) (add next-bytes (lent rows))) max-bytes.query)
      ?:  ?=(~ rows)
        (error 'limit-exceeded')
      (envelope 'ok' (flop rows) %.n cursor ~)
    $(candidates t.candidates, rows next-rows, last `i.candidates, row-bytes next-bytes)
  --
--
