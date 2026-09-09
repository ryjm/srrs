|%
::
+$  items   (map @tas item)
+$  action
  $%  $:  %new-stack
          name=@tas
          title=@t
          =items
      ==
  ::
      $:  %new-item
          stack-owner=@p
          who=@p
          stak=@tas
          name=@tas
          title=@t
          perm=perm-config
          front=@t
          back=@t
      ==
  ::
      [%raise-item who=@p stak=@tas item=@tas]
      [%answered-item owner=@p stak=@tas item=@tas answer=recall-grade]
      [%review-stack who=@p stak=@tas]
  ::
      [%delete-stack who=@p stak=@tas]
      [%delete-item stak=@tas item=@tas]
  ::
      [%edit-stack name=@tas title=@t]
  ::
      $:  %edit-item
          who=@p
          stak=@tas
          name=@tas
          title=@t
          perm=perm-config
          front=@t
          back=@t
      ==
  ::
      [%update-review ~]
  ::
      [%import who=@p stack=@tas]
      [%import-file =path]
  ::
      [%copy-stack owner=@p stak=@tas keep-learned=?]
  ::
      $:  %begin-capture
          id=@tas
          title=@t
          goal=@t
          source=@t
          created-by=@t
      ==
      $:  %prepare-capture
          id=@tas
          profile=assistant-model
          selections=(list evidence-selection)
          max-bytes=@ud
          excerpt-bytes=@ud
      ==
      $:  %stage-card
          capture=@tas
          proposal=@tas
          stack=@tas
          card=@tas
          title=@t
          front=@t
          back=@t
          rationale=@t
          source=@t
          created-by=@t
          objective=@t
          claim=@t
          why-new=@t
          caveat=@t
          packet=(unit @ux)
          citations=(list evidence-citation)
          preconditions=(list entity-precondition)
      ==
      [%approve-proposal capture=@tas proposal=@tas digest=@ux]
      [%reject-proposal capture=@tas proposal=@tas reason=(unit @t)]
      [%discard-capture capture=@tas]
      [%delete-capture capture=@tas]
      [%purge-evidence snapshots=(set @ux)]
      [%collect-retained ~]
      [%retire-operation-epoch ~]
      $:  %add-context-source
          id=@tas
          scope=context-scope
          kind=context-kind
          label=@t
          locator=@t
          content=@t
      ==
      [%set-context-egress id=@tas providers=(set ai-provider)]
      [%rename-context-source id=@tas label=@t]
      [%archive-orphan-contexts ~]
      [%remove-context-source id=@tas]
  ::  system actions: applied by the ship itself from its own outbound
  ::  request responses, never by a planner or a paired worker.
      $:  %finish-context-source
          id=@tas
          attempt=@ud
          label=@t
          content=@t
          final-locator=@t
      ==
      [%fail-context-source id=@tas attempt=@ud error=@tas]
      [%retry-context-source id=@tas]
  ::
      $:  %ask-card
          id=@tas
          owner=@p
          stak=@tas
          item=@tas
          mode=assistant-mode
          profile=assistant-model
          prompt=@t
          selections=(list evidence-selection)
          max-bytes=@ud
          excerpt-bytes=@ud
      ==
      [%replace-assistant-models provider=ai-provider origin=@t profiles=(list assistant-model)]
      $:  %answer-card-question
          id=@tas
          attempt=@ud
          response=@t
          citations=(list evidence-citation)
          usage=(unit @ud)
      ==
      $:  %apply-card-edit
          id=@tas
          attempt=@ud
          title=@t
          front=@t
          back=@t
          response=@t
          citations=(list evidence-citation)
          usage=(unit @ud)
      ==
      [%fail-card-question id=@tas attempt=@ud response=@tas]
      [%retry-card-question id=@tas]
      [%delete-card-question id=@tas]
      $:  %request-change
          id=@tas
          target=change-target
          profile=assistant-model
          prompt=@t
          start=?
      ==
      [%start-change id=@tas]
      $:  %propose-change
          id=@tas
          prompt=@t
          summary=@t
          operations=(list state-operation)
          preconditions=(list entity-precondition)
      ==
      $:  %finish-change
          id=@tas
          attempt=@ud
          summary=@t
          artifact=@t
          operations=(list state-operation)
          citations=(list evidence-citation)
          usage=(unit @ud)
      ==
      [%fail-change id=@tas attempt=@ud response=@tas]
      [%apply-change id=@tas digest=@ux]
      [%reject-change id=@tas]
      [%retry-change id=@tas]
      [%delete-change id=@tas]
  ::  provider accounts and sign-in. the ship runs the device and
  ::  paste-back flows itself and stores the resulting tokens.
      [%request-login id=@tas provider=ai-provider]
      $:  %post-login-challenge
          id=@tas
          attempt=@ud
          auth-url=@t
          user-code=@t
          device-id=@t
          interval=@ud
      ==
      [%submit-login-code id=@tas code=@t]
      [%finish-login id=@tas attempt=@ud]
      [%fail-login id=@tas attempt=@ud message=@tas]
      [%retry-login id=@tas]
      [%cancel-login id=@tas]
      $:  %import-account
          provider=ai-provider
          method=account-method
          access=@t
          refresh=@t
          account=@t
          expires=(unit @da)
          scopes=@t
      ==
      [%rotate-account provider=ai-provider serial=@ud access=@t refresh=@t expires=(unit @da)]
      [%fail-renewal provider=ai-provider serial=@ud message=@tas terminal=?]
      [%clear-account provider=ai-provider]
      [%refresh-catalog provider=ai-provider]
      [%share-clay-context pax=path]
      [%unshare-clay-context pax=path]
      [%fetch-remote-manifest who=@p]
      [%refresh-context-source id=@tas]
      [%dispatch-work work=entity-key]
      [%cancel-work work=entity-key]
  ==
::
::  The wire envelope is versioned independently of stored domain records.
::
+$  command
  [schema=@ud epoch=@da operation=@t digest=@ux submission=@ux payload=action]
::
+$  agent-read-kind
  $?(%orientation %stack %card %capture %proposal %question %change %context %login %model)
+$  agent-read
  $:  kind=agent-read-kind
      owner=(unit @p)
      stack=(unit @tas)
      card=(unit @tas)
      id=(unit @tas)
      status=(unit @tas)
      projection=$?(%metadata %detail)
      limit=@ud
      max-bytes=@ud
      cursor=(unit @t)
      since=(unit @t)
      context=(unit context-scope)
  ==
::
+$  entity-kind  $?(%stack %card %capture %proposal %question %change %context %login %model)
+$  entity-key
  [kind=entity-kind owner=@p scope=@tas id=@tas]
+$  entity-version
  $:  incarnation=@ud
      content-revision=@ud
      review-revision=@ud
      present=?
  ==
+$  entity-reference  [key=entity-key incarnation=@ud]
+$  entity-precondition
  [key=entity-key seen=(unit entity-version) content=? review=?]
+$  work-checkpoint
  $?  %none
      %context-frozen
      %provider-started
      %output-received
      %result-published
      %effect-committed
  ==
+$  work-record
  $:  attempt=@ud
      execution=$?(%queued %running %blocked %succeeded %failed %cancelled)
      effect=$?(%none %staged %committed %unknown)
      updated-at=@da
      checkpoint=work-checkpoint
      deadline=(unit @da)
      provider=(unit ai-provider)
      model-id=@tas
      model-revision=@ud
      packet=(unit @ux)
      packet-digest=(unit @ux)
      policy-version=@ud
      prompt-version=@ud
      schema-version=@ud
      max-invocations=@ud
      invocations=@ud
      input-bytes=@ud
      max-input-bytes=@ud
      max-output-bytes=@ud
      max-operations=@ud
      consumed-output-bytes=@ud
      redirects=@ud
      usage=(unit @ud)
      cost=(unit @ud)
      stop-reason=(unit @tas)
      retryable=?
      external=(unit @t)
  ==
+$  agent-read-summary
  $:  owner=@p
      stack=(unit @tas)
      card=(unit @tas)
      status=(unit @tas)
      queued=?
      evidence-gap=?
      open=?
  ==
+$  agent-read-scope
  [kind=agent-read-kind owner=(unit @p) stack=(unit @tas) card=(unit @tas) status=(unit @tas)]
+$  agent-read-index
  $:  revision=@ud
      updated-at=@da
      total=@ud
      queued=@ud
      evidence-gaps=@ud
      keys=(set entity-key)
  ==
+$  agent-state
  $:  revision=@ud
      next-incarnation=$~(1 @ud)
      versions=(map entity-key entity-version)
      jobs=(map entity-key work-record)
      epoch=@da
      receipts=(map [epoch=@da operation=@t] operation-receipt)
      receipt-count=@ud
      catalog-revision=@ud
      read-summaries=(map entity-key agent-read-summary)
      read-indexes=(map agent-read-scope agent-read-index)
      context-index=(map context-scope agent-read-index)
      changed=(set entity-key)
      failure=(unit [status=operation-status reason=@tas])
  ==
::
+$  context-scope
  $%  [%stack owner=@p stack=@tas card=(unit @tas)]
      [%capture id=@tas]
      [%change id=@tas]
  ==
+$  evidence-coverage  $?(%full %excerpt %listing)
+$  acquired-context
  [content=@t coverage=evidence-coverage origin-revision=(unit @t)]
+$  evidence-snapshot
  $:  id=@ux
      source=@tas
      owner=@p
      kind=context-kind
      scope=context-scope
      generation=@ud
      blob=@ux
      digest=@ux
      bytes=@ud
      label=@t
      locator=@t
      final-locator=@t
      origin-revision=(unit @t)
      retrieved-at=@da
      extraction=@tas
      extraction-version=@ud
      coverage=evidence-coverage
      available=?
  ==
+$  evidence-selection
  [source=@tas start=@ud end=(unit @ud) include=? mandatory=?]
+$  packet-entry
  $:  source=@tas
      snapshot=(unit @ux)
      policy-revision=@ud
      mandatory=?
      requested-start=@ud
      requested-end=(unit @ud)
      start=@ud
      end=@ud
      reason=(unit @tas)
  ==
+$  packet-request
  $:  work=entity-key
      attempt=@ud
      scope=context-scope
      subject=(unit [key=entity-key version=entity-version])
      profile=assistant-model
      mode=$?(%ask %edit %library %capture %desk)
      objective=@t
      title=@t
      front=@t
      back=@t
      selections=(list evidence-selection)
      max-bytes=@ud
      excerpt-bytes=@ud
  ==
+$  context-packet
  $:  id=@ux
      request=packet-request
      entries=(list packet-entry)
      created-at=@da
      prompt-version=@ud
      schema-version=@ud
      prompt-bytes=@ud
      prompt-digest=@ux
      input-digest=@ux
      blocked=(unit @tas)
  ==
+$  evidence-citation
  [snapshot=@ux start=@ud end=@ud quote=@t]
+$  evidence-state
  $:  blobs=(map @ux @t)
      blob-refs=(map @ux @ud)
      snapshots=(map @ux evidence-snapshot)
      source-snapshots=(map @tas (set @ux))
      packets=(map @ux context-packet)
      stored-bytes=@ud
      snapshot-count=@ud
      packet-count=@ud
  ==
+$  plan-diff
  $:  operation=state-operation
      before=(unit [title=@t front=@t back=@t])
      after=(unit [title=@t front=@t back=@t])
      review-effect=$?(%unchanged %queued %removed)
  ==
+$  plan-preview
  $:  status=$?(%ok %invalid %conflict %budget-exhausted)
      reason=@tas
      digest=@ux
      candidate=(map @tas stack)
      affected=(list entity-key)
      diffs=(list plan-diff)
  ==
+$  operation-status
  $?(%ok %blocked %conflict %invalid %unauthorized %budget-exhausted %outcome-unknown %replay-expired)
+$  operation-receipt
  $:  epoch=@da
      id=@t
      digest=@ux
      submission=@ux
      action=@tas
      status=operation-status
      reason=@tas
      effect=$?(%none %staged %committed %unknown)
      authority=$?(%operator %planner %system)
      work=(unit entity-key)
      attempt=(unit @ud)
      plan=(unit @ux)
      before=(list entity-precondition)
      after=(list entity-precondition)
      revision=@ud
      at=@da
  ==
::
::  ai capture sessions live on the ship. codex and claude can hand the
::  same learning session back and forth, and drafts remain proposals
::  until a person approves them in seer.
::
+$  proposal
  $:  id=@tas
      stack=@tas
      card=@tas
      title=@t
      front=@t
      back=@t
      rationale=@t
      source=@t
      created-by=@t
      created-at=@da
      objective=@t
      claim=@t
      why-new=@t
      caveat=@t
      packet=(unit @ux)
      citations=(list evidence-citation)
      artifact=(unit @ux)
      preconditions=(list entity-precondition)
  ==
::
+$  capture-status  $?(%open %complete)
::
+$  capture
  $:  id=@tas
      title=@t
      goal=@t
      source=@t
      created-by=@t
      created-at=@da
      status=capture-status
      approved=@ud
      rejected=@ud
      proposals=(map @tas proposal)
      packet=(unit @ux)
  ==
::
+$  provenance
  $:  kind=?(%capture %plan)
      capture=@tas
      source=@t
      rationale=@t
      created-by=@t
      proposed-at=@da
      approved-at=@da
      packet=(unit @ux)
      citations=(list evidence-citation)
      artifact=(unit @ux)
      revision=(unit entity-version)
  ==
::
+$  learning-key  [owner=@p stack=@tas content=@ux]
+$  learning-artifact
  $:  id=@ux
      kind=$?(%proposal %explanation %correction)
      owner=@p
      scope=context-scope
      objective=@t
      fingerprint=@ux
      signature=@ux
      packet=(unit @ux)
      input-digest=(unit @ux)
      subject=(unit [key=entity-key version=entity-version])
      draft=(unit proposal)
      text=@t
      citations=(list evidence-citation)
      prior=(unit @ux)
      decision=$?(%proposed %approved %rejected %superseded)
      decision-by=(unit @p)
      decision-at=(unit @da)
      reason=(unit @t)
      available=?
      created-at=@da
  ==
+$  learner-observation
  [subject=[key=entity-key version=entity-version] grade=recall-grade actor=@p at=@da]
+$  learning-state
  $:  artifacts=(map @ux learning-artifact)
      signatures=(map @ux @ux)
      input-index=(map [scope=context-scope kind=$?(%explanation %correction) digest=@ux] @ux)
      scope-index=(map context-scope (set @ux))
      candidate-index=(map learning-key (set @ux))
      library-index=(map learning-key (set entity-key))
      observations=(map entity-key (list learner-observation))
      artifact-count=@ud
      observation-count=@ud
      stored-bytes=@ud
      reuse-count=@ud
      duplicate-count=@ud
  ==
::
+$  ai-provider  $?(%codex %claude)
::
::  provider accounts live on this ship. a slot holds one method's
::  credential; renewal rotates oauth tokens in place. token material
::  never leaves agent state through any read surface.
::
+$  account-method  $?(%oauth %setup-token %api-key)
+$  account-renewal
  $:  active=(unit [serial=@ud deadline=@da])
      serial=@ud
      retry-at=@da
      error=@t
      terminal=?
  ==
+$  provider-account
  $:  method=account-method
      access=@t
      refresh=@t
      account=@t
      expires=(unit @da)
      scopes=@t
      observed-at=@da
      renewal=account-renewal
  ==
::  what a read surface may show about an account: never the tokens.
+$  account-view
  $:  method=account-method
      account=@t
      expires=(unit @da)
      scopes=@t
      observed-at=@da
      renewing=?
      renewal-error=@t
      renewal-terminal=?
  ==
::
+$  omp-role  $?(%smol %default %slow)
::
::  omp-style profiles keep the human choice (role), exact provider and
::  model selector, and local execution adapter together. the bridge
::  registers profiles backed by a credential it can use on this machine.
::
+$  assistant-model
  $:  id=@tas
      provider=ai-provider
      role=omp-role
      selector=@t
      model=@t
      label=@t
      description=@t
      origin=@t
      registered-at=@da
  ==
::
+$  assistant-mode  $?(%ask %edit)
::
+$  context-kind  $?(%note %clay %file %web)
::
+$  context-status  $?(%pending %working %ready %failed)
::
::  remote clay sharing. shared paths are listed in shared-context and
::  served over one-shot subscriptions: /shared-context gives the
::  manifest, /shared-context/file/[pax] gives a fresh read of a listed
::  file to any ship that asks. rev counters remain from the earlier
::  remote-scry design and are unused by the watch transport.
::
+$  shared-entry     [rev=@ud label=@t mark=@tas size=@ud]
+$  manifest-entry   [pax=path label=@t mark=@tas size=@ud]
+$  remote-manifest  [rev=@ud at=@da entries=(list manifest-entry)]
+$  keen-track       [who=@p pax=path at=@da]
::
+$  context-source
  $:  id=@tas
      scope=context-scope
      kind=context-kind
      label=@t
      locator=@t
      snapshot=(unit @ux)
      generation=@ud
      status=context-status
      error=@t
      attempt=@ud
      active=?
      egress=(set ai-provider)
      policy-revision=@ud
      created-at=@da
      updated-at=@da
  ==
::
+$  question-status  $?(%pending %working %answered %failed)
::
::  durable question jobs snapshot the card so answers remain auditable
::  even if the source stack changes while a provider is working.
::
+$  card-question
  $:  id=@tas
      owner=@p
      stack=@tas
      card=@tas
      title=@t
      front=@t
      back=@t
      mode=assistant-mode
      prompt=@t
      profile=assistant-model
      packet=(unit @ux)
      citations=(list evidence-citation)
      created-at=@da
      status=question-status
      attempt=@ud
      response=@t
      result-title=@t
      result-front=@t
      result-back=@t
      updated-at=@da
  ==
::
+$  change-target  $?(%library %desk)
::
+$  change-status  $?(%draft %pending %working %ready %applied %rejected %failed)
::
::  a reviewed capability language for prompt-driven changes. original
::  values are snapshots used to reject stale plans before they can
::  overwrite a newer human edit.
::
+$  state-operation-kind
  $?  %create-stack
      %rename-stack
      %delete-stack
      %create-card
      %edit-card
      %delete-card
      %queue-card
  ==
::
+$  state-operation
  $:  kind=state-operation-kind
      stack=@tas
      card=@tas
      title=@t
      front=@t
      back=@t
      original-title=@t
      original-front=@t
      original-back=@t
  ==
::
+$  change-request
  $:  id=@tas
      target=change-target
      prompt=@t
      profile=assistant-model
      packet=(unit @ux)
      preconditions=(list entity-precondition)
      scope-preconditions=(list entity-precondition)
      plan=(unit @ux)
      citations=(list evidence-citation)
      created-at=@da
      status=change-status
      attempt=@ud
      summary=@t
      operations=(list state-operation)
      artifact=@t
      response=@t
      updated-at=@da
  ==
::
::  provider sign-in runs on the bridge host. a login-request carries
::  the public half of the handshake: the verification url and user code
::  the person must visit, and (for paste-back flows) the one-time
::  authorization code they hand back. codes are cleared from current
::  state the moment a request settles; provider credentials stay in the
::  codex and claude keychains on the bridge host.
::
+$  login-status  $?(%pending %working %challenge %done %failed)
::
::  provider sign-in runs on this ship. a login-request carries the
::  public half of the handshake (verification url and user code) plus
::  the private half the ship needs to finish it (device id, pkce
::  verifier, expected state). private fields and pasted codes are
::  cleared the moment a request settles and never appear in reads.
::
+$  login-request
  $:  id=@tas
      provider=ai-provider
      status=login-status
      auth-url=@t
      user-code=@t
      pasted-code=@t
      message=@t
      device-id=@t
      verifier=@t
      nonce=@t
      interval=@ud
      inflight=(unit @tas)
      deadline=(unit @da)
      attempt=@ud
      created-at=@da
      updated-at=@da
  ==
::
+$  ai-state
  $:  stacks=(map @tas stack)
      captures=(map @tas capture)
      provenance=(map [stack=@tas card=@tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
      changes=(map @tas change-request)
      contexts=(map @tas context-source)
      evidence=evidence-state
      learning=learning-state
  ==
::
::  Internal shallow inputs to revision tracking; never a public bulk read.
::
+$  agent-view
  $:  data=ai-state
      subscribed=(map [@p @tas] stack)
      logins=(map @tas login-request)
      accounts=(map ai-provider account-view)
  ==
::  +stack-info: stack information
::
::     all metadata about a stack.
::
::    .owner: owner of the stack
::    .name: name of the stack
::    .title: title of the stack
::    .items: items in the stack
::    .edit: permissions for editing the stack
::    .date-created: date the stack was created
::    .date-modified: date the stack was last modified
::
+$  stack-info
  $:  owner=@p
      title=@t
      filename=@tas
      allow-edit=edit-config
      date-created=@da
      last-modified=@da
  ==
::
+$  perm-config  [read=rule:clay write=rule:clay]
::
+$  edit-config     $?(%none %item %all)
::
::    $stack: stack
::
::  main stack data structure. contains all metadata and review data
::  for a stack.
::
::  .info: stack information
::  .items: items in the stack
::  .review-items: review information
::  .contributors: list of contributors and their permissions
::  .subscribers: set of subscribers
::  .last-update: date of last update
::
+$  stack
  $:  info=$+(info-or-error (each stack-info $+(error tang)))
      name=@tas
      =items
      review-items=items
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item
  $:  =content
      =learn
      last-review=(unit @da)
      name=@tas
  ==
::
+$  content
  $:  author=@p
      title=@t
      filename=@tas
      date-created=@da
      last-edit=@da
      read=?
      front=@t
      back=@t
      snippet=@t
      comments=(map @da comment)
      pending=?
  ==
::
+$  comment
  $:  author=@p
      date-created=@da
      content=@t
      pending=?
  ==
::
+$  recall-grade  $?(%again %hard %good %easy)
::
+$  learn
  $:  ease=@rs
      interval=@dr
      box=@
  ==
+$  review
  $:  who=@p
      stack=@tas
      item=@tas
  ==
::
+$  stack-delta
  $%  [%add-item who=@p stack=@tas data=item]
      [%add-review-item who=@p stack=@tas data=item]
      [%add-stack who=@p data=stack]
      [%new-stack =term]
      ::
      [%delete-item who=@p stack=@tas item=@tas]
      [%delete-review-item who=@p stack=@tas item=@tas]
      [%delete-stack who=@p stack=@tas]
      ::
      [%update-stack who=@p data=stack]
      [%update-review (set review)]
  ==
::
+$  primary-delta
  $%  stack-delta
      [%read who=@p stack=@tas item=@tas]
  ==
--
