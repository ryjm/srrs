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
      $:  %schedule-item
          stak=@tas
          item=@tas
          scheduled=@da
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
      [%read who=@p stak=@tas item=@tas]
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
      ==
      [%approve-proposal capture=@tas proposal=@tas]
      [%reject-proposal capture=@tas proposal=@tas]
      [%discard-capture capture=@tas]
      [%delete-capture capture=@tas]
      $:  %add-context-source
          id=@tas
          owner=@p
          stak=@tas
          card=(unit @tas)
          kind=context-kind
          label=@t
          locator=@t
          content=@t
      ==
      [%remove-context-source id=@tas]
      [%claim-context-source id=@tas worker=@t nonce=@t proof=@]
      [%recover-context-source id=@tas worker=@t nonce=@t proof=@]
      [%finish-context-source id=@tas worker=@t label=@t content=@t nonce=@t proof=@]
      [%fail-context-source id=@tas worker=@t error=@t nonce=@t proof=@]
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
          context-ids=(list @tas)
      ==
      [%clear-assistant-models worker=@t]
      $:  %register-assistant-model
          id=@tas
          provider=ai-provider
          role=omp-role
          selector=@t
          model=@t
          label=@t
          description=@t
          worker=@t
      ==
      [%claim-card-question id=@tas worker=@t]
      [%answer-card-question id=@tas worker=@t response=@t]
      $:  %apply-card-edit
          id=@tas
          worker=@t
          title=@t
          front=@t
          back=@t
          response=@t
      ==
      [%fail-card-question id=@tas worker=@t response=@t]
      [%retry-card-question id=@tas]
      [%delete-card-question id=@tas]
      $:  %request-change
          id=@tas
          target=change-target
          profile=assistant-model
          prompt=@t
      ==
      [%claim-change id=@tas worker=@t]
      [%stage-change-operation id=@tas worker=@t operation=state-operation]
      [%finish-change id=@tas worker=@t summary=@t artifact=@t]
      [%fail-change id=@tas worker=@t response=@t]
      [%apply-change id=@tas]
      [%reject-change id=@tas]
      [%retry-change id=@tas]
      [%delete-change id=@tas]
      [%request-login id=@tas provider=ai-provider]
      [%issue-bridge-nonce nonce=@t]
      [%claim-login id=@tas worker=@t nonce=@t proof=@]
      [%post-login-challenge id=@tas worker=@t auth-url=@t user-code=@t nonce=@t proof=@]
      [%submit-login-code id=@tas code=@t]
      [%finish-login id=@tas worker=@t nonce=@t proof=@]
      [%fail-login id=@tas worker=@t message=@t nonce=@t proof=@]
      [%retry-login id=@tas]
      [%cancel-login id=@tas]
      [%consume-login-code id=@tas worker=@t nonce=@t proof=@]
      [%share-clay-context pax=path]
      [%unshare-clay-context pax=path]
      [%fetch-remote-manifest who=@p]
      [%refresh-context-source id=@tas]
  ==
::
::  AI capture sessions live on the ship, not in any one model's context.
::  Codex and Claude can therefore hand the same learning session back and
::  forth.  Drafts remain proposals until a person approves them in Seer.
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
  ==
::
+$  provenance
  $:  capture=@tas
      source=@t
      rationale=@t
      created-by=@t
      proposed-at=@da
      approved-at=@da
  ==
::
+$  ai-provider  $?(%codex %claude)
::
+$  omp-role  $?(%smol %default %slow)
::
::  OMP-style profiles keep the human choice (role), exact provider/model
::  selector, and local execution adapter together. The bridge only registers
::  profiles backed by a credential it can actually use on this machine.
::
+$  assistant-model
  $:  id=@tas
      provider=ai-provider
      role=omp-role
      selector=@t
      model=@t
      label=@t
      description=@t
      worker=@t
      registered-at=@da
  ==
::
+$  assistant-mode  $?(%ask %edit)
::
+$  context-kind  $?(%note %clay %file %web)
::
+$  context-status  $?(%pending %working %ready %failed)
::
::  Remote clay sharing: a shared file is grown into the gall publication
::  namespace (public to any ship that knows the path); the manifest lists
::  every shared entry and regrows on each change.  Revisions are tracked
::  because fine-protocol reads need concrete cases and culls need them.
::
+$  shared-entry     [rev=@ud label=@t mark=@tas size=@ud]
+$  manifest-entry   [pax=path label=@t mark=@tas size=@ud]
+$  remote-manifest  [rev=@ud at=@da entries=(list manifest-entry)]
+$  keen-track       [who=@p pax=path at=@da]
::
+$  context-source
  $:  id=@tas
      owner=@p
      stack=@tas
      card=(unit @tas)
      kind=context-kind
      label=@t
      locator=@t
      content=@t
      status=context-status
      error=@t
      worker=@t
      active=?
      created-at=@da
      updated-at=@da
  ==
::
+$  question-status  $?(%pending %working %answered %failed)
::
::  Durable question jobs snapshot the card so answers remain auditable even
::  if the source stack changes while a local model provider is working.
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
      created-at=@da
      status=question-status
      worker=@t
      response=@t
      result-title=@t
      result-front=@t
      result-back=@t
      updated-at=@da
  ==
::
+$  change-target  $?(%library %desk)
::
+$  change-status  $?(%pending %working %ready %applied %rejected %failed)
::
::  A reviewed capability language for prompt-driven changes.  Original
::  values are snapshots used to reject stale plans before they can overwrite
::  a newer human edit.
::
+$  state-operation-kind
  $?(%create-stack %rename-stack %delete-stack %create-card %edit-card %delete-card %queue-card)
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
      created-at=@da
      status=change-status
      worker=@t
      summary=@t
      operations=(list state-operation)
      artifact=@t
      response=@t
      updated-at=@da
  ==
::
::  Provider sign-in runs on the bridge host, never on the ship.  A
::  login-request only carries the public half of the handshake: the
::  verification URL and user code the person must visit, and (for
::  paste-back flows) the one-time authorization code they hand back.
::  Codes are cleared from current state the moment a request settles;
::  Seer never stores provider credentials.
::
+$  login-status  $?(%pending %working %challenge %done %failed)
::
+$  login-request
  $:  id=@tas
      provider=ai-provider
      status=login-status
      auth-url=@t
      user-code=@t
      pasted-code=@t
      message=@t
      worker=@t
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
      question-contexts=(map @tas (list @tas))
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
+$  stack-1
  $:  stack=(each stack-info tang)
      name=@tas
      items=(map @tas item-1)
      review-items=(map @tas item-1)
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item-1
  $:  =content
      =learn
      name=@tas
  ==
--
