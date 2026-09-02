/-  mcp, *seer
/+  *server, *seer, *seer-json, *seer-mcp, default-agent, verb, dbug, agentio
/=  index  /app/seer/index
/*  seer-tile  %png  /lib/web/seer-tile/png
::
|%
+$  versioned-state
  $%  [%0 state-zero]
      [%1 state-one]
      [%2 state-two]
      [%3 state-two]
      [%4 state-three]
      [%5 state-four]
      [%6 state-five]
      [%7 state-six]
      [%8 state-seven]
      [%9 state-eight]
      [%10 state-nine]
      [%11 state-ten]
      [%12 state-eleven]
      [%13 state-twelve]
      [%14 state-thirteen]
  ==
::
+$  state-zero
  $:  pubs=(map @tas stack)
      paths=(list path)
      subs=(map [ship @tas] stack)
      review=(set [who=ship stack=@tas item=@tas])
  ==
::
+$  state-one
  $:  stacks=(map @tas stack-1)
      paths=(list path)
      stack-subs=(map [ship @tas] stack-1)
  ==
::
+$  state-two
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
  ==
::
+$  state-three
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
  ==
+$  state-four
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question-five)
  ==
+$  state-five
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question-six)
  ==
+$  state-six
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
  ==
+$  state-seven
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
      changes=(map @tas change-request)
  ==
::
+$  state-eight
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
      changes=(map @tas change-request)
      logins=(map @tas login-request)
  ==
::
+$  state-nine
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
      captures=(map @tas capture)
      provenance=(map [@tas @tas] provenance)
      questions=(map @tas card-question)
      models=(map @tas assistant-model)
      changes=(map @tas change-request)
      logins=(map @tas login-request)
      bridge-capability=@
  ==
::
+$  state-ten
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
  ==
+$  state-eleven
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
      question-contexts=(map @tas (list @tas))
  ==
+$  state-twelve
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
      question-contexts=(map @tas (list @tas))
      shared-context=(map path shared-entry)
      shared-manifest-rev=@ud
      outstanding-keens=(map @tas keen-track)
      remote-manifests=(map @p remote-manifest)
      recent-clay=(list @t)
  ==
+$  state-thirteen
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
      question-contexts=(map @tas (list @tas))
      shared-context=(map path shared-entry)
      shared-manifest-rev=@ud
      outstanding-keens=(map @tas keen-track)
      remote-manifests=(map @p remote-manifest)
      recent-clay=(list @t)
      context-revs=(map @tas @ud)
  ==
+$  card-question-five
  $:  id=@tas
      owner=@p
      stack=@tas
      card=@tas
      title=@t
      front=@t
      back=@t
      prompt=@t
      provider=ai-provider
      created-at=@da
      status=question-status
      worker=@t
      response=@t
      updated-at=@da
  ==
+$  card-question-six
  $:  id=@tas
      owner=@p
      stack=@tas
      card=@tas
      title=@t
      front=@t
      back=@t
      mode=assistant-mode
      prompt=@t
      provider=ai-provider
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
+$  card  card:agent:gall
::
--
::
=|  [%14 state-thirteen]
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
    :_  this
    :~
      [%pass /bind/seer %arvo %e %connect [~ /seer] dap.bol]
      [%pass /bind/seer %arvo %e %connect [~ /apps/seer] dap.bol]
    ==

  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    =^  cards  state
      ?+    mark  (on-poke:def mark vase)
          %noun
        (poke-noun:sc !<(* vase))
          %sign-arvo
        (poke-sign-arvo:sc !<(sign-arvo vase))
          %seer-action
        (poke-seer-action:sc !<(action vase))
          %handle-http-request
        =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
        ?:  authenticated.inbound-request
          (poke-handle-http-request:sc eyre-id inbound-request)
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
        [%seertile *]       (peer-seertile:sc t.path)
        [%seer-primary *]   [~ state]
        [%http-response *]  [~ state]
        [%stack @ ~]  (peer-stack:sc i.t.path)
        [%shared-context ~]  serve-shared-manifest:sc
        [%shared-context %file @ *]  (serve-shared-file:sc t.t.path)
      ==
    [cards this]
  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
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
      ?.  ?=([%shared-fetch @ ~] wire)  (on-agent:def wire sign)
      ?~  p.sign  [~ this]
      =^  cards  state
        (fail-shared-fetch:sc i.t.wire 'That ship shares nothing at this path.')
      [cards this]
        %kick
      ?:  ?=([%shared-fetch @ ~] wire)
        =^  cards  state
          (fail-shared-fetch:sc i.t.wire 'The ship disconnected before replying.')
        [cards this]
      ?:  ?=([%shared-manifest @ ~] wire)
        =^  cards  state
          (fail-remote-manifest:sc (slav %p i.t.wire))
        [cards this]
      ?:  ?=([%import @ @ ~] wire)
        =/  who   (slav %p i.t.wire)
        =/  name  i.t.t.wire
        ?.  (~(has by stack-subs.state) [who name])  [~ this]
        :_  this
        [%pass wire %agent [who %seer] %watch /stack/[name]]~
      :_  this
      ?+  wire  ~
        [%primary @ ~]  ~[[%pass /seer-primary %agent [our.bol %seer] %watch /seer-primary]]
      ==
        %fact
      ?+    wire  (on-agent:def wire sign)
          [%shared-fetch @ ~]
        =^  cards  state  (take-shared-fetch:sc i.t.wire cage.sign)
        [cards this]
          [%shared-manifest @ ~]
        =^  cards  state
          (take-remote-manifest:sc (slav %p i.t.wire) cage.sign)
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
          =^  cards  state  (handle-import-stack:sc stack)
          [cards this]
        ==
      ==
    ==
    ++  pass-through
    |=  =cage
    ^-  card
    (fact:io cage ~[wire])
  --
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =^  cards  state
      ?+  wire  (on-arvo:def wire sign-arvo)
        [%bind %seer ~]             [~ state]
        [%eyre ~]             [~ state]
        [%view-bind ~]              [~ state]
        [%review-schedule @ ~]      (wake:sc wire)
        [%review-schedule @ @ @ ~]  (wake:sc wire)
        [%import @ @ ~]             (peer-stack:sc i.t.t.wire)
        [%read %paths ~]            [~ state]
        [%shared-timeout @ ~]     (shared-fetch-timeout:sc i.t.wire)
        [%shared-manifest-timeout @ ~]  (remote-manifest-timeout:sc (slav %p i.t.wire))
      ==
    [cards this]
  ::
  ++  on-save  !>(state)
  ++  on-load
    |=  old=vase
    ^-  (quip card _this)
    =/  old-state=(each versioned-state tang)
      (mule |.(!<(versioned-state old)))
    |^
    ^-  (quip card _this)
    =/  init-cards
      :~
        [%pass /bind/seer %arvo %e %connect [~ /seer] dap.bol]
        [%pass /bind/seer %arvo %e %connect [~ /apps/seer] dap.bol]
      ==
    ?:  ?=(%| -.old-state)
      ~!  p.old-state
      [init-cards this]
    ?-  -.p.old-state
        %0
      [~ this]

        %1
      :-  init-cards
      %=  this
          state
        =/  new-stacks=(map @tas stack)
          %-  ~(rep by stacks.p.old-state)
          |=  [[key=@tas val=stack-1] out=(map @tas stack)]
          ^-  (map @tas stack)
          %+  ~(put by out)
            key
          (convert-stack-1-2 val)
        =/  new-stack-subs=(map [@p @tas] stack)
          %-  ~(run by stack-subs.p.old-state)
          |=  old-stack=stack-1
          ^-  stack
          (convert-stack-1-2 old-stack)
        [%14 new-stacks ~ new-stack-subs ~ ~ ~ ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~]
      ==
    %2
      [~ this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state ~ ~ ~ ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %3
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state ~ ~ ~ ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %4
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state ~ ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %5
      =/  new-questions=(map @tas card-question)
        %-  ~(run by questions.p.old-state)
        |=  old=card-question-five
        ^-  card-question
        :*  id.old
            owner.old
            stack.old
            card.old
            title.old
            front.old
            back.old
            %ask
            prompt.old
            (legacy-model provider.old)
            created-at.old
            status.old
            worker.old
            response.old
            ''
            ''
            ''
            updated-at.old
        ==
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state new-questions ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %6
      =/  new-questions=(map @tas card-question)
        %-  ~(run by questions.p.old-state)
        |=  old=card-question-six
        ^-  card-question
        :*  id.old
            owner.old
            stack.old
            card.old
            title.old
            front.old
            back.old
            mode.old
            prompt.old
            (legacy-model provider.old)
            created-at.old
            status.old
            worker.old
            response.old
            result-title.old
            result-front.old
            result-back.old
            updated-at.old
        ==
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state new-questions ~ ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %7
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state ~ ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %8
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state ~ '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %9
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state logins.p.old-state '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %10
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state logins.p.old-state '' ~ ~ ~ ~ 0 ~ ~ ~ ~])]
    %11
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state logins.p.old-state bridge-secret.p.old-state bridge-nonces.p.old-state ~ ~ ~ 0 ~ ~ ~ ~])]
    %12
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state logins.p.old-state bridge-secret.p.old-state bridge-nonces.p.old-state contexts.p.old-state question-contexts.p.old-state ~ 0 ~ ~ ~ ~])]
    %13
      [init-cards this(state [%14 stacks.p.old-state paths.p.old-state stack-subs.p.old-state captures.p.old-state provenance.p.old-state questions.p.old-state models.p.old-state changes.p.old-state logins.p.old-state bridge-secret.p.old-state bridge-nonces.p.old-state contexts.p.old-state question-contexts.p.old-state shared-context.p.old-state shared-manifest-rev.p.old-state outstanding-keens.p.old-state remote-manifests.p.old-state recent-clay.p.old-state ~])]
    %14
      [init-cards this(state p.old-state)]
    ==
    ++  legacy-model
      |=  provider=ai-provider
      ^-  assistant-model
      =/  codex=?  =(%codex provider)
      :*  ?:(codex %legacy-codex %legacy-claude)
          provider
          %default
          ?:(codex 'openai-codex/default' 'anthropic/default')
          'default'
          ?:(codex 'Codex default (legacy)' 'Claude default (legacy)')
          'Queued before Seer recorded an exact OMP model selector.'
          'migration'
          *@da
      ==
    ++  convert-stack-1-2
      |=  prev=stack-1
      ^-  stack
      %=    prev
          items
        %-  ~(run by items.prev)
        |=  =item-1
        ^-  item::test
        (item content.item-1 learn.item-1 ~ name.item-1)
          review-items
        %-  ~(run by review-items.prev)
        |=  =item-1
        ^-  item
         (item content.item-1 learn.item-1 ~ name.item-1)
      ==
    --
  ++  on-leave  on-leave:def
  ++  on-peek
    |=  =path
    ^-  (unit (unit cage))
    ?+  path  (on-peek:def path)
        [%x %mcp %tools ~]    ``noun+!>(tools)
        [%x %mcp %prompts ~]  ``noun+!>(prompts)
        [%x %review ~]        ``noun+!>(all-reviews)
        [%x %all ~]        ``noun+!>(stacks.state)
        [%x %ai-state ~]
      ``noun+!>(`ai-state`[stacks.state captures.state provenance.state questions.state models.state changes.state contexts.state question-contexts.state])
        [%x %logins ~]  ``noun+!>(logins.state)
        [%x %stack-subs ~]        ``noun+!>(stack-subs.state)
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
=|  [cards=(list card) stak=stack]
::
|_  bol=bowl:gall
::  +this: self
::
++  this  .
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
      [%add-item * * *]           ?:(=(our.bol who.del) `stack.del ~)
      [%add-review-item * * *]    ?:(=(our.bol who.del) `stack.del ~)
      [%delete-item * * *]        ?:(=(our.bol who.del) `stack.del ~)
      [%delete-review-item * * *]  ?:(=(our.bol who.del) `stack.del ~)
      [%update-stack * *]         ?:(=(our.bol who.del) `name.data.del ~)
      [%delete-stack * *]         ?:(=(our.bol who.del) `stack.del ~)
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
    [%pass /action %agent [our.bol %seer] %poke %seer-action !>(action)]
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
  :: the door shares one stack across its action arms.
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
      %=  emit-primary
        stack-subs  (~(put by stack-subs.state) [owner.info name.stack] stack)
      ==
    this
  ::
  ++  delete-stack
    |=  owner=@p
    ^+  this
    =?  ..emit  !=(our.bol owner)
      (emit [%pass /import/(scot %p owner)/[name.stack] %agent [owner %seer] %leave ~])
    =.  ..emit
      %.  [%delete-stack owner name.stack]
      %=  emit-primary
        stacks  ?:(=(our.bol owner) (~(del by stacks) name.stack) stacks)
        stack-subs  (~(del by stack-subs) [owner name.stack])
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
    =.  ..emit  (emit-primary [%delete-item our.bol name.stack item])
    %~  update-stack  stack-emit
    %=  stack
      items  (~(del by items.stack) item)
      review-items  (~(del by review-items.stack) item)
    ==
  ::
  ++  add-item
    |=  =item
    ^+  this
    =.  ..emit  (emit-primary [%add-item our.bol name.stack item])
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
      %=  stack
        review-items  (~(uni by review-items.stack) (my ~[[name.item item]]))
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
    =.  ..emit  (~(delete-review-item stack-emit stack) item)
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
  =/  request-line  (parse-request-line url.request.inbound-request)
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
      (rush q:(fall body.request.inbound-request *octs) yquy:de-purl:html)
    (web-post eyre-id request-line fields)
  ==
::
++  web-get
  |=  [eyre-id=@ta =request-line]
  ^-  (quip card _state)
  ?+  request-line
    (respond-payload eyre-id not-found:gen)
  ::  canonical browser routes.
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
      [[~ [%apps %seer %stacks ~]] ~]
    (respond-page eyre-id [%stacks ~] ~)
      [[~ [%apps %seer %subscriptions ~]] ~]
    (respond-page eyre-id [%subscriptions ~] ~)
      [[~ [%apps %seer %stack @t @t ~]] *]
    =/  owner  (slav %p i.t.t.t.site.request-line)
    =/  name   (slav %tas i.t.t.t.t.site.request-line)
    =/  browse  (get-arg args.request-line 'browse')
    =/  pick    (get-arg args.request-line 'pick')
    =/  remote  (get-arg args.request-line 'remote')
    ?:  &(?=(~ browse) ?=(~ pick) ?=(~ remote))
      (respond-page eyre-id [%stack owner name] ~)
    (respond-page eyre-id [%stack-browse owner name (fall browse '') (fall pick '') (fall remote '')] ~)
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
    (respond-payload eyre-id (json-response:gen (state-to-json state)))
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
    (apply-web-action eyre-id act [%stack our.bol stack-name] `'Card added.')
  ::
      [[~ [%apps %seer %actions %approve-proposal ~]] ~]
    =/  capture-id   (slav %tas (form-got fields 'capture'))
    =/  proposal-id  (slav %tas (form-got fields 'proposal'))
    =/  maybe-session  (~(get by captures.state) capture-id)
    ?~  maybe-session
      (respond-page eyre-id [%inbox ~] `'That capture is no longer available.')
    =/  maybe-draft  (~(get by proposals.u.maybe-session) proposal-id)
    ?~  maybe-draft
      (respond-page eyre-id [%inbox ~] `'That proposal is no longer available.')
    =/  maybe-stack  (~(get by stacks.state) stack.u.maybe-draft)
    ?~  maybe-stack
      (respond-page eyre-id [%inbox ~] `'The target stack does not exist. Reject the proposal, or stage a new one.')
    ?:  (~(has by items.u.maybe-stack) card.u.maybe-draft)
      (respond-page eyre-id [%inbox ~] `'That card ID is in use. Reject the proposal, or stage a new one.')
    %:  apply-web-action
      eyre-id
      [%approve-proposal capture-id proposal-id]
      [%inbox ~]
      `'Card approved and queued for review.'
    ==
  ::
      [[~ [%apps %seer %actions %reject-proposal ~]] ~]
    =/  capture-id   (slav %tas (form-got fields 'capture'))
    =/  proposal-id  (slav %tas (form-got fields 'proposal'))
    %:  apply-web-action
      eyre-id
      [%reject-proposal capture-id proposal-id]
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
    =/  target=change-target  ?:(=(%desk target-name) %desk %library)
    =/  model-id  (slav %tas (form-got fields 'model'))
    =/  maybe-profile  (~(get by models.state) model-id)
    ?~  maybe-profile
      (respond-page eyre-id [%inbox ~] `'That assistant model is unavailable. Select another model before you send the request again.')
    =/  id-suffix=tape
      %+  skim
        (trip (scot %uv (mug [now.bol target prompt model-id])))
      |=  char=@
      !=(char '.')
    =/  change-id=@tas
      `@tas`(slav %tas (crip (weld "change-" id-suffix)))
    %:  apply-web-action
      eyre-id
      [%request-change change-id target u.maybe-profile prompt]
      [%inbox ~]
      `'Change request queued for {(trip label.u.maybe-profile)}.'
    ==
  ::
      [[~ [%apps %seer %actions %apply-change ~]] ~]
    =/  change-id  (slav %tas (form-got fields 'change-id'))
    %:  apply-web-action
      eyre-id
      [%apply-change change-id]
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
      [[~ [%apps %seer %actions %add-context-source ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  card-raw    (form-got fields 'card')
    =/  card=(unit @tas)
      ?:(=(0 (met 3 card-raw)) ~ (some `@tas`(slav %tas card-raw)))
    =/  kind-name  (slav %tas (form-got fields 'kind'))
    =/  kind=context-kind
      ?+  kind-name  %note
        %clay  %clay
        %file  %file
        %web   %web
      ==
    =/  locator
      ?:  =(%web kind)  (form-got fields 'web-locator')
      (form-got fields 'locator')
    =/  submitted-content  (form-got fields 'content')
    =/  clay-loc=(unit [who=@p dek=@tas rest=path])
      ?.(=(%clay kind) ~ (parse-clay-locator locator))
    ?:  &(=(%clay kind) ?=(~ clay-loc))
      (respond-page eyre-id [%stack owner stack-name] `'Use a Clay path like /doc/notes/md or /~ship/desk/doc/notes/md.')
    =/  foreign-add=?  &(?=(^ clay-loc) !=(our.bol who.u.clay-loc))
    =/  maybe-content=(unit @t)
      ?:  foreign-add  `''
      ?:  =(%clay kind)
        =/  loaded=(each @t tang)
          (mule |.((read-clay-context locator)))
        ?:  ?=(%| -.loaded)  ~
        `p.loaded
      `submitted-content
    ?~  maybe-content
      (respond-page eyre-id [%stack owner stack-name] `'That Clay path could not be read. Check the desk and file, e.g. /~ship/base/gen/hood/hi/hoon.')
    =/  content=@t  u.maybe-content
    ?:  (gth (met 3 content) 131.072)
      (respond-page eyre-id [%stack owner stack-name] `'Context sources must be 128 KB or smaller.')
    ?:  ?&  !=(%web kind)
            !foreign-add
            =(0 (met 3 content))
        ==
      (respond-page eyre-id [%stack owner stack-name] `'This context source is empty.')
    ?:  ?&  =(%web kind)
            =(0 (met 3 locator))
        ==
      (respond-page eyre-id [%stack owner stack-name] `'Enter an HTTP or HTTPS URL to fetch.')
    =/  raw-label  (form-got fields 'label')
    =/  label=@t
      ?:  !=(0 (met 3 raw-label))  raw-label
      ?:(=(%note kind) 'Context note' locator)
    =/  id-suffix=tape
      %+  skim
        (trip (scot %uv (mug [now.bol owner stack-name card kind label locator content])))
      |=  char=@
      !=(char '.')
    =/  context-id=@tas
      `@tas`(slav %tas (crip (weld "ctx-" id-suffix)))
    %:  apply-web-action
      eyre-id
      [%add-context-source context-id owner stack-name card kind label locator content]
      [%stack owner stack-name]
      ?:(=(%web kind) `'Web source queued for the local bridge.' `'Context attached.')
    ==
  ::
      [[~ [%apps %seer %actions %remove-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%remove-context-source context-id]
      [%stack owner stack-name]
      `'Context removed from future prompts.'
    ==
  ::
      [[~ [%apps %seer %actions %retry-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%retry-context-source context-id]
      [%stack owner stack-name]
      `'Web source queued again.'
    ==
  ::
      [[~ [%apps %seer %actions %refresh-context-source ~]] ~]
    =/  context-id  (slav %tas (form-got fields 'context-id'))
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    %:  apply-web-action
      eyre-id
      [%refresh-context-source context-id]
      [%stack owner stack-name]
      `'Refreshing from the source file.'
    ==
  ::
  ::
      [[~ [%apps %seer %actions %browse-remote-manifest ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  ship-raw    (form-got fields 'ship')
    =/  who=(unit @p)  (slaw %p ship-raw)
    ?~  who
      (respond-page eyre-id [%stack owner stack-name] `'Enter a ship name like ~sampel-palnet.')
    ?:  =(our.bol u.who)
      (respond-page eyre-id [%stack owner stack-name] `'That is this ship. Use the browser above for local files.')
    %:  apply-web-action
      eyre-id
      [%fetch-remote-manifest u.who]
      [%stack-browse owner stack-name '' '' (scot %p u.who)]
      ~
    ==
      [[~ [%apps %seer %actions %share-clay-context ~]] ~]
    =/  owner       (slav %p (form-got fields 'owner'))
    =/  stack-name  (slav %tas (form-got fields 'stack'))
    =/  maybe-pax   (parse-clay-path (form-got fields 'path'))
    ?~  maybe-pax
      (respond-page eyre-id [%stack owner stack-name] `'Use a desk-first path like /base/gen/hood/hi/hoon.')
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
      (respond-page eyre-id target-page `'That assistant model is unavailable. Select another model before you send the request again.')
    =/  profile=assistant-model  u.maybe-profile
    =/  id-suffix=tape
      %+  skim
        (trip (scot %uv (mug [now.bol owner stack-name item-name mode prompt])))
      |=  char=@
      !=(char '.')
    =/  question-id=@tas
      `@tas`(slav %tas (crip (weld "q-" id-suffix)))
    =/  context-ids=(list @tas)
      %+  murn  ~(tap by contexts.state)
      |=  [source-id=@tas source=context-source]
      ?.  (context-applies source owner stack-name `item-name)  ~
      =/  key=@t
        (crip "context-{(trip source-id)}")
      ?:  (~(has by fields) key)  `source-id
      ~
    %:  apply-web-action
      eyre-id
      [%ask-card question-id owner stack-name item-name mode profile prompt context-ids]
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
++  apply-web-action
  |=  [eyre-id=@ta act=action page=page:index notice=(unit @t)]
  ^-  (quip card _state)
  =^  action-cards  state  (poke-seer-action act)
  :_  state
  (weld action-cards (give-simple-payload:app eyre-id (render-action-page page notice)))
::
++  render-action-page
  |=  [page=page:index notice=(unit @t)]
  ^-  simple-payload:http
  =/  payload  (render-page page notice)
  =.  headers.response-header.payload
    [['HX-Push-Url' (page-url page)] headers.response-header.payload]
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
  [(give-simple-payload:app eyre-id (render-page page notice)) state]
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
    ?:  =('' browse.page)  ~
    (clay-level-data browse.page '')
  %-  manx-response:gen
  =/  stale=(map @tas ?(%stale %gone))
    ?.  ?=(?(%stack %stack-browse) -.page)  ~
    clay-source-stale
  (render:index our.bol stacks.state stack-subs.state captures.state questions.state contexts.state question-contexts.state models.state changes.state logins.state all-reviews page notice picker shared-context.state remote-manifests.state recent-clay.state stale)
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
    [(scot %p our.bol) dek.u.parsed (scot %da now.bol) rest.u.parsed]
  =/  ark=(each arch tang)  (mule |.(.^(arch %cy pax)))
  ?:  |(?=(%| -.ark) ?=(~ fil.p.ark))
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
  %+  sort
    ~(tap in .^((set desk) %cd [(scot %p our.bol) '' (scot %da now.bol) ~]))
  aor
::
++  clay-level-data
  |=  [loc=@t filter=@t]
  ^-  (unit picker-data:index)
  ?:  |(=('' loc) =('/' loc))
    `[%desks clay-desks]
  =/  parsed  (parse-clay-locator loc)
  ?:  |(?=(~ parsed) !=(our.bol who.u.parsed))  ~
  ?.  (~(has in (silt clay-desks)) dek.u.parsed)  ~
  =/  base=path
    [(scot %p our.bol) dek.u.parsed (scot %da now.bol) rest.u.parsed]
  =/  ark=(each arch tang)  (mule |.(.^(arch %cy base)))
  ?:  ?=(%| -.ark)  ~
  =/  kids=(list @ta)
    (sort (turn ~(tap by dir.p.ark) head) aor)
  =.  kids
    ?:  =('' filter)  kids
    %+  skim  kids
    |=  k=@ta
    =((end [3 (met 3 filter)] k) filter)
  =/  entries=(list [name=@ta dir=? fil=?])
    %+  murn  (scag 500 kids)
    |=  k=@ta
    ^-  (unit [@ta ? ?])
    =/  kark  .^(arch %cy (snoc base k))
    =/  is-dir=?   !=(~ dir.kark)
    =/  is-fil=?   &(?=(^ fil.kark) (~(has in clay-text-marks) k))
    ?:  |(is-dir is-fil)  `[k is-dir is-fil]
    ~
  =/  base-loc=tape
    %-  zing
    :-  "/{(trip (scot %p who.u.parsed))}/{(trip dek.u.parsed)}"
    (turn rest.u.parsed |=(k=@ta "/{(trip k)}"))
  =/  up-loc=tape
    ?~  rest.u.parsed  ""
    %-  zing
    :-  "/{(trip (scot %p who.u.parsed))}/{(trip dek.u.parsed)}"
    (turn (snip `path`rest.u.parsed) |=(k=@ta "/{(trip k)}"))
  `[%level base-loc up-loc entries]
::
++  respond-clay-browse
  |=  [eyre-id=@ta args=(list [k=@t v=@t])]
  ^-  (quip card _state)
  =/  loc=@t     (fall (get-arg args 'path') '')
  =/  filter=@t  (fall (get-arg args 'filter') '')
  =/  ret=tape   (trip (fall (get-arg args 'return') ''))
  =/  dat=(unit picker-data:index)  (clay-level-data loc filter)
  ?~  dat  (respond-payload eyre-id not-found:gen)
  %+  respond-payload  eyre-id
  %-  manx-response:gen
  ?-  -.u.dat
    %desks  (clay-browse-desks:index ret our.bol desks.u.dat)
    %level  (clay-browse-level:index ret base.u.dat up.u.dat entries.u.dat)
  ==
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
++  read-clay-context
  |=  raw=@t
  ^-  @t
  =/  parsed  (parse-clay-locator raw)
  ?~  parsed  !!
  ?.  =(our.bol who.u.parsed)  !!
  =/  pax=path
    [(scot %p who.u.parsed) dek.u.parsed (scot %da now.bol) rest.u.parsed]
  =/  archive=arch  .^(arch %cy pax)
  ?~  fil.archive  !!
  =/  value  .^(noun %cx pax)
  =/  maybe-lines=(unit wain)
    ?@(value `(to-wain:format value) ((soft wain) value))
  ?~  maybe-lines  !!
  =/  lines=wall
    (turn u.maybe-lines |=(line=cord (trip line)))
  (crip (zing (join "\0a" lines)))
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
  |=  [owner=@p stak=@tas card=(unit @tas)]
  ^-  ?
  =/  found=(unit stack)  (context-stack owner stak)
  ?~  found  %.n
  ?~  card  %.y
  (~(has by items.u.found) u.card)
::
++  context-applies
  |=  [source=context-source owner=@p stak=@tas card=(unit @tas)]
  ^-  ?
  ?&  active.source
      =(%ready status.source)
      =(owner owner.source)
      =(stak stack.source)
      ?|  ?=(~ card.source)
          =(card.source card)
      ==
  ==
::
++  operation-shape-valid
  |=  op=state-operation
  ^-  ?
  ?-  kind.op
    %create-stack  ?&(=(0 (met 3 card.op)) !=(0 (met 3 title.op)))
    %rename-stack  ?&(=(0 (met 3 card.op)) !=(0 (met 3 title.op)) !=(0 (met 3 original-title.op)))
    %delete-stack  ?&(=(0 (met 3 card.op)) !=(0 (met 3 original-title.op)))
    %create-card   ?&(!=(0 (met 3 card.op)) !=(0 (met 3 title.op)) !=(0 (met 3 front.op)) !=(0 (met 3 back.op)))
    %edit-card     ?&(!=(0 (met 3 card.op)) !=(0 (met 3 title.op)) !=(0 (met 3 front.op)) !=(0 (met 3 back.op)) !=(0 (met 3 original-title.op)))
    %delete-card   ?&(!=(0 (met 3 card.op)) !=(0 (met 3 original-title.op)))
    %queue-card    ?&(!=(0 (met 3 card.op)) !=(0 (met 3 original-title.op)))
  ==
::
++  operation-valid
  |=  op=state-operation
  ^-  ?
  =/  maybe-stack  (~(get by stacks.state) stack.op)
  ?-  kind.op
    %create-stack
      ?&  !(~(has by stacks.state) stack.op)
          (operation-shape-valid op)
      ==
    %rename-stack
      ?^  maybe-stack
        ?&  (operation-shape-valid op)
            =(original-title.op (local-stack-title u.maybe-stack))
        ==
      %.n
    %delete-stack
      ?^  maybe-stack
        ?&  (operation-shape-valid op)
            =(original-title.op (local-stack-title u.maybe-stack))
        ==
      %.n
    %create-card
      ?^  maybe-stack
        ?&  (operation-shape-valid op)
            !(~(has by items.u.maybe-stack) card.op)
        ==
      %.n
    %edit-card
      ?~  maybe-stack  %.n
      =/  maybe-item  (~(get by items.u.maybe-stack) card.op)
      ?~  maybe-item  %.n
      ?&  (operation-shape-valid op)
          =(original-title.op title.content.u.maybe-item)
          =(original-front.op (clean-body front.content.u.maybe-item))
          =(original-back.op (clean-body back.content.u.maybe-item))
      ==
    %delete-card
      ?~  maybe-stack  %.n
      =/  maybe-item  (~(get by items.u.maybe-stack) card.op)
      ?~  maybe-item  %.n
      ?&  (operation-shape-valid op)
          =(original-title.op title.content.u.maybe-item)
          =(original-front.op (clean-body front.content.u.maybe-item))
          =(original-back.op (clean-body back.content.u.maybe-item))
      ==
    %queue-card
      ?~  maybe-stack  %.n
      =/  maybe-item  (~(get by items.u.maybe-stack) card.op)
      ?~  maybe-item  %.n
      ?&  (operation-shape-valid op)
          =(original-title.op title.content.u.maybe-item)
          =(original-front.op (clean-body front.content.u.maybe-item))
          =(original-back.op (clean-body back.content.u.maybe-item))
      ==
  ==
::
++  change-valid
  |=  ops=(list state-operation)
  ^-  ?
  ?&  (operations-coherent ops)
      (operations-valid ops)
  ==
::
++  operations-valid
  |=  ops=(list state-operation)
  ^-  ?
  ?~  ops  %.y
  ?&  (operation-valid i.ops)
      $(ops t.ops)
  ==
::
++  operations-coherent
  |=  ops=(list state-operation)
  ^-  ?
  ?~  ops  %.y
  ?:  (operation-conflicts i.ops t.ops)  %.n
  $(ops t.ops)
::
++  operation-conflicts
  |=  [op=state-operation rest=(list state-operation)]
  ^-  ?
  ?~  rest  %.n
  =/  other  i.rest
  =/  same-stack=?  =(stack.op stack.other)
  =/  same-target=?
    ?&  same-stack
        ?:  =(0 card.op)
          =(0 card.other)
        =(card.op card.other)
    ==
  =/  structural=?
    ?&  same-stack
        ?|  =(%create-stack kind.op)
            =(%delete-stack kind.op)
            =(%create-stack kind.other)
            =(%delete-stack kind.other)
        ==
    ==
  ?|  same-target
      structural
      $(rest t.rest)
  ==
::
++  apply-operations
  |=  ops=(list state-operation)
  ^-  (quip card _state)
  ?~  ops  [~ state]
  =/  op  i.ops
  =/  act=action
    ?-  kind.op
      %create-stack  [%new-stack stack.op title.op *items]
      %rename-stack  [%edit-stack stack.op title.op]
      %delete-stack  [%delete-stack our.bol stack.op]
      %create-card
        :*  %new-item
            our.bol
            our.bol
            stack.op
            card.op
            title.op
            [read=*rule:clay write=*rule:clay]
            front.op
            back.op
        ==
      %edit-card
        :*  %edit-item
            our.bol
            stack.op
            card.op
            title.op
            [read=*rule:clay write=*rule:clay]
            front.op
            back.op
        ==
      %delete-card  [%delete-item stack.op card.op]
      %queue-card   [%raise-item our.bol stack.op card.op]
    ==
  =^  first-cards  state  (poke-seer-action act)
  =^  rest-cards  state  $(ops t.ops)
  [(weld first-cards rest-cards) state]
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
  ?-  -.act
      %new-stack
    ?.  =(our.bol src.bol)
      [~ state]
    ?:  ?&((~(has by stacks) name.act) =(items.act ~))
      [~ state]
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
    =<  abet
    (~(delete-stack stack-emit stack-to-delete) who.act)
      %delete-item
    =.  provenance.state
      (~(del by provenance.state) [stak.act item.act])
    =<  abet
    %.  item.act
    ~(delete-item stack-emit (~(got by stacks) stak.act))
      %edit-stack
    =/  =stack  (~(got by stacks) name.act)
    ?>  ?=(%.y -.info.stack)
    =/  =stack-info  p.info.stack
    =<  abet
    %~  update-stack  stack-emit
    %=  stack
      info         [%.y stack-info(title title.act, last-modified now.bol)]
      last-update  now.bol
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
    =/  front-matter=(map knot cord)
    %-  my
    :~  title+title.act
        author+(scot %p src.bol)
        date-created+(scot %da date-created.content.item)
        last-modified+(scot %da now.bol)
    ==
    =/  front  (add-front-matter front-matter front.act)
    =/  back  (add-front-matter front-matter back.act)
    =/  new-content  content.item(front front, back back, snippet (form-snippet front), title title.act)
    =<  abet
    %.  item(content new-content)
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
    =/  their-stack=stack  (~(got by stack-subs) [owner.act stak.act])

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
      [~ [%pass /stacks %agent [our.bol %seer] %poke %seer-action !>(new-act)]]
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
      %begin-capture
    ?:  (~(has by captures.state) id.act)
      [~ state]
    =/  session=capture
      :*  id.act
          title.act
          goal.act
          source.act
          created-by.act
          now.bol
          %open
          0
          0
          ~
      ==
    =.  captures.state  (~(put by captures.state) id.act session)
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
      ==
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
    =/  maybe-stack  (~(get by stacks.state) stack.draft)
    ?~  maybe-stack  [~ state]
    ?:  (~(has by items.u.maybe-stack) card.draft)  [~ state]
    =/  add-act=action
      :*  %new-item
          our.bol
          our.bol
          stack.draft
          card.draft
          title.draft
          [read=*rule:clay write=*rule:clay]
          front.draft
          back.draft
      ==
    =^  add-cards  state  (poke-seer-action add-act)
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
      ==
    =.  provenance.state
      (~(put by provenance.state) [stack.draft card.draft] origin)
    [add-cards state]
      %reject-proposal
    =/  maybe-session  (~(get by captures.state) capture.act)
    ?~  maybe-session  [~ state]
    =/  session  u.maybe-session
    ?:  !(~(has by proposals.session) proposal.act)  [~ state]
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
    [~ state]
      %add-context-source
    ?:  ?|  (~(has by contexts.state) id.act)
            =(0 (met 3 label.act))
            (gth (met 3 label.act) 240)
            (gth (met 3 locator.act) 2.048)
            (gth (met 3 content.act) 131.072)
            !(context-scope-exists owner.act stak.act card.act)
            ?&  !=(%web kind.act)
                ?=(~ (foreign-clay-locator kind.act locator.act))
                =(0 (met 3 content.act))
            ==
            ?&  =(%web kind.act)
                =(0 (met 3 locator.act))
            ==
        ==
      [~ state]
    =/  source=context-source
      :*  id.act
          owner.act
          stak.act
          card.act
          kind.act
          label.act
          locator.act
          content.act
          ?:  |(=(%web kind.act) ?=(^ (foreign-clay-locator kind.act locator.act)))  %pending  %ready
          ''
          ''
          %.y
          now.bol
          now.bol
      ==
    =.  contexts.state  (~(put by contexts.state) id.act source)
    =?  recent-clay.state  =(%clay kind.act)
      %+  scag  8
      `(list @t)`[locator.act (skip recent-clay.state |=(l=@t =(l locator.act)))]
    =?  context-revs.state
        ?&  =(%clay kind.act)
            ?=(~ (foreign-clay-locator kind.act locator.act))
        ==
      =/  parsed  (parse-clay-locator locator.act)
      ?~  parsed  context-revs.state
      (~(put by context-revs.state) id.act (clay-desk-rev dek.u.parsed))
    =/  foreign  (foreign-clay-locator kind.act locator.act)
    ?~  foreign  [~ state]
    =.  outstanding-keens.state
      %+  ~(put by outstanding-keens.state)  id.act
      [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
    :_  state
    :~  :*  %pass  [%shared-fetch id.act ~]  %agent  [who.u.foreign %seer]
            %watch  [%shared-context %file dek.u.foreign rest.u.foreign]
        ==
        [%pass [%shared-timeout id.act ~] %arvo %b %wait (add now.bol ~m2)]
    ==
      %remove-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    =.  active.source  %.n
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
    ?.  (bridge-proof-valid %claim-context-source id.act worker.act ~ nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =.  status.source  %working
    =.  worker.source  worker.act
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    [~ state]
      %recover-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%working status.source)
            =(%web kind.source)
        ==
      [~ state]
    ?.  (bridge-proof-valid %recover-context-source id.act worker.act ~[worker.source] nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =.  status.source  %pending
    =.  worker.source  ''
    =.  error.source  ''
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
    ?.  (bridge-proof-valid %finish-context-source id.act worker.act ~[label.act content.act] nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =.  label.source  ?:(=(0 (met 3 label.act)) label.source label.act)
    =.  content.source  content.act
    =.  status.source  %ready
    =.  error.source  ''
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    [~ state]
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
    ?.  (bridge-proof-valid %fail-context-source id.act worker.act ~[error.act] nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =.  status.source  %failed
    =.  error.source  error.act
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    [~ state]
      %refresh-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%clay kind.source)
            !=(%pending status.source)
        ==
      [~ state]
    =/  foreign  (foreign-clay-locator kind.source locator.source)
    ?^  foreign
      =.  status.source  %pending
      =.  error.source  ''
      =.  updated-at.source  now.bol
      =.  contexts.state  (~(put by contexts.state) id.act source)
      =.  outstanding-keens.state
        %+  ~(put by outstanding-keens.state)  id.act
        [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
      :_  state
      :~  :*  %pass  [%shared-fetch id.act ~]  %agent  [who.u.foreign %seer]
              %watch  [%shared-context %file dek.u.foreign rest.u.foreign]
          ==
          [%pass [%shared-timeout id.act ~] %arvo %b %wait (add now.bol ~m2)]
      ==
    =/  parsed  (parse-clay-locator locator.source)
    ?~  parsed  [~ state]
    =/  loaded=(each @t tang)  (mule |.((read-clay-context locator.source)))
    ?:  ?=(%| -.loaded)  [~ state]
    ?:  |(=(0 (met 3 p.loaded)) (gth (met 3 p.loaded) 131.072))  [~ state]
    =.  content.source  p.loaded
    =.  status.source  %ready
    =.  error.source  ''
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    =.  context-revs.state
      (~(put by context-revs.state) id.act (clay-desk-rev dek.u.parsed))
    [~ state]
      %retry-context-source
    =/  maybe-source  (~(get by contexts.state) id.act)
    ?~  maybe-source  [~ state]
    =/  source  u.maybe-source
    ?.  ?&  active.source
            =(%failed status.source)
        ==
      [~ state]
    ?.  |(=(%web kind.source) ?=(^ (foreign-clay-locator kind.source locator.source)))
      [~ state]
    =.  status.source  %pending
    =.  error.source  ''
    =.  worker.source  ''
    =.  updated-at.source  now.bol
    =.  contexts.state  (~(put by contexts.state) id.act source)
    =/  foreign  (foreign-clay-locator kind.source locator.source)
    ?~  foreign  [~ state]
    =.  outstanding-keens.state
      %+  ~(put by outstanding-keens.state)  id.act
      [who.u.foreign [dek.u.foreign rest.u.foreign] now.bol]
    :_  state
    :~  :*  %pass  [%shared-fetch id.act ~]  %agent  [who.u.foreign %seer]
            %watch  [%shared-context %file dek.u.foreign rest.u.foreign]
        ==
        [%pass [%shared-timeout id.act ~] %arvo %b %wait (add now.bol ~m2)]
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
    =/  loaded=(each @t tang)  (mule |.((read-clay-context (crip loc))))
    ?:  ?=(%| -.loaded)  [~ state]
    =/  content=@t  p.loaded
    ?:  |(=(0 (met 3 content)) (gth (met 3 content) 131.072))  [~ state]
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
    =.  shared-context.state  (~(del by shared-context.state) pax.act)
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
    =/  maybe-stack=(unit stack)
      ?:  =(our.bol owner.act)
        (~(get by stacks.state) stak.act)
      (~(get by stack-subs.state) [owner.act stak.act])
    ?~  maybe-stack  [~ state]
    =/  maybe-item=(unit item)
      (~(get by items.u.maybe-stack) item.act)
    ?~  maybe-item  [~ state]
    =/  selected-contexts=(list @tas)
      %+  murn  context-ids.act
      |=  source-id=@tas
      =/  found=(unit context-source)
        (~(get by contexts.state) source-id)
      ?~  found  ~
      ?:  (context-applies u.found owner.act stak.act `item.act)
        `source-id
      ~
    =.  selected-contexts  (scag 12 selected-contexts)
    =/  current=item  u.maybe-item
    =/  question=card-question
      :*  id.act
          owner.act
          stak.act
          item.act
          title.content.current
          front.content.current
          back.content.current
          mode.act
          prompt.act
          profile.act
          now.bol
          %pending
          ''
          ''
          ''
          ''
          ''
          now.bol
      ==
    =.  questions.state  (~(put by questions.state) id.act question)
    =.  question-contexts.state
      (~(put by question-contexts.state) id.act selected-contexts)
    [~ state]
      %clear-assistant-models
    =.  models.state  ~
    [~ state]
      %register-assistant-model
    ?:  ?|  =(0 (met 3 selector.act))
            =(0 (met 3 model.act))
            =(0 (met 3 label.act))
            =(0 (met 3 worker.act))
        ==
      [~ state]
    =/  profile=assistant-model
      :*  id.act
          provider.act
          role.act
          selector.act
          model.act
          label.act
          description.act
          worker.act
          now.bol
      ==
    =.  models.state  (~(put by models.state) id.act profile)
    [~ state]
      %claim-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  =(%pending status.question)  [~ state]
    =.  status.question  %working
    =.  worker.question  worker.act
    =.  updated-at.question  now.bol
    =.  questions.state  (~(put by questions.state) id.act question)
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
    =.  status.question  %answered
    =.  response.question  response.act
    =.  updated-at.question  now.bol
    =.  questions.state  (~(put by questions.state) id.act question)
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
    =/  maybe-stack  (~(get by stacks.state) stack.question)
    ?~  maybe-stack
      =.  status.question      %failed
      =.  response.question    'The stack was removed before this edit could be applied.'
      =.  updated-at.question  now.bol
      =.  questions.state  (~(put by questions.state) id.act question)
      [~ state]
    =/  maybe-item  (~(get by items.u.maybe-stack) card.question)
    ?~  maybe-item
      =.  status.question      %failed
      =.  response.question    'The card was removed before this edit could be applied.'
      =.  updated-at.question  now.bol
      =.  questions.state  (~(put by questions.state) id.act question)
      [~ state]
    =/  current  u.maybe-item
    ?.  ?&  =(title.content.current title.question)
            =(front.content.current front.question)
            =(back.content.current back.question)
        ==
      =.  status.question      %failed
      =.  response.question    'The card changed after you sent this request. Review the current card. Retry the request if needed.'
      =.  updated-at.question  now.bol
      =.  questions.state  (~(put by questions.state) id.act question)
      [~ state]
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
    =.  questions.state  (~(put by questions.state) id.act question)
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
    =.  response.question  response.act
    =.  updated-at.question  now.bol
    =.  questions.state  (~(put by questions.state) id.act question)
    [~ state]
      %retry-card-question
    =/  maybe-question  (~(get by questions.state) id.act)
    ?~  maybe-question  [~ state]
    =/  question  u.maybe-question
    ?.  =(%failed status.question)  [~ state]
    =.  status.question  %pending
    =.  worker.question  ''
    =.  response.question  ''
    =.  updated-at.question  now.bol
    =.  questions.state  (~(put by questions.state) id.act question)
    [~ state]
      %delete-card-question
    =.  questions.state  (~(del by questions.state) id.act)
    =.  question-contexts.state
      (~(del by question-contexts.state) id.act)
    [~ state]
      %request-change
    ?:  ?|  =(0 (met 3 prompt.act))
            (~(has by changes.state) id.act)
        ==
      [~ state]
    =/  request=change-request
      :*  id.act
          target.act
          prompt.act
          profile.act
          now.bol
          %pending
          ''
          ''
          ~
          ''
          ''
          now.bol
      ==
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
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
      %stage-change-operation
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&  =(%working status.request)
            =(%library target.request)
            =(worker.act worker.request)
            (operation-shape-valid operation.act)
            (lth (lent operations.request) 64)
        ==
      [~ state]
    =.  operations.request  [operation.act operations.request]
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %finish-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&  =(%working status.request)
            =(worker.act worker.request)
            !=(0 (met 3 summary.act))
            ?:  =(%library target.request)
              !=(~ operations.request)
            !=(0 (met 3 artifact.act))
        ==
      [~ state]
    =.  status.request      %ready
    =.  summary.request     summary.act
    =.  operations.request  (flop operations.request)
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
    =.  response.request    response.act
    =.  updated-at.request  now.bol
    =.  changes.state  (~(put by changes.state) id.act request)
    [~ state]
      %apply-change
    =/  maybe-request  (~(get by changes.state) id.act)
    ?~  maybe-request  [~ state]
    =/  request  u.maybe-request
    ?.  ?&  =(%ready status.request)
            =(%library target.request)
        ==
      [~ state]
    ?.  (change-valid operations.request)
      =.  status.request      %failed
      =.  response.request    'The library changed after the plan was created. Seer did not apply the plan. Build a new plan.'
      =.  updated-at.request  now.bol
      =.  changes.state  (~(put by changes.state) id.act request)
      [~ state]
    =^  operation-cards  state  (apply-operations operations.request)
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
    [~ state]
      %request-login
    ::  the ship never runs a provider login itself; it only queues the
    ::  request for the local bridge.  one live request per provider.
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
    =.  bridge-nonces.state
      %-  malt
      %+  skim  ~(tap by bridge-nonces.state)
      |=  [old-nonce=@t issued=@da]
      (lte (sub now.bol issued) ~m5)
    =.  bridge-nonces.state  (~(put by bridge-nonces.state) nonce.act now.bol)
    [~ state]
      %claim-login
    =/  maybe-login  (~(get by logins.state) id.act)
    ?~  maybe-login  [~ state]
    =/  req  u.maybe-login
    ?.  =(%pending status.req)  [~ state]
    ?.  (bridge-proof-valid %claim-login id.act worker.act ~ nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
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
    ?.  (bridge-proof-valid %post-login-challenge id.act worker.act ~[auth-url.act user-code.act] nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
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
    ?.  (bridge-proof-valid %consume-login-code id.act worker.act ~ nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
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
    ?.  (bridge-proof-valid %finish-login id.act worker.act ~ nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
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
    ?.  (bridge-proof-valid %fail-login id.act worker.act ~[message.act] nonce.act proof.act)  [~ state]
    =.  bridge-nonces.state  (~(del by bridge-nonces.state) nonce.act)
    =/  next=login-request
      :*  id.req  provider.req  %failed
          ''  ''  ''  message.act
          worker.req  created-at.req  now.bol
      ==
    =.  logins.state  (~(put by logins.state) id.act next)
    [~ state]
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
++  bridge-proof-valid
  |=  [action=@tas id=@tas worker=@t fields=(list @t) nonce=@t proof=@]
  ^-  ?
  ?:  =(0 bridge-secret.state)  %.n
  =/  issued=(unit @da)  (~(get by bridge-nonces.state) nonce)
  ?~  issued  %.n
  ?.  (lte (sub now.bol u.issued) ~m5)  %.n
  =/  parts=(list @t)
    (welp ~['seer-bridge-v1' action id worker nonce] fields)
  =/  payload=@t
    (crip (zing (turn parts |=(part=@t "{<(met 3 part)>}:{(trip part)}"))))
  =(proof (hmac-sha256t:hmac:crypto bridge-secret.state payload))
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
  =/  loaded=(each @t tang)  (mule |.((read-clay-context (crip loc))))
  ?:  ?=(%| -.loaded)  ~|(%shared-file-unreadable !!)
  ?:  (gth (met 3 p.loaded) 131.072)  ~|(%shared-file-too-large !!)
  :_  state
  :~  [%give %fact ~ %noun !>([%0 label.u.entry mark.u.entry p.loaded])]
      [%give %kick ~ ~]
  ==
::
++  fail-shared-fetch
  |=  [id=@tas msg=@t]
  ^-  (quip card _state)
  =.  outstanding-keens.state  (~(del by outstanding-keens.state) id)
  =/  maybe-source  (~(get by contexts.state) id)
  ?~  maybe-source  [~ state]
  =/  source  u.maybe-source
  ?.  =(%pending status.source)  [~ state]
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
  ?.  =(%pending status.source)  [~ state]
  =/  payload  ((soft ,[%0 label=@t mark=@tas content=@t]) q.q.cage)
  ?~  payload
    (fail-shared-fetch id 'That ship sent an unexpected reply.')
  ?:  ?|  =(0 (met 3 content.u.payload))
          (gth (met 3 content.u.payload) 131.072)
      ==
    (fail-shared-fetch id 'The shared file is empty or larger than 128 KB.')
  =.  outstanding-keens.state  (~(del by outstanding-keens.state) id)
  =.  content.source  content.u.payload
  =.  status.source  %ready
  =.  error.source  ''
  =.  updated-at.source  now.bol
  =.  contexts.state  (~(put by contexts.state) id source)
  [~ state]
::
++  shared-fetch-timeout
  |=  id=@tas
  ^-  (quip card _state)
  ?.  (~(has by outstanding-keens.state) id)  [~ state]
  (fail-shared-fetch id 'Timed out waiting for that ship to reply.')
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
      [%pass [%shared-manifest-timeout (scot %p who) ~] %arvo %b %wait (add now.bol ~s45)]
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
  =/  payload  ((soft ,[%0 entries=(list manifest-entry)]) q.q.cage)
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
    =.  stack-subs.state  (~(put by stack-subs.state) key data.del)
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
    ?.  =(src.bol our.bol)
      [~ state]
    ?+  a
      [~ state]
        %print-json
      ~&  >  state+(state-to-json state)
      [~ state]
        %clear-state
      [~ *[%14 state-thirteen]]
        [%set-bridge-capability @]
      =/  token=@t  +.a
      =.  bridge-secret.state  token
      =.  bridge-nonces.state  ~
      [~ state]
        %clear-bridge-capability
      =.  bridge-secret.state  ''
      =.  bridge-nonces.state  ~
      [~ state]
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
  |*  in=*
  =/  act  `$>(%new-item action)`in
  ^-  item
  =/  front-matter=(map knot cord)
    %-  my
    :~  title+title.act
         author+(scot %p src.bol)
         date-created+(scot %da now.bol)
         last-modified+(scot %da now.bol)
    ==
  =/  front  (add-front-matter front-matter front.act)
  =/  back  (add-front-matter front-matter back.act)
  =/  new-content=content
    :*  src.bol
        title.act
        name.act
        now.bol
        now.bol
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
    info  [%.y info]
    name  filename.info
    last-update  last-modified.info
    items  (~(uni by items) items.sta)
  ==
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
      =+  `(unit wain)`?@(fyl `(to-wain:format fyl) ((soft wain) fyl))
      ?^  -  (wain-to-tape u)  ~&("could not parse" !!)
    !!
  =/  filtered  (murn (need items) |*(a=(unit *) a))

  =<  abet
  %-  emit-action
  [%new-stack (string-to-symbol (trip name)) name (molt filtered)]
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
         `$>(%new-item action)`act
      (most (just `@`9) (star prn))
    --
  --
--
