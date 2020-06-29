/-  *srrs, chat-store, *chat-view, *chat-hook,
    *permission-store, *group-store, *invite-store, sole
/+  *srrs, *srrs-json, default-agent, verb, dbug,
    auto=language-server-complete, shoe
::
|%
+$  card  card:shoe
::
+$  versioned-state
  $%  state-0
  ==
::
+$  state-0
  $:  audience=(set target)                         ::  active targets
      width=@ud                                     ::  display width
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
      [%delete-item @tas @t]
      [%delete-stack @p @t]
      [%import @p @t]
      [%copy-stack @p @t ?]
      [%import-file path]
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
%-  (agent:shoe command)
^-  (shoe:shoe command)
=<
  |_  =bowl:gall
  +*  this       .
      srrs-core  +>
      sc         ~(. srrs-core(eny eny.bowl) bowl)
      def        ~(. (default-agent this %|) bowl)
      des        ~(. (default:shoe this command) bowl)
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
      ==
    [cards this]
  ::
  ++  on-watch  on-watch:def
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
  ++  command-parser
    |=  sole-id=@ta
    parser:sh:sc
  ::
  ++  tab-list
    |=  sole-id=@ta
    tab-list:sh:sc
  ::
  ++  on-command
    |=  [sole-id=@ta =command]
    =^  cards  state
      (work:sh:sc command)
    [cards this]
  ::
  ++  on-connect
    |=  sole-id=@ta
    ^-  (quip card _this)
    [[prompt:sh-out:sc ~] this]
  ::
  ++  can-connect     can-connect:des
  ++  on-disconnect   on-disconnect:des
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
::  +handle-delta: casts primary-delta to something printable
::
++  handle-delta
  |=  [=wire del=primary-delta]
  ^-  (quip card _state)
  =/  [wir=^wire mark=@tas]
    ?+  -.del  [wire %txt]
      %add-review-item  [/[-.wire]/chat %letter]
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
  =^  say-cards  state  (work:sh [%say !<(letter:chat-store q.cage)])
  [say-cards state]
::
::  +sh: handle user input
::
++  sh
  |%
  ::  +parser: command parser
  ::
  ::    parses the command line buffer.
  ::    produces commands which can be executed by +work.
  ::
  ++  parser
    |^
      %+  knee  *command  |.  ~+
      =-  ;~(pfix mic -)
      ;~  pose
        (stag %target tars)
        ;~(plug (tag %help) (easy ~))
        ;~(plug (tag %all-reviews) (easy ~))
        ;~((glue ace) (tag %delete-item) sym qut)
        ;~((glue ace) (tag %delete-stack) ship qut)
        ;~((glue ace) (tag %import) ship qut)
        ;~((glue ace) (tag %copy-stack) ship qut bool)
        ;~((glue ace) (tag %import-file) file-path)
        ;~(plug (tag %settings) (easy ~))
      ==
    ::
    ++  tag   |*(a=@tas (cold a (jest a)))
    ++  bool
      ;~  pose
        (cold %| (jest '%.y'))
        (cold %& (jest '%.n'))
      ==
    ++  ship  ;~(pfix sig fed:ag)
    ++  path  ;~(pfix net ;~(plug urs:ab (easy ~)))  ::NOTE  short only, tmp
    ++  file-path  ;~(pfix net (more net (cook crip (star ;~(less net prn)))))
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
    ::  +text: text message body
    ::
    ++  text
      %+  cook  crip
      (plus next)
  --
  ::  +tab-list: static list of autocomplete entries
  ::
  ++  tab-list
    ^-  (list [@t tank])
    :~
      [%help leaf+";help"]
      [%all-reviews leaf+";all-reviews"]
      [%delete-item leaf+";delete-item [stack-name] [item-id]"]
      [%delete-stack leaf+";delete-stack [stack-name]"]
      [%import leaf+";import [who (@p)] [stack-name]"]
      [%copy-stack leaf+";copy-stack [who (@p)] [stack-name] [keep-learned] (add subscribed stacks to main library)"]
      [%import-file leaf+";import-file [path to tab separated file]"]
      [%settings leaf+";settings"]
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
          %delete-item  (delete-item +.job)
          %delete-stack  (delete-stack +.job)
          %import  (import +.job)
          %copy-stack  (copy-stack +.job)
          %import-file  (import-file +.job)
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
    ::
    ::  +show-settings: print enabled flags, timezone and width settings
    ::
    ++  show-settings
      ^-  (quip card _state)
      :_  state
      =/  targets
        %+  turn  ~(tap in audience)
        |=  =target  ~&  target+target  ~
      :~  (print:sh-out "width: {(scow %ud width)}")
      ==
    ::
    ++  delete-item
      |=  [stack=@tas item=@t]
      ^-  (quip card _state)
      =-  [[- ~] state]
      %^  act  %delete-item  %srrs
      :-  %srrs-action
      !>  ^-  action
      [%delete-item stack item]
    ::
    ++  delete-stack
      |=  [who=@p stack=@t]
      ^-  (quip card _state)
      =-  [[- ~] state]
      %^  act  %delete-stack  %srrs
      :-  %srrs-action
      !>  ^-  action
      [%delete-stack who (string-to-symbol (trip stack))]
    ::
    ++  import
      |=  [who=@p stack=@t]
      ^-  (quip card _state)
      =-  [[- ~] state]
      %^  act  %import  %srrs
      :-  %srrs-action
      !>  ^-  action
      [%import who (string-to-symbol (trip stack))]
    ::
    ++  copy-stack
      |=  [who=@p stack=@t keep-learned=?]
      ^-  (quip card _state)
      =-  [[- ~] state]
      %^  act  %copy-stack  %srrs
      :-  %srrs-action
      !>  ^-  action
      [%copy-stack who (string-to-symbol (trip stack)) keep-learned]
    ::
    ++  import-file
      |=  =path
      ^-  (quip card _state)
      =-  [[- ~] state]
      %^  act  %import-file  %srrs
      :-  %srrs-action
      !>  ^-  action
      [%import-file path]
    ::
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
      =/  reviews  (scry-for (list review) %srrs /review)
      =/  json  :-  %a
        %+  turn
          reviews
        review-to-json
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
    |=  effect=sole-effect:sole
    ^-  card
    [%shoe ~ %sole effect]
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
