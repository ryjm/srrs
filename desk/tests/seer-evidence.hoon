/-  *seer
/+  *test, ev=seer-evidence
|%
++  fixed-now  ~2026.9.4
++  source
  ^-  context-source
  %*  .  *context-source
    id               %note
    scope            [%capture %capture]
    kind             %note
    label            'Original label'
    locator          'local note'
    active           %.y
    egress           (sy ~[%codex])
    policy-revision  1
  ==
++  request
  ^-  packet-request
  %*  .  *packet-request
    work           [%question ~zod %root %question]
    attempt        1
    scope          [%capture %capture]
    profile        %*(. *assistant-model provider %codex)
    mode           %ask
    objective      'Explain the selected evidence.'
    selections     ~[[%note 0 ~ %.y %.n]]
    max-bytes      32.768
    excerpt-bytes  131.072
  ==
++  field
  |=  [value=json key=@t]
  ^-  json
  ?>  ?=(%o -.value)
  (~(got by p.value) key)
++  published
  (publish-snapshot:ev ~zod fixed-now source 'aéz' %full 'local note' ~ %note *evidence-state)
::  Repeated identical refreshes are distinct immutable observations, but
::  share one scoped body. Archive affects selection, not pinned dispatch.
++  test-refresh-archive-revocation-and-purge
  =/  first  published
  =/  sources  (~(put by *(map @tas context-source)) %note source.first)
  =/  built  (build-packet:ev ~zod fixed-now request sources store.first)
  =/  original  (packet-projection:ev packet.built sources store.built 32.768)
  =/  refreshed
    (publish-snapshot:ev ~zod fixed-now source.first 'aéz' %full 'local note' ~ %note store.built)
  =/  archived  source.refreshed(active %.n, label 'Renamed locator')
  =/  sources  (~(put by sources) %note archived)
  =/  historical  (packet-projection:ev packet.built sources store.refreshed 32.768)
  =/  revoked  (~(put by sources) %note archived(egress ~, policy-revision 2))
  =/  old-id  (need snapshot.source.first)
  =/  old  (~(got by snapshots.store.refreshed) old-id)
  =/  purged
    store.refreshed(snapshots (~(put by snapshots.store.refreshed) old-id old(available %.n)))
  =/  unavailable  (packet-projection:ev packet.built sources purged 32.768)
  ;:  weld
    (expect-eq !>(~) !>(error.first))
    (expect-eq !>(~) !>(blocked.packet.built))
    (expect-eq !>(%.n) !>(=(snapshot.source.first snapshot.source.refreshed)))
    (expect-eq !>(4) !>(stored-bytes.store.refreshed))
    (expect-eq !>(2) !>(snapshot-count.store.refreshed))
    (expect-eq !>(2) !>((~(got by blob-refs.store.refreshed) blob.old)))
    (expect-eq !>((field original 'canonical_prompt')) !>((field historical 'canonical_prompt')))
    (expect-eq !>(~) !>((packet-egress-error:ev packet.built sources store.refreshed)))
    (expect-eq !>(`%egress-denied) !>((packet-egress-error:ev packet.built revoked store.refreshed)))
    (expect-eq !>([%s 'purged']) !>((field unavailable 'blocked_reason')))
    (expect-eq !>(~) !>((field unavailable 'canonical_prompt')))
    (expect-eq !>(`%purged) !>((validate-citations:ev packet.built ~[[old-id 1 3 'é']] purged)))
  ==
::  Byte limits must not split a multibyte character. Optional prefix
::  selection is explicit; exactly the same mandatory range must block.
++  test-utf8-selection-and-exact-citations
  =/  first  published
  =/  sources  (~(put by *(map @tas context-source)) %note source.first)
  =/  base-request  request
  =/  limited
    (build-packet:ev ~zod fixed-now base-request(excerpt-bytes 2) sources store.first)
  =/  mandatory
    (build-packet:ev ~zod fixed-now base-request(excerpt-bytes 2, selections ~[[%note 0 ~ %.y %.y]]) sources store.first)
  =/  full  (build-packet:ev ~zod fixed-now request sources store.first)
  =/  id  (need snapshot.source.first)
  ?>  ?=(^ entries.packet.limited)
  ?>  ?=(^ entries.packet.mandatory)
  =/  entry  i.entries.packet.limited
  ;:  weld
    (expect-eq !>(~) !>(blocked.packet.limited))
    (expect-eq !>([0 1 `%budget-omitted]) !>([start.entry end.entry reason.entry]))
    (expect-eq !>(`%budget-exhausted) !>(blocked.packet.mandatory))
    (expect-eq !>(4) !>(end.i.entries.packet.mandatory))
    (expect-eq !>(~) !>((validate-citations:ev packet.full ~[[id 1 3 'é']] store.full)))
    (expect-eq !>(`%invalid-citation-range) !>((validate-citations:ev packet.full ~[[id 1 2 'é']] store.full)))
    (expect-eq !>(`%citation-mismatch) !>((validate-citations:ev packet.full ~[[id 1 3 'e']] store.full)))
    (expect-eq !>(`%unselected-citation) !>((validate-citations:ev packet.limited ~[[id 1 3 'é']] store.limited)))
    (expect-eq !>(`%unselected-citation) !>((validate-citations:ev packet.full ~[[0x0 0 1 'a']] store.full)))
  ==
::  Failed admission must preserve every old snapshot and body reference.
++  test-snapshot-admission-and-bounded-expansion
  =/  first  published
  =/  malformed  (@t 0xc3)
  =/  rejected
    (publish-snapshot:ev ~zod fixed-now source.first malformed %full '' ~ %note store.first)
  =/  capped  store.first(snapshot-count 4.096)
  =/  full
    (publish-snapshot:ev ~zod fixed-now source.first 'new' %full '' ~ %note capped)
  =/  id  (need snapshot.source.first)
  =/  exact  (snapshot-projection:ev id 1 2 2.048 store.first)
  =/  split  (snapshot-projection:ev id 2 1 2.048 store.first)
  =/  small  (snapshot-projection:ev id 0 4 1.024 store.first)
  =/  huge  (bex 4.096)
  =/  bad-start  (snapshot-projection:ev 0x0 huge 1 1.024 store.first)
  =/  bad-length  (snapshot-projection:ev 0x0 0 huge 1.024 store.first)
  ;:  weld
    (expect-eq !>(`%invalid-utf8) !>(error.rejected))
    (expect-eq !>(source.first) !>(source.rejected))
    (expect-eq !>(store.first) !>(store.rejected))
    (expect-eq !>(`%snapshot-limit) !>(error.full))
    (expect-eq !>(capped) !>(store.full))
    (expect-eq !>([%s 'é']) !>((field exact 'text')))
    (expect-eq !>([%s 'invalid']) !>((field split 'status')))
    (expect-eq !>([%s 'invalid']) !>((field bad-start 'status')))
    (expect-eq !>([%s 'invalid']) !>((field bad-length 'status')))
    (expect-eq !>(%.y) !>((lte (met 3 (en:json:html small)) 1.024)))
  ==
--
