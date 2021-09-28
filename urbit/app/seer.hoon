/-  *seer
/+  *server, *seer, *seer-json, default-agent, verb, dbug
/=  index  /app/seer/index
::
|%
+$  versioned-state
  $%  [%0 state-zero]
      [%1 state-one]
      [%2 state-two]
      [%3 state-two]
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
+$  card  card:agent:gall
::
--
::
=|  [%3 state-two]
=*  state  -
^-  agent:gall
=<
  %-  agent:dbug
  %+  verb  |
  |_  bol=bowl:gall
  +*  this       .
      seer-core  +>
      sc         ~(. seer-core bol)
      def        ~(. (default-agent this %|) bol)
  ::
  ++  on-init
    ^-  (quip card _this)
    :_  this
      [%pass /bind/seer %arvo %e %connect [~ /seer] dap.bol]~

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
        :_  state
        %+  give-simple-payload:app  eyre-id
        %+  require-authorization:app  inbound-request
        poke-handle-http-request:sc
      ==
    [cards this]
  ::
  ++  on-watch
    |=  =path
    ^-  (quip card _this)
    =^  cards  state
      ?+  path  (on-watch:def path)
        [%seertile *]       (peer-seertile:sc t.path)
        [%seer-primary *]   (peer-seer-primary:sc t.path)
        [%http-response *]  [~ state]
        [%stack @ ~]  (peer-stack:sc i.t.path)
      ==
    [cards this]
  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ?+  wire  (on-agent:def wire sign)
        [%import @ @ ~]
      =/  name  i.t.t.wire
      ?+  -.sign  (on-agent:def wire sign)
          %fact
        ?>  ?=(%seer-stack p.cage.sign)
        =/  =stack  !<(stack q.cage.sign)
        =^  cards  state  (handle-import-stack:sc stack)
        [cards this]
      ==
    ==
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =^  cards  state
      ?+  wire  (on-arvo:def wire sign-arvo)
        [%bind %seer ~]             [~ state]
        [%view-bind ~]              [~ state]
        [%review-schedule @ ~]      (wake:sc wire)
        [%review-schedule @ @ @ ~]  (wake:sc wire)
        [%import @ @ ~]             (peer-stack:sc i.t.t.wire)
        [%read %paths ~]            [~ state]
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
        [%pass /bind/seer %arvo %e %connect [~ /seer] %seer]
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
        [%3 new-stacks ~ new-stack-subs]
      ==
    %2
      [~ this(state [%3 +.p.old-state])]
    %3
      [~ this(state p.old-state)]
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
        [%x %review ~]        ``noun+!>(all-reviews)
        [%x %all ~]        ``noun+!>(stacks.state)
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
  %-  emit
  [%give %fact ~[/seer-primary] %seer-primary-delta !>(del)]
::
++  emit-action
  |=  =action
  %-  emit
  [%pass /action %agent [our.bol %seer] %poke %seer-action !>(action)]
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
  :: todo: maybe doesn't need to be a door
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
    ?>  ?=(%.y -.stack.stack)
    =/  info=stack-info  +.stack.stack
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
  ++  update-learned-status
    |=  [=item =recall-grade]
    ^+  this
    =.  ..emit  (~(delete-review-item stack-emit stack) item)
    =/  =learned-status  (generate-learned-status item recall-grade)
    =/  review-date=@da  (add now.bol interval.learned-status)
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
      %.  item(learn learned-status, last-review `now.bol)
      %~  edit-item  stack-emit  stak
    (emit schedule-card)
  ::
  ++  clear-learned-status
    ^+  this
    =-  %~  update-stack  stack-emit  stack(items -)
    %-  ~(run by items.stack)
    |=  =item
    item(learn (learned-status [.2.5 0 0]))
  ::
  ++  update-owner
    ^+  this
    =/  updated-items=(map @tas item)
      %-  ~(run by items.stack)
      |=  =item
      =.  author.content.item  our.bol
      item
    %~  update-stack  stack-emit
    ?>  ?=(%.y -.stack.stack)
    =/  =stack-info  +.stack.stack
    %=  stack
      items  updated-items
      stack  [%.y stack-info(owner our.bol)]
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
  ~&  arvo+sign-arvo
  [~ state]
::
++  poke-handle-http-request
  |=  =inbound-request:eyre
  ^-  simple-payload:http
  =+  request-line=(parse-request-line url.request.inbound-request)
  ?+  request-line
    not-found:gen
  ::  send review state as json
  ::
      [[[~ %json] [%'~seer' %update-review ~]] ~]
    %-  json-response:gen
    :-  %a
    (turn all-reviews review-to-json)
  ::  learned status as json for given stack
      [[[~ %json] [%apps %seer %learn @ ~]] ~]
    =/  stack-name  i.t.t.site.request-line
    %-  json-response:gen
    %-  stack-status-to-json  (~(got by stacks) stack-name)
  ::  learned status as json for given stack and item
      [[[~ %json] [%apps %seer %learn @ @ ~]] ~]
    =/  stack-name  i.t.t.site.request-line
    =/  item-name  i.t.t.t.site.request-line
    =/  =stack  (~(got by stacks) stack-name)
    =/  =item  (~(got by items.stack) item-name)
    %-  json-response:gen
    %-  status-to-json  learn.item
  ::  home page; redirect
  ::
      [[~ [%apps %seer ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (redirect:gen '/seer/review')
  ::  review page
  ::
      [[~ [%apps %seer %review ~]] ~]
    =/  hym=manx  (index (state-to-json state))

    (manx-response:gen hym)
  ::  subscriptions
  ::
      [[~ [%apps %seer %stack-subs ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  created
  ::
      [[~ [%apps %seer %stacks ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new item
  ::
      [[~ [%apps %seer %new-item ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new stack
  ::
      [[~ [%apps %seer %new-stack ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  stack
  ::
      [[~ [%apps %seer @t @t ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  stack item
  ::
      [[~ [%apps %seer @t @t @t ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::
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
          edit.act
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
      ?>  ?=(%.y -.stack.u.sub)
      =/  =stack-info  +.stack.u.sub
      %~  add-stack  stack-emit
      %+  create-stack  stack-info(owner our.bol)
      (my [[name.act new-item] ~])
    %.  new-item
    %~  add-item  stack-emit  u.pub
    ::
      %delete-stack
    ~&  delete-stack+act
    =/  stack-to-delete
      ?:  =(our.bol who.act)
        (~(got by stacks) stak.act)
      (~(got by stack-subs) who.act stak.act)
    =<  abet
    (~(delete-stack stack-emit stack-to-delete) who.act)
      %delete-item
    ~&  delete-item+act
    =<  abet
    %.  item.act
    ~(delete-item stack-emit (~(got by stacks) stak.act))
      %edit-stack
    ~&  edit-stack+act
    [~ state]
    ::
      %review-stack
    ?>  =(our.bol who.act)
    =/  stack  (~(got by stacks) stak.act)
    =<  abet
    (~(review-stack stack-emit stack) who.act)
    ::
      %edit-item
    ~&  edit-item+act
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
    ~&  schedule-item+act
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
    ~&  >  answered-item+act
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
    %~  update-learned-status  stack-emit  stk
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
  ==
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
  :~
      [%give %fact ~ %seer-stack !>(stack)]
      [%give %kick ~ ~]
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
      ~&  seer+"{(spud t.t.wire)} scheduled for review, but no longer exists"
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
      [~ *[%3 state-two]]
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
    :~  title+name.act
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
  (item new-content (learned-status [.2.5 0 0]) ~ name.act)
::
++  create-stack
  |=  [info=stack-info items=(map @tas item)]
  ^-  stack
  =|  sta=stack
  %=  sta
    stack  [%.y info]
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
++  generate-learned-status
  |=  [=item =recall-grade]
  ^-  learned-status
  =/  item-status=learned-status  learn.item
  =/  ease=@rs  (next-ease recall-grade item-status)
  =/  box=@  (next-box recall-grade item-status)
  =/  interval=@dr  (next-interval [ease box item-status])
  (learned-status [ease interval box])
::
++  next-ease
  |=  [=recall-grade =learned-status]
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
  ?:  (lth box.learned-status 2)
    ease.learned-status
  =/  chg  (~(got by ease-changes) recall-grade)
  =/  a  (add:rs ease.learned-status chg)
  ?:  (gte a ease-min)
    a
  ?:  (gte a ease-max)
    ease-max
  ease-min
::
++  next-box
  |=  [=recall-grade =learned-status]
  ^-  @
  ?:  ?&
        =(recall-grade %easy)
        =(box.learned-status 0)
      ==
    2
  ?:  =(recall-grade %again)  0
  (add box.learned-status 1)
::
++  next-interval
  |=  [next-ease=@rs next-box=@ =learned-status]
  ^-  @dr
  ::  ~15 min, 1 day, 6 days
  =/  fixed-intervals=(list @dr)  [~s5 ~m15 ~d1 ~d6 ~]
  ?:  (lth next-box (lent fixed-intervals))
    (snag next-box fixed-intervals)
  (interval-fuzz interval.learned-status next-ease)
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

  abet:(emit-action [%new-stack (string-to-symbol (trip name)) name (molt filtered) %none read=*rule:clay write=*rule:clay])
  |%
  ++  wain-to-tape  |=(a=wain (turn a |=(b=cord (trip b))))
  ++  parse
    |=  [stack-name=@tas =tape]
    |^  (rust tape parser)
    ++  parser
      ~&  >  %parsing
      %+  more  ;~(pose (just `@`10) (just `@`13))
      %+  cook
        |=  a=wall
        ^-  (unit (pair @tas item))
        ~&  >  [%parsing a]
        ?.  ?=([* * *] a)  ~
        =/  front  (crip i.a)
        =/  back  (crip i.t.a)
        =/  uid
          %-  string-to-symbol
          "{<(sham %seer our.bol front eny.bol)>}"
        ~&  >  [%parsing front]
        ~&  >  [%parsing back]
        ~&  >  [%parsing uid]
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
         ~&  >  [%parsing act]
         ~&  >  [%parsing `$>(%new-item action)`act]
         `$>(%new-item action)`act
      (most (just `@`9) (star prn))
    --
  --
--
