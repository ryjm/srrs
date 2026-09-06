/-  *seer
|%
::
++  seer-schema-version  2
::
::  Display text only; action tags and receipts remain the machine contract.
++  operation-title
  |=  tag=@tas
  ^-  @t
  ?+  tag  'Action'
    %new-stack                'Create stack'
    %new-item                 'Create card'
    %schedule-item            'Schedule card'
    %raise-item               'Add card to review'
    %answered-item            'Record review answer'
    %review-stack             'Add stack to review'
    %delete-stack             'Delete stack'
    %delete-item              'Delete card'
    %edit-stack               'Rename stack'
    %edit-item                'Edit card'
    %read                     'Read card'
    %update-review            'Update review queue'
    %import                   'Import stack'
    %import-file              'Import file'
    %copy-stack               'Copy stack'
    %begin-capture            'Start card draft'
    %prepare-capture          'Prepare draft sources'
    %stage-card               'Save suggested card'
    %approve-proposal         'Add suggested card'
    %reject-proposal          'Discard suggested card'
    %discard-capture          'Discard draft'
    %delete-capture           'Remove draft from history'
    %purge-evidence           'Delete saved source text'
    %collect-retained         'Clean up unused history'
    %retire-operation-epoch   'Clear activity history'
    %add-context-source       'Add source'
    %set-context-egress       'Change source permissions'
    %rename-context-source    'Rename source'
    %archive-orphan-contexts  'Archive unused sources'
    %remove-context-source    'Remove source'
    %claim-context-source     'Start loading source'
    %finish-context-source    'Save loaded source'
    %fail-context-source      'Record source loading problem'
    %retry-context-source     'Try loading source again'
    %refresh-context-source   'Refresh source'
    %ask-card                 'Request AI help'
    %replace-assistant-models  'Update available AI models'
    %claim-card-question      'Start AI request'
    %answer-card-question     'Save AI answer'
    %apply-card-edit          'Save AI card edit'
    %fail-card-question       'Record AI request problem'
    %retry-card-question      'Try AI request again'
    %delete-card-question     'Delete AI conversation'
    %request-change           'Request AI changes'
    %claim-change             'Start preparing changes'
    %start-change             'Queue AI changes'
    %prepare-change-packet    'Prepare change sources'
    %propose-change           'Record proposed changes'
    %finish-change            'Save proposed changes'
    %fail-change              'Record change request problem'
    %apply-change             'Approve library changes'
    %reject-change            'Close change request'
    %retry-change             'Try change request again'
    %delete-change            'Delete change request'
    %request-login            'Start provider sign-in'
    %issue-bridge-nonce       'Prepare connection verification'
    %set-bridge-capability    'Change AI connection settings'
    %claim-login              'Start sign-in through the bridge'
    %post-login-challenge     'Show provider sign-in instructions'
    %submit-login-code        'Submit sign-in code'
    %finish-login             'Complete provider sign-in'
    %fail-login               'Record sign-in problem'
    %retry-login              'Try provider sign-in again'
    %cancel-login             'Close sign-in request'
    %consume-login-code       'Clear delivered sign-in code'
    %share-clay-context       'Share source file'
    %unshare-clay-context     'Stop sharing source file'
    %fetch-remote-manifest    'Request shared source list'
    %bridge-action            'Process bridge update'
    %checkpoint-work          'Record task progress'
    %heartbeat-work           'Keep task connection active'
    %recover-work             'Recover interrupted task'
    %cancel-work              'Cancel task'
  ==
::
++  operation-background
  |=  receipt=operation-receipt
  ^-  ?
  ?.  ?&  =(%ok status.receipt)
          !=(%unknown effect.receipt)
          !=(%outcome-unknown reason.receipt)
      ==
    %.n
  ?:  ?=(?(%read %answered-item %update-review) action.receipt)  %.y
  ?&  !=(%operator authority.receipt)
      ?=(?(%collect-retained %archive-orphan-contexts %replace-assistant-models %issue-bridge-nonce %claim-context-source %claim-card-question %claim-change %claim-login %prepare-change-packet %consume-login-code %checkpoint-work %heartbeat-work) action.receipt)
  ==
::
++  problem-description
  |=  reason=@tas
  ^-  @t
  ?+  reason  'Seer could not complete this action. Open its technical details to see the error code.'
    %no-change
      'No change was needed.'
    %receipt-not-found
      'No saved result was found. This does not show whether the action ran. Check the related item before submitting it again.'
    %operation-epoch-expired
      'This result belongs to activity history that was cleared. Its outcome cannot be confirmed here. Check the related item before submitting it again.'
    %outcome-unknown
      'An external request may have run, but Seer cannot confirm its result. Check the provider and the related task before considering another attempt.'
    %receipt-limit
      'Activity history is full, and no saved result is available for this request. Review outstanding tasks before clearing activity history in Settings.'
    %operation-digest-conflict
      'This request reference belongs to different submitted content. Check the original activity result; it does not confirm this submission.'
    %plan-digest-mismatch
      'The changes no longer match the preview you approved. Open the latest preview and review it before approving.'
    ?(%stale-precondition %stale-observation %content-conflict %original-mismatch)
      'The card or library changed after this request was prepared. Review the current content and prepare updated changes before approving.'
    ?(%missing-precondition %duplicate-precondition %precondition-domain %unversioned-entity %subject-version-unavailable)
      'Seer could not verify the current card or library version. Open the current item and prepare a fresh preview before approving changes.'
    ?(%stack-id-in-use %stack-exists)
      'A stack already uses this identifier. Open that stack, or choose a different identifier for the new stack.'
    ?(%card-id-in-use %card-exists)
      'A card already uses this identifier in the stack. Open that card, or choose a different identifier for the new card.'
    %change-id-in-use
      'A change request already uses this identifier. Open the existing request before creating another.'
    ?(%missing-stack %missing-card %subject-not-found %not-found)
      'The requested card or stack was not found. Open Library and select an item that is still available.'
    %invalid-stack
      'This stack cannot accept the requested changes. Open Library and choose an editable stack.'
    %wrong-owner
      'This action requires an item owned by your ship. Open your own copy before making changes.'
    ?(%change-not-found %capture-not-found %work-not-found)
      'The related request was not found. Check Activity and the current task list before starting new work.'
    ?(%change-not-draft %capture-complete %work-already-settled %work-not-queued %action-not-applicable)
      'This action is not available in the current state. Open the related item to see its latest status and available actions.'
    ?(%model-unavailable %model-changed)
      'The selected AI model is no longer available with these settings. Check the AI connection in Settings and choose an available model.'
    %provider-unavailable
      'The assistant was unavailable. Check its service status and your connection in Settings before starting more work.'
    %provider-unsupported
      'The bridge does not support this assistant. Choose a supported assistant in Settings.'
    %unsupported-isolation
      'This bridge cannot run AI requests with the required privacy controls. You can still add and review cards manually.'
    %login-failed
      'Provider sign-in did not complete. Open Settings to check the sign-in request and provider instructions.'
    %invalid-login-code
      'Seer could not accept this sign-in code. Paste only the code from the provider, without line breaks.'
    %invalid-login-challenge
      'The bridge returned sign-in instructions Seer could not accept. Check the sign-in request in Settings.'
    ?(%login-code-changed %login-version-unavailable)
      'The sign-in request changed before the code could be consumed. Check its current status in Settings before submitting another code.'
    %delivery-unavailable
      'No sign-in code is available to deliver. It may already have been consumed. Check the sign-in status in Settings.'
    ?(%paired-bridge-required %invalid-bridge-proof %invalid-bridge-capability)
      'Seer could not verify the bridge connection. Check the bridge configuration on the computer running it.'
    ?(%operator-entrypoint-required %worker-action-required %worker-mismatch %invalid-worker %work-scope-mismatch %catalog-claim-required)
      'This request does not have the required permission. Use Seer for manual actions and check the bridge connection in Settings.'
    ?(%invalid-command %invalid-worker-action %invalid-nonce)
      'Seer could not accept the request format. Reopen the page and check that the connected tools are up to date.'
    %action-trapped
      'Seer encountered an error while handling this action. Check the related item and Activity details before starting another attempt.'
    ?(%work-fenced %lease-expired %lease-unavailable)
      'This bridge worker no longer has permission to update the task. Check its current status before recovering it; an external request may already have started.'
    %lease-not-expired
      'The task connection is still active. Check its progress before attempting recovery.'
    ?(%work-deadline %deadline-expired %deadline-unavailable)
      'The task cannot continue within its recorded time limit. Check its status and any external result before starting another attempt.'
    ?(%checkpoint-order %source-owned-checkpoint %output-checkpoint-required %provider-checkpoint-required %packet-already-frozen %work-required)
      'This task update is not valid at the current stage. Check task progress and the bridge before starting more work.'
    %worker-failed
      'The bridge could not finish this request. Open the error details for more information.'
    ?(%invalid-provider-output %invalid-change-output)
      'The AI result could not be accepted. Review the request and its sources before deciding whether to ask for a new result.'
    %source-fetch-failed
      'The source could not be loaded. Open the related draft or stack and check its address and access permissions in the source list.'
    %clay-unavailable
      'The source file could not be read from this ship. Check that the file exists and its path is correct.'
    %remote-file-required
      'A shared source must point to a file, not a directory. Choose a file shared by the other ship.'
    ?(%missing %missing-source)
      'A source needed by this request was not found. Open the related draft or card and choose an available source.'
    %egress-denied
      'A source is not permitted to be sent to this assistant. Open the related draft or card and check its sharing permissions, or leave it out of the request.'
    %policy-changed
      'Source permissions changed after this request was prepared. Review the permissions and prepare a new request with the sources you intend to share.'
    %out-of-scope
      'A reference does not belong to this request or its selected sources. Choose sources attached to the relevant card, stack, or request.'
    %archived
      'A required source is archived. Choose an active source before preparing a new request.'
    ?(%not-ready %source-not-ready %failed)
      'A required source is not ready to use. Check its loading status in the source list on the related draft or card.'
    ?(%stale %stale-snapshot %stale-generation)
      'A source changed after this request was prepared. Review the current source and prepare a new request.'
    %purged
      'The saved source text was deleted. Add an available source and prepare a new request.'
    %listing-only
      'The selected source contains a file list, not file contents. Select a source file to use as a reference.'
    %excluded
      'A required source was excluded from the request. Review the source selection before continuing.'
    ?(%invalid-selection %invalid-range %duplicate-selection)
      'The source selection is invalid or repeated. Choose valid excerpts from the available sources.'
    ?(%packet-unavailable %missing-packet)
      'The saved sources for this request are unavailable. Open the related draft or card, check its source list, and prepare a new request.'
    ?(%packet-blocked %blocked-packet)
      'The selected sources cannot be used for this request. Open the related draft or card and check their availability and sharing permissions.'
    ?(%packet-mismatch %provider-mismatch %capture-mismatch)
      'The saved references do not match this request. Review the request, model, and selected sources before preparing it again.'
    ?(%citation-mismatch %invalid-citation-range %unselected-citation %uncited-proposal)
      'The result is missing valid source references. Ask for a result supported by exact excerpts from the selected sources.'
    ?(%missing-learning-objective %missing-capture-goal)
      'The card draft needs a learning goal. Describe what you want to learn before preparing drafts.'
    %missing-supported-claim
      'The card draft needs a claim supported by its sources. Review the draft and add a supported claim.'
    %missing-why-new
      'The card draft needs an explanation of what it adds to your library. Review existing cards before proposing it.'
    %duplicate-live-card
      'This card is already in your library. Use the existing card instead of adding a duplicate.'
    %duplicate-proposal
      'An equivalent card draft is already recorded. Review the existing draft instead of adding another.'
    %rejected-identical
      'This same card draft was already rejected. Review that decision; new wording alone does not make it a new draft.'
    %superseded-identical
      'This card draft has been replaced by a newer version. Review the newer draft.'
    %decision-conflict
      'This draft already has a different review decision. Open its current result before making another decision.'
    ?(%artifact-unavailable %missing-artifact)
      'The saved draft or AI result is unavailable. Check the current request before preparing a replacement.'
    %approved-card-dependency
      'An approved card still uses this source copy. Seer has kept it so the card retains its references.'
    ?(%snapshot-limit %packet-limit %artifact-limit %storage-limit %learning-storage-limit)
      'Retained history has reached its storage limit. Review cleanup options in Settings; references used by approved cards must be kept.'
    ?(%blob-conflict %snapshot-conflict %artifact-conflict %artifact-index-conflict)
      'Seer found conflicting retained records. Review Activity details before creating or deleting related history.'
    ?(%operation-limit %affected-limit %precondition-limit %observation-limit)
      'This request covers too many changes or library items. Split it into smaller requests.'
    ?(%operation-text-limit %output-budget-exhausted %artifact-too-large)
      'The proposed result is too large to save. Ask for fewer changes or a shorter result.'
    ?(%budget-exhausted %observation-byte-limit %library-read-report-limit)
      'The request and its references exceed the size limit. Narrow the request or select shorter source excerpts.'
    %source-too-large
      'The source text is too large to save. Add a smaller file or a shorter excerpt.'
    ?(%metadata-too-large %caveat-too-large %decision-reason-too-large)
      'The description is too long to save. Shorten the text before submitting it.'
    %invalid-utf8
      'The source is not valid UTF-8 text. Save it as UTF-8 before adding it.'
    %selection-limit
      'Too many source excerpts were selected. Choose fewer references for this request.'
    %citation-limit
      'The result contains too many source references. Ask for a shorter, more focused result.'
    %purge-limit
      'Too many retained references were selected for deletion. Select a smaller group.'
    %invocation-limit
      'This task has used its allowed AI requests. Review its progress and any existing result before starting more work.'
    ?(%model-limit %invalid-model-catalog)
      'Seer could not accept the list of AI models. Check the bridge and its model settings.'
    %nonce-limit
      'Too many connection checks are outstanding. Check the bridge connection before sending more requests.'
    ?(%invalid-capture %invalid-proposal %invalid-request)
      'The draft or request is missing required information or contains invalid content. Review its goal, text, and selected sources.'
    %invalid-change-prompt
      'The change request is empty, too long, or contains invalid text. Enter a clear, shorter description of the changes you want.'
    %invalid-change-summary
      'The proposed changes need a valid request and summary. Review both before submitting the proposal.'
    ?(%invalid-plan %operation-shape %ambiguous-operations)
      'The proposed changes are incomplete or conflict with one another. Prepare a clear, non-overlapping set of changes.'
    %empty-plan
      'The proposal contains no library changes. Review the request before preparing a new proposal.'
    %desk-brief-required
      'Ask for a written proposal describing the intended app improvements.'
    ?(%unobserved-plan-target %incomplete-library-observation %incomplete-library-metadata %incomplete-library-read)
      'The bridge did not read all library information needed for these changes. Narrow the request or complete that review before preparing changes.'
    ?(%invalid-read-report %invalid-library-read-report %invalid-bounded-query %duplicate-observation)
      'The bridge could not provide a valid record of the library it reviewed. Check the bridge before preparing new changes.'
    %no-supported-candidate
      'The assistant found no suitable result supported by the selected sources. Review the learning goal and choose more relevant sources.'
    %cancelled
      'The task was cancelled in Seer. This does not confirm that an external request was stopped.'
    ?(%capability-rotated %epoch-retired)
      'Connection settings or activity history changed, interrupting this task. Check its current status before starting more work.'
    %lease-recovered
      'The interrupted task was returned to the queue.'
  ==
::
++  operation-state
  |=  receipt=operation-receipt
  ^-  @t
  ?:  ?=(?(%receipt-not-found %operation-epoch-expired) reason.receipt)
    'Result unavailable'
  ?:  ?|  =(%unknown effect.receipt)
          =(%outcome-unknown status.receipt)
          =(%outcome-unknown reason.receipt)
      ==
    'Outcome uncertain'
  ?.  =(%ok status.receipt)
    ?+  status.receipt  'Needs attention'
      %conflict          'Needs review'
      %invalid           'Not accepted'
      %unauthorized      'Permission needed'
      %budget-exhausted  'Limit reached'
      %replay-expired    'Result unavailable'
    ==
  ?:  =(%no-change reason.receipt)  'No change needed'
  ?:  =(%staged effect.receipt)  'Needs review'
  ?:  =(%committed effect.receipt)  'Completed'
  ?+  action.receipt  'Completed'
    %begin-capture       'Draft recorded'
    ?(%ask-card %retry-card-question %request-change)
      'Request recorded'
    ?(%start-change %retry-change %request-login %retry-login %retry-context-source %recover-work)
      'Queued'
    ?(%claim-card-question %claim-change %claim-context-source %claim-login)
      'Started'
    %post-login-challenge  'Sign-in needed'
    %submit-login-code     'Code recorded'
  ==
::
++  operation-outcome
  |=  receipt=operation-receipt
  ^-  @t
  ::  Missing history is not evidence of failure or of an external request.
  ?:  ?=(?(%receipt-not-found %operation-epoch-expired) reason.receipt)
    (problem-description reason.receipt)
  ?:  ?|  =(%unknown effect.receipt)
          =(%outcome-unknown status.receipt)
          =(%outcome-unknown reason.receipt)
      ==
    (problem-description %outcome-unknown)
  ?.  =(%ok status.receipt)  (problem-description reason.receipt)
  ?:  =(%no-change reason.receipt)  (problem-description %no-change)
  ?+  action.receipt
    ?:  =(%staged effect.receipt)
      'A result was saved for review. It has not been applied to your library.'
    ?:  =(%committed effect.receipt)  'The library changes were saved.'
    'The action was recorded.'
    %new-stack          'The stack was created in your library.'
    %new-item           'The card was added to your library.'
    %edit-stack         'The stack name was saved.'
    ?(%edit-item %apply-card-edit)
      'The card edits were saved to your library.'
    %delete-stack       'The stack was removed from your library.'
    %delete-item        'The card was removed from your library.'
    %copy-stack         'A copy of the stack was saved to your library.'
    %raise-item         'The card was added to the review queue.'
    %review-stack       'The stack was added to the review queue.'
    %answered-item      'Your recall rating was saved.'
    %update-review      'The review queue was updated.'
    %import             'The stack import was requested. Check Library for the result.'
    %import-file        'The file import was requested. Check Library for the result.'
    %begin-capture
      'The card draft was created. Add sources to prepare it for your assistant.'
    %prepare-capture
      'The selected sources are ready for your assistant to use.'
    %stage-card
      'The card draft was saved for review. Approve it to add the card to your library.'
    %approve-proposal   'The approved card was added to your library.'
    %reject-proposal    'The card suggestion was rejected.'
    %discard-capture
      'The remaining drafts were discarded. Previously approved cards are unchanged.'
    %delete-capture
      'The completed draft was removed from history. Approved cards remain in your library.'
    %add-context-source
      'The source was added. Check its loading status in the draft or card.'
    %set-context-egress  'The source permissions were saved.'
    %rename-context-source  'The source name was saved.'
    %remove-context-source
      'The source was removed. Copies used by earlier requests are kept in history.'
    %archive-orphan-contexts  'Sources belonging to removed items were archived.'
    %finish-context-source  'The loaded source text was saved.'
    %refresh-context-source
      'The source refresh was accepted. Open the related draft or card and check the source list for the loading result.'
    %retry-context-source
      'The source was queued for another loading attempt. Follow its progress in the source list on the related draft or card.'
    ?(%ask-card %retry-card-question)
      'The AI request was accepted. Open the card to see its result or current progress.'
    %answer-card-question  'The AI answer was saved. Open the card to read it.'
    %delete-card-question  'The AI conversation was deleted. Saved card edits are unchanged.'
    %request-change
      'The change request was saved. Open it in Inbox to see the next step.'
    ?(%start-change %retry-change)
      'The change request was queued. Any proposed library changes still need your approval.'
    %prepare-change-packet
      'The library information and selected references were saved for this change request.'
    ?(%propose-change %finish-change)
      'The proposed changes are ready to review in Inbox.'
    %apply-change       'The approved changes were saved to your library.'
    %reject-change      'The change request was closed without applying changes.'
    %delete-change     'The change request was deleted. Any previously applied library changes remain.'
    ?(%request-login %retry-login)
      'The sign-in request was queued for the bridge. Open Settings for the next sign-in step.'
    %post-login-challenge
      'Provider sign-in instructions are ready. Open Settings to continue.'
    %submit-login-code
      'The sign-in code was submitted. Check Settings for the result.'
    %finish-login       'The bridge reported that sign-in completed.'
    %cancel-login
      'The sign-in request was closed in Seer. This does not sign you out of the provider.'
    %consume-login-code  'The delivered sign-in code was cleared from Seer.'
    %set-bridge-capability
      'AI connection settings were saved. Existing tasks may need attention; review them before starting more work.'
    %retire-operation-epoch
      'Activity history was cleared. Review interrupted AI tasks before starting more work.'
    %purge-evidence      'The selected saved source text was deleted.'
    %collect-retained    'Unused source copies were removed.'
    %replace-assistant-models  'The list of available AI models was updated.'
    %share-clay-context   'The source file is now shared with other ships.'
    %unshare-clay-context  'The source file is no longer shared with other ships.'
    %fetch-remote-manifest
      'The shared source list was requested. Open the related stack and check its source file picker for the result.'
    %issue-bridge-nonce  'A one-time connection check was prepared.'
    ?(%claim-card-question %claim-change %claim-context-source %claim-login)
      'The bridge accepted the task and marked it as started.'
    %checkpoint-work    'Task progress was recorded.'
    %heartbeat-work     'The task connection was renewed.'
    %recover-work
      'The interrupted task was returned to the queue before a provider request was recorded as started.'
    %cancel-work
      'Cancellation was recorded in Seer. This does not confirm that an external request was stopped.'
  ==
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
    ::  A sign-in waits for a person to finish the provider's device flow;
    ::  Codex device codes stay valid for fifteen minutes. Every other kind
    ::  of work is a single provider invocation and keeps the tight bound.
    =/  window=@dr  ?:(=(%login kind.key) ~m15 ~m3)
    %=  job
      attempt                attempt
      lease                  (shax (jam [epoch.control secret-revision.control key attempt now]))
      lease-until            `(add now ~m2)
      deadline               `(add now window)
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
