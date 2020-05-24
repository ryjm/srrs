/-  *srrs, sole-sur=sole, chat-store, *chat-view, *chat-hook,
    *permission-store, *group-store, *invite-store
/+  sole-lib=sole, *srrs, *srrs-json, default-agent, verb, dbug,
    auto=language-server-complete
::
|%
+$  card  card:agent:gall
::
+$  versioned-state
  $%  state-0
  ==
::
+$  state-0
  $:  audience=(set target)                         ::  active targets
      width=@ud                                     ::  display width
      cli=state=sole-share:sole-sur                 ::  console state
      eny=@uvJ                                      ::  entropy
  ==
::
+$  target  [in-group=? =ship =path]
::
+$  command
  $%  [%target (set target)]                        ::  set messaging target
      [%say letter:chat-store]                      ::  send message
      [%width @ud]                                  ::  display width
      [%help ~]                                     ::  print usage info
      [%all-reviews ~]
      [%settings ~]
  ==
::
--
=|  state-0
=*  state  -
::
%-  agent:dbug
%+  verb  |
^-  agent:gall
=<
  |_  =bowl:gall
  +*  this       .
      srrs-core  +>
      sc         ~(. srrs-core(eny eny.bowl) bowl)
      def        ~(. (default-agent this %|) bowl)
  ::
  ++  on-init
    ^-  (quip card _this)
    =^  cards  state  (prep:sc ~)
    [cards this]
  ::
  ++  on-save  !>(state)
  ::
  ++  on-load
    |=  old-state=vase
    ^-  (quip card _this)
    =/  old  !<(versioned-state old-state)
    =^  cards  state  (prep:sc `old)
    [cards this]
  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    =^  cards  state
      ?+  mark        (on-poke:def mark vase)
        %noun         (poke-noun:sc !<(* vase))
        %sole-action  (poke-sole-action:sc !<(sole-action:sole-sur vase))
      ==
    [cards this]
  ::
  ++  on-watch
    |=  =path
    ^-  (quip card _this)
    =^  cards  state  (peer:sc path)
    [cards this]
  ::
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    =^  cards  state
      ?-    -.sign
        %poke-ack   [- state]:(on-agent:def wire sign)
        %watch-ack  [- state]:(on-agent:def wire sign)
      ::
          %kick
        :_  state
        ?+  wire  ~
          [%srrs ~]  ~[connect:sc]
        ==
      ::
          %fact
        ?+  p.cage.sign  ~|([%srrs-cli-bad-sub-mark wire p.cage.sign] !!)
            %srrs-primary-delta
          (handle-delta:sc wire !<(primary-delta q.cage.sign))
        ==
      ==
    [cards this]
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    =^  cards  state
      ?+  wire  [~ state]
        [%srrs ~]  (handle-srrs:sc sign-arvo)
        [%srrs %chat ~]  (handle-srrs-chat:sc sign-arvo)
      ==
    [cards this]
  ++  on-fail   on-fail:def
  --
::
|_  =bowl:gall
::  +prep: setup & state adapter
::
++  prep
  |=  old=(unit versioned-state)
  ^-  (quip card _state)
  ?~  old
    =^  cards  state
      :-  ~[connect]
      %_  state
        audience  [[| our-self /srrs] ~ ~]
        width     80
      ==
    [cards state]
  [~ state(width 80, audience [[| our-self /srrs] ~ ~])]
::  +connect: connect to srrs
::
++  connect
  ^-  card
  [%pass /srrs %agent [our-self %srrs] %watch /srrs-primary]
::
++  our-self  (name:title our.bowl)
::  +target-to-path: prepend ship to the path
::
++  target-to-path
  |=  target
  ^-  ^path
  %+  weld
    ?:(in-group ~ /~)
  [(scot %p ship) path]
::  +poke-noun: debug helpers
::
++  poke-noun
  |=  a=*
  ^-  (quip card _state)
  ?:  ?=(%connect a)
    [[connect ~] state]
  [~ state]
::  +poke-sole-action: handle cli input
::
++  poke-sole-action
  ::TODO  use id.act to support multiple separate sessions
  |=  [act=sole-action:sole-sur]
  ^-  (quip card _state)
  (sole:sh-in act)
::  +peer: accept only cli subscriptions from ourselves
::
++  peer
  |=  =path
  ^-  (quip card _state)
  ?.  (team:title our-self src.bowl)
    ~|  [%peer-srrs-stranger src.bowl]
    !!
  ?.  ?=([%sole *] path)
    ~|  [%peer-srrs-strange path]
    !!
  ::  display a fresh prompt
  :-  [prompt:sh-out ~]
  ::  start with fresh sole state
  state(state.cli *sole-share:sole-sur)
::  +handle-delta: casts primary-delta to something printable
::
++  handle-delta
  |=  [=wire del=primary-delta]
  ^-  (quip card _state)
  =/  [wir=^wire mark=@tas]
    ?+  -.del  [wire %txt]
      %add-raised-item  [/[-.wire]/chat %letter]
      %add-item  [/[-.wire]/chat %letter]
    ==
  =/  ford-card=card  :*
    %pass  wir  %arvo  %f
    %build
      live=%.n
      ^-  schematic:ford
      =/  =beak  byk.bowl
      [%cast [p q]:beak mark [%$ [%srrs-primary-delta !>(del)]]]
  ==
  [[ford-card ~] state]
::  +handle-srrs: handle updates from the /srrs-primary wire
::
++  handle-srrs
  |=  =sign-arvo
  ^-  (quip card _state)
  ?>  ?=(%made +<.sign-arvo)
  =/  [date=@da result=made-result:ford]  +>.sign-arvo
  ?:  ?=(%incomplete -.result)
    [~ state]
  =/  =cage  (result-to-cage:ford build-result.result)
  [[(show-result:sh-out cage) ~] state]
::  +handle-srrs-chat: handle updates and send to chat
::
++  handle-srrs-chat
  |=  =sign-arvo
  ^-  (quip card _state)
  ?>  ?=(%made +<.sign-arvo)
  =/  [date=@da result=made-result:ford]  +>.sign-arvo
  ?:  ?=(%incomplete -.result)
    [~ state]
  ?:  ?=([%error *] build-result.result)
    (mean message.build-result.result)
  =/  =cage  (result-to-cage:ford build-result.result)
  =^  say-cards  state  (work:sh-in [%say !<(letter:chat-store q.cage)])
  [say-cards state]
::
::  +sh-in: handle user input
::
++  sh-in
  |%
  ::  +sole: apply sole action
  ::
  ++  sole
    |=  act=sole-action:sole-sur
    ^-  (quip card _state)
    ?-  -.dat.act
      %det  (edit +.dat.act)
      %clr  [~ state]
      %ret  obey
      %tab  (tab +.dat.act)
    ==
  ::  +tab-list: static list of autocomplete entries
  ::
  ++  tab-list
    ^-  (list (option:auto tank))
    :~
      [%help leaf+";help"]
      [%all-reviews leaf+";all-reviews"]
      [%settings leaf+";settings"]
    ==
  ++  tab
    |=  pos=@ud
    ^-  (quip card _state)
    ?:  ?|  =(~ buf.state.cli)
            !=(';' -.buf.state.cli)
        ==
      :_  state
      [(effect:sh-out [%bel ~]) ~]
    ::
    =+  (get-id:auto pos (tufa buf.state.cli))
    =/  needle=term
      (fall id '')
    ?:  &(!=(pos 1) =(0 (met 3 needle)))
      [~ state]  :: autocomplete empty command iff user at start of command
    =/  options=(list (option:auto tank))
      (search-prefix:auto needle tab-list)
    =/  advance=term
      (longest-match:auto options)
    =/  to-send=tape
      (trip (rsh 3 (met 3 needle) advance))
    =/  send-pos
      (add pos (met 3 (fall forward '')))
    =|  moves=(list card)
    =?  moves  ?=(^ options)
      [(tab:sh-out options) moves]
    =|  fxs=(list sole-effect:sole-sur)
    |-  ^-  (quip card _state)
    ?~  to-send
      [(flop moves) state]
    =^  char  state.cli
      (~(transmit sole-lib state.cli) [%ins send-pos `@c`i.to-send])
    %_  $
      moves  [(effect:sh-out %det char) moves]
      send-pos  +(send-pos)
      to-send  t.to-send
    ==
  ::  +edit: apply sole edit
  ::
  ::    called when typing into the cli prompt.
  ::    applies the change and does sanitizing.
  ::
  ++  edit
    |=  cal=sole-change:sole-sur
    ^-  (quip card _state)
    =^  inv  state.cli  (~(transceive sole-lib state.cli) cal)
    =+  fix=(sanity inv buf.state.cli)
    ?~  lit.fix
      [~ state]
    ::  just capital correction
    ?~  err.fix
      (slug fix)
    ::  allow interior edits and deletes
    ?.  &(?=($del -.inv) =(+(p.inv) (lent buf.state.cli)))
      [~ state]
    (slug fix)
  ::  +sanity: check input sanity
  ::
  ::    parses cli prompt using +read.
  ::    if invalid, produces error correction description, for use with +slug.
  ::
  ++  sanity
    |=  [inv=sole-edit:sole-sur buf=(list @c)]
    ^-  [lit=(list sole-edit:sole-sur) err=(unit @u)]
    =+  res=(rose (tufa buf) read)
    ?:  ?=(%& -.res)  [~ ~]
    [[inv]~ `p.res]
  ::  +slug: apply error correction to prompt input
  ::
  ++  slug
    |=  [lit=(list sole-edit:sole-sur) err=(unit @u)]
    ^-  (quip card _state)
    ?~  lit  [~ state]
    =^  lic  state.cli
      %-  ~(transmit sole-lib state.cli)
      ^-  sole-edit:sole-sur
      ?~(t.lit i.lit [%mor lit])
    :_  state
    :_  ~
    %+  effect:sh-out  %mor
    :-  [%det lic]
    ?~(err ~ [%err u.err]~)
  ::  +read: command parser
  ::
  ::    parses the command line buffer.
  ::    produces commands which can be executed by +work.
  ::
  ++  read
    |^
      %+  knee  *command  |.  ~+
      =-  ;~(pfix mic -)
      ;~  pose
        (stag %target tars)
        ;~(plug (tag %help) (easy ~))
        ;~(plug (tag %all-reviews) (easy ~))
        ;~(plug (tag %settings) (easy ~))
      ==
    ::
    ++  tag   |*(a=@tas (cold a (jest a)))
    ++  ship  ;~(pfix sig fed:ag)
    ++  path  ;~(pfix net ;~(plug urs:ab (easy ~)))  ::NOTE  short only, tmp
    ::  +mang: un/managed indicator prefix
    ::
    ++  mang
      ;~  pose
        (cold %| (jest '~/'))
        (cold %& (easy ~))
      ==
    ::  +tarl: local target, as /path
    ::
    ++  tarl  (stag our-self path)
    ::  +tarx: local target, maybe managed
    ::
    ++  tarx  ;~(plug mang path)
    ::  +tarp: sponsor target, as ^/path
    ::
    ++  tarp
      =-  ;~(pfix ket (stag - path))
      (sein:title our.bowl now.bowl our-self)
    ::  +targ: any target, as tarl, tarp, ~ship/path
    ::
    ++  targ
      ;~  plug
        mang
      ::
        ;~  pose
          tarl
          tarp
          ;~(plug ship path)
        ==
      ==
    ::  +tars: set of comma-separated targs
    ::
    ++  tars
      %+  cook  ~(gas in *(set target))
      (most ;~(plug com (star ace)) targ)
    ::  +ships: set of comma-separated ships
    ::
    ::  +ships: set of comma-separated ships
    ::
    ++  ships
      %+  cook  ~(gas in *(set ^ship))
      (most ;~(plug com (star ace)) ship)
  --
  ::  +obey: apply result
  ::
  ::    called upon hitting return in the prompt.
  ::    if input is invalid, +slug is called.
  ::    otherwise, the appropriate work is done and
  ::    the command (if any) gets echoed to the user.
  ::
  ++  obey
    ^-  (quip card _state)
    =+  buf=buf.state.cli
    =+  fix=(sanity [%nop ~] buf)
    ?^  lit.fix
      (slug fix)
    =+  jub=(rust (tufa buf) read)
    ?~  jub  [[(effect:sh-out %bel ~) ~] state]
    =^  cal  state.cli  (~(transmit sole-lib state.cli) [%set ~])
    =^  cards  state  (work u.jub)
    :_  state
    %+  weld
      ^-  (list card)
      ::  echo commands into scrollback
      ?.  =(`0 (find ";" buf))  ~
      [(note:sh-out (tufa `(list @)`buf)) ~]
    :_  cards
    %+  effect:sh-out  %mor
    :~  [%nex ~]
        [%det cal]
    ==
  ::  +work: run user command
  ::
  ++  work
    |=  job=command
    ^-  (quip card _state)
    |^  ?-  -.job
          %target    (set-target +.job)
          %say       (say +.job)
          %width     (set-width +.job)
          %help      help
          %all-reviews  all-reviews
          %settings  show-settings
        ==
    ::  +act: build action card
    ::
    ++  act
      |=  [what=term app=term =cage]
      ^-  card
      :*  %pass
          /cli-command/[what]
          %agent
          [our-self app]
          %poke
          cage
      ==
    ::  +set-target: set audience
    ::
    ++  set-target
      |=  tars=(set target)
      ^-  (quip card _state)
      =.  audience  tars
      [~ state]
    ::  +say: send messages to srrs chat
    ::
    ++  say
      |=  =letter:chat-store
      ^-  (quip card _state)
      =/  =serial  (shaf %msg-uid eny.bowl)
      :_  state(eny (shax eny.bowl))
      ^-  (list card)
      %+  turn  ~(tap in audience)
      |=  =target
      %^  act  %out-message  %chat-hook
      :-  %chat-action
      !>  ^-  action:chat-store
      :+  %message  (target-to-path target)
      [serial *@ our-self now.bowl letter]
    ::  +show-settings: print enabled flags, timezone and width settings
    ::
    ++  show-settings
      ^-  (quip card _state)
      :_  state
      :~  (print:sh-out "width: {(scow %ud width)}")
      ==
    ::  +set-width: configure cli printing width
    ::
    ++  set-width
      |=  w=@ud
      [~ state(width w)]
    ::  +all-reviews: show items needing review
    ::
    ++  all-reviews
      ^-  (quip card _state)
      =,  html
      =/  reviews  (scry-for (set update) %srrs /review)
      =/  json  :-  %a
        %+  turn
          ~(tap in reviews)
        update-to-json
      =/  print-card=card  (print:sh-out "reviews: {(en-json json)}")
      =^  say-cards  state
        (say `letter:chat-store`[%text (crip "reviews: {(en-json json)}")])
      [(flop (snoc say-cards print-card)) state]
    ::
    ::  +help: print (link to) usage instructions
    ::
    ++  help
      ^-  (quip card _state)
      =-  [[- ~] state]
      (print:sh-out "see https://github.com/ryjm/srrs")
    --
  --
::
::  +sh-out: output to the cli
::
++  sh-out
  |%
  ::  +effect: console effect card
  ::
  ++  effect
    |=  fec=sole-effect:sole-sur
    ^-  card
    ::TODO  don't hard-code session id 'drum' here
    [%give %fact ~[/sole/drum] %sole-effect !>(fec)]
  ::  +tab: print tab-complete list
  ::
  ++  tab
    |=  options=(list [cord tank])
    ^-  card
    (effect %tab options)
  ::  +print: puts some text into the cli as-is
  ::
  ++  print
    |=  txt=tape
    ^-  card
    (effect %txt txt)
  ::  +print-more: puts lines of text into the cli
  ::
  ++  print-more
    |=  txs=(list tape)
    ^-  card
    %+  effect  %mor
    (turn txs |=(t=tape [%txt t]))
  ::  +note: prints left-padded ---| txt
  ::
  ++  note
    |=  txt=tape
    ^-  card
    =+  lis=(simple-wrap txt (sub width 16))
    %-  print-more
    =+  ?:((gth (lent lis) 0) (snag 0 lis) "")
    :-  (runt [14 '-'] '|' ' ' -)
    %+  turn  (slag 1 lis)
    |=(a=tape (runt [14 ' '] '|' ' ' a))
  ::  +prompt: update prompt to display current audience
  ::
  ++  prompt
    ^-  card
    %+  effect  %pro
    :+  &  %srrs-line
    ^-  tape
    ">"
  ::
  ++  show-result
    |=  =cage
    ^-  card
    =/  typ  p.cage
    =/  =vase  q.cage
    (note "result: {(noah vase)}")
  ::
  --
::
++  simple-wrap
  |=  [txt=tape wid=@ud]
  ^-  (list tape)
  ?~  txt  ~
  =/  [end=@ud nex=?]
    ?:  (lte (lent txt) wid)  [(lent txt) &]
    =+  ace=(find " " (flop (scag +(wid) `tape`txt)))
    ?~  ace  [wid |]
    [(sub wid u.ace) &]
  :-  (tufa (scag end `(list @)`txt))
  $(txt (slag ?:(nex +(end) end) `tape`txt))
::
::NOTE  anything that uses this breaks moons support, because moons don't sync
::      full app state rn
++  scry-for
  |*  [=mold app=term =path]
  .^  mold
    %gx
    (scot %p our.bowl)
    app
    (scot %da now.bowl)
    (snoc `^path`path %noun)
  ==
--
