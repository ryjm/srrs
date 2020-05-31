/-  *srrs, publish
/+  *server, *srrs, *srrs-json, default-agent, verb, dbug, publish
/=  index
  /^  $-(json manx)
  /:  /===/app/srrs/index  /!noun/
::
/=  tile-js
  /^  octs
  /;  as-octs:mimes:html
  /:  /===/app/srrs/js/tile
  /|  /js/
      /~  ~
  ==
/=  js
  /^  octs
  /;  as-octs:mimes:html
  /|  /:  /===/app/srrs/js/index  /js/
      /~  ~
  ==
/=  css
  /^  octs
  /;  as-octs:mimes:html
  /:  /===/app/srrs/css/index
  /|  /css/
      /~  ~
  ==
/=  images
  /^  (map knot @)
  /:  /===/app/srrs/img  /_  /png/
::
|%
+$  versioned-state
  $%  [%0 state-zero]
      [%1 state-one]
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
  $:  stacks=(map @tas stack)
      paths=(list path)
      stack-subs=(map [ship @tas] stack)
  ==
::
+$  card  card:agent:gall
::
--
::
=|  [%1 state-one]
=*  state  -
^-  agent:gall
=<
  %-  agent:dbug
  %+  verb  |
  |_  bol=bowl:gall
  +*  this       .
      srrs-core  +>
      sc         ~(. srrs-core bol)
      def        ~(. (default-agent this %|) bol)
  ::
  ++  on-init
    :_  this
    =/  rav  [%sing %t [%da now.bol] /app/srrs]
    :~  [%pass /bind/srrs %arvo %e %connect [~ /'~srrs'] %srrs]
        :*  %pass  /launch/srrs  %agent  [our.bol %launch]  %poke
             %launch-action  !>([%add %srrs /srrstile '/~srrs/tile.js'])
        ==
        [%pass /read/paths %arvo %c %warp our.bol q.byk.bol `rav]
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
          %srrs-action
        (poke-srrs-action:sc !<(action vase))
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
        [%srrstile *]       (peer-srrstile:sc t.path)
        [%srrs-primary *]   (peer-srrs-primary:sc t.path)
        [%http-response *]  [~ state]
      ==
    [cards this]
  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ?+    -.sign  (on-agent:def wire sign)
        %kick
      ?.  ?=([%stack *] wire)
        (on-agent:def wire sign)
      [~ this]
    ::
        %fact
      ?.  ?=(%stack-rumor p.cage.sign)
        (on-agent:def wire sign)
      [~ this]
    ==
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =^  cards  state
      ?+  wire  (on-arvo:def wire sign-arvo)
        [%bind %srrs ~]             [~ state]
        [%review-schedule @ ~]      (wake:sc wire)
        [%review-schedule @ @ @ ~]  (wake:sc wire)
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
    ?:  ?=(%| -.old-state)
      ~!  p.old-state
      [~ this]
    ?-  -.p.old-state
        %0
      [~ this]
        %1
      [~ this(state p.old-state)]
    ==
  ++  on-leave  on-leave:def
  ++  on-peek
    |=  =path
    ^-  (unit (unit cage))
    ?+  path  (on-peek:def path)
        [%x %review ~]        ``noun+!>(all-reviews)
        [%x %all ~]        ``noun+!>(stacks.state)
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
  |=  [car=card stak=stack]
  this(cards [car cards], stak stak)
::
++  emit-primary
  |=  del=primary-delta
  %+  emit
  [%give %fact ~[/srrs-primary] %srrs-primary-delta !>(del)]
  stak
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
    this
  ::
  ++  delete-stack
    ^+  this
    %.  [%delete-stack our.bol name.stack]
    %=  emit-primary
      stacks  (~(del by stacks) name.stack)
    ==
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
  ++  delete-item
    |=  item=@tas
    ^+  this
    %~  update-stack  stack-emit
    %=  stack
      items  (~(del by items.stack) item)
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
      %.  item(learn learned-status)
      %~  edit-item  stack-emit  stak
    (emit schedule-card stak)

  ::
  ++  update-review
    ^+  this
    =/  del  [%update-review (silt all-reviews)]
    %-  emil
    :~  [%give %fact ~[/srrs-primary] %srrs-primary-delta !>(del)]
        [%give %fact ~[/srrstile] %json !>(make-tile-json)]
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
  ::  images
  ::
      [[[~ %png] [%'~srrs' @t ~]] ~]
    =/  filename=@t  i.t.site.request-line
    =/  img=(unit @t)  (~(get by images) filename)
    ?~  img
      not-found:gen
    (png-response:gen (as-octs:mimes:html u.img))
  ::  styling
  ::
      [[[~ %css] [%'~srrs' %index ~]] ~]
    (css-response:gen css)
  ::  scripting
  ::
      [[[~ %js] [%'~srrs' %index ~]] ~]
    (js-response:gen js)
  ::  tile js
  ::
      [[[~ %js] [%'~srrs' %tile ~]] ~]
    (js-response:gen tile-js)
  ::  send review state as json
  ::
      [[[~ %json] [%'~srrs' %update-review ~]] ~]
    %-  json-response:gen
    %-  json-to-octs
    :-  %a
    (turn all-reviews review-to-json)
  ::  learned status as json for given stack
      [[[~ %json] [%'~srrs' %learn @ ~]] ~]
    =/  stack-name  i.t.t.site.request-line
    %-  json-response:gen
    %-  json-to-octs
    %-  stack-status-to-json  (~(got by stacks) stack-name)
  ::  learned status as json for given stack and item
      [[[~ %json] [%'~srrs' %learn @ @ ~]] ~]
    =/  stack-name  i.t.t.site.request-line
    =/  item-name  i.t.t.t.site.request-line
    =/  =stack  (~(got by stacks) stack-name)
    =/  =item  (~(got by items.stack) item-name)
    %-  json-response:gen
    %-  json-to-octs
    %-  status-to-json  learn.item
  ::  home page; redirect
  ::
      [[~ [%'~srrs' ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (redirect:gen '/~srrs/review')
  ::  review page
  ::
      [[~ [%'~srrs' %review ~]] ~]
    =/  hym=manx  (index (state-to-json state))

    (manx-response:gen hym)
  ::  subscriptions
  ::
      [[~ [%'~srrs' %stack-subs ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  created
  ::
      [[~ [%'~srrs' %stacks ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new item
  ::
      [[~ [%'~srrs' %new-item ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new stack
  ::
      [[~ [%'~srrs' %new-stack ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  stack
  ::
      [[~ [%'~srrs' @t @t ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  stack item
  ::
      [[~ [%'~srrs' @t @t @t ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::
  ==
::
++  poke-srrs-action
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
    =<  abet
    %.  (item new-content (learned-status [.2.5 0 0]) name.act)
    %~  add-item  stack-emit  (~(got by stacks) stak.act)
    ::
      %delete-stack
    ~&  delete-stack+act
    =<  abet
    ~(delete-stack stack-emit (~(got by stacks) stak.act))
      %delete-item
    ~&  delete-item+act
    =<  abet
    %.  item.act
    ~(delete-item stack-emit (~(got by stacks) stak.act))
      %edit-stack
    ~&  edit-stack+act
    [~ state]
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
      %add-books
    =^  cards  state  (add-books books.act)
    [cards state]
      %answered-item
    ~&  answered-item+act
    =/  stack  (~(got by stacks) stak.act)
    =/  =item  (~(got by items.stack) item.act)
    =<  abet
    %.  [item answer.act]
    %~  update-learned-status  stack-emit  stack
      %read
    [~ state]
      %update-review
    =<  abet  update-review:stack-emit
  ==
::
++  peer-srrstile
  |=  wir=wire
  ^-  (quip card _state)
  :_  state
  [%give %fact ~[/srrstile] %json !>(make-tile-json)]~
::
++  peer-srrs-primary
  |=  wir=wire
  ^-  (quip card _state)
  ?.  =(our.bol src.bol)
    :_  state
    [%give %kick ~ ~]~
  [~ state]
::
++  our-beak  /(scot %p our.bol)/[q.byk.bol]/(scot %da now.bol)
::
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
      ~&  srrs+"{(spud t.t.wire)} scheduled for review, but no longer exists"
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
      ~&  state+(state-to-json state)
      [~ state]
        %clear-state
      [~ *[%1 state-one]]
    ==
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
      :+  %stack-subs
        %o
      %-  ~(rep by stack-subs.sat)
      |=  $:  [[who=@p nom=@tas] stack=stack]
              out=(map @t [%o (map @t json)])
          ==
      =/  shp=@t  (rsh 3 1 (scot %p who))
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
++  add-books
  |=  books=(map @tas notebook:publish)
  ^-  (quip card _state)
  %+  roll  ~(tap by books)
  |=  [book=[@tas notebook:publish] cad=(list card) sty=_state]
  ?:  (~(has by stacks.sty) -.book)
    [cad sty]
  =/  items
  (~(run by notes.book) |=(note=note:publish (item note (learned-status [.2.5 0 0]))))
  =/  act
  [%new-stack -.book title.book items %none read=*rule:clay write=*rule:clay]
  =/  mov=card
  [%pass /stacks %agent [our.bol %srrs] %poke %srrs-action !>(act)]
  [(snoc cad mov) sty]
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
--
