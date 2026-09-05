/-  mcp, seer-types=seer
/+  *server, *seer, *seer-json, *seer-mcp, reader=seer-read, ev=seer-evidence, effects=seer-effects, memory=seer-learning, default-agent, verb, dbug, agentio
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
      bridge-secret=@t
      bridge-nonces=(map @t @da)
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
  %-  agent:dbug
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
    ::  Reviewing an imported card emits a local copy poke.
    ~|  'seer-owner-action-required'
    ?>  =(our.bol src.bol)
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
        ?>  =(/eyre sap.bol)
        =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
        ?:  authenticated.inbound-request
          %+  poke-handle-http-request:sc  eyre-id
          inbound-request
        :_  state
        %+  give-simple-payload:app  eyre-id
        (login-redirect:gen request.inbound-request)
      ==
    [cards this]
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
      ==
    =/  act=(unit action)
      ?+  wire  ~
        [%review-schedule @ @ @ ~]  `[%raise-item our.bol i.t.wire i.t.t.wire]
        [%shared-timeout @ @ ~]  `[%refresh-context-source i.t.wire]
      ==
    =?  operating.state  ?=(^ act)
      (track-agent-state our.bol now.bol u.act before observation-view:sc operating.state)
    =.  operating.state  operating.state(changed ~, failure ~)
    [cards this]
  ::
  ++  on-save  !>(state)
  ++  on-load
    |=  old=vase
    ^-  (quip card _this)
    ~|  'seer-state-shape-changed: nuke and revive %seer'
    [-:on-init this(state !<(seer-state old))]
  ++  on-leave  on-leave:def
  ++  on-peek
    |=  =path
    ^-  (unit (unit cage))
    ?+    path  (on-peek:def path)
        [%x %idempotency-epoch ~]
      ``noun+!>(epoch.operating.state)
        [%x %assistant-model @ ~]
      ``noun+!>((~(get by models.state) (slav %tas i.t.t.path)))
        [%x %login-code @ ~]
      =/  id  (slav %tas i.t.t.path)
      =/  request  (~(get by logins.state) id)
      =/  version  (~(get by versions.operating.state) [%login our.bol %root id])
      ``noun+!>([version ?~(request '' pasted-code.u.request)])
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
        |.  (need ((soft ,[context-scope @t ai-provider @ud @ud]) (cue (slav %uv i.t.t.path))))
      =/  result=json
        ?~  query  (error-json 'invalid-query' 'learning')
        =/  [scope=context-scope objective=@t provider=ai-provider limit=@ud max-bytes=@ud]  u.query
        (lookup-artifacts:memory scope objective provider limit max-bytes contexts.state evidence.state versions.operating.state learning.state)
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
      ``noun+!>(logins.state)
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
        bridge-authorized=$~(%.n ?)
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
  ==
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
    (web-get eyre-id request-line)
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
      `'Capture opened. Attach sources, then freeze its packet.'
    ==
      [[~ [%apps %seer %actions %start-change ~]] ~]
    (apply-web-action eyre-id [%start-change (slav %tas (form-got fields 'change-id'))] [%inbox ~] `'Planning queued.')
      [[~ [%apps %seer %actions %prepare-capture ~]] ~]
    =/  id  (slav %tas (form-got fields 'capture'))
    =/  model  (~(got by models.state) (slav %tas (form-got fields 'model')))
    %:  apply-web-action  eyre-id
      [%prepare-capture id model (form-selections fields [%capture id]) (slav %ud (form-got fields 'max-bytes')) (slav %ud (form-got fields 'excerpt-bytes'))]
      [%inbox ~]
      `'Capture packet frozen. Inspect exact provider input.'
    ==
      [[~ [%apps %seer %actions %rename-context-source ~]] ~]
    (apply-web-action eyre-id [%rename-context-source (slav %tas (form-got fields 'context-id')) (form-got fields 'label')] (form-return fields) `'Source renamed.')
      [[~ [%apps %seer %actions %set-context-egress ~]] ~]
    =/  providers=(set ai-provider)  ~
    =?  providers  =('1' (form-got fields 'codex'))  (~(put in providers) %codex)
    =?  providers  =('1' (form-got fields 'claude'))  (~(put in providers) %claude)
    (apply-web-action eyre-id [%set-context-egress (slav %tas (form-got fields 'context-id')) providers] (form-return fields) `'Source egress policy updated.')
      [[~ [%apps %seer %actions %cancel-work ~]] ~]
    =/  key=entity-key
      %-  need
      %-  (soft entity-key)
      [(slav %tas (form-got fields 'work-kind')) (slav %p (form-got fields 'work-owner')) (slav %tas (form-got fields 'work-scope')) (slav %tas (form-got fields 'work-id'))]
    (apply-web-action eyre-id [%cancel-work key] (form-return fields) `'Work cancelled. Late worker results are fenced.')
      [[~ [%apps %seer %actions %archive-orphan-contexts ~]] ~]
    (apply-web-action eyre-id [%archive-orphan-contexts ~] [%inbox ~] `'Orphan sources archived. History is retained.')
      [[~ [%apps %seer %actions %collect-retained ~]] ~]
    (apply-web-action eyre-id [%collect-retained ~] [%inbox ~] `'Unused retained evidence collected.')
      [[~ [%apps %seer %actions %retire-operation-epoch ~]] ~]
    (apply-web-action eyre-id [%retire-operation-epoch ~] [%inbox ~] `'Operation epoch retired. Reload forms before new commands.')
      [[~ [%apps %seer %actions %purge-evidence ~]] ~]
    (apply-web-action eyre-id [%purge-evidence (silt ~[(slav %ux (form-got fields 'snapshot-ref'))])] [%inbox ~] `'Evidence purged; dependent retained text is unavailable.')
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
      `'Capture history removed.'
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
      `'Draft created. Attach evidence, then start planning.'
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
      `'Change request rejected.'
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
      `'Source recorded. Inspect its acquisition status.'
    ==
  ::
      [[~ [%apps %seer %actions %remove-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    %:  apply-web-action
      eyre-id
      [%remove-context-source context-id]
      (form-return fields)
      `'Context removed from future prompts.'
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
          (slav %ud (form-got fields 'max-bytes'))
          (slav %ud (form-got fields 'excerpt-bytes'))
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
    =/  request-id=@tas
      ?:(=(%claude provider) %logout-claude %logout-codex)
    %:  apply-web-action
      eyre-id
      [%request-login request-id provider]
      [%inbox ~]
      ~
    ==
  ::
      [[~ [%apps %seer %actions %submit-login-code ~]] ~]
    =/  login-id  (slav %tas (form-got fields 'login-id'))
    =/  code      (form-got fields 'code')
    =/  target-page=page:index
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
  ?~  epoch  (respond-page eyre-id page `'Missing or invalid operation epoch. Reload before trying again.')
  ?.  ?&(!=('' operation) (bounded-text:ev operation 128))
    (respond-page eyre-id page `'Missing or invalid operation identity. Reload before trying again.')
  =/  cmd  (make-command u.epoch operation act)
  =^  action-cards  state  (apply-command(operator-authorized %.y) cmd)
  =/  receipt  (operation-receipt-at:effects operating.state u.epoch operation `digest.cmd)
  =.  notice
    ?:  =(%ok status.receipt)
      ?:  =(%no-change reason.receipt)  `'No change was needed.'
      notice
    `(crip "{(trip status.receipt)}: {(trip reason.receipt)}. Inspect the operation receipt before a new attempt.")
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
    logins.state
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
++  prepare-library-packet
  |=  act=action
  ^-  (quip card _state)
  ?>  ?=(%prepare-change-packet -.act)
  =/  request  (~(get by changes.state) id.act)
  ?~  request  (fail-action %blocked %change-not-found)
  =/  key=entity-key  [%change our.bol %root id.act]
  =/  job  (~(get by jobs.operating.state) key)
  ?~  job  (fail-action %blocked %work-not-found)
  ?.  ?&  =(%working status.u.request)
          =(worker.act worker.u.request)
          =(%none checkpoint.u.job)
          ?=(~ packet.u.request)
      ==
    (fail-action %blocked %packet-already-frozen)
  ?:  (gth (lent (scag 129 observations.act)) 128)
    (fail-action %budget-exhausted %observation-limit)
  ?.  (bounded-text:ev read-report.act 16.384)
    (fail-action %invalid %invalid-read-report)
  =/  report  (de:json:html read-report.act)
  ?.  ?=([~ %o *] report)  (fail-action %invalid %invalid-read-report)
  =/  complete  (~(get by p.u.report) 'complete')
  =/  omissions  (~(get by p.u.report) 'omissions')
  =/  scope  (~(get by p.u.report) 'scope')
  ?.  ?&  ?=([~ %b *] complete)
          ?=([~ %a *] omissions)
          =(`s+?:(=(%library target.u.request) 'local-library' 'not-applicable') scope)
      ==
    (fail-action %invalid %invalid-read-report)
  ?:  ?|  (gth (lent (scag 129 p.u.omissions)) 128)
          ?&(p.u.complete !=(~ p.u.omissions))
      ==
    (fail-action %invalid %invalid-read-report)
  =/  observed  (malt (turn observations.act |=(fence=entity-precondition [key.fence fence])))
  ?.  =((lent observations.act) (lent ~(tap by observed)))
    (fail-action %invalid %duplicate-observation)
  =/  observations  ~(val by observed)
  =/  valid
    %+  levy  observations
    |=  fence=entity-precondition
    ?&  =(our.bol owner.key.fence)
        ?=(?(%stack %card) kind.key.fence)
        ?|(!=(%stack kind.key.fence) =(%root scope.key.fence))
        (fence-matches:effects fence (~(get by versions.operating.state) key.fence))
        =((entity-present:effects key.fence stacks.state) ?~(seen.fence %.n present.u.seen.fence))
    ==
  ?.  valid  (fail-action %conflict %stale-observation)
  =/  coverage=[complete=? value=json]
    ?:  =(%desk target.u.request)  [%.y ~]
    =/  stack-index
      (fall (~(get by read-indexes.operating.state) [%stack `our.bol ~ ~ ~]) *agent-read-index)
    =/  card-index
      (fall (~(get by read-indexes.operating.state) [%card `our.bol ~ ~ ~]) *agent-read-index)
    =/  seen=[stacks=@ud cards=@ud]
      =/  remaining  observations
      =/  found=[stacks=@ud cards=@ud]  [0 0]
      |-
      ?~  remaining  found
      =/  fence  i.remaining
      ?.  ?&(content.fence ?~(seen.fence %.n present.u.seen.fence))
        $(remaining t.remaining)
      =?  found  =(%stack kind.key.fence)  found(stacks +(stacks.found))
      =?  found  =(%card kind.key.fence)  found(cards +(cards.found))
      $(remaining t.remaining)
    =/  full=?  ?&(=(total.stack-index stacks.seen) =(total.card-index cards.seen))
    :-  full
    %-  pairs:enjs:format
    :~  ['scope' s+'local-library']
        ['owner' s+(scot %p our.bol)]
        ['complete' b+full]
        ['stack_count' (numb:enjs:format total.stack-index)]
        ['observed_stack_count' (numb:enjs:format stacks.seen)]
        ['unobserved_stack_count' (numb:enjs:format (sub total.stack-index stacks.seen))]
        ['card_count' (numb:enjs:format total.card-index)]
        ['observed_card_count' (numb:enjs:format cards.seen)]
        ['unobserved_card_count' (numb:enjs:format (sub total.card-index cards.seen))]
    ==
  ?:  ?&(p.u.complete !complete.coverage)
    (fail-action %blocked %incomplete-library-observation)
  =/  front
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['observations' [%a (turn observations library-observation)]]
        ['read_report' u.report]
        ['source_coverage' value.coverage]
    ==
  ?:  (gth (met 3 front) 65.536)  (fail-action %budget-exhausted %observation-byte-limit)
  =/  req=packet-request
    %*  .  *packet-request
      work           key
      attempt        attempt.u.job
      scope          [%change id.act]
      profile        profile.u.request
      mode           target.u.request
      objective      prompt.u.request
      front          front
      selections     (complete-selections [%change id.act] selections.act)
      max-bytes      max-bytes.act
      excerpt-bytes  excerpt-bytes.act
    ==
  =/  built  (build-packet:ev our.bol now.bol req contexts.state evidence.state)
  =.  evidence.state  store.built
  =/  retained=(unit @ux)
    ?:((~(has by packets.evidence.state) id.packet.built) `id.packet.built ~)
  =.  changes.state
    (~(put by changes.state) id.act u.request(packet retained, scope-preconditions observations, updated-at now.bol))
  ?^  blocked.packet.built  (fail-action %blocked u.blocked.packet.built)
  =/  next
    %=  u.job
      packet         retained
      packet-digest  `prompt-digest.packet.built
      prompt-version  prompt-version.packet.built
      schema-version  schema-version.packet.built
      input-bytes    prompt-bytes.packet.built
      checkpoint     %context-frozen
    ==
  =.  state  (put-work key next)
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
  ?.  =(u.profile(worker '', registered-at 0) profile.question(worker '', registered-at 0))
    (block-question question %model-unavailable)
  =.  question
    %=  question
      title         title.content.u.current
      front         front.content.u.current
      back          back.content.u.current
      worker        ''
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
    %issue-bridge-nonce     %.y
    %bridge-action          %.y
  ==
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
  =/  semantic=action
    ?.  ?=(%bridge-action -.payload.cmd)  payload.cmd
    (fall ((soft action) payload.payload.cmd) payload.cmd)
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
      authority   ?:(?=(%bridge-action -.payload.cmd) %worker ?:(operator-authorized %operator %planner))
      work        (work-key our.bol semantic)
      revision    revision.operating.state
      at          now.bol
    ==
  =/  result=(each (quip card _state) tang)
    ?.  ?&  =(seer-schema-version schema.cmd)
            =(digest.cmd (shax (jam payload.cmd)))
        ==
      [%& (fail-action %invalid %invalid-command)]
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
          !?=(?(%archive-orphan-contexts %collect-retained %purge-evidence %set-bridge-capability %retire-operation-epoch) -.semantic)
      ==
    =.  state  original
    (retain-receipt receipt(status %budget-exhausted, reason %affected-limit) ~)
  =/  failure  failure.operating.state
  =/  no-change
    ?&  ?=(~ keys)
        ?=(~ moves)
        =(original(operating *agent-state, bridge-nonces ~) state(operating *agent-state, bridge-nonces ~))
        !?=(?(%issue-bridge-nonce %retire-operation-epoch %set-bridge-capability) -.semantic)
    ==
  =?  failure  ?&(?=(~ failure) no-change)
    ?:  ?=(?(%archive-orphan-contexts %collect-retained %checkpoint-work %set-context-egress %update-review %read %replace-assistant-models) -.semantic)
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
  ?.  ?|(bridge-authorized ?=(~ (worker-request act)))
    (fail-action %unauthorized %paired-bridge-required)
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
      %schedule-item
    [~ state]
      %raise-item
    =/  stack  (~(got by stacks) stak.act)
    =/  =item  (~(got by items.stack) item.act)
    =<  abet
    %.  item
    %~  add-review-item  stack-emit  stack
      %copy-stack
    =/  their-stack=stack
      (~(got by stack-subs) [owner.act stak.act])
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
      %read
    [~ state]
      %update-review
    =<  abet  update-review:stack-emit
      %import
    =/  =wire  /import/(scot %p who.act)/[stack.act]
    :_  state
    [%pass wire %agent [who.act %seer] %watch /stack/[stack.act]]~
      %import-file
    (import-from-file path.act)
      %set-bridge-capability
    ?.  ?|  =('' secret.act)
            ?&((gte (met 3 secret.act) 32) (bounded-text:ev secret.act 4.096))
        ==
      (fail-action %invalid %invalid-bridge-capability)
    =.  bridge-secret.state  secret.act
    =.  bridge-nonces.state  ~
    =.  secret-revision.operating.state  +(secret-revision.operating.state)
    (fence-workers %capability-rotated)
      %retire-operation-epoch
    =^  moves  state  (fence-workers %epoch-retired)
    =.  operating.state
      operating.state(epoch (max now.bol +(epoch.operating.state)), receipts ~, receipt-count 0, secret-revision +(secret-revision.operating.state))
    [moves state]
      %checkpoint-work
    =/  job  (~(get by jobs.operating.state) work.act)
    ?~  job  (fail-action %blocked %work-not-found)
    =/  next  u.job
    ?:  =(stage.act checkpoint.next)  [~ state]
    ?:  =(%context-frozen stage.act)
      =/  error  (work-input-error work.act next)
      ?^  error  (fail-action %blocked u.error)
      ?.  =(%none checkpoint.next)  (fail-action %blocked %checkpoint-order)
      [~ (put-work work.act next(checkpoint stage.act))]
    ?:  =(%provider-started stage.act)
      ?.  ?|  =(%context-frozen checkpoint.next)
              ?&  !?=(?(%question %change) kind.work.act)
                  =(%none checkpoint.next)
              ==
          ==
        (fail-action %blocked %checkpoint-order)
      =/  error  (work-input-error work.act next)
      ?^  error  (fail-action %blocked u.error)
      ?.  (lth invocations.next max-invocations.next)
        (fail-action %budget-exhausted %invocation-limit)
      [~ (put-work work.act next(checkpoint stage.act, invocations +(invocations.next)))]
    ?:  =(%output-received stage.act)
      ?.  =(%provider-started checkpoint.next)  (fail-action %blocked %checkpoint-order)
      [~ (put-work work.act next(checkpoint stage.act))]
    (fail-action %blocked %source-owned-checkpoint)
      %heartbeat-work
    =/  job  (~(get by jobs.operating.state) work.act)
    ?~  job  (fail-action %blocked %work-not-found)
    ?~  deadline.u.job  (fail-action %blocked %deadline-unavailable)
    =/  until  (min (add now.bol ~m2) u.deadline.u.job)
    [~ (put-work work.act u.job(lease-until `until))]
      %recover-work
    =/  job  (~(get by jobs.operating.state) work.act)
    ?~  job  (fail-action %blocked %work-not-found)
    ?:  ?=(?(%provider-started %output-received) checkpoint.u.job)
      (stop-work work.act %outcome-unknown %.n)
    (stop-work work.act %lease-recovered %.y)
      %cancel-work
    ?.  =(our.bol owner.work.act)  (fail-action %unauthorized %wrong-owner)
    =/  job  (~(get by jobs.operating.state) work.act)
    ?~  job  (fail-action %blocked %work-not-found)
    ?.  ?=(?(%queued %running %blocked) execution.u.job)
      (fail-action %blocked %work-already-settled)
    (stop-work work.act %cancelled %.n)
      %purge-evidence
    (purge-retained snapshots.act)
      %collect-retained
    collect-retained
      %bridge-action
    =/  inner  ((soft action) payload.act)
    ?~  inner  (fail-action %invalid %invalid-worker-action)
    =/  request  (worker-request u.inner)
    ?~  request  (fail-action %unauthorized %worker-action-required)
    ?.  =(worker.act worker.u.request)  (fail-action %unauthorized %worker-mismatch)
    ?>  ?=(^ fields.u.request)
    =/  fields
      %+  welp
        ~['2' (scot %da acting-epoch) acting-operation (decimal-text attempt.act) (scot %ux lease.act)]
      t.fields.u.request
    ?.  (bridge-proof-valid -.u.inner id.u.request worker.act fields nonce.act proof.act)
      (fail-action %unauthorized %invalid-bridge-proof)
    =/  error  (worker-authority u.inner worker.act attempt.act lease.act)
    ?^  error  (fail-action %blocked u.error)
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =^  moves  state  (poke-seer-action(bridge-authorized %.y) u.inner)
    =/  key  (work-key our.bol u.inner)
    ?~  key  [moves state]
    =/  job  (~(get by jobs.operating.state) u.key)
    ?~  job  [moves state]
    =/  output  (publication-bytes u.inner)
    =?  state  ?&(?=(^ output) ?=(~ failure.operating.state))
      (put-work u.key u.job(consumed-output-bytes u.output))
    =/  failed=(unit @tas)
      ?+  -.u.inner  ~
        %fail-card-question  `(named-failure response.u.inner)
        %fail-change        `(named-failure response.u.inner)
        %fail-context-source  `(named-failure error.u.inner)
        %fail-login         `(named-failure message.u.inner)
      ==
    =?  state  ?=(^ failed)
      =/  current  (~(got by jobs.operating.state) u.key)
      %+  put-work  u.key
        %=  current
          stop-reason  failed
          execution    ?:(=(`%outcome-unknown failed) %blocked execution.current)
          effect       ?:(=(`%outcome-unknown failed) %unknown effect.current)
          retryable    %.n
          lease-until  ~
        ==
    =?  failure.operating.state  =(`%outcome-unknown failed)
      `[%outcome-unknown %outcome-unknown]
    [moves state]
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
    ?.  =(u.profile(worker '', registered-at 0) profile.act(worker '', registered-at 0))
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
    =/  origin
      :*  capture.act
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
            (gte context-count.state 512)
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
      %claim-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%pending status.source)
            =(%web kind.source)
        ==
      [~ state]
    =.  status.source  %working
    =.  worker.source  worker.act
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    [~ state]
      %finish-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%working status.source)
            =(worker.act worker.source)
            !=(0 (met 3 content.act))
            (lte (met 3 content.act) 131.072)
            (lte (met 3 label.act) 240)
        ==
      [~ state]
    =.  label.source
      ?:(=(0 (met 3 label.act)) label.source label.act)
    (accept-context source content.act %full final-locator.act ~ %web-text)
      %fail-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%working status.source)
            =(worker.act worker.source)
            !=(0 (met 3 error.act))
            (lte (met 3 error.act) 2.048)
        ==
      [~ state]
    =.  status.source  %failed
    =.  error.source  (named-failure error.act)
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    (fail-action %blocked (named-failure error.act))
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
        [~ state(contexts (~(put by contexts.state) id.act source(status %pending, worker '', error '', updated-at now.bol)))]
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
    =.  worker.source  ''
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
    =/  rows  profiles.act
    =/  catalog=(map @tas assistant-model)  ~
    |-
    ?~  rows  [~ state(models catalog)]
    =/  profile  i.rows
    ?.  ?&  !=(0 id.profile)
            (bounded-text:ev id.profile 128)
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
    =.  catalog  (~(put by catalog) id.profile profile(worker worker.act, registered-at now.bol))
    $(rows t.rows)
      %claim-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  =(%pending status.question)  [~ state]
    =/  error  (question-input-error question)
    ?^  error  (block-question question u.error)
    =.  status.question  %working
    =.  worker.question  worker.act
    =.  updated-at.question  now.bol
    =.  questions.state
      (~(put by questions.state) id.act question)
    [~ state]
      %answer-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&  =(%working status.question)
            =(%ask mode.question)
            =(worker.act worker.question)
        ==
      [~ state]
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
    [~ state]
      %apply-card-edit
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&  =(%working status.question)
            =(%edit mode.question)
            =(worker.act worker.question)
            =(our.bol owner.question)
            !=(0 (met 3 title.act))
            !=(0 (met 3 front.act))
            !=(0 (met 3 back.act))
            !=(0 (met 3 response.act))
        ==
      [~ state]
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
    [edit-cards state]
      %fail-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  ?&  =(%working status.question)
            =(worker.act worker.question)
        ==
      [~ state]
    =.  status.question  %failed
    =.  response.question  (named-failure response.act)
    =.  updated-at.question  now.bol
    =.  questions.state
      (~(put by questions.state) id.act question)
    (fail-action %blocked (named-failure response.act))
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
    ?.  =(u.profile(worker '', registered-at 0) profile.act(worker '', registered-at 0))
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
      %claim-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  =(%pending status.request)  [~ state]
    =.  status.request      %working
    =.  worker.request      worker.act
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %prepare-change-packet
    (prepare-library-packet act)
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
    ?.  ?&  =(%working status.request)
            =(worker.act worker.request)
            !=('' summary.act)
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
    [~ state]
      %fail-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&  =(%working status.request)
            =(worker.act worker.request)
        ==
      [~ state]
    =.  status.request      %failed
    =.  response.request    (named-failure response.act)
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    (fail-action %blocked (named-failure response.act))
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
    =.  worker.request      ''
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
    ::  the ship never runs a provider login itself; it only queues the
    ::  request for the local bridge. one live request per provider.
    ::
    =/  existing=(list [@tas login-request])
      %+  skim  ~(tap by logins.state)
      |=  [id=@tas req=login-request]
      =(provider.act provider.req)
    =/  active=?
      %+  lien  existing
      |=  [id=@tas req=login-request]
      ?=(?(%pending %working %challenge) status.req)
    ?:  active  [~ state]
    ::  settled requests for this provider make way for the new one
    ::
    =.  logins.state
      %-  malt
      %+  skip  ~(tap by logins.state)
      |=  [id=@tas req=login-request]
      =(provider.act provider.req)
    =/  req=login-request
      [id.act provider.act %pending '' '' '' '' '' now.bol now.bol]
    =.  logins.state  (~(put by logins.state) id.act req)
    [~ state]
      %issue-bridge-nonce
    ?.  ?&(!=('' nonce.act) (bounded-text:ev nonce.act 128))
      (fail-action %invalid %invalid-nonce)
    =.  bridge-nonces.state
      %-  malt
      %+  skim  ~(tap by bridge-nonces.state)
      |=  [old-nonce=@t issued=@da]
      (lte (sub now.bol issued) ~m5)
    ?:  ?&  !(~(has by bridge-nonces.state) nonce.act)
            (gte (lent ~(tap by bridge-nonces.state)) 512)
        ==
      (fail-action %budget-exhausted %nonce-limit)
    =.  bridge-nonces.state
      (~(put by bridge-nonces.state) nonce.act now.bol)
    [~ state]
      %claim-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  =(%pending status.req)  [~ state]
    =/  next=login-request
      :*  id.req  provider.req  %working
          auth-url.req  user-code.req  pasted-code.req  message.req
          worker.act  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %post-login-challenge
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  ?&  =(%working status.req)
            =(worker.act worker.req)
        ==
      [~ state]
    ?.  ?&  !=('' auth-url.act)
            (valid-auth-url provider.req auth-url.act)
            (bounded-text:ev auth-url.act 2.048)
            (bounded-text:ev user-code.act 1.024)
        ==
      (fail-action %invalid %invalid-login-challenge)
    =/  next=login-request
      :*  id.req  provider.req  %challenge
          auth-url.act  user-code.act  pasted-code.req  message.req
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
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
    =/  next=login-request
      :*  id.req  provider.req  %challenge
          auth-url.req  user-code.req  code.act  message.req
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %consume-login-code
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  ?&  =(%challenge status.req)
            =(worker.act worker.req)
        ==
      [~ state]
    =/  version  (~(get by versions.operating.state) [%login our.bol %root id.act])
    ?~  version  (fail-action %conflict %login-version-unavailable)
    ?.  ?&(present.u.version =(content-revision.act content-revision.u.version))
      (fail-action %conflict %login-code-changed)
    ?:  =('' pasted-code.req)  (fail-action %blocked %delivery-unavailable)
    =/  next=login-request
      :*  id.req  provider.req  %challenge
          auth-url.req  user-code.req  ''  message.req
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %finish-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?:  =(%done status.req)  [~ state]
    ?.  ?&  ?|(=(%working status.req) =(%challenge status.req))
            =(worker.act worker.req)
        ==
      [~ state]
    =/  next=login-request
      :*  id.req  provider.req  %done
          ''  ''  ''  ''
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
      %fail-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?:  ?|(=(%done status.req) =(%failed status.req))  [~ state]
    ?.  =(worker.act worker.req)  [~ state]
    =/  next=login-request
      :*  id.req  provider.req  %failed
          ''  ''  ''  (named-failure message.act)
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    (fail-action %blocked (named-failure message.act))
      %retry-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  =(%failed status.req)  [~ state]
    =/  next=login-request
      :*  id.req  provider.req  %pending
          ''  ''  ''  ''  ''
          created-at.req  now.bol
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
      :*  id.req  provider.req  %failed
          ''  ''  ''  'Cancelled.'
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
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
      worker        ''
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
      worker      ''
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
    source(status %failed, error 'evidence-purged', worker '', generation +(generation.source), updated-at now.bol)
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
++  publication-bytes
  |=  act=action
  ^-  (unit @ud)
  ?+  -.act  ~
    %answer-card-question  `(add (met 3 response.act) (citation-bytes:memory citations.act))
    %apply-card-edit
      `(add (roll (turn ~[title.act front.act back.act response.act] |=(text=@t (met 3 text))) add) (citation-bytes:memory citations.act))
    %finish-change
      `(add (add (met 3 summary.act) (met 3 artifact.act)) (add (roll (turn operations.act operation-bytes:effects) add) (citation-bytes:memory citations.act)))
    %finish-context-source  `(met 3 content.act)
    %finish-login  `0
  ==
::
++  named-failure
  |=  raw=@t
  ^-  @tas
  ?+  raw  %worker-failed
    %'PROVIDER_UNSUPPORTED'      %provider-unsupported
    %'OUTCOME_UNKNOWN'           %outcome-unknown
    %'PROVIDER_UNAVAILABLE'      %provider-unavailable
    %'INVALID_PROVIDER_OUTPUT'   %invalid-provider-output
    %'SOURCE_FETCH_FAILED'       %source-fetch-failed
    %'LOGIN_FAILED'              %login-failed
    %'PACKET_BLOCKED'            %packet-blocked
    %'PACKET_MISMATCH'           %packet-mismatch
    %'WORK_DEADLINE'             %work-deadline
    %'INVALID_BOUNDED_QUERY'       %invalid-bounded-query
    %'INCOMPLETE_LIBRARY_METADATA'  %incomplete-library-metadata
    %'INVALID_LIBRARY_READ_REPORT'  %invalid-library-read-report
    %'INCOMPLETE_LIBRARY_READ'     %incomplete-library-read
    %'LIBRARY_READ_REPORT_LIMIT'   %library-read-report-limit
    %'NO_SUPPORTED_CANDIDATE'      %no-supported-candidate
  ==
::
++  fence-workers
  |=  reason=@tas
  ^-  (quip card _state)
  =/  rows  ~(tap by jobs.operating.state)
  |-
  ?~  rows  [~ state]
  =/  [key=entity-key job=work-record]  i.rows
  ?.  ?=(?(%running %queued) execution.job)  $(rows t.rows)
  =/  stop  ?:(?=(?(%provider-started %output-received) checkpoint.job) %outcome-unknown reason)
  =^  ignored  state  (stop-work key stop %.n)
  =.  failure.operating.state  ~
  $(rows t.rows)
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
++  worker-authority
  |=  [act=action worker=@t attempt=@ud lease=@ux]
  ^-  (unit @tas)
  ?.  ?&(!=('' worker) (bounded-text:ev worker 128))
    `%invalid-worker
  ?:  =(%replace-assistant-models -.act)
    ?:  ?&(=(0 attempt) =(0 lease))  ~
    `%catalog-claim-required
  =/  key  (work-key our.bol act)
  ?~  key  `%work-required
  ?.  ?&(=(our.bol owner.u.key) =(%root scope.u.key))  `%work-scope-mismatch
  =/  job  (~(get by jobs.operating.state) u.key)
  ?~  job  `%work-not-found
  ?:  (claim-action act)
    ?.  ?&(=(0 attempt) =(0 lease) =(%queued execution.u.job))  `%work-not-queued
    =/  profile=(unit assistant-model)
      ?+  kind.u.key  ~
        %question
          =/  req  (~(get by questions.state) id.u.key)
          ?~(req ~ `profile.u.req)
        %change
          =/  req  (~(get by changes.state) id.u.key)
          ?~(req ~ `profile.u.req)
      ==
    ?~  profile  ~
    =/  current  (~(get by models.state) id.u.profile)
    ?~  current  `%model-unavailable
    ?.  =(u.current(worker '', registered-at 0) u.profile(worker '', registered-at 0))
      `%model-changed
    ~
  ?.  ?&  =(%running execution.u.job)
          =(worker worker.u.job)
          =(attempt attempt.u.job)
          =(lease lease.u.job)
          !=(0 lease)
          =(secret-revision.operating.state secret-revision.u.job)
      ==
    `%work-fenced
  ?~  lease-until.u.job  `%lease-unavailable
  ?:  =(%recover-work -.act)
    ?:  (gte now.bol u.lease-until.u.job)  ~
    `%lease-not-expired
  ?.  (lth now.bol u.lease-until.u.job)  `%lease-expired
  ?~  deadline.u.job  `%deadline-unavailable
  ?.  (lth now.bol u.deadline.u.job)  `%deadline-expired
  ::  Failure publication must remain possible after an input is revoked.
  ?:  ?=(?(%fail-card-question %fail-change %fail-context-source %fail-login %heartbeat-work) -.act)  ~
  =/  output  (publication-bytes act)
  ?^  output
    ?.  =(%output-received checkpoint.u.job)  `%output-checkpoint-required
    ?:  ?&  ?=(%finish-change -.act)
            (gth (lent (scag +(max-operations.u.job) operations.act)) max-operations.u.job)
        ==
      `%operation-limit
    ?:  (gth u.output max-output-bytes.u.job)  `%output-budget-exhausted
    (work-input-error u.key u.job)
  ?:  ?=(?(%post-login-challenge %consume-login-code) -.act)
    ?:  =(%provider-started checkpoint.u.job)  ~
    `%provider-checkpoint-required
  ~
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
          =(u.profile(worker '', description '', registered-at *@da) profile.request.u.packet)
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
        state(questions (~(put by questions.state) id.key u.req(status ?:(requeue %pending %failed), worker '', response reason, updated-at now.bol)))
      %change
        =/  req  (~(get by changes.state) id.key)
        ?~  req  state
        =/  next  u.req(status ?:(requeue %pending %failed), worker '', response reason, updated-at now.bol)
        =?  next  requeue  next(packet ~, scope-preconditions ~, preconditions ~, plan ~)
        state(changes (~(put by changes.state) id.key next))
      %context
        =/  req  (~(get by contexts.state) id.key)
        ?~  req  state
        state(contexts (~(put by contexts.state) id.key u.req(status ?:(requeue %pending %failed), worker '', error reason, generation +(generation.u.req), updated-at now.bol)))
      %login
        =/  req  (~(get by logins.state) id.key)
        ?~  req  state
        state(logins (~(put by logins.state) id.key u.req(status ?:(requeue %pending %failed), worker '', auth-url '', user-code '', pasted-code '', message reason, updated-at now.bol)))
    ==
  =/  tracker  (agent-tracker our.bol now.bol before observation-view operating.state)
  =.  operating.state  (one:tracker key)
  =/  next
    %=  u.job
      execution    ?:(requeue %queued ?:(=(%outcome-unknown reason) %blocked %cancelled))
      effect       ?:(=(%outcome-unknown reason) %unknown effect.u.job)
      worker       ''
      lease-until  ~
      lease        0x0
      stop-reason  `reason
      retryable    requeue
    ==
  =.  state  (put-work key next)
  ?:  =(%outcome-unknown reason)  (fail-action %outcome-unknown reason)
  [~ state]
::
++  bridge-proof-valid
  |=  [action=@tas id=@tas worker=@t fields=(list @t) nonce=@t proof=@]
  ^-  ?
  ?:  =(0 bridge-secret.state)  %.n
  =/  issued=(unit @da)  (~(get by bridge-nonces.state) nonce)
  ?~  issued  %.n
  ?.  (lte (sub now.bol u.issued) ~m5)  %.n
  =/  parts=(list @t)
    (welp ~['seer-bridge-v2' action id worker nonce] fields)
  =/  payload=@t
    %-  crip
    %-  zing
    %+  turn  parts
    |=(part=@t "{(trip (decimal-text (met 3 part)))}:{(trip part)}")
  .=  proof
  %+  hmac-sha256t:hmac:crypto  bridge-secret.state
  payload
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
        [%set-bridge-capability @]
      =/  act=action  [%set-bridge-capability `@t`+.a]
      (apply-command (make-command epoch.operating.state (local-operation act) act))
        %clear-bridge-capability
      =/  act=action  [%set-bridge-capability '']
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
