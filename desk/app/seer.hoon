/-  mcp, seer-types=seer
/+  *server, *seer, *seer-json, *seer-mcp, reader=seer-read, ev=seer-evidence, effects=seer-effects, memory=seer-learning, oa=seer-oauth, net=seer-net, default-agent, verb, agentio
/=  index  /app/seer/index
/*  seer-tile  %png  /lib/web/seer-tile/png
::  htmx 2.0.2 dist/htmx.min.js, pinned from unpkg;
::  sha256 e1746d9759ec0d43c5c284452333a310bb5fd7285ebac4b2dc9bf44d72b5a887
::
/*  htmx-src  %js  /lib/web/htmx-min/js
::
=,  seer-types
|%
+$  seer-state
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
      changes=(map @tas change-request)
      logins=(map @tas login-request)
      accounts=(map ai-provider provider-account)
      catalog-pending=(set ai-provider)
      catalog-active=(map ai-provider [serial=@ud deadline=@da])
      catalog-serial=@ud
      contexts=(map @tas context-source)
      context-count=@ud
      evidence=evidence-state
      learning=learning-state
      shared-context=(map path shared-entry)
      shared-manifest-rev=@ud
      outstanding-keens=(map @tas keen-track)
      remote-manifests=(map @p remote-manifest)
      recent-clay=(list @t)
      context-revs=(map @tas @ud)
      operating=agent-state
  ==
+$  card  card:agent:gall
::
--
::
=|  seer-state
=*  state  -
^-  agent:gall
=<
  %+  verb  |
  |_  bol=bowl:gall
  +*  this       .
      seer-core  +>
      io         ~(. agentio bol)
      sc         ~(. seer-core bol)
      def        ~(. (default-agent this %|) bol)
  ::
  ++  on-init
    ^-  (quip card _this)
    :_  this(epoch.operating.state now.bol)
    :~
      [%pass /bind/seer %arvo %e %connect [~ /seer] dap.bol]
      [%pass /bind/seer %arvo %e %connect [~ /apps/seer] dap.bol]
    ==
  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    ::  All poke ingress is local. Federation uses watches/facts.
    ::  Reviewing an imported card emits a local copy poke. Eyre attributes
    ::  unauthenticated requests to an anonymous identity, so the owner
    ::  check applies to every mark except the HTTP request itself, which
    ::  answers with a login redirect.
    ~|  'seer-owner-action-required'
    ?>  ?|(=(our.bol src.bol) =(%handle-http-request mark))
    =^  cards  state
      ?+    mark  (on-poke:def mark vase)
          %noun
        =/  native  sc
        =.  operator-authorized.native  trusted-operator:native
        (poke-noun:native !<(* vase))
          %sign-arvo
        ?>  trusted-operator:sc
        (poke-sign-arvo:sc !<(sign-arvo vase))
          %seer-action
        =/  envelope  !<(command vase)
        =/  native  sc
        =.  operator-authorized.native  trusted-operator:native
        (apply-command:native envelope)
          %handle-http-request
        =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
        ::  Eyre pokes authenticated requests as this ship; a guest identity
        ::  or a foreign poke of this mark only ever receives the redirect.
        ?:  ?&(authenticated.inbound-request =(our.bol src.bol))
          %+  poke-handle-http-request:sc  eyre-id
          inbound-request
        :_  state
        %+  give-simple-payload:app  eyre-id
        (login-redirect:gen request.inbound-request)
      ==
    =^  more  state  flush:sc
    [(weld cards more) this]
  ::
  ++  on-watch
    |=  =path
    ^-  (quip card _this)
    =^  cards  state
      ?+  path  (on-watch:def path)
        [%seertile *]                (peer-seertile:sc t.path)
        [%seer-primary *]            [~ state]
        [%http-response *]           [~ state]
        [%stack @ ~]                 (peer-stack:sc i.t.path)
        [%shared-context ~]          serve-shared-manifest:sc
        [%shared-context %file @ *]  (serve-shared-file:sc t.t.path)
      ==
    [cards this]
  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    =.  operating.state  operating.state(changed ~, failure ~)
    =/  current-fetch
      ?.  ?=([%shared-fetch @ @ ~] wire)  %.y
      =/  source  (~(get by contexts.state) i.t.wire)
      ?~  source  %.n
      =(generation.u.source (slav %ud i.t.t.wire))
    ?.  current-fetch  [~ this]
    =/  before  observation-view:sc
    =^  moves  this
      |^  ^-  (quip card _this)
      ?+    -.sign  (on-agent:def wire sign)
          %watch-ack
        ?:  ?=([%shared-manifest @ ~] wire)
          ?~  p.sign  [~ this]
          =^  cards  state
            (fail-remote-manifest:sc (slav %p i.t.wire))
          [cards this]
        ?:  ?=([%import @ @ ~] wire)
          [~ this]
        ?.  ?=([%shared-fetch @ @ ~] wire)
          (on-agent:def wire sign)
        ?~  p.sign  [~ this]
        =^  cards  state
          %+  fail-shared-fetch:sc  i.t.wire
          'That ship shares nothing at this path.'
        [cards this]
          %kick
        ?:  ?=([%shared-fetch @ @ ~] wire)
          =^  cards  state
            %+  fail-shared-fetch:sc  i.t.wire
            'The ship disconnected before replying.'
          [cards this]
        ?:  ?=([%shared-manifest @ ~] wire)
          =^  cards  state
            (fail-remote-manifest:sc (slav %p i.t.wire))
          [cards this]
        ?:  ?=([%import @ @ ~] wire)
          =/  who   (slav %p i.t.wire)
          =/  name  i.t.t.wire
          ?.  (~(has by stack-subs.state) [who name])
            [~ this]
          :_  this
          [%pass wire %agent [who %seer] %watch /stack/[name]]~
        :_  this
        ?+    wire  ~
            [%primary @ ~]
          :_  ~
          :*  %pass
              /seer-primary
              %agent
              [our.bol %seer]
              %watch
              /seer-primary
          ==
        ==
          %fact
        ?+    wire  (on-agent:def wire sign)
            [%shared-fetch @ @ ~]
          =^  cards  state
            (take-shared-fetch:sc i.t.wire cage.sign)
          [cards this]
            [%shared-manifest @ ~]
          =^  cards  state
            %+  take-remote-manifest:sc  (slav %p i.t.wire)
            cage.sign
          [cards this]
            [%seer-primary ~]
          [~ this]
            [%import @ @ ~]
          =/  name  i.t.t.wire
          ?+  p.cage.sign  ~|([%seer-cli-bad-sub-mark wire p.cage.sign] !!)
              %seer-primary-delta
            =^  cards  state
              %:  apply-remote-delta:sc
                (slav %p i.t.wire)
                name
                !<(primary-delta q.cage.sign)
              ==
            [cards this]
              %seer-stack
            =/  =stack  !<(stack q.cage.sign)
            =^  cards  state
              (handle-import-stack:sc stack)
            [cards this]
          ==
        ==
      ==
      ++  pass-through
        |=  =cage
        ^-  card
        (fact:io cage ~[wire])
      --
    =/  act=(unit action)
      ?+  wire  ~
        [%shared-fetch @ @ ~]  `[%refresh-context-source i.t.wire]
        [%import @ @ ~]  `[%import (slav %p i.t.wire) i.t.t.wire]
      ==
    ?~  act  [moves this]
    =.  operating.state
      (track-agent-state our.bol now.bol u.act before observation-view:sc operating.state)
    =.  operating.state  operating.state(changed ~, failure ~)
    [moves this]
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =.  operating.state  operating.state(changed ~, failure ~)
    =/  before  observation-view:sc
    =^  cards  state
      ?+    wire  (on-arvo:def wire sign-arvo)
          [%bind %seer ~]
        [~ state]
          [%eyre ~]
        [~ state]
          [%view-bind ~]
        [~ state]
          [%review-schedule @ ~]
        (wake:sc wire)
          [%review-schedule @ @ @ ~]
        (wake:sc wire)
          [%import @ @ ~]
        (peer-stack:sc i.t.t.wire)
          [%read %paths ~]
        [~ state]
          [%shared-timeout @ @ ~]
        =/  source  (~(get by contexts.state) i.t.wire)
        ?~  source  [~ state]
        ?.  =(generation.u.source (slav %ud i.t.t.wire))  [~ state]
        (shared-fetch-timeout:sc i.t.wire)
          [%shared-manifest-timeout @ ~]
        (remote-manifest-timeout:sc (slav %p i.t.wire))
          [%seer-request @ @ @ ~]
        ?.  ?=([%iris %http-response *] sign-arvo)  [~ state]
        (take-response:sc (slav %tas i.t.wire) (slav %tas i.t.t.wire) (slav %ud i.t.t.t.wire) client-response.sign-arvo)
          [%seer-login @ @ @ ~]
        ?.  ?=([%iris %http-response *] sign-arvo)  [~ state]
        (take-login-response:sc (slav %tas i.t.wire) (slav %tas i.t.t.wire) (slav %ud i.t.t.t.wire) client-response.sign-arvo)
          [%seer-renew @ @ ~]
        ?.  ?=([%iris %http-response *] sign-arvo)  [~ state]
        =/  provider  ((soft ai-provider) (slav %tas i.t.wire))
        ?~  provider  [~ state]
        (take-renewal:sc u.provider (slav %ud i.t.t.wire) client-response.sign-arvo)
          [%seer-catalog @ @ ~]
        ?.  ?=([%iris %http-response *] sign-arvo)  [~ state]
        =/  provider  ((soft ai-provider) (slav %tas i.t.wire))
        ?~  provider  [~ state]
        (take-catalog:sc u.provider (slav %ud i.t.t.wire) client-response.sign-arvo)
          [%seer-deadline @ @ @ ~]
        (take-deadline:sc (slav %tas i.t.wire) (slav %tas i.t.t.wire) (slav %ud i.t.t.t.wire))
          [%seer-poll @ @ ~]
        (take-login-poll:sc (slav %tas i.t.wire) (slav %ud i.t.t.wire))
          [%seer-renew-deadline @ @ ~]
        =/  provider  ((soft ai-provider) (slav %tas i.t.wire))
        ?~  provider  [~ state]
        (take-renewal-deadline:sc u.provider (slav %ud i.t.t.wire))
          [%seer-catalog-deadline @ @ ~]
        =/  provider  ((soft ai-provider) (slav %tas i.t.wire))
        ?~  provider  [~ state]
        (take-catalog-deadline:sc u.provider (slav %ud i.t.t.wire))
      ==
    =/  act=(unit action)
      ?+  wire  ~
        [%review-schedule @ @ @ ~]  `[%raise-item our.bol i.t.wire i.t.t.wire]
        [%shared-timeout @ @ ~]  `[%refresh-context-source i.t.wire]
      ==
    =?  operating.state  ?=(^ act)
      (track-agent-state our.bol now.bol u.act before observation-view:sc operating.state)
    =.  operating.state  operating.state(changed ~, failure ~)
    =^  more  state  flush:sc
    [(weld cards more) this]
  ::
  ++  on-save  !>(state)
  ++  on-load
    |=  old=vase
    ^-  (quip card _this)
    ~|  'seer-state-shape-changed: nuke and revive %seer'
    =.  state  !<(seer-state old)
    =^  overdue  state  settle-overdue:sc
    =^  cards  state  flush:sc
    [:(weld -:on-init overdue cards) this]
  ++  on-leave  on-leave:def
  ++  on-peek
    |=  =path
    ^-  (unit (unit cage))
    ?+    path  (on-peek:def path)
        [%x %idempotency-epoch ~]
      ``noun+!>(epoch.operating.state)
        [%x %assistant-model @ ~]
      ``noun+!>((~(get by models.state) (slav %tas i.t.t.path)))
        [%x %accounts ~]
      ``noun+!>(account-views:sc)
        [%x %operation-result @ ~]
      =/  result  (operation-result:sc i.t.t.path)
      ``json+!>(result)
        [%x %preview-change @ @ ~]
      =/  preview  (change-preview:sc (slav %tas i.t.t.path))
      ``json+!>((preview-json:effects preview (slav %ud i.t.t.t.path)))
        [%x %preview-proposal @ @ @ ~]
      =/  session  (~(get by captures.state) (slav %tas i.t.t.path))
      =/  draft=(unit proposal)
        ?~  session  ~
        (~(get by proposals.u.session) (slav %tas i.t.t.t.path))
      =/  preview=plan-preview
        ?~  draft  [%invalid %not-found 0x0 stacks.state ~ ~]
        (proposal-preview:effects our.bol now.bol stacks.state versions.operating.state u.draft)
      ``json+!>((preview-json:effects preview (slav %ud i.t.t.t.t.path)))
        [%x %learning @ ~]
      ?:  (gth (met 3 i.t.t.path) 4.096)
        ``json+!>((error-json 'invalid-query' 'learning'))
      =/  query
        %-  mole
        |.  (need ((soft ,[context-scope @t ai-provider @ud @ud [@t @t @t] (unit @ux)]) (cue (slav %uv i.t.t.path))))
      =/  result=json
        ?~  query  (error-json 'invalid-query' 'learning')
        =/  [scope=context-scope objective=@t provider=ai-provider limit=@ud max-bytes=@ud content=[@t @t @t] snapshot=(unit @ux)]  u.query
        (lookup-artifacts:memory scope objective provider limit max-bytes content snapshot contexts.state evidence.state versions.operating.state learning.state)
      ``json+!>(result)
        [%x %agent-context ~]
      ``json+!>(agent-context:sc)
        [%x %agent-read @ ~]
      =/  query  (decode-read:reader i.t.t.path)
      =/  request=agent-read
        ?~  query
          %*  .  *agent-read
            kind        %orientation
            projection  %metadata
            limit       20
            max-bytes   32.768
          ==
        u.query
      =/  read-core
        (agent-reader:reader our.bol now.bol observation-view:sc operating.state request)
      =/  result
        ?~  query
          (error:read-core 'invalid-query')
        page.read-core
      ``json+!>(result)
        [%x %entity-version @ @ @ @ ~]
      =/  key=entity-key
        %-  need
        %-  (soft entity-key)
        [(slav %tas i.t.t.path) (slav %p i.t.t.t.path) (slav %tas i.t.t.t.t.path) (slav %tas i.t.t.t.t.t.path)]
      ``noun+!>((~(get by versions.operating.state) key))
        [%x %work @ @ @ @ ~]
      =/  key=entity-key
        %-  need
        %-  (soft entity-key)
        [(slav %tas i.t.t.path) (slav %p i.t.t.t.path) (slav %tas i.t.t.t.t.path) (slav %tas i.t.t.t.t.t.path)]
      ``noun+!>((~(get by jobs.operating.state) key))
        [%x %context-source @ ~]
      ``noun+!>((~(get by contexts.state) (@tas i.t.t.path)))
        [%x %context-packet @ @ ~]
      =/  id  (slav %ux i.t.t.path)
      =/  max-bytes  (slav %ud i.t.t.t.path)
      =/  packet  (~(get by packets.evidence.state) id)
      =/  result=json
        ?~  packet  (error-json 'not-found' 'context packet')
        (packet-projection:ev u.packet contexts.state evidence.state max-bytes)
      ``json+!>(result)
        [%x %evidence-snapshot @ @ @ @ ~]
      =/  id  (slav %ux i.t.t.path)
      =/  start  (slav %ud i.t.t.t.path)
      =/  length  (slav %ud i.t.t.t.t.path)
      =/  max-bytes  (slav %ud i.t.t.t.t.t.path)
      ``json+!>((snapshot-projection:ev id start length max-bytes evidence.state))
        [%x %mcp %tools ~]
      ``noun+!>(tools)
        [%x %mcp %prompts ~]
      ``noun+!>(prompts)
        [%x %review ~]
      ``noun+!>(all-reviews)
        [%x %all ~]
      ``noun+!>(stacks.state)
        [%x %ai-state ~]
      =/  snapshot=ai-state
        :*  stacks.state
            captures.state
            provenance.state
            questions.state
            models.state
            changes.state
            contexts.state
            evidence.state
            learning.state
        ==
      ``noun+!>(snapshot)
        [%x %logins ~]
      ``noun+!>(redacted-logins:sc)
        [%x %stack-subs ~]
      ``noun+!>(stack-subs.state)
        [%x %stacks *]
      ?~  t.t.path
        ~
      ``noun+!>((~(get by stacks.state) `@tas`i.t.t.path))
    ==
  ++  on-fail   on-fail:def
  --
::  cards: list of outgoing moves
::  stak:  the current stack
::
=|  $:  cards=(list card)
        stak=stack
        system-authorized=$~(%.n ?)
        operator-authorized=$~(%.n ?)
        acting-operation=@t
        acting-epoch=@da
        form-fields=(map @t @t)
    ==
::
|_  bol=bowl:gall
::  +this: self
::
++  this  .
::
++  observation-view
  ^-  agent-view
  :*  :*  stacks.state
          captures.state
          provenance.state
          questions.state
          models.state
          changes.state
          contexts.state
          evidence.state
          learning.state
      ==
      stack-subs.state
      logins.state
      account-views
  ==
::
++  account-views
  ^-  (map ai-provider account-view)
  %-  ~(run by accounts.state)
  |=(account=provider-account (view-of-account:oa account))
::
++  redacted-logins
  ^-  (map @tas login-request)
  %-  ~(run by logins.state)
  |=(req=login-request req(pasted-code '', device-id '', verifier '', nonce ''))
::
++  agent-context
  ^-  json
  =/  query=agent-read
    %*  .  *agent-read
      kind        %orientation
      projection  %metadata
      limit       20
      max-bytes   32.768
    ==
  =/  read-core
    (agent-reader:reader our.bol now.bol observation-view operating.state query)
  page.read-core
::  +emit: emit a card and set stak
::
++  emit
  |=  car=card
  this(cards [car cards])
::
++  emit-primary
  |=  del=primary-delta
  =/  target=(unit @tas)
    ?+  del  ~
      [%add-item * * *]            ?:(=(our.bol who.del) `stack.del ~)
      [%add-review-item * * *]     ?:(=(our.bol who.del) `stack.del ~)
      [%delete-item * * *]         ?:(=(our.bol who.del) `stack.del ~)
      [%delete-review-item * * *]  ?:(=(our.bol who.del) `stack.del ~)
      [%update-stack * *]          ?:(=(our.bol who.del) `name.data.del ~)
      [%delete-stack * *]          ?:(=(our.bol who.del) `stack.del ~)
    ==
  %-  emil
  %-  zing
  :~  ~[[%give %fact ~[/seer-primary] %seer-primary-delta !>(del)]]
    ::
      ?~  target  ~
      ~[[%give %fact ~[/stack/[u.target]] %seer-primary-delta !>(del)]]
  ==
::
++  emit-action
  |=  =action
  %-  emil
  :~
    [%pass /action %agent [our.bol %seer] %poke %seer-action (command-vase epoch.operating.state (local-operation action) action)]
  ==
::
++  emil
  |=  rac=(list card)
  |-  ^+  this
  ?~  rac
    this
  =.  cards  [i.rac cards]
  $(rac t.rac)
::  +abet: finalize
::
++  abet
  ^-  (quip card _state)
  [(flop cards) state]
::  +stack-emit: handles state updates for the given stack
::
++  stack-emit
  ::  the door shares one stack across its action arms.
  ::
  |_  =stack
  ::
  ++  add-stack
    ^+  this
    ?.  (~(has by stacks) name.stack)
      %.  [%add-stack our.bol stack]
      %=  emit-primary
        stacks  (~(put by stacks.state) name.stack stack)
      ==
    =/  old-stack  (~(got by stacks) name.stack)
    %~  update-stack  stack-emit
    %=  stack
      items  (~(uni by items.old-stack) items.stack)
    ==
  ::
  ++  add-stack-subs
    ^+  this
    ?>  ?=(%.y -.info.stack)
    =/  info=stack-info  p.info.stack
    ?.  (~(has by stack-subs) [owner.info name.stack])
      %.  [%add-stack owner.info stack]
      %=    emit-primary
          stack-subs
        (~(put by stack-subs.state) [owner.info name.stack] stack)
      ==
    this
  ::
  ++  delete-stack
    |=  owner=@p
    ^+  this
    =?  ..emit  !=(our.bol owner)
      %-  emit
      :*  %pass
          /import/(scot %p owner)/[name.stack]
          %agent
          [owner %seer]
          %leave
          ~
      ==
    =.  ..emit
      %.  [%delete-stack owner name.stack]
      %=    emit-primary
          stacks
        ?:(=(our.bol owner) (~(del by stacks) name.stack) stacks)
          stack-subs
        (~(del by stack-subs) [owner name.stack])
      ==
    ~(update-review stack-emit stak)
  ::
  ++  update-stack
    ^+  this
    =.  ..emit  this(stak stack)
    ?:  (~(has by stacks) name.stack)
      %.  [%update-stack our.bol stack]
      %=  emit-primary
        stacks  (~(put by stacks) name.stack stack)
      ==
    this
  ::
  ++  review-stack
    |=  owner=@p
    ^+  this
    =.  ..emit
      %~  update-stack  stack-emit
      %=  stack
        review-items  items.stack
      ==
    ~(update-review stack-emit stak)
  ::
  ++  delete-item
    |=  item=@tas
    ^+  this
    =.  ..emit
      (emit-primary [%delete-item our.bol name.stack item])
    %~  update-stack  stack-emit
    %=  stack
      items  (~(del by items.stack) item)
      review-items  (~(del by review-items.stack) item)
    ==
  ::
  ++  add-item
    |=  =item
    ^+  this
    =.  ..emit
      (emit-primary [%add-item our.bol name.stack item])
    =.  ..emit
    %~  update-stack  stack-emit
    %=  stack
      items  (~(uni by items.stack) (my ~[[name.item item]]))
    ==
    (~(add-review-item stack-emit stak) item)
  ::
  ++  edit-item
    |=  =item
    ^+  this
    %~  update-stack  stack-emit
    %=  stack
      items  (~(uni by items.stack) (my ~[[name.item item]]))
      review-items
        ?:  (~(has by review-items.stack) name.item)
          (~(put by review-items.stack) name.item item)
        review-items.stack
    ==
  ::
  ++  add-review-item
    |=  =item
    ^+  this
    =.  ..emit
      %~  update-stack  stack-emit
      %=    stack
          review-items
        (~(uni by review-items.stack) (my ~[[name.item item]]))
      ==
    ~(update-review stack-emit stak)
  ::
  ++  delete-review-item
    |=  =item
    ^+  this
    =.  ..emit
      %~  update-stack  stack-emit
      %=  stack
        review-items  (~(del by review-items.stack) name.item)
      ==
    ~(update-review stack-emit stak)
  ::
  ++  update-learn
    |=  [=item =recall-grade]
    ^+  this
    =.  ..emit
      (~(delete-review-item stack-emit stack) item)
    =/  =learn  (generate-learn item recall-grade)
    =/  review-date=@da  (add now.bol interval.learn)
    =/  =path
      :~  %review-schedule
        (scot %tas name.stak)
        (scot %tas name.item)
        (scot %da review-date)
      ==
    =/  schedule-card=card
      :*  %pass
          path
          [%arvo %b %wait review-date]
      ==
    =.  ..emit
      %.  item(learn learn, last-review `now.bol)
      %~  edit-item  stack-emit  stak
    (emit schedule-card)
  ::
  ++  clear-learn
    ^+  this
    =-  %~  update-stack  stack-emit  stack(items -)
    %-  ~(run by items.stack)
    |=  =item
    item(learn (learn [.2.5 0 0]))
  ::
  ++  update-owner
    ^+  this
    =/  updated-items=(map @tas item)
      %-  ~(run by items.stack)
      |=  =item
      =.  author.content.item  our.bol
      item
    %~  update-stack  stack-emit
    ?>  ?=(%.y -.info.stack)
    =/  =stack-info  +.info.stack
    %=  stack
      items  updated-items
      info  [%.y stack-info(owner our.bol)]
    ==
  ::
  ++  update-review
    ^+  this
    =/  del  [%update-review (silt all-reviews)]
    %-  emil
    :~  [%give %fact ~[/seer-primary] %seer-primary-delta !>(del)]
        [%give %fact ~[/seertile] %json !>(make-tile-json)]
    ==
  --
++  poke-sign-arvo
  |=  =sign-arvo
  ^-  (quip card _state)
  [~ state]
::
++  poke-handle-http-request
  |=  [eyre-id=@ta =inbound-request:eyre]
  ^-  (quip card _state)
  =/  request-line
    (parse-request-line url.request.inbound-request)
  ?+  method.request.inbound-request
    (respond-payload eyre-id [[405 ~] ~])
  ::
      %'GET'
    =/  result=(each (quip card _state) tang)
      (mule |.((web-get eyre-id request-line)))
    ?:  ?=(%| -.result)
      %-  (slog leaf+"seer: page failed {(trip url.request.inbound-request)}" p.result)
      (respond-payload eyre-id [[500 ['content-type' 'text/plain']~] `(as-octs:mimes:html 'Seer could not render this page.')])
    p.result
  ::
      %'POST'
    =/  fields=(map @t @t)
      %-  malt
      %-  fall  :_  ~
      %+  rush  q:(fall body.request.inbound-request *octs)
      yquy:de-purl:html
    =/  result=(each (quip card _state) tang)
      (mule |.((web-post(form-fields fields) eyre-id request-line fields)))
    ?:  ?=(%| -.result)
      (respond-page eyre-id [%inbox ~] `'Invalid form. No operation was applied.')
    p.result
  ==
::
++  web-get
  |=  [eyre-id=@ta =request-line]
  ^-  (quip card _state)
  ?+  request-line
    (respond-payload eyre-id not-found:gen)
  ::  canonical browser routes.
      [[~ [%apps %seer %activity ~]] *]
    =/  operation  (get-arg args.request-line 'operation-id')
    ?~  operation  (respond-page eyre-id [%activity ~] ~)
    ?.  ?&(!=('' u.operation) (bounded-text:ev u.operation 128))
      (respond-page eyre-id [%activity ~] `'Enter an operation ID of 1 to 128 characters. You can copy one from Activity.')
    =/  epoch
      (slaw %da (fall (get-arg args.request-line 'idempotency-epoch') (scot %da epoch.operating.state)))
    ?~  epoch
      (respond-page eyre-id [%activity ~] `'The history date is not valid. Copy it from the operation details, or open Activity to search current history.')
    =/  expected  (get-arg args.request-line 'digest')
    =.  expected  ?~(expected ~ ?:(=('' u.expected) ~ expected))
    =/  digest=(unit @ux)  ?~(expected ~ (slaw %ux u.expected))
    ?:  ?&(?=(^ expected) ?=(~ digest))
      (respond-page eyre-id [%activity ~] `'The request fingerprint is not valid. Copy it from the operation details, or leave it out of the lookup.')
    =/  receipt  (operation-receipt-at:effects operating.state u.epoch u.operation digest)
    (respond-page eyre-id [%activity `receipt] ~)
  ::
      [[~ [%apps %seer %settings ~]] ~]
    (respond-page eyre-id [%settings ~] ~)
  ::
      [[~ [%apps %seer %operation-result ~]] *]
    =/  epoch  (slaw %da (fall (get-arg args.request-line 'idempotency-epoch') ''))
    =/  operation  (fall (get-arg args.request-line 'operation-id') '')
    =/  expected  (get-arg args.request-line 'digest')
    =/  digest=(unit @ux)  ?~(expected ~ (slaw %ux u.expected))
    ?:  ?|  =('' operation)
            !(bounded-text:ev operation 128)
            ?&(?=(^ expected) ?=(~ digest))
        ==
      (respond-payload eyre-id (json-response:gen (error-json 'invalid-query' 'operation receipt')))
    ?~  epoch  (respond-payload eyre-id (json-response:gen (error-json 'invalid-query' 'operation receipt')))
    =/  receipt  (operation-receipt-at:effects operating.state u.epoch operation digest)
    (respond-payload eyre-id (json-response:gen (receipt-json:effects receipt 32.768)))
  ::
      [[~ [%apps %seer ~]] ~]
    (respond-page eyre-id [%review ~] ~)
      [[~ [%apps %seer %review ~]] ~]
    (respond-page eyre-id [%review ~] ~)
      [[~ [%apps %seer %inbox ~]] ~]
    (respond-page eyre-id [%inbox ~] ~)
      [[[~ %png] [%apps %seer %tile ~]] ~]
    %+  respond-payload  eyre-id
    (png-response:gen (as-octs:mimes:html seer-tile))
      [[[~ %js] [%apps %seer %htmx-min ~]] ~]
    %+  respond-payload  eyre-id
    (js-response:gen (as-octs:mimes:html htmx-src))
  ::  the aero ios shell opens its native seer screen when this hint parses.
  ::
      [[[~ %json] [%apps %seer %aero ~]] ~]
    %+  respond-payload  eyre-id
    %-  json-response:gen
    (pairs:enjs:format ~[['module' s+'seer'] ['minVersion' s+'1.0.0']])
      [[~ [%apps %seer %stacks ~]] ~]
    (respond-page eyre-id [%stacks ~] ~)
      [[~ [%apps %seer %subscriptions ~]] ~]
    (respond-page eyre-id [%subscriptions ~] ~)
      [[~ [%apps %seer %stack @t @t ~]] *]
    =/  owner  (slav %p i.t.t.t.site.request-line)
    =/  name   (slav %tas i.t.t.t.t.site.request-line)
    =/  dsk     (get-arg args.request-line 'desk')
    =/  qry     (get-arg args.request-line 'q')
    =/  pick    (get-arg args.request-line 'pick')
    =/  remote  (get-arg args.request-line 'remote')
    ?:  &(?=(~ dsk) ?=(~ qry) ?=(~ pick) ?=(~ remote))
      (respond-page eyre-id [%stack owner name] ~)
    %^    respond-page
        eyre-id
      :*  %stack-browse
          owner
          name
          (fall dsk '')
          (fall qry '')
          (fall pick '')
          (fall remote '')
      ==
    ~
      [[~ [%apps %seer %clay-browse ~]] *]
    (respond-clay-browse eyre-id args.request-line)
  ::  preserve the old json endpoints for cli and external integrations.
  ::
      [[[~ %json] [%seer %update-review ~]] ~]
    %+  respond-payload  eyre-id
    %-  json-response:gen
    [%a (turn all-reviews review-to-json)]
      [[[~ %json] [%seer %learn @t ~]] ~]
    =/  stack-name  (slav %tas i.t.t.site.request-line)
    %+  respond-payload  eyre-id
    %-  json-response:gen
    (stack-status-to-json (~(got by stacks) stack-name))
      [[[~ %json] [%seer %learn @t @t ~]] ~]
    =/  stack-name  (slav %tas i.t.t.site.request-line)
    =/  item-name   (slav %tas i.t.t.t.site.request-line)
    =/  =stack      (~(got by stacks) stack-name)
    =/  =item       (~(got by items.stack) item-name)
    %+  respond-payload  eyre-id
    %-  json-response:gen
    (status-to-json learn.item)
      [[[~ %json] [%seer %stacks ~]] ~]
    %+  respond-payload  eyre-id
    (json-response:gen (state-to-json state))
  ::  legacy links now land on the repaired ui.
  ::
      [[~ [%seer ~]] ~]
    (respond-payload eyre-id (redirect:gen '/apps/seer/review'))
      [[~ [%seer @ ~]] ~]
    (respond-payload eyre-id (redirect:gen '/apps/seer/review'))
  ==
::
++  web-post
  |=  [eyre-id=@ta =request-line fields=(map @t @t)]
  ^-  (quip card _state)
  ?+  request-line
    (respond-payload eyre-id not-found:gen)
  ::
      [[~ [%apps %seer %actions %begin-capture ~]] ~]
    %:  apply-web-action  eyre-id
      [%begin-capture (form-id 'capture') (form-got fields 'title') (form-got fields 'goal') (form-got fields 'source') 'operator']
      [%inbox ~]
      `'Card draft created. Add sources, then prepare it for the assistant.'
    ==
      [[~ [%apps %seer %actions %start-change ~]] ~]
    (apply-web-action eyre-id [%start-change (slav %tas (form-got fields 'change-id'))] [%inbox ~] `'Change request queued. The assistant will prepare the changes for your review.')
      [[~ [%apps %seer %actions %prepare-capture ~]] ~]
    =/  id  (slav %tas (form-got fields 'capture'))
    =/  model  (~(got by models.state) (slav %tas (form-got fields 'model')))
    %:  apply-web-action  eyre-id
      [%prepare-capture id model (form-selections fields [%capture id]) (need (rush (form-got fields 'max-bytes') dim:ag)) (need (rush (form-got fields 'excerpt-bytes') dim:ag))]
      [%inbox ~]
      `'Sources prepared. Review the exact text before sending it to the assistant.'
    ==
      [[~ [%apps %seer %actions %rename-context-source ~]] ~]
    (apply-web-action eyre-id [%rename-context-source (slav %tas (form-got fields 'context-id')) (form-got fields 'label')] (form-return fields) `'Source renamed.')
      [[~ [%apps %seer %actions %set-context-egress ~]] ~]
    =/  providers=(set ai-provider)  ~
    =?  providers  =('1' (form-got fields 'codex'))  (~(put in providers) %codex)
    =?  providers  =('1' (form-got fields 'claude'))  (~(put in providers) %claude)
    (apply-web-action eyre-id [%set-context-egress (slav %tas (form-got fields 'context-id')) providers] (form-return fields) `'Source sharing permissions updated.')
      [[~ [%apps %seer %actions %cancel-work ~]] ~]
    =/  key=entity-key
      %-  need
      %-  (soft entity-key)
      [(slav %tas (form-got fields 'work-kind')) (slav %p (form-got fields 'work-owner')) (slav %tas (form-got fields 'work-scope')) (slav %tas (form-got fields 'work-id'))]
    (apply-web-action eyre-id [%cancel-work key] (form-return fields) `'Work cancelled. Later results will not be applied.')
      [[~ [%apps %seer %actions %archive-orphan-contexts ~]] ~]
    (apply-web-action eyre-id [%archive-orphan-contexts ~] [%settings ~] `'Unlinked sources archived. History is retained.')
      [[~ [%apps %seer %actions %collect-retained ~]] ~]
    (apply-web-action eyre-id [%collect-retained ~] [%settings ~] `'Unused saved source text removed.')
      [[~ [%apps %seer %actions %retire-operation-epoch ~]] ~]
    (apply-web-action eyre-id [%retire-operation-epoch ~] [%settings ~] `'Operation history cleared. Older forms can no longer submit actions.')
      [[~ [%apps %seer %actions %purge-evidence ~]] ~]
    (apply-web-action eyre-id [%purge-evidence (silt ~[(slav %ux (form-got fields 'snapshot-ref'))])] [%settings ~] `'Saved source text deleted. Requests that relied on it can no longer use that text.')
      [[~ [%apps %seer %actions %new-stack ~]] ~]
    =/  name   (slav %tas (form-got fields 'name'))
    =/  title  (form-got fields 'title')
    %:  apply-web-action
      eyre-id
      [%new-stack name title *items]
      [%stacks ~]
      `'Stack created.'
    ==
  ::
      [[~ [%apps %seer %actions %new-item ~]] ~]
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  item-name   (slav %tas (form-got fields 'name'))
    =/  title       (form-got fields 'title')
    =/  front       (form-got fields 'front')
    =/  back        (form-got fields 'back')
    =/  act=action
      :*  %new-item
          our.bol
          our.bol
          stack-name
          item-name
          title
          [read=*rule:clay write=*rule:clay]
          front
          back
      ==
    %:  apply-web-action
      eyre-id
      act
      [%stack our.bol stack-name]
      `'Card added.'
    ==
  ::
      [[~ [%apps %seer %actions %approve-proposal ~]] ~]
    =/  capture-id   (slav %tas (form-got fields 'capture'))
    =/  proposal-id  (slav %tas (form-got fields 'proposal'))
    %:  apply-web-action
      eyre-id
      [%approve-proposal capture-id proposal-id (slav %ux (form-got fields 'digest'))]
      [%inbox ~]
      `'Card approved and queued for review.'
    ==
  ::
      [[~ [%apps %seer %actions %reject-proposal ~]] ~]
    =/  capture-id   (slav %tas (form-got fields 'capture'))
    =/  proposal-id  (slav %tas (form-got fields 'proposal'))
    %:  apply-web-action
      eyre-id
      [%reject-proposal capture-id proposal-id (optional-form-text fields 'reason')]
      [%inbox ~]
      `'Proposal rejected.'
    ==
  ::
      [[~ [%apps %seer %actions %discard-capture ~]] ~]
    =/  capture-id  (slav %tas (form-got fields 'capture'))
    %:  apply-web-action
      eyre-id
      [%discard-capture capture-id]
      [%inbox ~]
      `'Remaining proposals cleared.'
    ==
  ::
      [[~ [%apps %seer %actions %delete-capture ~]] ~]
    =/  capture-id  (slav %tas (form-got fields 'capture'))
    %:  apply-web-action
      eyre-id
      [%delete-capture capture-id]
      [%inbox ~]
      `'Card draft history removed.'
    ==
  ::
      [[~ [%apps %seer %actions %review-stack ~]] ~]
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%review-stack our.bol stack-name]
      [%review ~]
      `'Stack added to the review queue.'
    ==
  ::
      [[~ [%apps %seer %actions %answer ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  item-name   (slav %tas (form-got fields 'item'))
    =/  answer      (grade (form-got fields 'answer'))
    %:  apply-web-action
      eyre-id
      [%answered-item owner stack-name item-name answer]
      [%review ~]
      ~
    ==
  ::
      [[~ [%apps %seer %actions %request-change ~]] ~]
    =/  prompt  (form-got fields 'prompt')
    =/  target-name  (slav %tas (form-got fields 'target'))
    =/  target=change-target
      ?:(=(%desk target-name) %desk %library)
    =/  model-id  (slav %tas (form-got fields 'model'))
    =/  maybe-profile  (~(get by models.state) model-id)
    ?~  maybe-profile
      =/  message=@t
        %+  rap  3
        :~  'That assistant model is unavailable. Select another '
            'model before you send the request again.'
        ==
      %^    respond-page
          eyre-id
        [%inbox ~]
      `message
    =/  change-id  (form-id 'change')
    %:  apply-web-action
      eyre-id
      [%request-change change-id target u.maybe-profile prompt %.n]
      [%inbox ~]
      `'Draft created. Add sources, then choose Prepare changes.'
    ==
  ::
      [[~ [%apps %seer %actions %apply-change ~]] ~]
    =/  change-id  (slav %tas (form-got fields 'change-id'))
    %:  apply-web-action
      eyre-id
      [%apply-change change-id (slav %ux (form-got fields 'digest'))]
      [%inbox ~]
      `'Change plan approved.'
    ==
  ::
      [[~ [%apps %seer %actions %reject-change ~]] ~]
    =/  change-id  (slav %tas (form-got fields 'change-id'))
    %:  apply-web-action
      eyre-id
      [%reject-change change-id]
      [%inbox ~]
      `'Request closed. No proposed changes were applied.'
    ==
  ::
      [[~ [%apps %seer %actions %retry-change ~]] ~]
    =/  change-id  (slav %tas (form-got fields 'change-id'))
    %:  apply-web-action
      eyre-id
      [%retry-change change-id]
      [%inbox ~]
      `'Change request queued with current library state.'
    ==
  ::
      [[~ [%apps %seer %actions %delete-change ~]] ~]
    =/  change-id  (slav %tas (form-got fields 'change-id'))
    %:  apply-web-action
      eyre-id
      [%delete-change change-id]
      [%inbox ~]
      `'Change history removed.'
    ==
  ::
      [[~ [%apps %seer %actions %add-context-source ~]] ~]
    =/  scope  (form-scope fields)
    =/  kind  (need ((soft context-kind) (slav %tas (form-got fields 'kind'))))
    =/  locator
      ?:  =(%web kind)  (form-got fields 'web-locator')
      (form-got fields 'locator')
    =/  label  (form-got fields 'label')
    =.  label  ?:(=('' label) ?:(=(%note kind) 'Context note' locator) label)
    %:  apply-web-action  eyre-id
      [%add-context-source (form-id 'ctx') scope kind label locator (form-got fields 'content')]
      (form-return fields)
      `'Source added. Check whether its text is ready.'
    ==
  ::
      [[~ [%apps %seer %actions %remove-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    %:  apply-web-action
      eyre-id
      [%remove-context-source context-id]
      (form-return fields)
      `'Source removed from future requests.'
    ==
  ::
      [[~ [%apps %seer %actions %retry-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    %:  apply-web-action
      eyre-id
      [%retry-context-source context-id]
      (form-return fields)
      `'Web source queued again.'
    ==
  ::
      [[~ [%apps %seer %actions %refresh-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    %:  apply-web-action
      eyre-id
      [%refresh-context-source context-id]
      (form-return fields)
      `'Refreshing from the source file.'
    ==
  ::
      [[~ [%apps %seer %actions %browse-remote-manifest ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  ship-raw    (form-got fields 'ship')
    =/  who=(unit @p)  (slaw %p ship-raw)
    ?~  who
      %^    respond-page
          eyre-id
        [%stack owner stack-name]
      `'Enter a ship name like ~sampel-palnet.'
    ?:  =(our.bol u.who)
      %^    respond-page
          eyre-id
        [%stack owner stack-name]
      `'That is this ship. Use the browser above for local files.'
    %:  apply-web-action
      eyre-id
      [%fetch-remote-manifest u.who]
      [%stack-browse owner stack-name '' '' '' (scot %p u.who)]
      ~
    ==
  ::
      [[~ [%apps %seer %actions %share-clay-context ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  maybe-pax   (parse-clay-path (form-got fields 'path'))
    ?~  maybe-pax
      %^    respond-page
          eyre-id
        [%stack owner stack-name]
      `'Use a desk-first path like /base/gen/hood/hi/hoon.'
    %:  apply-web-action
      eyre-id
      [%share-clay-context u.maybe-pax]
      [%stack owner stack-name]
      `'Shared publicly for other ships.'
    ==
  ::
      [[~ [%apps %seer %actions %unshare-clay-context ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  maybe-pax   (parse-clay-path (form-got fields 'path'))
    ?~  maybe-pax
      (respond-page eyre-id [%stack owner stack-name] ~)
    %:  apply-web-action
      eyre-id
      [%unshare-clay-context u.maybe-pax]
      [%stack owner stack-name]
      `'No longer listed for other ships.'
    ==
  ::
      [[~ [%apps %seer %actions %ask-card ~]] ~]
    =/  owner          (slav %p (form-got fields 'owner'))
    =/  stack-name     (slav %tas (form-got fields 'stack'))
    =/  item-name      (slav %tas (form-got fields 'item'))
    =/  prompt         (form-got fields 'question')
    =/  mode-name      (slav %tas (form-got fields 'mode'))
    =/  mode=assistant-mode
      ?:(=(%edit mode-name) %edit %ask)
    =/  target-page=page:index
      ?:  =('review' (form-got fields 'return'))
        [%review ~]
      [%stack owner stack-name]
    =/  model-id  (slav %tas (form-got fields 'model'))
    =/  maybe-profile  (~(get by models.state) model-id)
    ?~  maybe-profile
      =/  message=@t
        %+  rap  3
        :~  'That assistant model is unavailable. Select another '
            'model before you send the request again.'
        ==
      %^    respond-page
          eyre-id
        target-page
      `message
    =/  profile=assistant-model  u.maybe-profile
    =/  question-id  (form-id 'q')
    =/  selections  (form-selections fields [%stack owner stack-name `item-name])
    %:  apply-web-action
      eyre-id
      :*  %ask-card
          question-id
          owner
          stack-name
          item-name
          mode
          profile
          prompt
          selections
          (need (rush (form-got fields 'max-bytes') dim:ag))
          (need (rush (form-got fields 'excerpt-bytes') dim:ag))
      ==
      target-page
      `'Request sent to {(trip label.profile)}.'
    ==
  ::
      [[~ [%apps %seer %actions %request-login ~]] ~]
    =/  provider-raw  (form-got fields 'provider')
    =/  provider=ai-provider
      ?:(=('claude' provider-raw) %claude %codex)
    =/  login-id=@tas
      ?:(=(%claude provider) %login-claude %login-codex)
    =/  target-page=page:index
      ?:  =('settings' (form-got fields 'return'))
        [%settings ~]
      ?:  =('inbox' (form-got fields 'return'))
        [%inbox ~]
      [%review ~]
    %:  apply-web-action
      eyre-id
      [%request-login login-id provider]
      target-page
      ~
    ==
  ::
      [[~ [%apps %seer %actions %request-logout ~]] ~]
    =/  provider-raw  (form-got fields 'provider')
    =/  provider=ai-provider
      ?:(=('claude' provider-raw) %claude %codex)
    (apply-web-action eyre-id [%clear-account provider] [%settings ~] `'Signed out on this ship. The provider account itself is unchanged.')
  ::
      [[~ [%apps %seer %actions %import-account ~]] ~]
    =/  provider-raw  (form-got fields 'provider')
    =/  provider=ai-provider
      ?:(=('claude' provider-raw) %claude %codex)
    =/  parsed  (parse-pasted:oa provider now.bol (form-got fields 'credentials'))
    ?~  parsed
      (respond-page eyre-id [%settings ~] `'Seer could not read those credentials. Paste the complete credential JSON, a setup token, or an API key.')
    %:  apply-web-action
      eyre-id
      [%import-account provider method.u.parsed access.u.parsed refresh.u.parsed account.u.parsed expires.u.parsed scopes.u.parsed]
      [%settings ~]
      `'Provider sign-in saved on this ship.'
    ==
  ::
      [[~ [%apps %seer %actions %refresh-catalog ~]] ~]
    =/  provider-raw  (form-got fields 'provider')
    =/  provider=ai-provider
      ?:(=('claude' provider-raw) %claude %codex)
    (apply-web-action eyre-id [%refresh-catalog provider] [%settings ~] `'Model list requested from the provider.')
  ::
      [[~ [%apps %seer %actions %submit-login-code ~]] ~]
    =/  login-id  (slav %tas (form-got fields 'login-id'))
    =/  code      (form-got fields 'code')
    =/  target-page=page:index
      ?:  =('settings' (form-got fields 'return'))
        [%settings ~]
      ?:  =('inbox' (form-got fields 'return'))
        [%inbox ~]
      [%review ~]
    %:  apply-web-action
      eyre-id
      [%submit-login-code login-id code]
      target-page
      ~
    ==
  ::
      [[~ [%apps %seer %actions %cancel-login ~]] ~]
    =/  login-id  (slav %tas (form-got fields 'login-id'))
    =/  target-page=page:index
      ?:  =('settings' (form-got fields 'return'))
        [%settings ~]
      ?:  =('inbox' (form-got fields 'return'))
        [%inbox ~]
      [%review ~]
    %:  apply-web-action
      eyre-id
      [%cancel-login login-id]
      target-page
      ~
    ==
  ::
      [[~ [%apps %seer %actions %retry-login ~]] ~]
    =/  login-id  (slav %tas (form-got fields 'login-id'))
    =/  target-page=page:index
      ?:  =('settings' (form-got fields 'return'))
        [%settings ~]
      ?:  =('inbox' (form-got fields 'return'))
        [%inbox ~]
      [%review ~]
    %:  apply-web-action
      eyre-id
      [%retry-login login-id]
      target-page
      ~
    ==
  ::
      [[~ [%apps %seer %actions %retry-card-question ~]] ~]
    =/  question-id  (slav %tas (form-got fields 'question-id'))
    =/  owner        (slav %p (form-got fields 'owner'))
    =/  stack-name   (slav %tas (form-got fields 'stack'))
    =/  target-page=page:index
      ?:  =('review' (form-got fields 'return'))
        [%review ~]
      [%stack owner stack-name]
    %:  apply-web-action
      eyre-id
      [%retry-card-question question-id]
      target-page
      `'Assistant request queued again.'
    ==
  ::
      [[~ [%apps %seer %actions %delete-card-question ~]] ~]
    =/  question-id  (slav %tas (form-got fields 'question-id'))
    =/  owner        (slav %p (form-got fields 'owner'))
    =/  stack-name   (slav %tas (form-got fields 'stack'))
    =/  target-page=page:index
      ?:  =('review' (form-got fields 'return'))
        [%review ~]
      [%stack owner stack-name]
    %:  apply-web-action
      eyre-id
      [%delete-card-question question-id]
      target-page
      `'Assistant request dismissed.'
    ==
  ::
      [[~ [%apps %seer %actions %raise-item ~]] ~]
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  item-name   (slav %tas (form-got fields 'item'))
    %:  apply-web-action
      eyre-id
      [%raise-item our.bol stack-name item-name]
      [%stack our.bol stack-name]
      `'Card added to the review queue.'
    ==
  ::
      [[~ [%apps %seer %actions %delete-item ~]] ~]
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  item-name   (slav %tas (form-got fields 'item'))
    %:  apply-web-action
      eyre-id
      [%delete-item stack-name item-name]
      [%stack our.bol stack-name]
      `'Card deleted.'
    ==
  ::
      [[~ [%apps %seer %actions %delete-stack ~]] ~]
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%delete-stack our.bol stack-name]
      [%stacks ~]
      `'Stack deleted.'
    ==
  ::
      [[~ [%apps %seer %actions %import ~]] ~]
    =/  ship        (slav %p (form-got fields 'ship'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%import ship stack-name]
      [%subscriptions ~]
      `'Subscription requested.'
    ==
  ::
      [[~ [%apps %seer %actions %copy-stack ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%copy-stack owner stack-name %.y]
      [%stacks ~]
      `'Stack copied.'
    ==
  ==
::
++  form-id
  |=  prefix=@t
  ^-  @tas
  =/  suffix  (scot %uv (shax (jam [(form-got form-fields 'idempotency-epoch') (form-got form-fields 'operation-id')])))
  (slav %tas (crip "{(trip prefix)}-{(skip (trip suffix) |=(ch=@ =('.' ch)))}"))
::
++  optional-form-text
  |=  [fields=(map @t @t) key=@t]
  ^-  (unit @t)
  =/  value  (form-got fields key)
  ?:  =('' value)  ~
  `value
::
++  form-scope
  |=  fields=(map @t @t)
  ^-  context-scope
  =/  kind  (form-got fields 'scope-kind')
  ?:  =('capture' kind)  [%capture (slav %tas (form-got fields 'scope-id'))]
  ?:  =('change' kind)  [%change (slav %tas (form-got fields 'scope-id'))]
  =/  card  (optional-form-text fields 'card')
  [%stack (slav %p (form-got fields 'owner')) (slav %tas (form-got fields 'stack')) ?~(card ~ `(slav %tas u.card))]
::
++  form-return
  |=  fields=(map @t @t)
  ^-  page:index
  =/  target  (form-got fields 'return')
  ?:  =('inbox' target)  [%inbox ~]
  ?:  =('review' target)  [%review ~]
  ?:  =('settings' target)  [%settings ~]
  =/  owner  (slaw %p (form-got fields 'owner'))
  =/  stack  (slaw %tas (form-got fields 'stack'))
  ?~  owner  [%inbox ~]
  ?~  stack  [%inbox ~]
  [%stack u.owner u.stack]
::
++  form-selections
  |=  [fields=(map @t @t) scope=context-scope]
  ^-  (list evidence-selection)
  %+  murn  ~(tap by contexts.state)
  |=  [id=@tas source=context-source]
  ?.  ?&(active.source (scope-applies:ev scope.source scope))  ~
  =/  include  =('1' (form-got fields (crip "context-{(trip id)}")))
  `[id 0 ~ include include]
::
++  apply-web-action
  |=  [eyre-id=@ta act=action page=page:index notice=(unit @t)]
  ^-  (quip card _state)
  =/  epoch  (slaw %da (form-got form-fields 'idempotency-epoch'))
  =/  operation  (form-got form-fields 'operation-id')
  ?~  epoch  (respond-page eyre-id page `'This page is out of date. Reload it before trying again.')
  ?.  ?&(!=('' operation) (bounded-text:ev operation 128))
    (respond-page eyre-id page `'This page is out of date. Reload it before trying again.')
  =/  cmd  (make-command u.epoch operation act)
  =^  action-cards  state  (apply-command(operator-authorized %.y) cmd)
  =/  receipt  (operation-receipt-at:effects operating.state u.epoch operation `digest.cmd)
  =.  notice
    ?:  =(%ok status.receipt)
      ?:  =(%no-change reason.receipt)  `'No change was needed.'
      notice
    `(operation-outcome receipt)
  :_  state
  %+  weld  action-cards
  %+  give-simple-payload:app  eyre-id
  (render-action-page page notice)
::
++  render-action-page
  |=  [page=page:index notice=(unit @t)]
  ^-  simple-payload:http
  =/  payload  (render-page page notice)
  =.  headers.response-header.payload
    :-  ['HX-Push-Url' (page-url page)]
    headers.response-header.payload
  payload
::
++  page-url
  |=  page=page:index
  ^-  @t
  ?-  -.page
    %review         '/apps/seer/review'
    %inbox          '/apps/seer/inbox'
    %stacks         '/apps/seer/stacks'
    %subscriptions  '/apps/seer/subscriptions'
    %activity       '/apps/seer/activity'
    %settings       '/apps/seer/settings'
    %stack
      %-  crip
      "/apps/seer/stack/{(scow %p owner.page)}/{(trip name.page)}"
    %stack-browse
      %-  crip
      "/apps/seer/stack/{(scow %p owner.page)}/{(trip name.page)}"
  ==
::
++  respond-page
  |=  [eyre-id=@ta page=page:index notice=(unit @t)]
  ^-  (quip card _state)
  :_  state
  %+  give-simple-payload:app  eyre-id
  (render-page page notice)
::
++  respond-payload
  |=  [eyre-id=@ta payload=simple-payload:http]
  ^-  (quip card _state)
  [(give-simple-payload:app eyre-id payload) state]
::
++  render-page
  |=  [page=page:index notice=(unit @t)]
  ^-  simple-payload:http
  =/  picker=(unit picker-data:index)
    ?.  ?=(%stack-browse -.page)  ~
    ?:  =('' desk.page)  ~
    =/  dek=(unit @tas)  (slaw %tas desk.page)
    ?~  dek  ~
    ?.  (~(has in (silt clay-desks)) u.dek)  ~
    =/  walked  (walk-clay-desk u.dek)
    :-  ~
    :*  %files
        u.dek
        total.walked
        (filter-clay-paths q.page files.walked)
    ==
  =/  desks=(list @tas)
    ?:(?=(?(%stack %stack-browse) -.page) clay-desks ~)
  %-  manx-response:gen
  =/  stale=(map @tas ?(%stale %gone))
    ?.  ?=(?(%stack %stack-browse) -.page)  ~
    clay-source-stale
  %:  render:index
    our.bol
    stacks.state
    stack-subs.state
    captures.state
    questions.state
    contexts.state
    evidence.state
    models.state
    changes.state
    redacted-logins
    all-reviews
    page
    notice
    picker
    shared-context.state
    remote-manifests.state
    recent-clay.state
    stale
    desks
    operating.state
    learning.state
    account-views
  ==
::
++  get-arg
  |=  [args=(list [k=@t v=@t]) key=@t]
  ^-  (unit @t)
  ?~  args  ~
  ?:  =(key k.i.args)  `v.i.args
  $(args t.args)
::
++  clay-text-marks
  ^-  (set @ta)
  %-  silt
  ^-  (list @ta)
  :~  %txt  %md  %markdown  %org  %json  %csv  %tsv  %html  %htm  %xml
      %hoon  %js  %mjs  %ts  %tsx  %jsx  %py  %rs  %go  %toml  %yaml  %yml
  ==
::
++  parse-clay-path
  |=  raw=@t
  ^-  (unit path)
  %+  rush  raw
  ;~(pfix fas (more fas (cook crip (star ;~(less fas prn)))))
::
++  shared-manifest
  ^-  (list manifest-entry)
  %+  turn  ~(tap by shared-context.state)
  |=  [pax=path entry=shared-entry]
  ^-  manifest-entry
  [pax label.entry mark.entry size.entry]
::
++  clay-desk-rev
  |=  dek=@tas
  ^-  @ud
  =/  res=(each * tang)
    %-  mule
    |.(.^(* %cw [(scot %p our.bol) dek (scot %da now.bol) ~]))
  ?:  ?=(%| -.res)  0
  =/  c  ((soft ,[ud=@ud da=@da]) p.res)
  ?~(c 0 ud.u.c)
::
++  clay-source-stale
  ^-  (map @tas ?(%stale %gone))
  =|  out=(map @tas ?(%stale %gone))
  =|  revs=(map @tas @ud)
  =/  rows  ~(tap by contexts.state)
  |-
  ?~  rows  out
  =/  [id=@tas src=context-source]  i.rows
  ?.  &(active.src =(%clay kind.src))
    $(rows t.rows)
  =/  parsed  (parse-clay-locator locator.src)
  ?:  |(?=(~ parsed) !=(our.bol who.u.parsed))
    $(rows t.rows)
  =/  captured  (~(get by context-revs.state) id)
  ?~  captured  $(rows t.rows)
  =/  pax=path
    :*  (scot %p our.bol)
        dek.u.parsed
        (scot %da now.bol)
        rest.u.parsed
    ==
  =/  ark=(each arch tang)  (mule |.(.^(arch %cy pax)))
  ::  a collection has no file at its own node, so it counts as gone
  ::  only when the node holds neither a file nor children.
  ::
  ?:  ?|  ?=(%| -.ark)
          ?&  ?=(~ fil.p.ark)
              =(~ dir.p.ark)
          ==
      ==
    $(rows t.rows, out (~(put by out) id %gone))
  =/  cur=@ud
    ?^  hav=(~(get by revs) dek.u.parsed)  u.hav
    (clay-desk-rev dek.u.parsed)
  =.  revs  (~(put by revs) dek.u.parsed cur)
  ?:  (gth cur u.captured)
    $(rows t.rows, out (~(put by out) id %stale))
  $(rows t.rows)
::
++  clay-desks
  ^-  (list @tas)
  =/  all=(set desk)
    .^((set desk) %cd [(scot %p our.bol) '' (scot %da now.bol) ~])
  (sort ~(tap in all) aor)
::
::  +walk-clay-desk: every text-compatible file in a desk, from a
::  single %ct scry. total counts matches past the collection cap.
::
++  walk-clay-desk
  |=  dek=@tas
  ^-  [total=@ud files=(list path)]
  =/  base=path  [(scot %p our.bol) dek (scot %da now.bol) ~]
  =/  all=(each (list path) tang)
    (mule |.(.^((list path) %ct base)))
  ?:  ?=(%| -.all)  [0 ~]
  =/  hits=(list path)
    %+  skim  p.all
    |=  pax=path
    ?&  ?=(^ pax)
        (~(has in clay-text-marks) (rear `path`pax))
    ==
  [(lent hits) (scag 2.000 (sort hits aor))]
::
++  subseq-match
  |=  [needle=tape hay=tape]
  ^-  ?
  ?~  needle  %.y
  ?~  hay  %.n
  ?:  =(i.needle i.hay)
    $(needle t.needle, hay t.hay)
  $(hay t.hay)
::
++  filter-clay-paths
  |=  [q=@t files=(list path)]
  ^-  (list path)
  ?:  =('' q)  files
  =/  needle=tape  (cass (trip q))
  %+  skim  files
  |=  pax=path
  (subseq-match needle (cass (spud pax)))
::
++  respond-clay-browse
  |=  [eyre-id=@ta args=(list [k=@t v=@t])]
  ^-  (quip card _state)
  =/  dek-arg  (get-arg args 'desk')
  ?~  dek-arg  (respond-payload eyre-id not-found:gen)
  =/  q=@t      (fall (get-arg args 'q') '')
  =/  ret=tape  (trip (fall (get-arg args 'return') ''))
  =/  dek=(unit @tas)  (slaw %tas u.dek-arg)
  ?~  dek  (respond-payload eyre-id not-found:gen)
  ?.  (~(has in (silt clay-desks)) u.dek)
    (respond-payload eyre-id not-found:gen)
  =/  walked  (walk-clay-desk u.dek)
  =/  hits  (filter-clay-paths q files.walked)
  %+  respond-payload  eyre-id
  %-  manx-response:gen
  (clay-results:index our.bol ret u.dek total.walked hits)
::
++  form-got
  |=  [fields=(map @t @t) key=@t]
  ^-  @t
  (fall (~(get by fields) key) '')
::
++  clean-body
  |=  raw=@t
  ^-  @t
  =/  marker  (find ";>" (trip raw))
  ?~  marker  raw
  =/  start  (add 3 u.marker)
  (cut 3 [start (met 3 raw)] raw)
::
++  parse-clay-locator
  |=  raw=@t
  ^-  (unit [who=@p dek=@tas rest=path])
  =/  maybe-px=(unit path)  (parse-clay-path raw)
  ?~  maybe-px  ~
  =/  px=path  u.maybe-px
  ?:  |(?=(~ px) !=('~' (end 3 i.px)))
    `[our.bol q.byk.bol px]
  ?.  ?=([@ @ *] px)  ~
  =/  who=(unit @p)  (slaw %p i.px)
  ?~  who  ~
  =/  dek=(unit @tas)  (slaw %tas i.t.px)
  ?~  dek  ~
  `[u.who u.dek t.t.px]
::
++  foreign-clay-locator
  |=  [kind=context-kind locator=@t]
  ^-  (unit [who=@p dek=@tas rest=path])
  ?.  =(%clay kind)  ~
  =/  parsed  (parse-clay-locator locator)
  ?~  parsed  ~
  ?:  =(our.bol who.u.parsed)  ~
  parsed
::
::  +clay-file-text: read one clay file as text.
::
++  clay-file-text
  |=  pax=path
  ^-  @t
  =/  value  .^(noun %cx pax)
  =/  maybe-lines=(unit wain)
    ?@(value `(to-wain:format value) ((soft wain) value))
  ?~  maybe-lines  !!
  =/  lines=wall
    (turn u.maybe-lines |=(line=cord (trip line)))
  (crip (zing (join "\0a" lines)))
::
::  +clay-collection-files: every text-mark file under a locator's
::  prefix, sorted. an empty prefix names the whole desk.
::
++  clay-collection-files
  |=  [dek=@tas prefix=path]
  ^-  (list path)
  =/  base=path  [(scot %p our.bol) dek (scot %da now.bol) ~]
  =/  all=(list path)  .^((list path) %ct base)
  %+  sort
    %+  skim  all
    |=  f=path
    ?&  ?=(^ f)
        (~(has in clay-text-marks) (rear `path`f))
        =(prefix (scag (lent prefix) `path`f))
    ==
  aor
::  +clay-manifest-text: a listing of a collection's files. the header
::  names the collection so a model reads the shape without the bodies;
::  attaching an individual file inlines it as its own source.
::
++  clay-manifest-text
  |=  [locator=@t files=(list path) shown=(list path)]
  ^-  @t
  =/  head=tape
    ?:  =((lent files) (lent shown))
      "=== listing {(trip locator)} · {<(lent files)>} files"
    %+  weld  "=== listing {(trip locator)} · "
    "{<(lent shown)>} of {<(lent files)>} files"
  =/  note=tape
    "::  bodies are not inlined; attach a path to read one"
  =/  rows=(list tape)
    %+  weld  ~[head note]
    (turn shown |=(f=path (spud f)))
  (crip (zing (join "\0a" rows)))
::
::  +clay-collection-text: every file under the prefix, concatenated
::  with path headers, or ~ when the total passes the context cap.
::
++  clay-collection-text
  |=  [base=path files=(list path)]
  ^-  (unit @t)
  =|  pieces=wall
  =|  bytes=@ud
  =/  rest=(list path)  files
  |-  ^-  (unit @t)
  ?~  rest
    `(crip (zing (join "\0a\0a" (flop pieces))))
  =/  body=@t  (clay-file-text (weld base `path`i.rest))
  =/  piece=tape  "=== {(spud i.rest)}\0a{(trip body)}"
  =/  grown=@ud  (add bytes (add 2 (lent piece)))
  ?:  (gth grown 131.072)  ~
  $(rest t.rest, pieces [piece pieces], bytes grown)
::
::  +read-clay-context: resolve a clay locator to text. a locator that
::  names a file reads that file. a locator that names a directory or a
::  whole desk concatenates every text-mark file beneath it, and falls
::  back to a listing when those bodies pass the context cap.
::
++  read-clay-context
  |=  raw=@t
  ^-  acquired-context
  =/  parsed  (parse-clay-locator raw)
  ?~  parsed  !!
  ?.  =(our.bol who.u.parsed)  !!
  =/  pax=path
    :*  (scot %p who.u.parsed)
        dek.u.parsed
        (scot %da now.bol)
        rest.u.parsed
    ==
  =/  archive=arch  .^(arch %cy pax)
  =/  rev  (clay-desk-rev dek.u.parsed)
  =/  origin=(unit @t)  ?:(=(0 rev) ~ `(scot %ud rev))
  ?^  fil.archive
    [(clay-file-text pax) %full origin]
  =/  base=path
    [(scot %p who.u.parsed) dek.u.parsed (scot %da now.bol) ~]
  =/  found=(list path)
    (clay-collection-files dek.u.parsed rest.u.parsed)
  ?~  found  !!
  ::  widen the list type again: +scag and +join are wet gates and cast
  ::  their product to the sample they were handed.
  ::
  =/  files=(list path)  found
  =/  shown=(list path)  (scag 2.000 files)
  ::  a whole desk is always a listing: real desks run megabytes.
  ::
  ?~  rest.u.parsed
    [(clay-manifest-text raw files shown) %listing origin]
  =/  inlined=(unit @t)  (clay-collection-text base files)
  ?^  inlined  [u.inlined %full origin]
  [(clay-manifest-text raw files shown) %listing origin]
::
++  local-stack-title
  |=  =stack
  ^-  @t
  ?.  ?=(%.y -.info.stack)
    name.stack
  title.p.info.stack
::
++  context-stack
  |=  [owner=@p stak=@tas]
  ^-  (unit stack)
  ?:  =(owner our.bol)
    (~(get by stacks.state) stak)
  (~(get by stack-subs.state) [owner stak])
::
++  context-scope-exists
  |=  scope=context-scope
  ^-  ?
  ?-  -.scope
    %capture  (~(has by captures.state) id.scope)
    %change   (~(has by changes.state) id.scope)
    %stack
      =/  found=(unit stack)  (context-stack owner.scope stack.scope)
      ?~  found  %.n
      ?~  card.scope  %.y
      (~(has by items.u.found) u.card.scope)
  ==
::
++  context-applies
  |=  [source=context-source owner=@p stak=@tas card=(unit @tas)]
  ^-  ?
  ?&  active.source
      =(%ready status.source)
      (scope-applies:ev scope.source [%stack owner stak card])
  ==
::
++  accept-context
  |=  $:  source=context-source
          content=@t
          coverage=evidence-coverage
          final-locator=@t
          origin=(unit @t)
          extraction=@tas
      ==
  ^-  (quip card _state)
  ?.  active.source  [~ state]
  =/  published
    %:  publish-snapshot:ev
      our.bol  now.bol  source  content  coverage  final-locator  origin  extraction  evidence.state
    ==
  =/  next=context-source
    %=  source.published
      status      ?~(error.published %ready %failed)
      error       ?~(error.published '' u.error.published)
      updated-at  now.bol
    ==
  =.  state  state(contexts (~(put by contexts.state) id.next next), evidence store.published)
  ?^  error.published  (fail-action %blocked u.error.published)
  [~ state]
::
++  archive-context-scope
  |=  scope=context-scope
  ^-  _state
  =/  rows  ~(tap by contexts.state)
  |-
  ?~  rows  state
  =/  [id=@tas source=context-source]  i.rows
  ?.  ?&(active.source (scope-applies:ev scope scope.source))
    $(rows t.rows)
  =/  before  observation-view
  =.  contexts.state
    (~(put by contexts.state) id source(active %.n, generation +(generation.source), updated-at now.bol))
  =.  outstanding-keens.state  (~(del by outstanding-keens.state) id)
  =/  tracker  (agent-tracker our.bol now.bol before observation-view operating.state)
  =.  operating.state  (one:tracker [%context our.bol %root id])
  $(rows t.rows)
::
++  scope-source-count
  |=  scope=context-scope
  ^-  @ud
  =/  index  (~(get by context-index.operating.state) scope)
  ?~  index  0
  %-  lent
  %+  skim  ~(tap in keys.u.index)
  |=  key=entity-key
  =/  source  (~(get by contexts.state) id.key)
  ?~  source  %.n
  active.u.source
::
++  complete-selections
  |=  [scope=context-scope selections=(list evidence-selection)]
  ^-  (list evidence-selection)
  ::  Unchecked applicable sources remain explicit exclusions.
  =/  selected=(set @tas)  (silt (turn selections |=(entry=evidence-selection source.entry)))
  =/  omitted=(list evidence-selection)
    %+  murn  ~(tap by contexts.state)
    |=  [id=@tas source=context-source]
    ?.  ?&  active.source
            (scope-applies:ev scope.source scope)
            !(~(has in selected) id)
        ==
      ~
    `[id 0 ~ %.n %.n]
  (weld selections omitted)
::
++  observed-plan-fences
  |=  [ops=(list state-operation) observed=(list entity-precondition)]
  ^-  (unit (list entity-precondition))
  =/  supplied  (malt (turn observed |=(fence=entity-precondition [key.fence fence])))
  =/  required  (capture-preconditions:effects our.bol versions.operating.state ops)
  =/  out=(list entity-precondition)  ~
  |-
  ?~  required  `(flop out)
  =/  fence  i.required
  =/  old  (~(get by supplied) key.fence)
  ?~  old
    ::  New targets may capture a negative fence; never rebase live targets.
    ?:  ?~(seen.fence %.n present.u.seen.fence)  ~
    $(required t.required, out [fence out])
  ?.  ?&  ?|(!content.fence content.u.old)
          ?|(!review.fence review.u.old)
      ==
    ~
  $(required t.required, out [fence(seen seen.u.old) out])
::
++  library-observation
  |=  fence=entity-precondition
  ^-  json
  =/  key  key.fence
  =/  base
    %-  pairs:enjs:format
    :~  ['ref' (key-json:ev key)]
        ['version' ?~(seen.fence ~ (version-json:ev u.seen.fence))]
        ['content' b+content.fence]
        ['review' b+review.fence]
    ==
  ?.  ?~(seen.fence %.n present.u.seen.fence)  base
  =/  parent  (~(get by stacks.state) ?:(=(%stack kind.key) id.key scope.key))
  ?~  parent  base
  =/  detail
    ?:  =(%stack kind.key)
      (pairs:enjs:format ~[['title' s+(local-stack-title u.parent)]])
    =/  card  (~(get by items.u.parent) id.key)
    ?~  card  (pairs:enjs:format ~)
    %-  pairs:enjs:format
    :~  ['title' s+title.content.u.card]
        ['front' ?:(content.fence s+(clean-body front.content.u.card) ~)]
        ['back' ?:(content.fence s+(clean-body back.content.u.card) ~)]
    ==
  (merge-json:reader base detail)
::
::  +prompt-tokens: lowercase words of at least three letters, for the
::  deterministic relevance ranking of library observations.
::
++  prompt-tokens
  |=  text=@t
  ^-  (set @t)
  =/  tap  (cass (trip text))
  =/  out=(set @t)  ~
  =/  word=tape  ~
  |-
  ?~  tap
    ?:  (gte (lent word) 3)  (~(put in out) (crip (flop word)))
    out
  ?:  ?|(&((gte i.tap 'a') (lte i.tap 'z')) &((gte i.tap '0') (lte i.tap '9')))
    $(tap t.tap, word [i.tap word])
  =?  out  (gte (lent word) 3)  (~(put in out) (crip (flop word)))
  $(tap t.tap, word ~)
::
++  overlap-score
  |=  [words=(set @t) text=@t]
  ^-  @ud
  =/  found  (prompt-tokens text)
  ~(wyt in (~(int in words) found))
::
::  +library-selection: the stacks and cards a library plan may observe,
::  chosen deterministically from this ship's own library under the
::  schema-2 limits. remote stacks are read-only and appear as omissions.
::
++  library-selection
  |=  prompt=@t
  ^-  $:  fences=(list entity-precondition)
          omissions=(list [reason=@tas ref=@t])
          observed=[stacks=@ud cards=@ud]
      ==
  =/  words  (prompt-tokens prompt)
  =/  ranked=(list [score=@ud id=@tas =stack])
    %+  sort
      %+  turn  ~(tap by stacks.state)
      |=  [id=@tas =stack]
      =/  base  (overlap-score words (local-stack-title stack))
      =/  cards
        %+  roll  ~(tap by items.stack)
        |=  [[name=@tas =item] acc=@ud]
        (add acc (overlap-score words (rap 3 title.content.item ' ' front.content.item ~)))
      [(add (mul 4 base) cards) id stack]
    |=  [a=[score=@ud id=@tas *] b=[score=@ud id=@tas *]]
    ?:  =(score.a score.b)  (aor id.a id.b)
    (gth score.a score.b)
  =/  remote=(list [reason=@tas ref=@t])
    %+  turn  ~(tap by stack-subs.state)
    |=  [[who=@p id=@tas] *]
    [%remote-read-only (rap 3 (scot %p who) '/' id ~)]
  =/  fences=(list entity-precondition)  ~
  =/  omissions=(list [reason=@tas ref=@t])  remote
  =/  stacks=@ud  0
  =/  cards=@ud  0
  =/  bytes=@ud  0
  |-
  ?~  ranked  [(flop fences) (flop omissions) stacks cards]
  =/  [score=@ud id=@tas =stack]  i.ranked
  ?:  (gte stacks 6)
    $(ranked t.ranked, omissions [[%stack-limit id] omissions])
  =/  stack-key=entity-key  [%stack our.bol %root id]
  =.  fences  [[stack-key (~(get by versions.operating.state) stack-key) %.y %.n] fences]
  =.  stacks  +(stacks)
  =/  card-rows=(list [score=@ud name=@tas =item])
    %+  sort
      %+  turn  ~(tap by items.stack)
      |=  [name=@tas =item]
      [(overlap-score words (rap 3 title.content.item ' ' front.content.item ~)) name item]
    |=  [a=[score=@ud name=@tas *] b=[score=@ud name=@tas *]]
    ?:  =(score.a score.b)  (aor name.a name.b)
    (gth score.a score.b)
  =/  taken=@ud  0
  |-
  ?~  card-rows  ^$(ranked t.ranked)
  =/  [card-score=@ud name=@tas =item]  i.card-rows
  =/  ref  (rap 3 id '/' name ~)
  ?:  ?|((gte taken 8) (gte cards 24))
    $(card-rows t.card-rows, omissions [[%card-limit ref] omissions])
  =/  cost  (add 96 (add (met 3 title.content.item) (add (met 3 front.content.item) (met 3 back.content.item))))
  ?:  (gth (add bytes cost) 98.304)
    $(card-rows t.card-rows, omissions [[%byte-limit ref] omissions])
  =/  card-key=entity-key  [%card our.bol id name]
  %=  $
    card-rows  t.card-rows
    fences     [[card-key (~(get by versions.operating.state) card-key) %.y %.n] fences]
    taken      +(taken)
    cards      +(cards)
    bytes      (add bytes cost)
  ==
::
::  +freeze-change-packet: the ship authors the library observation and
::  freezes the provider packet for a change request before dispatch.
::
++  freeze-change-packet
  |=  [id=@tas attempt=@ud]
  ^-  (quip card _state)
  =/  request  (~(get by changes.state) id)
  ?~  request  (fail-action %blocked %change-not-found)
  =/  key=entity-key  [%change our.bol %root id]
  ?.  ?&(=(%working status.u.request) ?=(~ packet.u.request))
    (fail-action %blocked %packet-already-frozen)
  =/  selection=[fences=(list entity-precondition) omissions=(list [reason=@tas ref=@t]) observed=[stacks=@ud cards=@ud]]
    ?:  =(%desk target.u.request)  [~ ~ 0 0]
    (library-selection prompt.u.request)
  =/  observations  fences.selection
  =/  stack-index
    (fall (~(get by read-indexes.operating.state) [%stack `our.bol ~ ~ ~]) *agent-read-index)
  =/  card-index
    (fall (~(get by read-indexes.operating.state) [%card `our.bol ~ ~ ~]) *agent-read-index)
  =/  full=?
    ?:  =(%desk target.u.request)  %.y
    ?&(=(total.stack-index stacks.observed.selection) =(total.card-index cards.observed.selection))
  =/  coverage=json
    ?:  =(%desk target.u.request)  ~
    %-  pairs:enjs:format
    :~  ['scope' s+'local-library']
        ['owner' s+(scot %p our.bol)]
        ['complete' b+full]
        ['stack_count' (numb:enjs:format total.stack-index)]
        ['observed_stack_count' (numb:enjs:format stacks.observed.selection)]
        ['unobserved_stack_count' (numb:enjs:format (sub total.stack-index (min total.stack-index stacks.observed.selection)))]
        ['card_count' (numb:enjs:format total.card-index)]
        ['observed_card_count' (numb:enjs:format cards.observed.selection)]
        ['unobserved_card_count' (numb:enjs:format (sub total.card-index (min total.card-index cards.observed.selection)))]
    ==
  =/  front
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['observations' [%a (turn observations library-observation)]]
        ['source_coverage' coverage]
        :-  'omissions'
        :-  %a
        %+  turn  omissions.selection
        |=  [reason=@tas ref=@t]
        (pairs:enjs:format ~[['reason' s+reason] ['ref' s+ref]])
    ==
  ?:  (gth (met 3 front) 131.072)  (fail-action %budget-exhausted %observation-byte-limit)
  =/  selections=(list evidence-selection)
    %+  murn  ~(tap by contexts.state)
    |=  [source-id=@tas source=context-source]
    ?.  ?&(active.source =([%change id] scope.source))  ~
    `[source-id 0 ~ %.y %.y]
  =/  req=packet-request
    %*  .  *packet-request
      work           key
      attempt        attempt
      scope          [%change id]
      profile        profile.u.request
      mode           target.u.request
      objective      prompt.u.request
      front          front
      selections     (complete-selections [%change id] selections)
      max-bytes      131.072
      excerpt-bytes  24.000
    ==
  =/  built  (build-packet:ev our.bol now.bol req contexts.state evidence.state)
  =.  evidence.state  store.built
  =/  retained=(unit @ux)
    ?:((~(has by packets.evidence.state) id.packet.built) `id.packet.built ~)
  =.  changes.state
    (~(put by changes.state) id u.request(packet retained, scope-preconditions observations, updated-at now.bol))
  ?^  blocked.packet.built  (fail-action %blocked u.blocked.packet.built)
  [~ state]
::
++  block-question
  |=  [question=card-question reason=@tas]
  ^-  (quip card _state)
  =.  question
    question(status %failed, response reason, updated-at now.bol)
  =.  questions.state  (~(put by questions.state) id.question question)
  (fail-action %blocked reason)
::
++  prepare-question
  |=  $:  question=card-question
          selections=(list evidence-selection)
          max-bytes=@ud
          excerpt-bytes=@ud
          attempt=@ud
      ==
  ^-  (quip card _state)
  =/  found  (context-stack owner.question stack.question)
  ?~  found  (block-question question %subject-not-found)
  =/  current  (~(get by items.u.found) card.question)
  ?~  current  (block-question question %subject-not-found)
  =/  key=entity-key  [%card owner.question stack.question card.question]
  =/  version  (~(get by versions.operating.state) key)
  ?~  version  (block-question question %subject-version-unavailable)
  =/  profile  (~(get by models.state) id.profile.question)
  ?~  profile  (block-question question %model-unavailable)
  ?.  =(u.profile(origin '', registered-at 0) profile.question(origin '', registered-at 0))
    (block-question question %model-unavailable)
  =.  question
    %=  question
      title         title.content.u.current
      front         front.content.u.current
      back          back.content.u.current
      response      ''
      citations     ~
      result-title  ''
      result-front  ''
      result-back   ''
      updated-at    now.bol
    ==
  =/  request=packet-request
    %*  .  *packet-request
      work           [%question our.bol %root id.question]
      attempt        attempt
      scope          [%stack owner.question stack.question `card.question]
      subject        `[key u.version]
      profile        profile.question
      mode           mode.question
      objective      prompt.question
      title          title.question
      front          (clean-body front.question)
      back           (clean-body back.question)
      selections     (complete-selections [%stack owner.question stack.question `card.question] selections)
      max-bytes      max-bytes
      excerpt-bytes  excerpt-bytes
    ==
  =/  built  (build-packet:ev our.bol now.bol request contexts.state evidence.state)
  =.  evidence.state  store.built
  =.  packet.question
    ?:  (~(has by packets.evidence.state) id.packet.built)  `id.packet.built
    ~
  ?^  blocked.packet.built
    (block-question question u.blocked.packet.built)
  =.  status.question  %pending
  =/  reusable
    ?.  =(%ask mode.question)  ~
    (find-reusable:memory packet.built contexts.state evidence.state versions.operating.state learning.state)
  =?  question  ?=(^ reusable)
    question(status %answered, response text.u.reusable, citations citations.u.reusable)
  =?  reuse-count.learning.state  ?=(^ reusable)  +(reuse-count.learning.state)
  [~ state(questions (~(put by questions.state) id.question question))]
::
++  question-packet
  |=  question=card-question
  ^-  (unit context-packet)
  ?~  packet.question  ~
  (~(get by packets.evidence.state) u.packet.question)
::
++  question-input-error
  |=  question=card-question
  ^-  (unit @tas)
  =/  packet  (question-packet question)
  ?~  packet  `%packet-unavailable
  =/  error  (packet-egress-error:ev u.packet contexts.state evidence.state)
  ?^  error  error
  ?.  =(%edit mode.question)  ~
  =/  subject  subject.request.u.packet
  ?~  subject  `%subject-version-unavailable
  =/  current  (~(get by versions.operating.state) key.u.subject)
  ?~  current  `%subject-not-found
  ?.  ?&  present.u.current
          =(incarnation.u.current incarnation.version.u.subject)
          =(content-revision.u.current content-revision.version.u.subject)
      ==
    `%content-conflict
  ~
::
++  question-result-error
  |=  [question=card-question citations=(list evidence-citation)]
  ^-  (unit @tas)
  =/  error  (question-input-error question)
  ?^  error  error
  =/  packet  (need (question-packet question))
  (validate-citations:ev packet citations evidence.state)
::
++  local-operation
  |=  act=action
  ^-  @t
  (scot %uv (shax (jam [epoch.operating.state now.bol receipt-count.operating.state act])))
::
++  fail-action
  |=  [status=operation-status reason=@tas]
  ^-  (quip card _state)
  [~ state(failure.operating `[status reason])]
::
++  trusted-operator
  ^-  ?
  ?&  =(our.bol src.bol)
      ?|  =(/gall/hood sap.bol)
          =(/gall/dojo sap.bol)
          =(/gall/seer sap.bol)
          =(/gall/seer-cli sap.bol)
          =(/dill sap.bol)
      ==
  ==
::
++  planner-action
  |=  act=action
  ^-  ?
  ?+  -.act  %.n
    %begin-capture          %.y
    %prepare-capture        %.y
    %stage-card             %.y
    %request-change         !start.act
    %propose-change         %.y
    %add-context-source     %.y
    %refresh-context-source  %.y
    %remove-context-source  %.y
    %rename-context-source  %.y
    %ask-card               =(%ask mode.act)
  ==
::
::  +system-command: apply one of the ship's own transitions with a
::  receipt. the operation id is unique per event; replay never applies.
::
++  system-command
  |=  act=action
  ^-  (quip card _state)
  =/  cmd  (make-command epoch.operating.state (local-operation act) act)
  (apply-command(system-authorized %.y, operator-authorized %.y) cmd)
::
++  receipt-fences
  |=  [keys=(list entity-key) versions=(map entity-key entity-version)]
  ^-  (list entity-precondition)
  (turn keys |=(key=entity-key [key (~(get by versions) key) %.y %.y]))
::
++  apply-command
  |=  cmd=command
  ^-  (quip card _state)
  ::  Receipts and effects are one event. Replays never enter domain code.
  =/  key  [epoch.cmd operation.cmd]
  ?:  (~(has by receipts.operating.state) key)  [~ state]
  ?.  =(epoch.cmd epoch.operating.state)  [~ state]
  ?.  ?&(!=('' operation.cmd) (bounded-text:ev operation.cmd 128))
    [~ state]
  ?:  ?&  (gte receipt-count.operating.state 4.096)
          !?=(%retire-operation-epoch -.payload.cmd)
      ==
    [~ state]
  =.  operating.state  operating.state(changed ~, failure ~)
  =/  original  state
  =/  semantic=action  payload.cmd
  =/  receipt=operation-receipt
    %*  .  *operation-receipt
      epoch       epoch.cmd
      id          operation.cmd
      digest      digest.cmd
      submission  submission.cmd
      action      -.semantic
      status      %invalid
      reason      %invalid-command
      effect      %none
      authority   ?:(system-authorized %system ?:(operator-authorized %operator %planner))
      work        (work-key our.bol semantic)
      revision    revision.operating.state
      at          now.bol
    ==
  =/  result=(each (quip card _state) tang)
    ?.  ?&  =(seer-schema-version schema.cmd)
            =(digest.cmd (shax (jam payload.cmd)))
        ==
      [%& (fail-action %invalid %invalid-command)]
    ?:  ?&(!system-authorized (system-action payload.cmd))
      [%& (fail-action %unauthorized %system-action-required)]
    ?.  ?|(operator-authorized (planner-action payload.cmd))
      [%& (fail-action %unauthorized %operator-entrypoint-required)]
    %-  mule
    |.  (poke-seer-action(acting-operation operation.cmd, acting-epoch epoch.cmd) payload.cmd)
  =/  moves=(list card)  ~
  ?:  ?=(%| -.result)
    =.  receipt  receipt(reason %action-trapped)
    (retain-receipt receipt moves)
  =.  moves  -.p.result
  =.  state  +.p.result
  =/  keys  ~(tap in changed.operating.state)
  ?:  ?&  (gth (lent keys) 256)
          !?=(?(%archive-orphan-contexts %collect-retained %purge-evidence %retire-operation-epoch) -.semantic)
      ==
    =.  state  original
    (retain-receipt receipt(status %budget-exhausted, reason %affected-limit) ~)
  =/  failure  failure.operating.state
  =/  no-change
    ?&  ?=(~ keys)
        ?=(~ moves)
        =(original(operating *agent-state) state(operating *agent-state))
        !?=(?(%retire-operation-epoch) -.semantic)
    ==
  =?  failure  ?&(?=(~ failure) no-change)
    ?:  ?=(?(%archive-orphan-contexts %collect-retained %set-context-egress %update-review %replace-assistant-models %refresh-catalog %clear-account %cancel-work) -.semantic)
      ~
    `[%blocked %action-not-applicable]
  =.  receipt
    %=  receipt
      status    ?~(failure %ok status.u.failure)
      reason    ?~(failure ?:(no-change %no-change %ok) reason.u.failure)
      before    (receipt-fences keys versions.operating.original)
      after     (receipt-fences keys versions.operating.state)
      revision  revision.operating.state
      effect
        ?:  ?=([~ %outcome-unknown *] failure)  %unknown
        ?:  (lien keys |=(key=entity-key ?=(?(%card %stack) kind.key)))  %committed
        ?:  ?=(?(%stage-card %propose-change %finish-change) -.semantic)  ?~(failure %staged %none)
        %none
    ==
  =/  job=(unit work-record)
    ?~  work.receipt  ~
    (~(get by jobs.operating.state) u.work.receipt)
  =?  attempt.receipt  ?=(^ job)  `attempt.u.job
  =?  plan.receipt  ?=(%apply-change -.semantic)  `digest.semantic
  =?  plan.receipt  ?=(%approve-proposal -.semantic)  `digest.semantic
  (retain-receipt receipt moves)
::
++  retain-receipt
  |=  [receipt=operation-receipt moves=(list card)]
  ^-  (quip card _state)
  =.  operating.state
    %=  operating.state
      receipts       (~(put by receipts.operating.state) [epoch.receipt id.receipt] receipt)
      receipt-count  +(receipt-count.operating.state)
      changed        ~
      failure        ~
    ==
  [moves state]
::
++  change-preview
  |=  id=@tas
  ^-  plan-preview
  =/  request  (~(get by changes.state) id)
  ?~  request  [%invalid %not-found 0x0 stacks.state ~ ~]
  (validate-plan:effects our.bol now.bol stacks.state versions.operating.state operations.u.request preconditions.u.request)
::
++  commit-preview
  |=  preview=plan-preview
  ^-  (quip card _state)
  ?.  =(%ok status.preview)  (fail-action status.preview reason.preview)
  =/  before  observation-view
  ::  Commit the exact fully validated candidate, not reconstructed actions.
  =.  stacks.state  candidate.preview
  =/  keys  affected.preview
  =/  parents=(set @tas)  ~
  =.  state
    |-
    ?~  keys  state
    =/  key  i.keys
    =/  tracker  (agent-tracker our.bol now.bol before observation-view operating.state)
    =.  operating.state
      ?:  =(%card kind.key)  (card:tracker our.bol scope.key id.key)
      (one:tracker key)
    ?.  =(%card kind.key)
      =?  state  !(~(has by stacks.state) id.key)
        (archive-context-scope [%stack our.bol id.key ~])
      $(keys t.keys)
    =/  parent  (~(get by stacks.state) scope.key)
    ?:  ?~(parent %.y !(~(has by items.u.parent) id.key))
      =.  provenance.state  (~(del by provenance.state) [scope.key id.key])
      =.  state  (archive-context-scope [%stack our.bol scope.key `id.key])
      $(keys t.keys)
    $(keys t.keys)
  =.  parents
    %-  silt
    (turn affected.preview |=(key=entity-key ?:(=(%stack kind.key) id.key scope.key)))
  =<  abet
  =/  rows  ~(tap in parents)
  |-
  ?~  rows  this
  =/  current  (~(get by stacks.state) i.rows)
  =.  ..emit
    %-  emit-primary
    ?~  current  [%delete-stack our.bol i.rows]
    [%update-stack our.bol u.current]
  $(rows t.rows)
::
++  index-learning
  |=  before=agent-view
  ^-  learning-state
  =/  keys  ~(tap in changed.operating.state)
  =/  store  learning.state
  |-
  ?~  keys  store
  =/  key  i.keys
  ?.  ?&(=(our.bol owner.key) =(%card kind.key))  $(keys t.keys)
  =/  previous  (~(get by stacks.data.before) scope.key)
  =/  current  (~(get by stacks.state) scope.key)
  =.  store
    %:  index-card:memory  key
      ?~(previous ~ (~(get by items.u.previous) id.key))
      ?~(current ~ (~(get by items.u.current) id.key))
      store
    ==
  $(keys t.keys)
::
++  grade
  |=  value=@t
  ^-  recall-grade
  =/  name  (slav %tas value)
  ?+  name  %good
      %again  %again
      %hard   %hard
      %good   %good
      %easy   %easy
  ==
::
++  poke-seer-action
  |=  act=action
  ^-  (quip card _state)
  =/  before  observation-view
  =^  moves  state  (apply-seer-action act)
  =.  operating.state
    (track-agent-state our.bol now.bol act before observation-view operating.state)
  =.  learning.state  (index-learning before)
  [moves state]
::
++  apply-seer-action
  |=  act=action
  ^-  (quip card _state)
  ?-  -.act
      %new-stack
    ?.  =(our.bol src.bol)
      [~ state]
    ?:  (~(has by stacks) name.act)  (fail-action %conflict %stack-id-in-use)
    ::
    =/  conf=stack-info
      :*  our.bol
          title.act
          name.act
          =edit-config
          now.bol
          now.bol
      ==
    =<  abet
    ~(add-stack stack-emit (create-stack conf items.act))
      %new-item
    =/  existing  (~(get by stacks.state) stak.act)
    ?:  ?~(existing %.n (~(has by items.u.existing) name.act))
      (fail-action %conflict %card-id-in-use)
    =/  new-item=item  (create-item act)
    =<  abet
    =/  sub=(unit stack)
      (~(get by stack-subs) [stack-owner.act stak.act])
    =/  pub=(unit stack)
      (~(get by stacks) stak.act)
    ?~  pub
      ?~  sub
        this
      ?>  ?=(%.y -.info.u.sub)
      =/  =stack-info  +.info.u.sub
      %~  add-stack  stack-emit
      %+  create-stack  stack-info(owner our.bol)
      (my [[name.act new-item] ~])
    %.  new-item
    %~  add-item  stack-emit  u.pub
    ::
      %delete-stack
    =/  stack-to-delete
      ?:  =(our.bol who.act)
        (~(got by stacks) stak.act)
      (~(got by stack-subs) who.act stak.act)
    =.  state  (archive-context-scope [%stack who.act stak.act ~])
    =<  abet
    (~(delete-stack stack-emit stack-to-delete) who.act)
      %delete-item
    =.  provenance.state
      (~(del by provenance.state) [stak.act item.act])
    =.  state  (archive-context-scope [%stack our.bol stak.act `item.act])
    =<  abet
    %.  item.act
    ~(delete-item stack-emit (~(got by stacks) stak.act))
      %edit-stack
    =/  =stack  (~(got by stacks) name.act)
    ?>  ?=(%.y -.info.stack)
    =/  =stack-info  p.info.stack
    =<  abet
    %~  update-stack  stack-emit
    %=    stack
        info
      [%.y stack-info(title title.act, last-modified now.bol)]
        last-update
      now.bol
    ==
    ::
      %review-stack
    ?>  =(our.bol who.act)
    =/  stack  (~(got by stacks) stak.act)
    =<  abet
    (~(review-stack stack-emit stack) who.act)
    ::
      %edit-item
    =/  stack  (~(got by stacks) stak.act)
    =/  item=item  (~(got by items.stack) name.act)
    =/  next  (edit-item:effects src.bol now.bol item title.act front.act back.act)
    =<  abet
    %.  next
    %~  edit-item  stack-emit  stack
      %raise-item
    =/  stack  (~(got by stacks) stak.act)
    =/  =item  (~(got by items.stack) item.act)
    =<  abet
    %.  item
    %~  add-review-item  stack-emit  stack
      %copy-stack
    =/  their-stack=stack
      (~(got by stack-subs) [owner.act stak.act])
    ::  A fresh copy starts its own review history unless the learner
    ::  explicitly keeps what was learned from the subscription.
    =?  their-stack  !keep-learned.act
      =/  reset  |=(=item item(learn (learn [.2.5 0 0]), last-review ~))
      %=  their-stack
        items         (~(run by items.their-stack) reset)
        review-items  (~(run by review-items.their-stack) reset)
      ==
    =<  abet
    =.  ..emit  ~(update-owner stack-emit their-stack)
    ~(add-stack stack-emit stak:emit)
      %answered-item
    =/  is-owner=?  =(our.bol owner.act)
    =/  stk=stack
      ?:  is-owner
        (~(got by stacks) stak.act)
      (~(got by stack-subs) [owner.act stak.act])
    =/  =item  (~(got by items.stk) item.act)
    =?  learning.state  is-owner
      =/  key=entity-key  [%card our.bol stak.act item.act]
      =/  version  (~(get by versions.operating.state) key)
      ?~  version  learning.state
      (record-grade:memory our.bol now.bol key u.version answer.act learning.state)
    =/  mov=(unit card)
      ?:  is-owner
        ~
      =/  new-act=action
        :*  %new-item
            owner.act
            our.bol
            stak.act
            name.item
            title.content.item
            [read=*rule:clay write=*rule:clay]
            front.content.item
            back.content.item
        ==
      :-  ~
      :*  %pass
          /stacks
          %agent
          [our.bol %seer]
          %poke
          %seer-action
          (command-vase epoch.operating.state (local-operation new-act) new-act)
      ==
    =<  abet
    ?.  ?=(%~ mov)
      (emit (need mov))
    %.  [item answer.act]
    %~  update-learn  stack-emit  stk
      %update-review
    =<  abet  update-review:stack-emit
      %import
    =/  =wire  /import/(scot %p who.act)/[stack.act]
    :_  state
    [%pass wire %agent [who.act %seer] %watch /stack/[stack.act]]~
      %import-file
    (import-from-file path.act)
      %retire-operation-epoch
    =^  moves  state  (fence-running %epoch-retired)
    =.  operating.state
      operating.state(epoch (max now.bol +(epoch.operating.state)), receipts ~, receipt-count 0)
    [moves state]
      %cancel-work
    ?.  =(our.bol owner.work.act)  (fail-action %unauthorized %wrong-owner)
    =/  job  (~(get by jobs.operating.state) work.act)
    ?~  job  (fail-action %blocked %work-not-found)
    ?.  ?=(?(%queued %running %blocked) execution.u.job)
      (fail-action %blocked %work-already-settled)
    =/  running  =(%running execution.u.job)
    =/  cancels  ?:(running (cancel-cards work.act attempt.u.job) ~)
    =^  moves  state  (stop-work work.act %cancelled %.n)
    ::  a provider may already have run a cancelled request; only a fetch
    ::  is known to have had no effect.
    =?  state  ?&(running ?=(?(%question %change) kind.work.act))
      (mark-unknown work.act %cancelled)
    [(weld cancels moves) state]
      %purge-evidence
    (purge-retained snapshots.act)
      %collect-retained
    collect-retained
      %import-account
    ?.  ?&  !=('' access.act)
            (bounded-text:ev access.act 16.384)
            (bounded-text:ev refresh.act 16.384)
            (bounded-text:ev account.act 512)
            (bounded-text:ev scopes.act 1.024)
        ==
      (fail-action %invalid %invalid-account)
    ::  a new sign-in fences any renewal of the slot it replaces: the
    ::  serial keeps counting so a late rotation can never match.
    =/  previous  (~(get by accounts.state) provider.act)
    =/  cancels=(list card)
      ?~  previous  ~
      ?~  active.renewal.u.previous  ~
      ~[(cancel-card:net /seer-renew/(scot %tas provider.act)/(scot %ud serial.u.active.renewal.u.previous))]
    =/  slot=provider-account
      :*  method.act
          access.act
          ?:(=(%api-key method.act) '' refresh.act)
          account.act
          ?:(=(%api-key method.act) ~ expires.act)
          scopes.act
          now.bol
          [~ ?~(previous 0 serial.renewal.u.previous) *@da '' %.n]
      ==
    =.  accounts.state  (~(put by accounts.state) provider.act slot)
    =.  catalog-pending.state  (~(put in catalog-pending.state) provider.act)
    [cancels state]
      %rotate-account
    =/  slot  (~(get by accounts.state) provider.act)
    ?~  slot  (fail-action %blocked %account-missing)
    ?.  ?&(?=(^ active.renewal.u.slot) =(serial.act serial.u.active.renewal.u.slot))
      (fail-action %blocked %attempt-fenced)
    ?:  =('' access.act)  (fail-action %invalid %invalid-account)
    =/  next=provider-account
      %=  u.slot
        access       access.act
        refresh      ?:(=('' refresh.act) refresh.u.slot refresh.act)
        expires      expires.act
        observed-at  now.bol
        renewal      [~ serial.renewal.u.slot *@da '' %.n]
      ==
    [~ state(accounts (~(put by accounts.state) provider.act next))]
      %fail-renewal
    =/  slot  (~(get by accounts.state) provider.act)
    ?~  slot  (fail-action %blocked %account-missing)
    ?.  ?&(?=(^ active.renewal.u.slot) =(serial.act serial.u.active.renewal.u.slot))
      (fail-action %blocked %attempt-fenced)
    =/  next=provider-account
      %=  u.slot
        renewal  [~ serial.renewal.u.slot (add now.bol renewal-cooldown:oa) (scot %tas message.act) terminal.act]
      ==
    =.  accounts.state  (~(put by accounts.state) provider.act next)
    (fail-action %blocked ?:(terminal.act %renewal-terminal %renewal-cooldown))
      %clear-account
    =/  slot  (~(get by accounts.state) provider.act)
    ?~  slot  [~ state]
    =/  cancels=(list card)
      ?~  active.renewal.u.slot  ~
      ~[(cancel-card:net /seer-renew/(scot %tas provider.act)/(scot %ud serial.u.active.renewal.u.slot))]
    =.  accounts.state  (~(del by accounts.state) provider.act)
    =.  catalog-pending.state  (~(del in catalog-pending.state) provider.act)
    =.  catalog-active.state  (~(del by catalog-active.state) provider.act)
    [cancels state]
      %refresh-catalog
    ?.  (~(has by accounts.state) provider.act)  (fail-action %blocked %sign-in-required)
    [~ state(catalog-pending (~(put in catalog-pending.state) provider.act))]
      %dispatch-work
    (dispatch-work work.act)
      %begin-capture
    ?:  (~(has by captures.state) id.act)
      [~ state]
    ?.  ?&  !=('' title.act)
            !=('' goal.act)
            (bounded-text:ev title.act 1.024)
            (bounded-text:ev goal.act 131.072)
            (bounded-text:ev source.act 131.072)
        ==
      (fail-action %invalid %invalid-capture)
    =/  session=capture
      %*  .  *capture
        id          id.act
        title       title.act
        goal        goal.act
        source      source.act
        created-by  created-by.act
        created-at  now.bol
        status      %open
      ==
    =.  captures.state
      (~(put by captures.state) id.act session)
    [~ state]
      %prepare-capture
    =/  session  (~(get by captures.state) id.act)
    ?~  session  (fail-action %blocked %capture-not-found)
    ?.  =(%open status.u.session)  (fail-action %blocked %capture-complete)
    =/  profile  (~(get by models.state) id.profile.act)
    ?~  profile  (fail-action %blocked %model-unavailable)
    ?.  =(u.profile(origin '', registered-at 0) profile.act(origin '', registered-at 0))
      (fail-action %conflict %model-changed)
    =/  req=packet-request
      %*  .  *packet-request
        work           [%capture our.bol %root id.act]
        attempt        1
        scope          [%capture id.act]
        profile        u.profile
        mode           %capture
        objective      goal.u.session
        title          title.u.session
        front          source.u.session
        selections     (complete-selections [%capture id.act] selections.act)
        max-bytes      max-bytes.act
        excerpt-bytes  excerpt-bytes.act
      ==
    =/  built  (build-packet:ev our.bol now.bol req contexts.state evidence.state)
    =.  evidence.state  store.built
    =/  retained=(unit @ux)
      ?:((~(has by packets.evidence.state) id.packet.built) `id.packet.built ~)
    =.  captures.state  (~(put by captures.state) id.act u.session(packet retained))
    ?^  blocked.packet.built  (fail-action %blocked u.blocked.packet.built)
    [~ state]
      %stage-card
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    =/  session  u.maybe-session
    ?.  =(%open status.session)  [~ state]
    =/  maybe-stack  (~(get by stacks.state) stack.act)
    ?~  maybe-stack  [~ state]
    ?:  (~(has by items.u.maybe-stack) card.act)  [~ state]
    ?:  (~(has by proposals.session) proposal.act)  [~ state]
    =/  draft=proposal
      :*  proposal.act
          stack.act
          card.act
          title.act
          front.act
          back.act
          rationale.act
          source.act
          created-by.act
          now.bol
          objective.act
          claim.act
          why-new.act
          caveat.act
          packet.act
          citations.act
          ~
          preconditions.act
      ==
    =/  preview  (proposal-preview:effects our.bol now.bol stacks.state versions.operating.state draft)
    ?.  =(%ok status.preview)  (fail-action status.preview reason.preview)
    =/  staged
      (stage-artifact:memory our.bol now.bol capture.act session draft learning.state evidence.state contexts.state)
    =.  learning.state  store.staged
    ?^  error.staged  (fail-action %blocked u.error.staged)
    =.  draft  draft.staged
    =.  proposals.session
      (~(put by proposals.session) proposal.act draft)
    =.  captures.state
      (~(put by captures.state) capture.act session)
    [~ state]
      %approve-proposal
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    =/  session  u.maybe-session
    =/  maybe-draft  (~(get by proposals.session) proposal.act)
    ?~  maybe-draft  [~ state]
    =/  draft  u.maybe-draft
    =/  preview  (proposal-preview:effects our.bol now.bol stacks.state versions.operating.state draft)
    ?.  =(digest.act digest.preview)  (fail-action %conflict %plan-digest-mismatch)
    ?.  =(%ok status.preview)  (fail-action status.preview reason.preview)
    ?~  artifact.draft  (fail-action %blocked %artifact-unavailable)
    =/  retained  (~(get by artifacts.learning.state) u.artifact.draft)
    ?~  retained  (fail-action %blocked %artifact-unavailable)
    ?~  packet.draft  (fail-action %blocked %packet-unavailable)
    =/  packet  (~(get by packets.evidence.state) u.packet.draft)
    ?~  packet  (fail-action %blocked %packet-unavailable)
    =/  error  (artifact-error:memory u.retained provider.profile.request.u.packet contexts.state evidence.state versions.operating.state)
    ?^  error  (fail-action %blocked u.error)
    =/  decision  (decide-artifact:memory our.bol now.bol u.artifact.draft %approved ~ learning.state)
    ?^  error.decision  (fail-action %blocked u.error.decision)
    =^  add-cards  state  (commit-preview preview)
    =.  learning.state  store.decision
    =/  left=(map @tas proposal)
      (~(del by proposals.session) proposal.act)
    =.  proposals.session  left
    =.  approved.session  +(approved.session)
    =.  status.session  ?:(=(~ left) %complete %open)
    =.  captures.state
      (~(put by captures.state) capture.act session)
    =/  origin=provenance:seer-types
      :*  %capture
          capture.act
          source.draft
          rationale.draft
          created-by.draft
          created-at.draft
          now.bol
          packet.draft
          citations.draft
          artifact.draft
          (~(get by versions.operating.state) [%card our.bol stack.draft card.draft])
      ==
    =.  provenance.state
      (~(put by provenance.state) [stack.draft card.draft] origin)
    [add-cards state]
      %reject-proposal
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    =/  session  u.maybe-session
    ?:  !(~(has by proposals.session) proposal.act)  [~ state]
    =/  draft  (~(got by proposals.session) proposal.act)
    ?~  artifact.draft  (fail-action %blocked %artifact-unavailable)
    =/  decision  (decide-artifact:memory our.bol now.bol u.artifact.draft %rejected reason.act learning.state)
    ?^  error.decision  (fail-action %blocked u.error.decision)
    =.  learning.state  store.decision
    =/  left=(map @tas proposal)
      (~(del by proposals.session) proposal.act)
    =.  proposals.session  left
    =.  rejected.session  +(rejected.session)
    =.  status.session  ?:(=(~ left) %complete %open)
    =.  captures.state
      (~(put by captures.state) capture.act session)
    [~ state]
      %discard-capture
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    =/  session  u.maybe-session
    =/  drafts  ~(val by proposals.session)
    =.  learning.state
      =/  store  learning.state
      |-
      ?~  drafts  store
      ?~  artifact.i.drafts  $(drafts t.drafts)
      =/  decision  (decide-artifact:memory our.bol now.bol u.artifact.i.drafts %rejected ~ store)
      $(drafts t.drafts, store store.decision)
    =.  rejected.session
      (add rejected.session (lent ~(tap by proposals.session)))
    =.  proposals.session  ~
    =.  status.session  %complete
    =.  captures.state
      (~(put by captures.state) capture.act session)
    [~ state]
      %delete-capture
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    ?.  =(%complete status.u.maybe-session)  [~ state]
    =.  captures.state  (~(del by captures.state) capture.act)
    =.  state  (archive-context-scope [%capture capture.act])
    [~ state]
      %add-context-source
    ?:  ?|  (~(has by contexts.state) id.act)
            (gte (lent (skim ~(val by contexts.state) |=(source=context-source active.source))) 512)
            (gte (scope-source-count scope.act) 64)
            =(0 (met 3 label.act))
            (gth (met 3 label.act) 240)
            (gth (met 3 locator.act) 2.048)
            (gth (met 3 content.act) 131.072)
            !(context-scope-exists scope.act)
            ?&  ?=(?(%note %file) kind.act)
                =(0 (met 3 content.act))
            ==
            ?&  =(%web kind.act)
                =(0 (met 3 locator.act))
            ==
        ==
      [~ state]
    =/  source=context-source
      %*  .  *context-source
        id               id.act
        scope            scope.act
        kind             kind.act
        label            label.act
        locator          locator.act
        status           %pending
        active           %.y
        egress           ~
        policy-revision  1
        created-at       now.bol
        updated-at       now.bol
      ==
    =.  contexts.state  (~(put by contexts.state) id.act source)
    =.  context-count.state  +(context-count.state)
    =?  recent-clay.state  =(%clay kind.act)
      %+  scag  8
      ^-  (list @t)
      :-  locator.act
      (skip recent-clay.state |=(l=@t =(l locator.act)))
    ?:  =(%web kind.act)  [~ state]
    ?.  =(%clay kind.act)
      (accept-context source content.act %full locator.act ~ %owner-text)
    =/  foreign  (foreign-clay-locator kind.act locator.act)
    ?~  foreign
      =/  loaded=(each acquired-context tang)
        (mule |.((read-clay-context locator.act)))
      ?:  ?=(%| -.loaded)
        =.  contexts.state  (~(put by contexts.state) id.act source(status %failed, error 'clay-unavailable'))
        (fail-action %blocked %clay-unavailable)
      =/  parsed  (need (parse-clay-locator locator.act))
      =.  context-revs.state
        (~(put by context-revs.state) id.act (clay-desk-rev dek.parsed))
      (accept-context source content.p.loaded coverage.p.loaded locator.act origin-revision.p.loaded %clay-text)
    ?.  ?&  ?=(^ rest.u.foreign)
            (~(has in clay-text-marks) (rear rest.u.foreign))
        ==
      =.  contexts.state  (~(put by contexts.state) id.act source(status %failed, error 'remote-file-required'))
      (fail-action %blocked %remote-file-required)
    =.  outstanding-keens.state
      %+  ~(put by outstanding-keens.state)  id.act
      [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
    :_  state
    :~  :*  %pass
            [%shared-fetch id.act (scot %ud generation.source) ~]
            %agent
            [who.u.foreign %seer]
            %watch
            [%shared-context %file dek.u.foreign rest.u.foreign]
        ==
        :*  %pass
            [%shared-timeout id.act (scot %ud generation.source) ~]
            %arvo
            %b
            %wait
            (add now.bol ~m2)
        ==
    ==
      %set-context-egress
    =/  found  (~(get by contexts.state) id.act)
    ?~  found  [~ state]
    =/  source  u.found
    ?:  =(providers.act egress.source)  [~ state]
    =.  source
      source(egress providers.act, policy-revision +(policy-revision.source), updated-at now.bol)
    [~ state(contexts (~(put by contexts.state) id.act source))]
      %rename-context-source
    =/  found  (~(get by contexts.state) id.act)
    ?~  found  [~ state]
    ?.  ?&(=(our.bol src.bol) (lte (met 3 label.act) 240) !=('' label.act))
      [~ state]
    =/  source  u.found(label label.act, updated-at now.bol)
    [~ state(contexts (~(put by contexts.state) id.act source))]
      %archive-orphan-contexts
    =/  rows  ~(tap by contexts.state)
    |-
    ?~  rows  [~ state]
    =/  [id=@tas source=context-source]  i.rows
    ?:  ?|(!active.source (context-scope-exists scope.source))
      $(rows t.rows)
    =.  contexts.state
      (~(put by contexts.state) id source(active %.n, generation +(generation.source), updated-at now.bol))
    $(rows t.rows)
      %remove-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    =.  active.source  %.n
    =.  generation.source  +(generation.source)
    =.  outstanding-keens.state  (~(del by outstanding-keens.state) id.act)
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    [~ state]
      %finish-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&(active.source =(%working status.source) =(attempt.act attempt.source))
      (fail-action %blocked %attempt-fenced)
    ?.  ?&  !=(0 (met 3 content.act))
            (lte (met 3 content.act) 131.072)
            (lte (met 3 label.act) 240)
        ==
      =.  contexts.state
        (~(put by contexts.state) id.act source(status %failed, error 'source-too-large', updated-at now.bol))
      (fail-action %blocked %source-too-large)
    =.  label.source
      ?:(=(0 (met 3 label.act)) label.source label.act)
    (accept-context source content.act %full final-locator.act ~ %web-text)
      %fail-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&(active.source =(%working status.source) =(attempt.act attempt.source))
      (fail-action %blocked %attempt-fenced)
    =.  status.source  %failed
    =.  error.source  (scot %tas error.act)
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    (fail-action %blocked error.act)
      %refresh-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            !=(%pending status.source)
            !=(%working status.source)
        ==
      [~ state]
    =.  generation.source  +(generation.source)
    ?.  =(%clay kind.source)
      ?:  =(%web kind.source)
        [~ state(contexts (~(put by contexts.state) id.act source(status %pending, error '', updated-at now.bol)))]
      =/  body  (context-body source evidence.state)
      ?~  body  [~ state]
      (accept-context source u.body %full locator.source ~ %owner-text)
    =/  foreign
      (foreign-clay-locator kind.source locator.source)
    ?^  foreign
      =.  status.source  %pending
      =.  error.source  ''
      =.  updated-at.source  now.bol
      =.  contexts.state
        (~(put by contexts.state) id.act source)
      =.  outstanding-keens.state
        %+  ~(put by outstanding-keens.state)  id.act
        [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
      :_  state
      :~  :*  %pass
              [%shared-fetch id.act (scot %ud generation.source) ~]
              %agent
              [who.u.foreign %seer]
              %watch
              [%shared-context %file dek.u.foreign rest.u.foreign]
          ==
          :*  %pass
              [%shared-timeout id.act (scot %ud generation.source) ~]
              %arvo
              %b
              %wait
              (add now.bol ~m2)
          ==
      ==
    =/  parsed  (parse-clay-locator locator.source)
    ?~  parsed  [~ state]
    =/  loaded=(each acquired-context tang)
      (mule |.((read-clay-context locator.source)))
    ?:  ?=(%| -.loaded)  [~ state]
    =.  context-revs.state
      (~(put by context-revs.state) id.act (clay-desk-rev dek.u.parsed))
    (accept-context source content.p.loaded coverage.p.loaded locator.source origin-revision.p.loaded %clay-text)
      %retry-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%failed status.source)
        ==
      [~ state]
    ?.  ?|  =(%web kind.source)
            ?=(^ (foreign-clay-locator kind.source locator.source))
        ==
      [~ state]
    =.  generation.source  +(generation.source)
    =.  status.source  %pending
    =.  error.source  ''
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    =/  foreign
      (foreign-clay-locator kind.source locator.source)
    ?~  foreign  [~ state]
    =.  outstanding-keens.state
      %+  ~(put by outstanding-keens.state)  id.act
      [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
    :_  state
    :~  :*  %pass
            [%shared-fetch id.act (scot %ud generation.source) ~]
            %agent
            [who.u.foreign %seer]
            %watch
            [%shared-context %file dek.u.foreign rest.u.foreign]
        ==
        :*  %pass
            [%shared-timeout id.act (scot %ud generation.source) ~]
            %arvo
            %b
            %wait
            (add now.bol ~m2)
        ==
    ==
      %fetch-remote-manifest
    ?.  =(our.bol src.bol)  [~ state]
    (fetch-remote-manifest who.act)
      %share-clay-context
    ?.  =(our.bol src.bol)  [~ state]
    ?.  ?=([@ @ @ *] pax.act)  [~ state]
    =/  dek=@tas  `@tas`i.pax.act
    =/  rest=path  t.pax.act
    =/  file-mark=@ta  (rear rest)
    ?.  (~(has in clay-text-marks) file-mark)  [~ state]
    =/  loc=tape
      %-  zing
      :-  "/{(trip (scot %p our.bol))}/{(trip dek)}"
      (turn rest |=(k=@ta "/{(trip k)}"))
    =/  loaded=(each acquired-context tang)
      (mule |.((read-clay-context (crip loc))))
    ?:  ?=(%| -.loaded)  [~ state]
    ?.  =(%full coverage.p.loaded)  [~ state]
    =/  content=@t  content.p.loaded
    ?:  ?|  =(0 (met 3 content))
            (gth (met 3 content) 131.072)
        ==
      [~ state]
    =/  old  (~(get by shared-context.state) pax.act)
    =/  file-rev=@ud  ?~(old 1 +(rev.u.old))
    =/  label=@t  (crip loc)
    =.  shared-context.state
      %+  ~(put by shared-context.state)  pax.act
      [file-rev label file-mark (met 3 content)]
    =/  manifest-rev=@ud  +(shared-manifest-rev.state)
    =.  shared-manifest-rev.state  manifest-rev
    [~ state]
      %unshare-clay-context
    ?.  =(our.bol src.bol)  [~ state]
    =/  old  (~(get by shared-context.state) pax.act)
    ?~  old  [~ state]
    =.  shared-context.state
      (~(del by shared-context.state) pax.act)
    =/  manifest-rev=@ud  +(shared-manifest-rev.state)
    =.  shared-manifest-rev.state  manifest-rev
    [~ state]
      %ask-card
    ?:  ?|  =(0 (met 3 prompt.act))
            (~(has by questions.state) id.act)
            ?&  =(%edit mode.act)
                !=(our.bol owner.act)
            ==
        ==
      [~ state]
    =/  question=card-question
      %*  .  *card-question
        id          id.act
        owner       owner.act
        stack       stak.act
        card        item.act
        mode        mode.act
        prompt      prompt.act
        profile     profile.act
        created-at  now.bol
        updated-at  now.bol
      ==
    (prepare-question question selections.act max-bytes.act excerpt-bytes.act 1)
      %replace-assistant-models
    ?:  (gth (lent (scag 129 profiles.act)) 128)
      (fail-action %budget-exhausted %model-limit)
    ::  Only the named provider's profiles are replaced; the other
    ::  provider's catalog keeps its own observation.
    =/  kept=(map @tas assistant-model)
      %-  malt
      %+  skip  ~(tap by models.state)
      |=([id=@tas profile=assistant-model] =(provider.act provider.profile))
    =/  rows  profiles.act
    =/  catalog=(map @tas assistant-model)  kept
    |-
    ?~  rows
      =.  catalog-revision.operating.state  +(catalog-revision.operating.state)
      [~ state(models catalog)]
    =/  profile  i.rows
    ?.  ?&  !=(0 id.profile)
            (bounded-text:ev id.profile 128)
            =(provider.act provider.profile)
            !=('' selector.profile)
            (bounded-text:ev selector.profile 512)
            !=('' model.profile)
            (bounded-text:ev model.profile 512)
            !=('' label.profile)
            (bounded-text:ev label.profile 240)
            (bounded-text:ev description.profile 2.048)
            !(~(has by catalog) id.profile)
        ==
      (fail-action %invalid %invalid-model-catalog)
    =.  catalog  (~(put by catalog) id.profile profile(origin origin.act, registered-at now.bol))
    $(rows t.rows)
      %answer-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&  =(%working status.question)
            =(%ask mode.question)
            =(attempt.act attempt.question)
        ==
      (fail-action %blocked %attempt-fenced)
    ?.  (lte (met 3 response.act) 65.536)
      (block-question question %output-budget-exhausted)
    =/  error  (question-result-error question citations.act)
    ?^  error  (block-question question u.error)
    =/  retained
      (record-explanation:memory our.bol now.bol (need (question-packet question)) response.act citations.act %explanation learning.state evidence.state contexts.state)
    ?^  error.retained  (block-question question u.error.retained)
    =.  learning.state  store.retained
    =.  citations.question  citations.act
    =.  status.question  %answered
    =.  response.question  response.act
    =.  updated-at.question  now.bol
    =.  questions.state
      (~(put by questions.state) id.act question)
    =.  state  (record-usage [%question our.bol %root id.act] usage.act)
    [~ state]
      %apply-card-edit
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&  =(%working status.question)
            =(%edit mode.question)
            =(attempt.act attempt.question)
            =(our.bol owner.question)
        ==
      (fail-action %blocked %attempt-fenced)
    ?.  ?&  !=(0 (met 3 title.act))
            !=(0 (met 3 front.act))
            !=(0 (met 3 back.act))
            !=(0 (met 3 response.act))
        ==
      (block-question question %invalid-provider-output)
    ?.  ?&  (lte (met 3 title.act) 512)
            (lte (met 3 front.act) 32.768)
            (lte (met 3 back.act) 32.768)
            (lte (met 3 response.act) 32.768)
        ==
      (block-question question %output-budget-exhausted)
    =/  error  (question-result-error question citations.act)
    ?^  error  (block-question question u.error)
    =.  citations.question  citations.act
    =/  retained
      (record-explanation:memory our.bol now.bol (need (question-packet question)) response.act citations.act %correction learning.state evidence.state contexts.state)
    ?^  error.retained  (block-question question u.error.retained)
    =.  learning.state  store.retained
    =/  edit-act=action
      :*  %edit-item
          our.bol
          stack.question
          card.question
          title.act
          [read=*rule:clay write=*rule:clay]
          front.act
          back.act
      ==
    =^  edit-cards  state  (poke-seer-action edit-act)
    =.  status.question        %answered
    =.  response.question      response.act
    =.  result-title.question  title.act
    =.  result-front.question  front.act
    =.  result-back.question   back.act
    =.  updated-at.question    now.bol
    =.  questions.state
      (~(put by questions.state) id.act question)
    =.  state  (record-usage [%question our.bol %root id.act] usage.act)
    [edit-cards state]
      %fail-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&(=(%working status.question) =(attempt.act attempt.question))
      (fail-action %blocked %attempt-fenced)
    =.  status.question  %failed
    =.  response.question  (scot %tas response.act)
    =.  updated-at.question  now.bol
    =.  questions.state
      (~(put by questions.state) id.act question)
    (fail-action %blocked response.act)
      %retry-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  =(%failed status.question)  [~ state]
    =/  packet  (question-packet question)
    ?~  packet  (block-question question %packet-unavailable)
    =/  old  (~(get by jobs.operating.state) [%question our.bol %root id.act])
    =/  next-attempt  ?~(old 1 +(attempt.u.old))
    %:  prepare-question
      question
      selections.request.u.packet
      max-bytes.request.u.packet
      excerpt-bytes.request.u.packet
      next-attempt
    ==
      %delete-card-question
    =.  questions.state  (~(del by questions.state) id.act)
    [~ state]
      %request-change
    ?:  (~(has by changes.state) id.act)  (fail-action %conflict %change-id-in-use)
    ?.  ?&(!=('' prompt.act) (bounded-text:ev prompt.act 131.072))
      (fail-action %invalid %invalid-change-prompt)
    =/  profile  (~(get by models.state) id.profile.act)
    ?~  profile  (fail-action %blocked %model-unavailable)
    ?.  =(u.profile(origin '', registered-at 0) profile.act(origin '', registered-at 0))
      (fail-action %conflict %model-changed)
    =/  request=change-request
      %*  .  *change-request
        id          id.act
        target      target.act
        prompt      prompt.act
        profile     u.profile
        created-at  now.bol
        updated-at  now.bol
        status      ?:(start.act %pending %draft)
      ==
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %start-change
    =/  request  (~(get by changes.state) id.act)
    ?~  request  (fail-action %blocked %change-not-found)
    ?.  =(%draft status.u.request)  (fail-action %blocked %change-not-draft)
    [~ state(changes (~(put by changes.state) id.act u.request(status %pending, updated-at now.bol)))]
      %propose-change
    ?:  (~(has by changes.state) id.act)  (fail-action %conflict %change-id-in-use)
    ?.  ?&  !=('' prompt.act)
            (bounded-text:ev prompt.act 131.072)
            !=('' summary.act)
            (bounded-text:ev summary.act 32.768)
        ==
      (fail-action %invalid %invalid-change-summary)
    =/  preview
      (validate-plan:effects our.bol now.bol stacks.state versions.operating.state operations.act preconditions.act)
    ?.  =(%ok status.preview)  (fail-action status.preview reason.preview)
    =/  request=change-request
      %*  .  *change-request
        id             id.act
        target         %library
        prompt         prompt.act
        summary        summary.act
        operations     operations.act
        preconditions  preconditions.act
        plan           `digest.preview
        created-at     now.bol
        updated-at     now.bol
        status         %ready
      ==
    [~ state(changes (~(put by changes.state) id.act request))]
      %finish-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&(=(%working status.request) =(attempt.act attempt.request))
      (fail-action %blocked %attempt-fenced)
    ?.  ?&  !=('' summary.act)
            (bounded-text:ev summary.act 32.768)
            (bounded-text:ev artifact.act 65.536)
        ==
      (fail-action %invalid %invalid-change-output)
    ?~  packet.request  (fail-action %blocked %packet-unavailable)
    =/  packet  (~(get by packets.evidence.state) u.packet.request)
    ?~  packet  (fail-action %blocked %packet-unavailable)
    =/  error  (validate-citations:ev u.packet citations.act evidence.state)
    ?^  error  (fail-action %blocked u.error)
    =/  observed=(unit (list entity-precondition))
      ?:  =(%desk target.request)  `~
      (observed-plan-fences operations.act scope-preconditions.request)
    ?~  observed  (fail-action %conflict %unobserved-plan-target)
    ?:  ?&(=(%desk target.request) ?|(?=(^ operations.act) =('' artifact.act)))
      (fail-action %invalid %desk-brief-required)
    =/  preview=(unit plan-preview)
      ?:  =(%desk target.request)  ~
      `(validate-plan:effects our.bol now.bol stacks.state versions.operating.state operations.act u.observed)
    ?:  ?&(?=(^ preview) !=(%ok status.u.preview))
      (fail-action status.u.preview reason.u.preview)
    =.  preconditions.request  u.observed
    =.  plan.request  ?~(preview ~ `digest.u.preview)
    =.  citations.request   citations.act
    =.  status.request      %ready
    =.  summary.request     summary.act
    =.  operations.request  operations.act
    =.  artifact.request    artifact.act
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    =.  state  (record-usage [%change our.bol %root id.act] usage.act)
    [~ state]
      %fail-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&(=(%working status.request) =(attempt.act attempt.request))
      (fail-action %blocked %attempt-fenced)
    =.  status.request      %failed
    =.  response.request    (scot %tas response.act)
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    (fail-action %blocked response.act)
      %apply-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&  =(%ready status.request)
            =(%library target.request)
        ==
      [~ state]
    =/  preview  (change-preview id.act)
    ?.  ?&(=(plan.request `digest.act) =(digest.act digest.preview))
      (fail-action %conflict %plan-digest-mismatch)
    ?.  =(%ok status.preview)  (fail-action status.preview reason.preview)
    =/  evidence-error=(unit @tas)
      ?~  packet.request  ~
      =/  packet  (~(get by packets.evidence.state) u.packet.request)
      ?~  packet  `%packet-unavailable
      (packet-egress-error:ev u.packet contexts.state evidence.state)
    ?^  evidence-error  (fail-action %blocked u.evidence-error)
    =^  operation-cards  state  (commit-preview preview)
    ::  Cards created by an approved plan carry the plan as their
    ::  provenance, exactly as capture-approved cards carry the capture.
    =/  created  operations.request
    |-
    ?^  created
      =/  op  i.created
      ?.  =(%create-card kind.op)  $(created t.created)
      =/  parent  (~(get by stacks.state) stack.op)
      ?:  ?|(?=(~ parent) !(~(has by items.u.parent) card.op))  $(created t.created)
      =/  origin=provenance:seer-types
        :*  %plan
            id.act
            'change-plan'
            summary.request
            (rap 3 (scot %tas provider.profile.request) '/' model.profile.request ~)
            created-at.request
            now.bol
            packet.request
            citations.request
            ~
            (~(get by versions.operating.state) [%card our.bol stack.op card.op])
        ==
      =.  provenance.state  (~(put by provenance.state) [stack.op card.op] origin)
      $(created t.created)
    =.  status.request      %applied
    =.  response.request    'Plan applied after approval.'
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [operation-cards state]
      %reject-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?|  =(%ready status.request)
            =(%draft status.request)
            =(%failed status.request)
        ==
      [~ state]
    =.  status.request      %rejected
    =.  response.request    'Request rejected.'
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %retry-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  =(%failed status.request)  [~ state]
    =.  status.request      %pending
    =.  updated-at.request  now.bol
    =.  summary.request     ''
    =.  operations.request  ~
    =.  artifact.request    ''
    =.  response.request    ''
    =.  packet.request  ~
    =.  plan.request  ~
    =.  preconditions.request  ~
    =.  scope-preconditions.request  ~
    =.  citations.request  ~
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %delete-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    ?.  ?|  =(%applied status.u.maybe-request)
            =(%rejected status.u.maybe-request)
            =(%failed status.u.maybe-request)
        ==
      [~ state]
    =.  changes.state  (~(del by changes.state) id.act)
    =.  state  (archive-context-scope [%change id.act])
    [~ state]
      %request-login
    ::  one live request per provider; the ship runs the flow itself once
    ::  the dispatcher picks the request up.
    =/  active=?
      %+  lien  ~(tap by logins.state)
      |=  [id=@tas req=login-request]
      ?&(=(provider.act provider.req) ?=(?(%pending %working %challenge) status.req))
    ?:  active  [~ state]
    =.  logins.state
      %-  malt
      %+  skip  ~(tap by logins.state)
      |=  [id=@tas req=login-request]
      =(provider.act provider.req)
    =/  req=login-request
      %*  .  *login-request
        id          id.act
        provider    provider.act
        status      %pending
        created-at  now.bol
        updated-at  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act req)
    [~ state]
      %post-login-challenge
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  ?&(=(%working status.req) =(attempt.act attempt.req))
      (fail-action %blocked %attempt-fenced)
    ?.  ?&  !=('' auth-url.act)
            (valid-auth-url provider.req auth-url.act)
            (bounded-text:ev auth-url.act 2.048)
            (bounded-text:ev user-code.act 1.024)
            (bounded-text:ev device-id.act 1.024)
        ==
      (fail-action %invalid %invalid-login-challenge)
    =/  next=login-request
      %=  req
        status      %challenge
        auth-url    auth-url.act
        user-code   user-code.act
        device-id   device-id.act
        interval    interval.act
        updated-at  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    :_  state
    ~[(wait-card:net /seer-poll/[id.act]/(scot %ud attempt.req) (add now.bol (mul interval.act ~s1)))]
      %submit-login-code
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  =(%challenge status.req)  [~ state]
    ?.  ?&  !=('' code.act)
            (bounded-text:ev code.act 8.192)
            !(lien (trip code.act) |=(ch=@ ?|(=(0 ch) =(10 ch) =(13 ch))))
        ==
      (fail-action %invalid %invalid-login-code)
    ?.  =(%claude provider.req)  (fail-action %blocked %action-not-applicable)
    =/  parts  (split-pasted-code:oa (crip (trim-tape:oa (trip code.act))))
    ?.  ?|(=('' state.parts) =(nonce.req state.parts))
      (fail-action %invalid %invalid-login-state)
    =/  next=login-request
      %=  req
        status       %working
        pasted-code  ''
        inflight     `%exchange
        updated-at   now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    :_  state
    :~  %+  iris-card:net  (login-wire id.act %exchange attempt.req)
        (claude-exchange-request:oa code.parts nonce.req verifier.req)
    ==
      %finish-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?:  =(%done status.req)  [~ state]
    ?.  ?&(?=(?(%working %challenge) status.req) =(attempt.act attempt.req))
      (fail-action %blocked %attempt-fenced)
    =/  next=login-request
      %=  req
        status       %done
        auth-url     ''
        user-code    ''
        pasted-code  ''
        message      ''
        device-id    ''
        verifier     ''
        nonce        ''
        deadline     ~
        updated-at   now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %fail-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?:  ?|(=(%done status.req) =(%failed status.req))  [~ state]
    ?.  =(attempt.act attempt.req)  (fail-action %blocked %attempt-fenced)
    =/  next=login-request
      %=  req
        status       %failed
        auth-url     ''
        user-code    ''
        pasted-code  ''
        message      (scot %tas message.act)
        device-id    ''
        verifier     ''
        nonce        ''
        deadline     ~
        inflight     ~
        updated-at   now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    :_  state(operating operating.state(failure `[%blocked message.act]))
    (login-cancel-cards req)
      %retry-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  =(%failed status.req)  [~ state]
    =/  next=login-request
      %=  req
        status       %pending
        auth-url     ''
        user-code    ''
        pasted-code  ''
        message      ''
        device-id    ''
        verifier     ''
        nonce        ''
        deadline     ~
        updated-at   now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %cancel-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?:  ?|(=(%done status.req) =(%failed status.req))
      =.  logins.state  (~(del by logins.state) id.act)
      [~ state]
    =/  next=login-request
      %=  req
        status       %failed
        auth-url     ''
        user-code    ''
        pasted-code  ''
        message      'cancelled'
        device-id    ''
        verifier     ''
        nonce        ''
        deadline     ~
        inflight     ~
        updated-at   now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [(login-cancel-cards req) state]
  ==
::
++  packet-depends
  |=  [ref=(unit @ux) citations=(list evidence-citation) ids=(set @ux)]
  ^-  ?
  ?:  (lien citations |=(cite=evidence-citation (~(has in ids) snapshot.cite)))  %.y
  ?~  ref  %.n
  =/  packet  (~(get by packets.evidence.state) u.ref)
  ?~  packet  %.n
  !=(~ (~(int in (packet-snapshots:memory u.packet)) ids))
::
++  purge-retained
  |=  ids=(set @ux)
  ^-  (quip card _state)
  ?:  (gth (lent ~(tap in ids)) 128)  (fail-action %budget-exhausted %purge-limit)
  =/  protected
    %+  lien  ~(tap by provenance.state)
    |=  [key=[stack=@tas card=@tas] origin=provenance:seer-types]
    =/  parent  (~(get by stacks.state) stack.key)
    ?~  parent  %.n
    ?&  (~(has by items.u.parent) card.key)
        (packet-depends packet.origin citations.origin ids)
    ==
  ?:  protected  (fail-action %blocked %approved-card-dependency)
  =/  purged  (purge-snapshots:memory ids evidence.state learning.state)
  =.  evidence.state  evidence.purged
  =.  learning.state  store.purged
  =.  questions.state
    %-  ~(run by questions.state)
    |=  question=card-question
    ?.  (packet-depends packet.question citations.question ids)  question
    %=  question
      title         ''
      front         ''
      back          ''
      prompt        ''
      response      'evidence-purged'
      result-title  ''
      result-front  ''
      result-back   ''
      citations     (turn citations.question |=(cite=evidence-citation cite(quote '')))
      status        %failed
      updated-at    now.bol
    ==
  =.  changes.state
    %-  ~(run by changes.state)
    |=  request=change-request
    ?.  (packet-depends packet.request citations.request ids)  request
    %=  request
      prompt      ''
      summary     ''
      operations  ~
      artifact    ''
      response    'evidence-purged'
      citations   (turn citations.request |=(cite=evidence-citation cite(quote '')))
      status      %failed
      updated-at  now.bol
    ==
  =.  captures.state
    %-  ~(run by captures.state)
    |=  session=capture
    =/  dependent  (packet-depends packet.session ~ ids)
    =/  proposals
      %-  ~(run by proposals.session)
      |=  draft=proposal
      ?.  (packet-depends packet.draft citations.draft ids)  draft
      %=  draft
        title      ''
        front      ''
        back       ''
        rationale  ''
        source     ''
        objective  ''
        claim      ''
        why-new    ''
        caveat     ''
        citations  (turn citations.draft |=(cite=evidence-citation cite(quote '')))
      ==
    session(proposals proposals, title ?:(dependent '' title.session), goal ?:(dependent '' goal.session), source ?:(dependent '' source.session))
  =.  contexts.state
    %-  ~(run by contexts.state)
    |=  source=context-source
    ?~  snapshot.source  source
    ?.  (~(has in ids) u.snapshot.source)  source
    source(status %failed, error 'evidence-purged', generation +(generation.source), updated-at now.bol)
  [~ state]
::
++  collect-retained
  ^-  (quip card _state)
  =/  keep-packets=(set @ux)  ~
  =/  keep-snapshots=(set @ux)
    =/  rows  contexts.state
    =/  kept=(set @ux)  ~
    |-  ^-  (set @ux)
    ?~  rows  kept
    =?  kept  ?&(active.q.n.rows ?=(^ snapshot.q.n.rows))
      (~(put in kept) u.snapshot.q.n.rows)
    =.  kept  $(rows l.rows)
    $(rows r.rows)
  ::  Existing live records are explicit dependencies, including answered
  ::  explanations. Deleting a record releases it; unlink does not purge it.
  =.  keep-packets
    =/  rows  questions.state
    |-  ^-  (set @ux)
    ?~  rows  keep-packets
    =.  keep-packets
      ?~  packet.q.n.rows  keep-packets
      (~(put in keep-packets) u.packet.q.n.rows)
    =.  keep-packets  $(rows l.rows)
    $(rows r.rows)
  =.  keep-packets
    =/  rows  changes.state
    |-  ^-  (set @ux)
    ?~  rows  keep-packets
    =.  keep-packets
      ?~  packet.q.n.rows  keep-packets
      (~(put in keep-packets) u.packet.q.n.rows)
    =.  keep-packets  $(rows l.rows)
    $(rows r.rows)
  =.  keep-packets
    =/  rows  provenance.state
    |-  ^-  (set @ux)
    ?~  rows  keep-packets
    =.  keep-packets
      ?~  packet.q.n.rows  keep-packets
      (~(put in keep-packets) u.packet.q.n.rows)
    =.  keep-packets  $(rows l.rows)
    $(rows r.rows)
  =.  keep-packets
    =/  rows  captures.state
    |-  ^-  (set @ux)
    ?~  rows  keep-packets
    =.  keep-packets
      ?~  packet.q.n.rows  keep-packets
      (~(put in keep-packets) u.packet.q.n.rows)
    =.  keep-packets
      =/  drafts  proposals.q.n.rows
      |-  ^-  (set @ux)
      ?~  drafts  keep-packets
      =.  keep-packets
        ?~  packet.q.n.drafts  keep-packets
        (~(put in keep-packets) u.packet.q.n.drafts)
      =.  keep-packets  $(drafts l.drafts)
      $(drafts r.drafts)
    =.  keep-packets  $(rows l.rows)
    $(rows r.rows)
  =/  kept
    (collect-unused:memory now.bol (sub now.bol ~d30) keep-packets keep-snapshots evidence.state learning.state)
  [~ state(evidence evidence.kept, learning store.kept)]
::
++  operation-result
  |=  raw=@t
  ^-  json
  ?:  (gth (met 3 raw) 4.096)  (error-json 'invalid-query' 'operation receipt')
  =/  query
    %-  mole
    |.  (need ((soft ,[epoch=@da operation=@t expected=(unit @ux)]) (cue (slav %uv raw))))
  ?~  query  (error-json 'invalid-query' 'operation receipt')
  (receipt-json:effects (operation-receipt-at:effects operating.state epoch.u.query operation.u.query expected.u.query) 32.768)
::
::  ship-native execution. every outbound request is a card whose wire
::  names the work and its attempt; only a response for the current
::  attempt of a running record has any effect.
::
++  record-usage
  |=  [key=entity-key usage=(unit @ud)]
  ^-  _state
  =/  job  (~(get by jobs.operating.state) key)
  ?~  job  state
  (put-work key u.job(usage usage, checkpoint %output-received))
::
++  work-window
  |=  kind=entity-kind
  ^-  @dr
  ?:  =(%login kind)  login-window:oa
  ?:  =(%context kind)  ~s20
  ~m3
::
++  response-cap
  |=  kind=entity-kind
  ^-  @ud
  ?:  =(%context kind)  131.072
  ?:  =(%login kind)  65.536
  262.144
::
++  request-wire
  |=  [key=entity-key attempt=@ud]
  ^-  wire
  /seer-request/(scot %tas kind.key)/[id.key]/(scot %ud attempt)
::
++  deadline-wire
  |=  [key=entity-key attempt=@ud]
  ^-  wire
  /seer-deadline/(scot %tas kind.key)/[id.key]/(scot %ud attempt)
::
++  login-wire
  |=  [id=@tas step=@tas attempt=@ud]
  ^-  wire
  /seer-login/[id]/[step]/(scot %ud attempt)
::
++  cancel-cards
  |=  [key=entity-key attempt=@ud]
  ^-  (list card)
  ?.  =(%login kind.key)  ~[(cancel-card:net (request-wire key attempt))]
  =/  req  (~(get by logins.state) id.key)
  ?~  req  ~
  ?.  =(attempt attempt.u.req)  ~
  (login-cancel-cards u.req)
::
::  +login-cancel-cards: only the request this sign-in has in flight;
::  iris rejects a cancel for a wire with nothing outstanding.
::
++  login-cancel-cards
  |=  req=login-request
  ^-  (list card)
  ?~  inflight.req  ~
  ~[(cancel-card:net (login-wire id.req u.inflight.req attempt.req))]
::
++  http-failure
  |=  [status=@ud body=@t]
  ^-  @tas
  ?:  ?|(=(401 status) =(403 status))  %provider-unauthorized
  ?:  =(429 status)  %provider-rate-limited
  ?:  (gte status 500)  %provider-unavailable
  %provider-error
::
++  fence-running
  |=  reason=@tas
  ^-  (quip card _state)
  =/  rows  ~(tap by jobs.operating.state)
  =|  moves=(list card)
  |-
  ?~  rows  [moves state]
  =/  [key=entity-key job=work-record]  i.rows
  ?.  ?=(?(%running %queued) execution.job)  $(rows t.rows)
  =/  stop  ?:(?=(?(%provider-started %output-received) checkpoint.job) %outcome-unknown reason)
  =/  cancels  ?:(=(%running execution.job) (cancel-cards key attempt.job) ~)
  =^  ignored  state  (stop-work key stop %.n)
  =.  failure.operating.state  ~
  $(rows t.rows, moves (weld moves cancels))
::
++  put-work
  |=  [key=entity-key job=work-record]
  ^-  _state
  =.  operating.state  operating.state(jobs (~(put by jobs.operating.state) key job(updated-at now.bol)))
  =/  tracker  (agent-tracker our.bol now.bol observation-view observation-view operating.state)
  =/  version  (~(get by versions.operating.state) key)
  =.  operating.state  (stamp:tracker key %.y %.n ?~(version %.n present.u.version))
  state
::
++  work-input-error
  |=  [key=entity-key job=work-record]
  ^-  (unit @tas)
  ?.  ?=(?(%question %change) kind.key)  ~
  ?~  packet.job  `%packet-unavailable
  =/  packet  (~(get by packets.evidence.state) u.packet.job)
  ?~  packet  `%packet-unavailable
  ?.  ?&  =(packet-digest.job `prompt-digest.u.packet)
          =(schema-version.u.packet seer-schema-version)
          =(schema-version.job seer-schema-version)
          =(prompt-version.job prompt-version.u.packet)
          =(policy-version.job 1)
          =(provider.job `provider.profile.request.u.packet)
          =(model-id.job id.profile.request.u.packet)
          =(input-bytes.job prompt-bytes.u.packet)
          (lte prompt-bytes.u.packet max-input-bytes.job)
      ==
    `%packet-mismatch
  =/  profile  (~(get by models.state) model-id.job)
  =/  version  (~(get by versions.operating.state) [%model our.bol %root model-id.job])
  ?~  profile  `%model-unavailable
  ?~  version  `%model-unavailable
  ?.  ?&  present.u.version
          =(model-revision.job content-revision.u.version)
          =(u.profile(origin '', description '', registered-at *@da) profile.request.u.packet)
      ==
    `%model-changed
  =/  error  (packet-egress-error:ev u.packet contexts.state evidence.state)
  ?^  error  error
  ?.  =(%question kind.key)  ~
  =/  question  (~(get by questions.state) id.key)
  ?~  question  `%subject-not-found
  (question-input-error u.question)
::
++  stop-work
  |=  [key=entity-key reason=@tas requeue=?]
  ^-  (quip card _state)
  =/  job  (~(get by jobs.operating.state) key)
  ?~  job  (fail-action %blocked %work-not-found)
  =/  before  observation-view
  =.  state
    ?+  kind.key  state
      %question
        =/  req  (~(get by questions.state) id.key)
        ?~  req  state
        state(questions (~(put by questions.state) id.key u.req(status ?:(requeue %pending %failed), response (scot %tas reason), updated-at now.bol)))
      %change
        =/  req  (~(get by changes.state) id.key)
        ?~  req  state
        =/  next  u.req(status ?:(requeue %pending %failed), response (scot %tas reason), updated-at now.bol)
        =?  next  requeue  next(packet ~, scope-preconditions ~, preconditions ~, plan ~)
        state(changes (~(put by changes.state) id.key next))
      %context
        =/  req  (~(get by contexts.state) id.key)
        ?~  req  state
        state(contexts (~(put by contexts.state) id.key u.req(status ?:(requeue %pending %failed), error (scot %tas reason), generation +(generation.u.req), updated-at now.bol)))
      %login
        =/  req  (~(get by logins.state) id.key)
        ?~  req  state
        state(logins (~(put by logins.state) id.key u.req(status ?:(requeue %pending %failed), auth-url '', user-code '', pasted-code '', device-id '', verifier '', nonce '', inflight ~, deadline ~, message (scot %tas reason), updated-at now.bol)))
    ==
  =/  tracker  (agent-tracker our.bol now.bol before observation-view operating.state)
  =.  operating.state  (one:tracker key)
  =/  next
    %=  u.job
      execution    ?:(requeue %queued ?:(=(%outcome-unknown reason) %blocked %cancelled))
      effect       ?:(=(%outcome-unknown reason) %unknown effect.u.job)
      stop-reason  `reason
      retryable    requeue
    ==
  =.  state  (put-work key next)
  ?:  =(%outcome-unknown reason)  (fail-action %outcome-unknown reason)
  [~ state]
::
::  +flush: the transport boundary. runs after every event: renew
::  expiring accounts that pending work needs, then start whatever the
::  concurrency bounds allow. each dispatch is its own recorded command.
::
++  flush
  ^-  (quip card _state)
  =^  renewals  state  start-renewals
  =^  logins  state  dispatch-logins
  =^  provider  state  dispatch-provider-work
  =^  fetches  state  dispatch-fetches
  =^  catalogs  state  dispatch-catalogs
  [:(weld renewals logins provider fetches catalogs) state]
::
++  provider-demand
  |=  provider=ai-provider
  ^-  ?
  ?|  (~(has in catalog-pending.state) provider)
      %+  lien  ~(tap by questions.state)
      |=([id=@tas q=card-question] ?&(=(%pending status.q) =(provider provider.profile.q)))
      %+  lien  ~(tap by changes.state)
      |=([id=@tas c=change-request] ?&(=(%pending status.c) =(provider provider.profile.c)))
  ==
::
++  account-usable
  |=  provider=ai-provider
  ^-  ?
  =/  slot  (~(get by accounts.state) provider)
  ?~  slot  %.n
  =(%usable (renewal-state:oa u.slot now.bol))
::
++  start-renewals
  ^-  (quip card _state)
  =/  providers=(list ai-provider)  ~[%codex %claude]
  =|  moves=(list card)
  |-
  ?~  providers  [moves state]
  =/  provider  i.providers
  =/  slot  (~(get by accounts.state) provider)
  ?~  slot  $(providers t.providers)
  ?.  ?&(=(%renew (renewal-state:oa u.slot now.bol)) (provider-demand provider))
    $(providers t.providers)
  =/  serial  +(serial.renewal.u.slot)
  =/  deadline  (add now.bol renewal-window:oa)
  =.  accounts.state
    %+  ~(put by accounts.state)  provider
    u.slot(renewal [`[serial deadline] serial retry-at.renewal.u.slot error.renewal.u.slot terminal.renewal.u.slot])
  =/  cards=(list card)
    :~  (iris-card:net /seer-renew/(scot %tas provider)/(scot %ud serial) (refresh-request:oa provider refresh.u.slot))
        (wait-card:net /seer-renew-deadline/(scot %tas provider)/(scot %ud serial) deadline)
    ==
  $(providers t.providers, moves (weld moves cards))
::
++  dispatch-logins
  ^-  (quip card _state)
  =/  rows  ~(tap by logins.state)
  =|  moves=(list card)
  |-
  ?~  rows  [moves state]
  =/  [id=@tas req=login-request]  i.rows
  ?.  =(%pending status.req)  $(rows t.rows)
  =^  cards  state  (system-command [%dispatch-work [%login our.bol %root id]])
  $(rows t.rows, moves (weld moves cards))
::
++  dispatch-provider-work
  ^-  (quip card _state)
  =/  providers=(list ai-provider)  ~[%codex %claude]
  =|  moves=(list card)
  |-
  ?~  providers  [moves state]
  =/  provider  i.providers
  ?.  (account-usable provider)  $(providers t.providers)
  =/  running=?
    ?|  %+  lien  ~(tap by questions.state)
        |=([id=@tas q=card-question] ?&(=(%working status.q) =(provider provider.profile.q)))
        %+  lien  ~(tap by changes.state)
        |=([id=@tas c=change-request] ?&(=(%working status.c) =(provider provider.profile.c)))
    ==
  ?:  running  $(providers t.providers)
  ::  oldest pending item for this provider, questions and changes alike
  =/  question-rows=(list [at=@da key=entity-key])
    %+  murn  ~(tap by questions.state)
    |=  [id=@tas q=card-question]
    ^-  (unit [at=@da key=entity-key])
    ?.  ?&(=(%pending status.q) =(provider provider.profile.q))  ~
    `[created-at.q [%question our.bol %root id]]
  =/  change-rows=(list [at=@da key=entity-key])
    %+  murn  ~(tap by changes.state)
    |=  [id=@tas c=change-request]
    ^-  (unit [at=@da key=entity-key])
    ?.  ?&(=(%pending status.c) =(provider provider.profile.c))  ~
    `[created-at.c [%change our.bol %root id]]
  =/  candidates=(list [at=@da key=entity-key])
    %+  sort  (weld question-rows change-rows)
    |=([a=[at=@da key=entity-key] b=[at=@da key=entity-key]] (lth at.a at.b))
  =/  cards=(list card)  ~
  =/  started=?  %.n
  |-
  ?:  ?|(started ?=(~ candidates))
    ^$(providers t.providers, moves (weld moves cards))
  =^  more  state  (system-command [%dispatch-work key.i.candidates])
  =/  now-running
    ?-  kind.key.i.candidates
      %question  =/(q (~(get by questions.state) id.key.i.candidates) ?~(q %.n =(%working status.u.q)))
      %change    =/(c (~(get by changes.state) id.key.i.candidates) ?~(c %.n =(%working status.u.c)))
      *          %.n
    ==
  $(candidates t.candidates, cards (weld cards more), started now-running)
::
++  dispatch-fetches
  ^-  (quip card _state)
  =/  running=@ud
    %-  lent
    %+  skim  ~(tap by contexts.state)
    |=([id=@tas s=context-source] ?&(active.s =(%working status.s) =(%web kind.s)))
  =/  pending=(list [at=@da id=@tas])
    %+  sort
      %+  murn  ~(tap by contexts.state)
      |=  [id=@tas s=context-source]
      ?.  ?&(active.s =(%pending status.s) =(%web kind.s))  ~
      `[updated-at.s id]
    |=([a=[at=@da *] b=[at=@da *]] (lth at.a at.b))
  =|  moves=(list card)
  |-
  ?:  ?|(?=(~ pending) (gte running 2))  [moves state]
  =^  cards  state  (system-command [%dispatch-work [%context our.bol %root id.i.pending]])
  =/  source  (~(get by contexts.state) id.i.pending)
  =/  started  ?~(source %.n =(%working status.u.source))
  $(pending t.pending, moves (weld moves cards), running ?:(started +(running) running))
::
++  dispatch-catalogs
  ^-  (quip card _state)
  =/  providers  ~(tap in catalog-pending.state)
  =|  moves=(list card)
  |-
  ?~  providers  [moves state]
  =/  provider  i.providers
  ?:  (~(has by catalog-active.state) provider)  $(providers t.providers)
  ?.  (account-usable provider)  $(providers t.providers)
  =/  slot  (~(got by accounts.state) provider)
  =/  serial  +(catalog-serial.state)
  =/  deadline  (add now.bol ~m1)
  =.  catalog-serial.state  serial
  =.  catalog-pending.state  (~(del in catalog-pending.state) provider)
  =.  catalog-active.state  (~(put by catalog-active.state) provider [serial deadline])
  =/  headers
    [['accept' 'application/json'] (auth-headers:oa provider slot)]
  =/  cards=(list card)
    :~  (iris-card:net /seer-catalog/(scot %tas provider)/(scot %ud serial) (request:net %'GET' (catalog-url:oa provider slot) headers ~))
        (wait-card:net /seer-catalog-deadline/(scot %tas provider)/(scot %ud serial) deadline)
    ==
  $(providers t.providers, moves (weld moves cards))
::
::  +dispatch-work: the recorded transition from queued to running. the
::  handler emits the request itself so the wire and the attempt agree.
::
++  dispatch-work
  |=  key=entity-key
  ^-  (quip card _state)
  ?+  kind.key  (fail-action %blocked %action-not-applicable)
    %question  (dispatch-question id.key)
    %change    (dispatch-change id.key)
    %context   (dispatch-fetch id.key)
    %login     (dispatch-login id.key)
  ==
::
++  dispatch-question
  |=  id=@tas
  ^-  (quip card _state)
  =/  found  (~(get by questions.state) id)
  ?~  found  (fail-action %blocked %work-not-found)
  =/  question  u.found
  ?.  =(%pending status.question)  (fail-action %blocked %work-not-queued)
  =/  error  (question-input-error question)
  ?^  error  (block-question question u.error)
  =/  provider  provider.profile.question
  =/  account  (~(get by accounts.state) provider)
  ?~  account  (block-question question %sign-in-required)
  =/  packet  (need (question-packet question))
  =/  attempt  +(attempt.question)
  =.  questions.state
    (~(put by questions.state) id question(status %working, attempt attempt, updated-at now.bol))
  (provider-request-cards [%question our.bol %root id] attempt provider u.account model.profile.question packet)
::
++  dispatch-change
  |=  id=@tas
  ^-  (quip card _state)
  =/  found  (~(get by changes.state) id)
  ?~  found  (fail-action %blocked %work-not-found)
  =/  request  u.found
  ?.  =(%pending status.request)  (fail-action %blocked %work-not-queued)
  =/  provider  provider.profile.request
  =/  account  (~(get by accounts.state) provider)
  =/  attempt  +(attempt.request)
  =.  changes.state
    (~(put by changes.state) id request(status %working, attempt attempt, packet ~, plan ~, updated-at now.bol))
  ?~  account
    =.  changes.state
      (~(put by changes.state) id request(status %failed, attempt attempt, response 'sign-in-required', updated-at now.bol))
    (fail-action %blocked %sign-in-required)
  =^  ignored  state  (freeze-change-packet id attempt)
  =/  failure  failure.operating.state
  ?^  failure
    =/  current  (~(got by changes.state) id)
    =.  changes.state
      (~(put by changes.state) id current(status %failed, response (scot %tas reason.u.failure), updated-at now.bol))
    [~ state]
  =/  current  (~(got by changes.state) id)
  =/  packet
    ?~  packet.current  ~
    (~(get by packets.evidence.state) u.packet.current)
  ?~  packet
    =.  changes.state
      (~(put by changes.state) id current(status %failed, response 'packet-unavailable', updated-at now.bol))
    (fail-action %blocked %packet-unavailable)
  (provider-request-cards [%change our.bol %root id] attempt provider u.account model.profile.request u.packet)
::
++  provider-request-cards
  |=  $:  key=entity-key
          attempt=@ud
          provider=ai-provider
          account=provider-account
          model=@t
          packet=context-packet
      ==
  ^-  (quip card _state)
  =/  prompt  (prompt:ev packet evidence.state)
  =/  instructions  'You are Seer, a learning assistant. Follow the contract in the user message exactly and return only the JSON object it describes.'
  =/  body
    ?-  provider
      %codex   (responses-body:net model instructions prompt)
      %claude  (messages-body:net model instructions prompt 8.192)
    ==
  =/  headers=header-list:http
    :*  ['content-type' 'application/json']
        ['accept' ?:(=(%codex provider) 'text/event-stream' 'application/json')]
        (auth-headers:oa provider account)
    ==
  =/  req  (request:net %'POST' (generation-url:oa provider account) headers `body)
  :_  state
  :~  (iris-card:net (request-wire key attempt) req)
      (wait-card:net (deadline-wire key attempt) (add now.bol (work-window kind.key)))
  ==
::
++  fetch-request
  |=  url=@t
  ^-  request:http
  %:  request:net  %'GET'  url
    :~  ['accept' 'text/html, text/plain;q=0.9, application/xhtml+xml;q=0.9, application/xml;q=0.8, */*;q=0.5']
        ['accept-language' 'en']
        ['user-agent' 'Mozilla/5.0 (compatible; Seer/0.3; +https://github.com/ryjm/srrs)']
    ==
    ~
  ==
::
++  dispatch-fetch
  |=  id=@tas
  ^-  (quip card _state)
  =/  found  (~(get by contexts.state) id)
  ?~  found  (fail-action %blocked %work-not-found)
  =/  source  u.found
  ?.  ?&(active.source =(%pending status.source) =(%web kind.source))
    (fail-action %blocked %work-not-queued)
  =/  rejected  (destination-error:net locator.source)
  ?^  rejected
    =.  contexts.state
      (~(put by contexts.state) id source(status %failed, error (scot %tas u.rejected), updated-at now.bol))
    (fail-action %blocked u.rejected)
  =/  attempt  +(attempt.source)
  =.  contexts.state
    (~(put by contexts.state) id source(status %working, attempt attempt, error '', updated-at now.bol))
  =/  key=entity-key  [%context our.bol %root id]
  :_  state
  :~  (iris-card:net (request-wire key attempt) (fetch-request locator.source))
      (wait-card:net (deadline-wire key attempt) (add now.bol (work-window %context)))
  ==
::
++  dispatch-login
  |=  id=@tas
  ^-  (quip card _state)
  =/  found  (~(get by logins.state) id)
  ?~  found  (fail-action %blocked %work-not-found)
  =/  req  u.found
  ?.  =(%pending status.req)  (fail-action %blocked %work-not-queued)
  =/  attempt  +(attempt.req)
  =/  deadline  (add now.bol login-window:oa)
  =/  key=entity-key  [%login our.bol %root id]
  ?-    provider.req
      %codex
    =.  logins.state
      (~(put by logins.state) id req(status %working, attempt attempt, inflight `%usercode, deadline `deadline, updated-at now.bol))
    :_  state
    :~  (iris-card:net (login-wire id %usercode attempt) usercode-request:oa)
        (wait-card:net (deadline-wire key attempt) deadline)
    ==
      %claude
    =/  keys  (pkce:oa eny.bol)
    =.  logins.state
      %+  ~(put by logins.state)  id
      %=  req
        status      %challenge
        attempt     attempt
        auth-url    (claude-authorize-link:oa challenge.keys state.keys)
        verifier    verifier.keys
        nonce       state.keys
        inflight    ~
        deadline    `deadline
        updated-at  now.bol
      ==
    :_  state
    ~[(wait-card:net (deadline-wire key attempt) deadline)]
  ==
::
::  responses for provider work and fetches
::
++  take-response
  |=  [kind=@tas id=@tas attempt=@ud res=client-response:iris]
  ^-  (quip card _state)
  ?+  kind  [~ state]
    %question  (take-question id attempt res)
    %change    (take-change id attempt res)
    %context   (take-fetch id attempt res)
  ==
::
++  provider-result
  |=  [provider=ai-provider body=@t]
  ^-  provider-result:net
  ?-  provider
    %codex   (responses-result:net (sse-events:net body))
    %claude  (messages-result:net body)
  ==
::
++  result-failure
  |=  result=provider-result:net
  ^-  (unit @tas)
  ?^  error.result  `%provider-error
  ?:  tool-call.result  `%invalid-provider-output
  ?:  refusal.result  `%provider-refused
  ?.  completed.result  `%invalid-provider-output
  ?~  text.result  `%invalid-provider-output
  ~
::
::  +parse-citations: only citations that name a canonical snapshot
::  reference survive; an invented reference is dropped here and a real
::  one is still checked against the frozen packet before storage.
::
++  parse-citations
  |=  rows=(list json)
  ^-  (unit (list evidence-citation))
  ?:  (gth (lent rows) 32)  ~
  =|  out=(list evidence-citation)
  |-
  ?~  rows  `(flop out)
  =/  row  i.rows
  =/  ref  (get-string:net row 'snapshot_ref')
  =/  start  (get-number:net row 'start')
  =/  end  (get-number:net row 'end')
  =/  quote  (get-string:net row 'quote')
  ?:  |(?=(~ ref) ?=(~ start) ?=(~ end) ?=(~ quote))  $(rows t.rows)
  =/  snapshot  (slaw %ux u.ref)
  ?~  snapshot  $(rows t.rows)
  $(rows t.rows, out [[u.snapshot u.start u.end u.quote] out])
::
++  clean-text
  |=  [value=(unit @t) limit=@ud]
  ^-  (unit @t)
  ?~  value  ~
  =/  trimmed  (crip (trim-tape:oa (trip u.value)))
  ?:  =('' trimmed)  ~
  ?:  (gth (met 3 trimmed) limit)  ~
  ?:  (lien (trip trimmed) |=(ch=@ =(0 ch)))  ~
  `trimmed
::
++  parse-question-output
  |=  [mode=assistant-mode text=@t]
  ^-  (unit [answer=@t title=@t front=@t back=@t citations=(list evidence-citation)])
  =/  jon  (provider-json:net text)
  ?~  jon  ~
  =/  citations  (parse-citations (get-array:net u.jon 'citations'))
  ?~  citations  ~
  =/  answer  (clean-text (get-string:net u.jon 'answer') 60.000)
  ?-    mode
      %ask
    ?~  answer  ~
    `[u.answer '' '' '' u.citations]
      %edit
    =/  title  (clean-text (get-string:net u.jon 'title') 240)
    =/  front  (clean-text (get-string:net u.jon 'front') 16.000)
    =/  back  (clean-text (get-string:net u.jon 'back') 16.000)
    =/  summary  (clean-text ?~(answer (get-string:net u.jon 'summary') answer) 1.200)
    ?:  |(?=(~ title) ?=(~ front) ?=(~ back) ?=(~ summary))  ~
    `[u.summary u.title u.front u.back u.citations]
  ==
::
++  valid-slug
  |=  text=@t
  ^-  ?
  =/  tap  (trip text)
  ?~  tap  %.n
  ?.  ?|(&((gte i.tap 'a') (lte i.tap 'z')) &((gte i.tap '0') (lte i.tap '9')))  %.n
  %+  levy  t.tap
  |=(ch=@ ?|(&((gte ch 'a') (lte ch 'z')) &((gte ch '0') (lte ch '9')) =(ch '-')))
::
::  +title-slug: a card identifier derived from a title when the planner
::  leaves card_id empty on a create-card candidate. lowercase ascii
::  letters and digits are kept, every other run becomes one dash.
::
++  title-slug
  |=  title=@t
  ^-  @t
  =/  tap  (trip title)
  =|  out=tape
  =/  dash=?  %.n
  |-
  ?~  tap
    =/  cut=tape  (scag 48 (flop out))
    ?~  cut  ''
    %-  crip
    ?.  =('-' (rear cut))  cut
    (scag (dec (lent cut)) `tape`cut)
  =/  ch  i.tap
  =/  lower  ?:(&((gte ch 'A') (lte ch 'Z')) (add ch 32) ch)
  ?:  ?|(&((gte lower 'a') (lte lower 'z')) &((gte lower '0') (lte lower '9')))
    $(tap t.tap, out [lower out], dash %.n)
  ?:  |(dash ?=(~ out))  $(tap t.tap)
  $(tap t.tap, out ['-' out], dash %.y)
::
++  parse-operation
  |=  row=json
  ^-  (unit state-operation)
  =/  kind-text  (string-or:net row 'kind' '')
  =/  kind=(unit state-operation-kind)
    ?+  kind-text  ~
      %'create-stack'  `%create-stack
      %'rename-stack'  `%rename-stack
      %'delete-stack'  `%delete-stack
      %'create-card'   `%create-card
      %'edit-card'     `%edit-card
      %'delete-card'   `%delete-card
      %'queue-card'    `%queue-card
    ==
  ?~  kind  ~
  =/  field
    |=  [name=@t required=?]
    ^-  (unit @t)
    =/  value  (get-string:net row name)
    ?~  value  ?:(required ~ `'')
    ?:  (gth (met 3 u.value) 16.000)  ~
    ?:  (lien (trip u.value) |=(ch=@ =(0 ch)))  ~
    ?:  ?&(required =('' (crip (trim-tape:oa (trip u.value)))))  ~
    value
  =/  stack-required  %.y
  =/  card-required  ?=(?(%create-card %edit-card %delete-card %queue-card) u.kind)
  =/  title-required  ?=(?(%create-stack %rename-stack %create-card %edit-card) u.kind)
  =/  body-required  ?=(?(%create-card %edit-card) u.kind)
  =/  original-title-required  ?=(?(%rename-stack %delete-stack %edit-card %delete-card %queue-card) u.kind)
  =/  original-body-required  ?=(?(%edit-card %delete-card %queue-card) u.kind)
  =/  stack  (field 'stack_id' stack-required)
  =/  card  (field 'card_id' card-required)
  =?  card  ?&(?=(%create-card u.kind) =(`'' (field 'card_id' %.n)))
    =/  derived  (title-slug (fall (field 'title' %.n) ''))
    ?:(=('' derived) ~ `derived)
  =/  title  (field 'title' title-required)
  =/  front  (field 'front' body-required)
  =/  back  (field 'back' body-required)
  =/  original-title  (field 'original_title' original-title-required)
  =/  original-front  (field 'original_front' original-body-required)
  =/  original-back  (field 'original_back' original-body-required)
  ?:  ?|  ?=(~ stack)  ?=(~ card)  ?=(~ title)  ?=(~ front)  ?=(~ back)
          ?=(~ original-title)  ?=(~ original-front)  ?=(~ original-back)
      ==
    ~
  ?.  (valid-slug u.stack)  ~
  ?.  ?:(card-required (valid-slug u.card) =('' u.card))  ~
  =/  stack-id=(unit @tas)  (slaw %tas u.stack)
  =/  card-id=(unit @tas)  ?:(=('' u.card) `%$ (slaw %tas u.card))
  ?:  |(?=(~ stack-id) ?=(~ card-id))  ~
  :-  ~
  :*  u.kind
      u.stack-id
      u.card-id
      u.title
      u.front
      u.back
      u.original-title
      u.original-front
      u.original-back
  ==
::
++  parse-plan-output
  |=  [target=change-target text=@t]
  ^-  (unit [summary=@t artifact=@t operations=(list state-operation) citations=(list evidence-citation)])
  =/  jon  (provider-json:net text)
  ?~  jon  ~
  =/  citations  (parse-citations (get-array:net u.jon 'citations'))
  ?~  citations  ~
  =/  summary  (clean-text (get-string:net u.jon 'summary') 2.000)
  ?~  summary  ~
  ?:  =(%desk target)
    =/  artifact  (clean-text (get-string:net u.jon 'artifact') 32.000)
    ?~  artifact  ~
    `[u.summary u.artifact ~ u.citations]
  =/  rows  (get-array:net u.jon 'operations')
  ?:  (gth (lent rows) 64)  ~
  =/  operations=(list state-operation)  ~
  =/  targets=(set @t)  ~
  |-
  ?~  rows  `[u.summary '' (flop operations) u.citations]
  =/  parsed  (parse-operation i.rows)
  ?~  parsed  ~
  =/  ref  (rap 3 (scot %tas stack.u.parsed) '/' (scot %tas card.u.parsed) ~)
  ?:  (~(has in targets) ref)  ~
  $(rows t.rows, operations [u.parsed operations], targets (~(put in targets) ref))
::
++  take-question
  |=  [id=@tas attempt=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  found  (~(get by questions.state) id)
  ?~  found  [~ state]
  =/  question  u.found
  ?.  ?&(=(%working status.question) =(attempt attempt.question))  [~ state]
  =/  key=entity-key  [%question our.bol %root id]
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res (response-cap %question))  [~ state]
    =^  moves  state  (system-command [%fail-card-question id attempt %output-limit])
    [[(cancel-card:net (request-wire key attempt)) moves] state]
      %cancel
    (system-command [%fail-card-question id attempt %unreachable])
      %finished
    =/  status  status-code.response-header.res
    =/  body  (body-text:net full-file.res)
    ?.  =(200 status)
      (system-command [%fail-card-question id attempt (http-failure status body)])
    =/  result  (provider-result provider.profile.question body)
    =/  problem  (result-failure result)
    ?^  problem  (system-command [%fail-card-question id attempt u.problem])
    =/  parsed  (parse-question-output mode.question (need text.result))
    ?~  parsed  (system-command [%fail-card-question id attempt %invalid-provider-output])
    =/  citations  (anchor-citations:ev citations.u.parsed evidence.state)
    =^  moves  state
      ?-  mode.question
        %ask   (system-command [%answer-card-question id attempt answer.u.parsed citations usage.result])
        %edit  (system-command [%apply-card-edit id attempt title.u.parsed front.u.parsed back.u.parsed answer.u.parsed citations usage.result])
      ==
    =/  after  (~(get by questions.state) id)
    ?.  ?&(?=(^ after) =(%working status.u.after))  [moves state]
    =^  more  state  (system-command [%fail-card-question id attempt %invalid-provider-output])
    [(weld moves more) state]
  ==
::
++  take-change
  |=  [id=@tas attempt=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  found  (~(get by changes.state) id)
  ?~  found  [~ state]
  =/  request  u.found
  ?.  ?&(=(%working status.request) =(attempt attempt.request))  [~ state]
  =/  key=entity-key  [%change our.bol %root id]
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res (response-cap %change))  [~ state]
    =^  moves  state  (system-command [%fail-change id attempt %output-limit])
    [[(cancel-card:net (request-wire key attempt)) moves] state]
      %cancel
    (system-command [%fail-change id attempt %unreachable])
      %finished
    =/  status  status-code.response-header.res
    =/  body  (body-text:net full-file.res)
    ?.  =(200 status)
      (system-command [%fail-change id attempt (http-failure status body)])
    =/  result  (provider-result provider.profile.request body)
    =/  problem  (result-failure result)
    ?^  problem  (system-command [%fail-change id attempt u.problem])
    =/  parsed  (parse-plan-output target.request (need text.result))
    ?~  parsed  (system-command [%fail-change id attempt %invalid-provider-output])
    =.  citations.u.parsed  (anchor-citations:ev citations.u.parsed evidence.state)
    ?:  ?&(=(%library target.request) ?=(~ operations.u.parsed))
      (system-command [%fail-change id attempt %no-supported-candidate])
    =^  moves  state
      (system-command [%finish-change id attempt summary.u.parsed artifact.u.parsed operations.u.parsed citations.u.parsed usage.result])
    =/  after  (~(get by changes.state) id)
    ?.  ?&(?=(^ after) =(%working status.u.after))  [moves state]
    =^  more  state  (system-command [%fail-change id attempt %invalid-provider-output])
    [(weld moves more) state]
  ==
::
++  take-fetch
  |=  [id=@tas attempt=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  found  (~(get by contexts.state) id)
  ?~  found  [~ state]
  =/  source  u.found
  ?.  ?&(active.source =(%working status.source) =(attempt attempt.source))  [~ state]
  =/  key=entity-key  [%context our.bol %root id]
  =/  job  (~(get by jobs.operating.state) key)
  =/  current-url  ?~(job locator.source (fall external.u.job locator.source))
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res (response-cap %context))  [~ state]
    =^  moves  state  (system-command [%fail-context-source id attempt %output-limit])
    [[(cancel-card:net (request-wire key attempt)) moves] state]
      %cancel
    (system-command [%fail-context-source id attempt %unreachable])
      %finished
    =/  status  status-code.response-header.res
    =/  headers  headers.response-header.res
    ?:  ?&((gte status 300) (lth status 400))
      =/  location  (header:net headers 'location')
      =/  next-url  ?~(location ~ (resolve-redirect:net current-url u.location))
      ?~  next-url  (system-command [%fail-context-source id attempt %invalid-redirect])
      ?^  (destination-error:net u.next-url)
        (system-command [%fail-context-source id attempt %destination-rejected])
      =/  hops  ?~(job 0 redirects.u.job)
      ?:  (gte hops 5)  (system-command [%fail-context-source id attempt %redirect-limit])
      =?  state  ?=(^ job)  (put-work key u.job(redirects +(hops), external `u.next-url))
      :_  state
      ~[(iris-card:net (request-wire key attempt) (fetch-request u.next-url))]
    ?.  =(200 status)
      (system-command [%fail-context-source id attempt ?:((gte status 500) %provider-unavailable %fetch-failed)])
    =/  raw  (body-text:net full-file.res)
    ?:  (gth (met 3 raw) (response-cap %context))
      (system-command [%fail-context-source id attempt %output-limit])
    =/  text  ?:((is-html:net headers) (html-text:net raw) raw)
    ?:  =('' text)  (system-command [%fail-context-source id attempt %fetch-failed])
    (system-command [%finish-context-source id attempt '' text current-url])
  ==
::
::  +settle-overdue: after a reload, settle every attempt whose deadline
::  passed while no wake could reach the agent. behn keeps the timers, but
::  a suspended agent misses their wakes; the handlers fence by attempt,
::  so a wake that does arrive later changes nothing.
::
++  settle-overdue
  ^-  (quip card _state)
  =|  cards=(list card)
  =/  jobs  ~(tap by jobs.operating.state)
  |-
  ?^  jobs
    =/  key=entity-key  p.i.jobs
    =/  job=work-record  q.i.jobs
    ?.  ?&(=(%running execution.job) ?=(^ deadline.job) (gte now.bol u.deadline.job))
      $(jobs t.jobs)
    =^  moves  state  (take-deadline kind.key id.key attempt.job)
    $(jobs t.jobs, cards (weld cards moves))
  =/  logins  ~(tap by logins.state)
  |-
  ?^  logins
    =/  req=login-request  q.i.logins
    ?.  ?&(?=(?(%working %challenge) status.req) ?=(^ deadline.req) (gte now.bol u.deadline.req))
      $(logins t.logins)
    =^  moves  state  (take-deadline %login id.req attempt.req)
    $(logins t.logins, cards (weld cards moves))
  =/  accounts  ~(tap by accounts.state)
  |-
  ?^  accounts
    =/  active  active.renewal.q.i.accounts
    ?.  ?&(?=(^ active) (gte now.bol deadline.u.active))
      $(accounts t.accounts)
    =^  moves  state  (take-renewal-deadline p.i.accounts serial.u.active)
    $(accounts t.accounts, cards (weld cards moves))
  =/  catalogs  ~(tap by catalog-active.state)
  |-
  ?^  catalogs
    ?.  (gte now.bol deadline.q.i.catalogs)  $(catalogs t.catalogs)
    =^  moves  state  (take-catalog-deadline p.i.catalogs serial.q.i.catalogs)
    $(catalogs t.catalogs, cards (weld cards moves))
  [cards state]
::
++  take-deadline
  |=  [kind=@tas id=@tas attempt=@ud]
  ^-  (quip card _state)
  ?+    kind  [~ state]
      %question
    =/  found  (~(get by questions.state) id)
    ?~  found  [~ state]
    ?.  ?&(=(%working status.u.found) =(attempt attempt.u.found))  [~ state]
    =/  key=entity-key  [%question our.bol %root id]
    =^  moves  state  (system-command [%fail-card-question id attempt %timeout])
    =.  state  (mark-unknown key %timeout)
    [(weld (cancel-cards key attempt) moves) state]
      %change
    =/  found  (~(get by changes.state) id)
    ?~  found  [~ state]
    ?.  ?&(=(%working status.u.found) =(attempt attempt.u.found))  [~ state]
    =/  key=entity-key  [%change our.bol %root id]
    =^  moves  state  (system-command [%fail-change id attempt %timeout])
    =.  state  (mark-unknown key %timeout)
    [(weld (cancel-cards key attempt) moves) state]
      %context
    =/  found  (~(get by contexts.state) id)
    ?~  found  [~ state]
    ?.  ?&(=(%working status.u.found) =(attempt attempt.u.found))  [~ state]
    =/  key=entity-key  [%context our.bol %root id]
    =^  moves  state  (system-command [%fail-context-source id attempt %timeout])
    [(weld (cancel-cards key attempt) moves) state]
      %login
    =/  found  (~(get by logins.state) id)
    ?~  found  [~ state]
    ?.  ?&(?=(?(%working %challenge) status.u.found) =(attempt attempt.u.found))  [~ state]
    (system-command [%fail-login id attempt %expired])
  ==
::
++  mark-unknown
  |=  [key=entity-key reason=@tas]
  ^-  _state
  =/  job  (~(get by jobs.operating.state) key)
  ?~  job  state
  (put-work key u.job(effect %unknown, stop-reason `reason))
::
::  sign-in responses
::
++  take-login-response
  |=  [id=@tas step=@tas attempt=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  found  (~(get by logins.state) id)
  ?~  found  [~ state]
  =/  req  u.found
  ?.  =(attempt attempt.req)  [~ state]
  ?:  ?=(?(%done %failed %pending) status.req)  [~ state]
  ?.  =(`step inflight.req)  [~ state]
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res (response-cap %login))  [~ state]
    (system-command [%fail-login id attempt %denied])
      %cancel
    =.  logins.state  (~(put by logins.state) id req(inflight ~))
    (system-command [%fail-login id attempt %unreachable])
      %finished
    =.  logins.state  (~(put by logins.state) id req(inflight ~))
    =/  status  status-code.response-header.res
    =/  body  (body-text:net full-file.res)
    ?+    step  [~ state]
        %usercode
      ?.  =(%working status.req)  [~ state]
      ?.  =(200 status)
        =/  lowered  (trip (lower:net body))
        =/  reason=@tas
          ?:  ?|(!=(~ (find "disabled" lowered)) !=(~ (find "not enabled" lowered)))  %device-auth-disabled
          ?:  (gte status 500)  %unreachable
          %denied
        (system-command [%fail-login id attempt reason])
      =/  parsed  (parse-usercode:oa body)
      ?~  parsed  (system-command [%fail-login id attempt %invalid-login-challenge])
      (system-command [%post-login-challenge id attempt codex-device-page:oa user-code.u.parsed device-id.u.parsed interval.u.parsed])
        %poll
      ?.  =(%challenge status.req)  [~ state]
      =/  outcome  (parse-poll:oa status body)
      ?-    -.outcome
          %pending
        :_  state
        ~[(wait-card:net /seer-poll/[id]/(scot %ud attempt) (add now.bol (mul (max 2 interval.req) ~s1)))]
          %failed
        (system-command [%fail-login id attempt reason.outcome])
          %code
        =.  logins.state
          (~(put by logins.state) id req(status %working, verifier verifier.outcome, inflight `%exchange, updated-at now.bol))
        :_  state
        ~[(iris-card:net (login-wire id %exchange attempt) (codex-exchange-request:oa code.outcome verifier.outcome))]
      ==
        %exchange
      ?.  =(%working status.req)  [~ state]
      ?.  =(200 status)
        (system-command [%fail-login id attempt ?:((gte status 500) %unreachable %denied)])
      =/  granted  (parse-token-response:oa provider.req now.bol body)
      ?~  granted  (system-command [%fail-login id attempt %invalid-login-challenge])
      =^  moves  state
        %-  system-command
        :*  %import-account
            provider.req
            %oauth
            access.u.granted
            refresh.u.granted
            ?:(=('' account.u.granted) label.u.granted account.u.granted)
            expires.u.granted
            scopes.u.granted
        ==
      =^  more  state  (system-command [%finish-login id attempt])
      [(weld moves more) state]
    ==
  ==
::
++  take-login-poll
  |=  [id=@tas attempt=@ud]
  ^-  (quip card _state)
  =/  found  (~(get by logins.state) id)
  ?~  found  [~ state]
  =/  req  u.found
  ?.  ?&(=(%challenge status.req) =(attempt attempt.req) =(%codex provider.req) !=('' device-id.req))
    [~ state]
  ?:  ?&(?=(^ deadline.req) (gte now.bol u.deadline.req))
    (system-command [%fail-login id attempt %expired])
  =.  logins.state  (~(put by logins.state) id req(inflight `%poll))
  :_  state
  ~[(iris-card:net (login-wire id %poll attempt) (poll-request:oa device-id.req user-code.req))]
::
::  renewal responses
::
++  take-renewal
  |=  [provider=ai-provider serial=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  slot  (~(get by accounts.state) provider)
  ?~  slot  [~ state]
  ?.  ?&(?=(^ active.renewal.u.slot) =(serial serial.u.active.renewal.u.slot))  [~ state]
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res (response-cap %login))  [~ state]
    =^  moves  state  (system-command [%fail-renewal provider serial %renewal-failed %.n])
    [[(cancel-card:net /seer-renew/(scot %tas provider)/(scot %ud serial)) moves] state]
      %cancel
    (system-command [%fail-renewal provider serial %renewal-failed %.n])
      %finished
    =/  status  status-code.response-header.res
    ?.  =(200 status)
      =/  terminal  ?|(=(400 status) =(401 status) =(403 status))
      (system-command [%fail-renewal provider serial ?:(terminal %renewal-terminal %renewal-failed) terminal])
    =/  granted  (parse-token-response:oa provider now.bol (body-text:net full-file.res))
    ?~  granted  (system-command [%fail-renewal provider serial %renewal-failed %.n])
    ?:  ?~(expires.u.granted %.y (lte u.expires.u.granted (add now.bol renewal-margin:oa)))
      (system-command [%fail-renewal provider serial %renewal-failed %.n])
    (system-command [%rotate-account provider serial access.u.granted refresh.u.granted expires.u.granted])
  ==
::
++  take-renewal-deadline
  |=  [provider=ai-provider serial=@ud]
  ^-  (quip card _state)
  =/  slot  (~(get by accounts.state) provider)
  ?~  slot  [~ state]
  ?.  ?&(?=(^ active.renewal.u.slot) =(serial serial.u.active.renewal.u.slot))  [~ state]
  =^  moves  state  (system-command [%fail-renewal provider serial %renewal-timeout %.n])
  [[(cancel-card:net /seer-renew/(scot %tas provider)/(scot %ud serial)) moves] state]
::
::  catalog responses
::
++  catalog-profiles
  |=  [provider=ai-provider rows=(list [slug=@t label=@t])]
  ^-  (list assistant-model)
  %+  murn  (scag 128 rows)
  |=  [slug=@t label=@t]
  ^-  (unit assistant-model)
  =/  clean=tape
    %+  turn  (cass (trip slug))
    |=  ch=@
    ?:(?|(&((gte ch 'a') (lte ch 'z')) &((gte ch '0') (lte ch '9')) =(ch '-')) ch '-')
  ?~  clean  ~
  =/  id  (slaw %tas (crip (weld (trip (scot %tas provider)) (weld "-" clean))))
  ?~  id  ~
  =/  lowered  (cass (trip slug))
  =/  role=omp-role
    ?:  ?|(!=(~ (find "sol" lowered)) !=(~ (find "haiku" lowered)) !=(~ (find "mini" lowered)) !=(~ (find "spark" lowered)))  %smol
    ?:  ?|(!=(~ (find "luna" lowered)) !=(~ (find "opus" lowered)) !=(~ (find "fable" lowered)))  %slow
    %default
  =/  selector  (rap 3 ?:(=(%codex provider) 'openai-codex/' 'anthropic/') slug ~)
  :-  ~
  :*  u.id
      provider
      role
      selector
      slug
      label
      ''
      'catalog'
      now.bol
  ==
::
++  take-catalog
  |=  [provider=ai-provider serial=@ud res=client-response:iris]
  ^-  (quip card _state)
  =/  active  (~(get by catalog-active.state) provider)
  ?~  active  [~ state]
  ?.  =(serial serial.u.active)  [~ state]
  ?-    -.res
      %progress
    ?.  (gth bytes-read.res 1.048.576)  [~ state]
    =.  catalog-active.state  (~(del by catalog-active.state) provider)
    :_  state
    ~[(cancel-card:net /seer-catalog/(scot %tas provider)/(scot %ud serial))]
      %cancel
    [~ state(catalog-active (~(del by catalog-active.state) provider))]
      %finished
    =.  catalog-active.state  (~(del by catalog-active.state) provider)
    ?.  =(200 status-code.response-header.res)  [~ state]
    =/  body  (body-text:net full-file.res)
    =/  rows
      ?-  provider
        %codex   (codex-catalog:net body)
        %claude  (claude-catalog:net body)
      ==
    =/  profiles  (catalog-profiles provider rows)
    ?~  profiles  [~ state]
    (system-command [%replace-assistant-models provider 'catalog' profiles])
  ==
::
++  take-catalog-deadline
  |=  [provider=ai-provider serial=@ud]
  ^-  (quip card _state)
  =/  active  (~(get by catalog-active.state) provider)
  ?~  active  [~ state]
  ?.  =(serial serial.u.active)  [~ state]
  =.  catalog-active.state  (~(del by catalog-active.state) provider)
  :_  state
  ~[(cancel-card:net /seer-catalog/(scot %tas provider)/(scot %ud serial))]
::
++  serve-shared-manifest
  ^-  (quip card _state)
  :_  state
  :~  [%give %fact ~ %noun !>([%0 shared-manifest])]
      [%give %kick ~ ~]
  ==
::
++  serve-shared-file
  |=  pax=path
  ^-  (quip card _state)
  =/  entry  (~(get by shared-context.state) pax)
  ?~  entry  ~|(%shared-file-not-listed !!)
  =/  loc=tape
    %-  zing
    :-  "/{(trip (scot %p our.bol))}"
    (turn pax |=(k=@ta "/{(trip k)}"))
  =/  loaded=(each acquired-context tang)
    (mule |.((read-clay-context (crip loc))))
  ?:  ?=(%| -.loaded)  ~|(%shared-file-unreadable !!)
  ?.  =(%full coverage.p.loaded)  ~|(%shared-file-content-required !!)
  ?:  (gth (met 3 content.p.loaded) 131.072)
    ~|(%shared-file-too-large !!)
  :_  state
  :~  [%give %fact ~ %noun !>([%1 label.u.entry mark.u.entry p.loaded])]
      [%give %kick ~ ~]
  ==
::
++  fail-shared-fetch
  |=  [id=@tas msg=@t]
  ^-  (quip card _state)
  =.  outstanding-keens.state
    (~(del by outstanding-keens.state) id)
  =/  maybe-source  (~(get by contexts.state) id)
  ?~  maybe-source  [~ state]
  =/  source  u.maybe-source
  ?.  ?&(active.source =(%pending status.source))  [~ state]
  =.  status.source  %failed
  =.  error.source  msg
  =.  updated-at.source  now.bol
  =.  contexts.state  (~(put by contexts.state) id source)
  [~ state]
::
++  take-shared-fetch
  |=  [id=@tas =cage]
  ^-  (quip card _state)
  =/  maybe-source  (~(get by contexts.state) id)
  ?~  maybe-source  [~ state]
  =/  source  u.maybe-source
  ?.  ?&(active.source =(%pending status.source))  [~ state]
  =/  keen  (~(get by outstanding-keens.state) id)
  ?~  keen  [~ state]
  ?.  =(src.bol who.u.keen)  [~ state]
  =/  payload
    ((soft ,[%1 label=@t mark=@tas acquired=acquired-context]) q.q.cage)
  ?~  payload
    (fail-shared-fetch id 'That ship sent an unexpected reply.')
  ?:  ?|  !=(%full coverage.acquired.u.payload)
          =(0 (met 3 content.acquired.u.payload))
          (gth (met 3 content.acquired.u.payload) 131.072)
      ==
    %+  fail-shared-fetch  id
    'The shared file is empty or larger than 128 KB.'
  =.  outstanding-keens.state
    (~(del by outstanding-keens.state) id)
  (accept-context source content.acquired.u.payload %full locator.source origin-revision.acquired.u.payload %shared-clay)
::
++  shared-fetch-timeout
  |=  id=@tas
  ^-  (quip card _state)
  ?.  (~(has by outstanding-keens.state) id)  [~ state]
  %+  fail-shared-fetch  id
  'Timed out waiting for that ship to reply.'
::
++  fetch-remote-manifest
  |=  who=@p
  ^-  (quip card _state)
  =/  existing  (~(get by remote-manifests.state) who)
  ?:  ?&  ?=(^ existing)
          =(0 rev.u.existing)
          !=(*@da at.u.existing)
          (lth now.bol (add at.u.existing ~s45))
      ==
    [~ state]
  =.  remote-manifests.state
    (~(put by remote-manifests.state) who [0 now.bol ~])
  :_  state
  :~  :*  %pass  [%shared-manifest (scot %p who) ~]  %agent  [who %seer]
          %watch  /shared-context
      ==
      :*  %pass
          [%shared-manifest-timeout (scot %p who) ~]
          %arvo
          %b
          %wait
          (add now.bol ~s45)
      ==
  ==
::
++  fail-remote-manifest
  |=  who=@p
  ^-  (quip card _state)
  =/  existing  (~(get by remote-manifests.state) who)
  ?.  ?&  ?=(^ existing)
          =(0 rev.u.existing)
          !=(*@da at.u.existing)
      ==
    [~ state]
  =.  remote-manifests.state
    (~(put by remote-manifests.state) who [0 *@da ~])
  [~ state]
::
++  take-remote-manifest
  |=  [who=@p =cage]
  ^-  (quip card _state)
  =/  payload
    ((soft ,[%0 entries=(list manifest-entry)]) q.q.cage)
  ?~  payload  (fail-remote-manifest who)
  =.  remote-manifests.state
    %+  ~(put by remote-manifests.state)  who
    [1 now.bol (scag 500 entries.u.payload)]
  [~ state]
::
++  remote-manifest-timeout
  |=  who=@p
  ^-  (quip card _state)
  (fail-remote-manifest who)
::
++  peer-seertile
  |=  wir=wire
  ^-  (quip card _state)
  :_  state
  [%give %fact ~[/seertile] %json !>(make-tile-json)]~
::
++  peer-seer-primary
  |=  wir=wire
  ^-  (quip card _state)
  ?.  =(our.bol src.bol)
    :_  state
    [%give %kick ~ ~]~
  [~ state]
::
++  peer-stack
  |=  stack-name=@tas
  ^-  (quip card _state)
  =/  =stack  (~(got by stacks.state) stack-name)
  :_  state
  [%give %fact ~ %seer-stack !>(stack)]~
::
++  apply-remote-delta
  |=  [who=@p name=@tas del=primary-delta]
  ^-  (quip card _state)
  =/  key  [who name]
  ?.  (~(has by stack-subs.state) key)  [~ state]
  ?+  del  [~ state]
      [%update-stack * *]
    ?.  &(=(who who.del) =(name name.data.del))  [~ state]
    =.  stack-subs.state
      (~(put by stack-subs.state) key data.del)
    [~ state]
  ::
      [%delete-stack * *]
    ?.  &(=(who who.del) =(name stack.del))  [~ state]
    =.  stack-subs.state  (~(del by stack-subs.state) key)
    :_  state
    [%pass /import/(scot %p who)/[name] %agent [who %seer] %leave ~]~
  ==
::
++  our-beak  /(scot %p our.bol)/[q.byk.bol]/(scot %da now.bol)
++  wake
  |=  =wire
  ^-  (quip card _state)
  ?+  wire
    [~ state]
      [%review-schedule @ @ @ ~]
    =/  item
      %+  biff
        (~(get by stacks) i.t.wire)
      |=(=stack (~(get by items.stack) i.t.t.wire))
    ?~  item
      ~&  peer+"missing {(spud t.t.wire)} item scheduled for review!"
      [~ state]
    =<  abet
    %.  (need item)
    %~  add-review-item  stack-emit  (~(got by stacks) i.t.wire)
  ==
::
++  poke-noun
  |=  a=*
    ^-  (quip card _state)
    ?.  ?&(=(src.bol our.bol) operator-authorized)
      [~ state]
    ?+  a
      [~ state]
        %print-json
      ~&  >  state+(state-to-json state)
      [~ state]
        [%import-account @ @]
      ::  :seer &noun [%import-account %codex 'pasted credentials or key']
      =/  provider=(unit ai-provider)  ((soft ai-provider) +<.a)
      =/  text=@t  `@t`+>.a
      ?~  provider  [~ state]
      =/  parsed  (parse-pasted:oa u.provider now.bol text)
      ?~  parsed  [~ state]
      =/  act=action
        [%import-account u.provider method.u.parsed access.u.parsed refresh.u.parsed account.u.parsed expires.u.parsed scopes.u.parsed]
      (apply-command (make-command epoch.operating.state (local-operation act) act))
        [%clear-account @]
      =/  provider=(unit ai-provider)  ((soft ai-provider) +.a)
      ?~  provider  [~ state]
      =/  act=action  [%clear-account u.provider]
      (apply-command (make-command epoch.operating.state (local-operation act) act))
        [%refresh-catalog @]
      =/  provider=(unit ai-provider)  ((soft ai-provider) +.a)
      ?~  provider  [~ state]
      =/  act=action  [%refresh-catalog u.provider]
      (apply-command (make-command epoch.operating.state (local-operation act) act))
    ==
::
++  handle-import-stack
  |=   =stack
  ^-  (quip card _state)
  =<  abet
  ~(add-stack-subs stack-emit stack)
::
++  state-to-json
  |=  sat=_state
  ^-  json
  %-  pairs:enjs:format
  :~  :+  %pubs
        %o
      %+  roll  ~(tap by stacks.sat)
      |=  [[nom=@tas stack=stack] out=(map @t json)]
      %+  ~(put by out)
        nom
      (total-build-to-json stack)
  ::
      :+  %subs
        %o
      %-  ~(rep by stack-subs.sat)
      |=  $:  [[who=@p nom=@tas] stack=stack]
              out=(map @t [%o (map @t json)])
          ==
      =/  shp=@t  (rsh [3 1] (scot %p who))
      ?:  (~(has by out) shp)
        %+  ~(put by out)
          shp
        :-  %o
        %+  ~(put by +:(~(got by out) shp))
          nom
        (total-build-to-json stack)
      %+  ~(put by out)
        shp
      :-  %o
      (my [nom (total-build-to-json stack)] ~)
  ::
      :+  %review
        %a
      %+  turn  all-reviews  review-to-json
  ==
::
++  make-tile-json
  ^-  json
  %-  pairs:enjs:format
  :~  review+(numb:enjs:format (lent all-reviews))
  ==
::
++  create-item
  |=  act=action
  ^-  item
  ?>  ?=(%new-item -.act)
  (create-item:effects src.bol now.bol act)
::
++  create-stack
  |=  [info=stack-info items=(map @tas item)]
  ^-  stack
  (create-stack:effects info items)
::
++  all-reviews
  ^-  (list review)
  %-  zing
  %+  turn  ~(val by stacks)
  |=  =stack
  %+  turn  ~(val by review-items.stack)
  |=  =item  [author.content.item name.stack name.item]
::
++  generate-learn
  |=  [=item =recall-grade]
  ^-  learn
  =/  item-status=learn  learn.item
  =/  ease=@rs  (next-ease recall-grade item-status)
  =/  box=@  (next-box recall-grade item-status)
  =/  interval=@dr  (next-interval [ease box item-status])
  (learn [ease interval box])
::
++  next-ease
  |=  [=recall-grade =learn]
  ^-  @rs
  =/  ease-changes=(map ^recall-grade @rs)
  %-  malt
  ^-  (list [^recall-grade @rs])
  :~  [%again .-0.3]
      [%hard .-0.15]
      [%good .0]
      [%easy .0.15]
  ==
  =/  ease-min=@rs  .1.3
  =/  ease-max=@rs  .5.0
  ?:  (lth box.learn 2)
    ease.learn
  =/  chg  (~(got by ease-changes) recall-grade)
  =/  a  (add:rs ease.learn chg)
  ?:  (gte a ease-min)
    a
  ?:  (gte a ease-max)
    ease-max
  ease-min
::
++  next-box
  |=  [=recall-grade =learn]
  ^-  @
  ?:  ?&
        =(recall-grade %easy)
        =(box.learn 0)
      ==
    2
  ?:  =(recall-grade %again)  0
  (add box.learn 1)
::
++  next-interval
  |=  [next-ease=@rs next-box=@ =learn]
  ^-  @dr
  ::  ~15 min, 1 day, 6 days
  ::
  =/  fixed-intervals=(list @dr)  [~s5 ~m15 ~d1 ~d6 ~]
  ?:  (lth next-box (lent fixed-intervals))
    (snag next-box fixed-intervals)
  (interval-fuzz interval.learn next-ease)
::
++  interval-fuzz
  |=  [interval=@dr next-ease=@rs]
  ^-  @dr
  =/  random  ~(. og eny.bol)
  =/  interval-rs  (time-to-rs interval)
  =/  r=@rs  (add:rs `@rs`.0.9 (rad:random .1.1))
  =/  fuzzed  (mul:rs (mul:rs next-ease interval-rs) r)
  (rs-to-time fuzzed)
::
++  import-from-file
  =<
  |=  px=path
  =/  pax=path  (welp our-beak px)
  =/  name  `@t`+<:(flop pax)
  =/  items
    %+  parse  name
    %-  of-wall:format
    =+  ark=.^(arch %cy pax)
    ?^  fil.ark
      =/  fyl  .^(noun %cx pax)
      =+  ^-  (unit wain)
          ?@(fyl `(to-wain:format fyl) ((soft wain) fyl))
      ?^  -  (wain-to-tape u)  ~&("could not parse" !!)
    !!
  =/  filtered  (murn (need items) |*(a=(unit *) a))
  =<  abet
  %-  emit-action
  :*  %new-stack
      (string-to-symbol (trip name))
      name
      (molt filtered)
  ==
  |%
  ++  wain-to-tape  |=(a=wain (turn a |=(b=cord (trip b))))
  ++  parse
    |=  [stack-name=@tas =tape]
    |^  (rust tape parser)
    ++  parser
      %+  more  ;~(pose (just `@`10) (just `@`13))
      %+  cook
        |=  a=wall
        ^-  (unit (pair @tas item))
        ?.  ?=([* * *] a)  ~
        =/  front  (crip i.a)
        =/  back  (crip i.t.a)
        =/  uid
          %-  string-to-symbol
          "{<(sham %seer our.bol front eny.bol)>}"
        :-  ~
        :-  uid
        %-  create-item
        =/  act
          :*  %new-item
              our.bol
              our.bol
              stack-name
              uid
              `@tas`front
              [read=*rule:clay write=*rule:clay]
              `@t`front
              `@t`back
          ==
        `action`act
      (most (just `@`9) (star prn))
    --
  --
--
