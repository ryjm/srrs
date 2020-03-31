/-  *srrs, publish
/+  *server, *srrs, default-agent, verb, dbug, publish
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
  ==
::
+$  state-zero
  $:  pubs=(map @tas stack)
      paths=(list path)
      subs=(map [ship @tas] stack)
      awaiting=(map @tas [builds=(set wire) partial=(unit delta)])
      latest=(list [who=ship stack=@tas item=@tas])
      unread=(set [who=ship stack=@tas item=@tas])
      review=(set [who=ship stack=@tas item=@tas])
      invites=(map [who=ship stack=@tas] title=@t)
  ==
::
+$  card  card:agent:gall
::
--
::
=|  versioned-state
=*  state  -
^-  agent:gall
%-  agent:dbug
%+  verb  |
=<
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
            %launch-action  !>([%srrs /srrstile '/~srrs/tile.js'])
        ==
        [%pass /read/paths %arvo %c %warp our.bol q.byk.bol `rav]
    ==
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
      ?+  path  [~ state]
        [%srrstile *]       (peer-srrstile:sc t.path)
        [%srrs-primary *]   ~&  srrsprim+path  (peer-srrs-primary:sc t.path)
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
    ?+  wire
      (on-arvo:def wire sign-arvo)
        [%bind ~]
      [~ this]
    ==
  ::
  ++  on-save  !>(state)
  ++  on-load
    |=  old=vase
    ^-  (quip card _this)
    =/  old-state=(each versioned-state tang)
      (mule |.(!<(versioned-state old)))
    ?:  ?=(%& -.old-state)
      ~!  p.old-state
      [~ this(state p.old-state)]
    :_  this
    [(sing-clay /read/paths /app/srrs)]~
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-fail   on-fail:def
  --
::
|_  bol=bowl:gall
::  +write-file: write file at path
::
++  write-file
  =,  space:userlib
  |=  [pax=path cay=cage]
  ^-  card
  =.  pax  (weld our-beak pax)
  [%pass (weld /write-file pax) %arvo %c %info (foal pax cay)]
::
++  delete-file
  =,  space:userlib
  |=  pax=path
  ^-  card
  =.  pax  (weld our-beak pax)
  [%pass (weld /remove-file pax) %arvo %c %info (fray pax)]
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
++  poke-sign-arvo
  |=  =sign-arvo
  ^-  (quip card _state)
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
      [[~ [%'~srrs' %subs ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  created
  ::
      [[~ [%'~srrs' %pubs ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new item
  ::
      [[~ [%'~srrs' %new-item ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  new blog
  ::
      [[~ [%'~srrs' %new-stack ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  blog
  ::
      [[~ [%'~srrs' @t @t ~]] ~]
    =/  hym=manx  (index (state-to-json state))
    (manx-response:gen hym)
  ::  blog item
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
    ?:  ?&((~(has by pubs) name.act) =(items.act ~))
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
    ::
    =/  add-items
    %+  roll  ~(tap by items.act)
    |=  [[item=@tas note=note:publish] cad=(list card)]
    (snoc cad (add-item item title.conf))
    =^  cards  state  (add-stack conf items.act)
    [(weld add-items cards) state]
      %new-item
    :_  state
    [(add-item name.act stak.act)]~
    ::
      %delete-stack
    ~&  delete-stack+act
    [~ state]
      %delete-item
    ~&  delete-item+act
    [~ state]
      %edit-stack
    ~&  edit-stack+act
    [~ state]
      %edit-item
    ~&  edit-item+act
    [~ state]
      %schedule-item
    ~&  schedule-item+act
    [~ state]
      %raise-item
    ~&  raise-item+act
    :-  ~
    %=  state
      review  (~(put in review.state) [our.bol stak.act item.act])
    ==
      %add-books
    =^  cards  state  (add-books books.act)
    [cards state]
      %answered-item
    ~&  answered-item+act
    =^  cards  state  (update-learned-status stak.act item.act answer.act)
    [cards state]
      %invite
    ~&  invite+act
    [~ state]
      %reject-invite
    ~&  reject-invite+act
    [~ state]
      %serve
    ~&  serve+act
    [~ state]
      %unserve
    ~&  unserve+act
    [~ state]
      %subscribe
    ~&  subscribe+act
    [~ state]
      %unsubscribe
    ~&  unsubscribe+act
    [~ state]
      %read
    ~&  read+act
    [~ state]
  ==
::
++  peer-srrstile
  |=  wir=wire
  ^-  (quip card _state)
  ~&  wir+wire
  :_  state
  [%give %fact ~ %json !>(make-tile-json)]~
::
++  pull
  |=  wir=wire
  ^-  (quip card _state)
  ?+  wir
    [~ state]
  ::
      [%stack @t ~]
    =/  stak=@tas  i.t.wir
    =/  stk=(unit stack)  (~(get by pubs) stak)
    ?~  stk
      [~ state]
    =/  new=stack
      u.stk(subscribers (~(del in subscribers.u.stk) src.bol))
    [~ state(pubs (~(put by pubs) stak new))]
  ::
  ==
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
++  poke-noun
  |=  a=*
    ^-  (quip card _state)
    ?.  =(src.bol our.bol)
      [~ state]
    ?+  a
      [~ state]
        %print-json
      ~&  (state-to-json state)
      [~ state]
        %clear-state
      ~&  state+state
      [~ *versioned-state]
    ==
::
++  state-to-json
  |=  sat=_state
  ^-  json
  %-  pairs:enjs:format
  :~  :+  %pubs
        %o
      %+  roll  ~(tap by pubs.sat)
      |=  [[nom=@tas stack=stack] out=(map @t json)]
      %+  ~(put by out)
        nom
      (total-build-to-json stack)
  ::
      :+  %subs
        %o
      %-  ~(rep by subs.sat)
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
      :+  %latest
        %a
      %+  turn  latest.sat
      |=  [who=@p stack=@tas item=@tas]
      %-  pairs:enjs:format
      :~  who+(ship:enjs:format who)
          stack+s+stack
          item+s+item
      ==
      :+  %review
        %a
      %+  turn  ~(tap in review.sat)
      |=  [who=@p stack=@tas item=@tas]
      %-  pairs:enjs:format
      :~  who+(ship:enjs:format who)
          stack+s+stack
          item+s+item
      ==

  ::
      :+  %unread
        %a
      %+  turn  ~(tap in unread.sat)
      |=  [who=@p stack=@tas item=@tas]
      %-  pairs:enjs:format
      :~  who+(ship:enjs:format who)
          stack+s+stack
          item+s+item
      ==
  ::
      :+  %invites
        %a
      %+  turn  ~(tap in invites.sat)
      |=  [[who=@p stack=@tas] title=@t]
      %-  pairs:enjs:format
      :~  who+(ship:enjs:format who)
          stack+s+stack
          title+s+title
      ==
  ==
::
++  make-tile-moves
  ^-  (list card)
  [%give %fact ~[/srrstile] %json !>(make-tile-json)]~
::
++  make-tile-json
  ^-  json
  %-  pairs:enjs:format
  :~  invites+(numb:enjs:format ~(wyt by invites))
      new+(numb:enjs:format ~(wyt in unread))
  ==
::
++  add-item
  |=  [nam=@tas stak=@tas]
  ^-  card
  =/  ipax=path  /app/srrs/[stak]/[nam]/srrs-item-info
  =/  info
  =|  inf=item-info
    %=  inf
      author  src.bol
      stack  stak
      name  nam
      date-created  now.bol
      last-modified  now.bol
    ==
  (write-file ipax %srrs-item-info !>(info))
::
++  add-stack
  |=  [info=stack-info items=(map @tas note:publish)]
  ^-  (quip card _state)
  =|  sta=stack
  =/  new-stack
  %=  sta
    stack  [%.y info]
    name  filename.info
    last-update  last-modified.info
    items  items
    status  (~(run by items) |*(a=* (learned-status [.2.5 0 0])))
  ==
  =/  new-pubs  (~(put by pubs.state) filename.info new-stack)
  =/  pax=path  /app/srrs/[filename.info]/srrs-info
  [[(write-file pax %srrs-info !>(info))]~ state(pubs new-pubs)]
::
++  add-books
  |=  books=(map @tas notebook:publish)
  ^-  (quip card _state)
  %+  roll  ~(tap by books)
  |=  [book=[@tas notebook:publish] cad=(list card) sty=_state]
  ::  =/  exists=?
  ::  ?|
  ::    (~(has by pubs.sty) -.book)
  ::    !=((find [pax]~ paths.sty) ~)
  ::  ==
  ::  ?:  exists
  ::    [cad sty]
  =/  act
  [%new-stack -.book title.book notes.book %none read=*rule:clay write=*rule:clay]
  =/  mov=card
  [%pass /stacks %agent [our.bol %srrs] %poke %srrs-action !>(act)]
  [(snoc cad mov) sty]
::
++  update-learned-status
  |=  [stak=@tas item=@tas =recall-grade]
  ^-  (quip card _state)
  =/  old-stack=stack  (~(got by pubs.state) stak)
  =/  item-status=learned-status  (~(got by status.old-stack) item)
  =/  ease=@rs  (next-ease recall-grade item-status)
  =/  box=@  (next-box recall-grade item-status)
  ~&  box+box
  =/  interval=@rs  (next-interval [ease box item-status])
  =/  new-item-status=learned-status  (learned-status [ease interval box])
  ~&  new-item-status+new-item-status
  =/  new-status  (~(put by status.old-stack) item new-item-status)
  =/  new-stack  old-stack(status new-status)
  [~ state(pubs (~(put by pubs) stak new-stack))]
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
  ~&  old+box.learned-status
  ~&  new+(add box.learned-status 1)
  (add box.learned-status 1)
::
++  next-interval
  |=  [next-ease=@rs next-box=@ =learned-status]
  ^-  @rs
  ::  ~15 min, 1 day, 6 days
  =/  fixed-intervals=(list @rs)  [.0 .0.1 .1.0 .6.0 ~]
  ?:  (lth next-box (lent fixed-intervals))
    (snag next-box fixed-intervals)
  (interval-fuzz (mul:rs next-ease interval.learned-status))
::
++  next-clay
  |=  [=wire =path]
  ^-  card
  =/  rav  [%next %t [%da now.bol] path]
  [%pass wire %arvo %c %warp our.bol q.byk.bol `rav]
::
++  interval-fuzz
  |=  interval=@rs
  =/  random  ~(. og eny.bol)
  =/  r=@rs  (add:rs `@rs`.0.9 (rad:random .1.1))
  (mul:rs interval r)
::
++  sing-clay
  |=  [=wire =path]
  ^-  card
  =/  rav  [%sing %t [%da now.bol] path]
  [%pass wire %arvo %c %warp our.bol q.byk.bol `rav]
--
