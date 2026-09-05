/-  *seer, *sole
/+  *seer, *seer-json, default-agent, verb, dbug,
    auto=language-server-complete, shoe
::
|%
+$  card  card:shoe
::
+$  cli-state
  $:  width=$~(80 @ud)
      sessions=(map sole-id session)
      eny=@uvJ
  ==
::
+$  session  version=@ud
::
+$  command
  $%
    ::  display width
    ::
    [%width @ud]
    ::  print usage info
    ::
    [%help ~]
    [%all-reviews ~]
    [%stacks ~]
    [%delete-item @tas @t]
    [%add-stack @tas]
    [%delete-stack @tas (unit @p)]
    [%import @p @t]
    [%copy-stack @p @t ?]
    [%import-file path]
    [%settings ~]
  ==
::
--
=|  cli-state
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
      seer-core  +>
      sc         ~(. seer-core(eny eny.bowl) bowl)
      def        ~(. (default-agent this %|) bowl)
      des        ~(. (default:shoe this command) bowl)
  ::
  ++  on-init
    ^-  (quip card _this)
    [~[connect:sc] this(eny.state eny.bowl)]
  ::
  ++  on-save  !>(state)
  ::
  ++  on-load
    |=  =vase
    ^-  (quip card _this)
    ~|  'seer-cli-state-shape-changed: nuke %seer-cli and revive %seer'
    [~ this(state !<(cli-state vase))]
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
          %poke-ack
        ?.  ?=([%cli-command @ @ @ @ ~] wire)
          [- state]:(on-agent:def wire sign)
        (command-result:sc wire)
        %watch-ack  [- state]:(on-agent:def wire sign)
      ::
          %kick
        :_  state
        ?+  wire  ~
          [%seer ~]  ~[connect:sc]
        ==
      ::
          %fact
        ?+  p.cage.sign  ~|([%seer-cli-bad-sub-mark wire p.cage.sign] !!)
            %seer-primary-delta
          (handle-delta:sc wire !<(primary-delta q.cage.sign))
        ==
      ==
    [cards this]
  ::
  ++  on-arvo  on-arvo:def
  ::
  ++  on-fail   on-fail:def
  ++  command-parser
    |=  =sole-id
    parser:(make:sh:sc sole-id)
  ::
  ++  tab-list
    |=  =sole-id
    %+  turn  tab-list:sh:sc
    |=  [term=cord detail=tank]
    [(cat 3 ';' term) detail]
  ::
  ++  on-command
    |=  [=sole-id =command]
    ?>  =(our.bowl src.bowl)
    ?>  ?|  =(/gall/hood sap.bowl)
            =(/gall/dojo sap.bowl)
            =(/dill sap.bowl)
            =(/eyre sap.bowl)
        ==
    =^  cards  state
      (work:(make:sh:sc sole-id) command)
    [cards this]
  ::
  ++  on-connect
    |=  =sole-id
    ^-  (quip card _this)
    [[prompt:(make:sh-out:sc sole-id)]~ this]
  ::
  ++  can-connect     can-connect:des
  ++  on-disconnect   on-disconnect:des
  --
::
|_  =bowl:gall
::  +connect: connect to seer
::
++  connect
  ^-  card
  [%pass /seer %agent [our-self %seer] %watch /seer-primary]
::
++  get-session
  |=  =sole-id
  ^-  session
  (~(gut by sessions) sole-id %*(. *session version `@ud`1))
::
++  our-self  our.bowl
::  +poke-noun: debug helpers
::
++  poke-noun
  |=  a=*
  ^-  (quip card _state)
  ?:  ?=(%connect a)
    [[connect ~] state]
  [~ state]
::
++  command-result
  |=  wire=path
  ^-  (quip card _state)
  ?>  ?=([%cli-command @ @ @ @ ~] wire)
  =/  epoch  (slav %da i.t.t.wire)
  =/  operation  i.t.t.t.wire
  =/  session-id  (need ((soft sole-id) (cue (slav %uv i.t.t.t.t.wire))))
  =/  query  (scot %uv (jam [epoch operation *(unit @ux)]))
  =/  result=(each json tang)
    %-  mule
    |.
    .^  json
      %gx
      (scot %p our.bowl)
      %seer
      (scot %da now.bowl)
      /operation-result/[query]/json
    ==
  =/  message=tape
    ?:  ?=(%| -.result)  "receipt unavailable; reconcile before retrying"
    ?.  ?=(%o -.p.result)  "invalid receipt; reconcile before retrying"
    =/  status  (~(get by p.p.result) 'status')
    =/  reason  (~(get by p.p.result) 'reason')
    ?.  ?&(?=([~ %s *] status) ?=([~ %s *] reason))
      "invalid receipt; reconcile before retrying"
    "{(trip p.u.status)}: {(trip p.u.reason)}"
  :_  state
  :~  (print:(make:sh-out session-id) message)
      (print:(make:sh-out session-id) "operation {(trip operation)}; epoch {(scow %da epoch)}")
  ==
::  +handle-delta: casts primary-delta to something printable
::
++  handle-delta
  |=  [=wire del=primary-delta]
  ^-  (quip card _state)
  =/  [wir=^wire mark=@tas]
    ~&  >>  wire+wire
    ?+  -.del  [wire %txt]
      %add-review-item  [/[-.wire]/chat %letter]
      %add-item         [/[-.wire]/chat %letter]
    ==
  =/  cay=cage  [%seer-primary-delta !>(del)]
  =/  cc-path=path
    /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)/[p.cay]/[mark]
  =+  .^(=tube:clay %cc cc-path)
  =/  =cage  [mark (tube q.cay)]
  ?+  wir  [~ state]
    [%seer ~]  (handle-seer cage)
    [%seer %chat ~]  (handle-seer-chat cage)
  ==
::  +handle-seer: handle updates from the /seer-primary wire
::
++  handle-seer
  |=  =cage
  ^-  (quip card _state)
  [[(show-result:sh-out:sh cage) ~] state]
::  +handle-seer-chat: handle updates and send to chat
::
++  handle-seer-chat
  |=  =cage
  ^-  (quip card _state)
  ~!  q.cage
  ::  =^  say-cards  state  (work:sh [%say !<(letter:chat-store q.cage)])
  ::  [say-cards state]
  ::
  [~ state]
::
::  +sh: handle user input
::
++  sh
  |_  [=sole-id session]
  +*  session  +<+
      sh-out   ~(. ^sh-out sole-id session)
      put-ses  state(sessions (~(put by sessions) sole-id session))
  ::
  ++  make
    |=  =^sole-id
    %_  ..make
      sole-id  sole-id
      +<+      (get-session sole-id)
    ==
  ::  +parser: command parser
  ::
  ::    parses the command line buffer.
  ::    produces commands which can be executed by +work.
  ::
  ++  parser
    |^
      %+  stag  |
      %+  knee  *command  |.  ~+
      =-  ;~(pfix mic -)
      ;~  pose
        ;~(plug (tag %help) (easy ~))
        ;~(plug (tag %all-reviews) (easy ~))
        ;~(plug (tag %stacks) (easy ~))
        ;~((glue ace) (tag %delete-item) sym qut)
        ;~((glue ace) (tag %add-stack) sym)
        ;~((glue ace) (tag %delete-stack) ;~(plug sym shup))
        ;~((glue ace) (tag %import) ship qut)
        ;~((glue ace) (tag %copy-stack) ship qut bool)
        ;~((glue ace) (tag %import-file) file-path)
        ;~(plug (tag %settings) (easy ~))
      ==
    ::
    ++  tag   |*(a=@tas (cold a (jest a)))
    ++  shup  ;~(pose (cook some ship) (easy ~))
    ++  bool
      ;~  pose
        (cold %| (jest '%.y'))
        (cold %& (jest '%.n'))
      ==
    ++  ship  ;~(pfix sig fed:ag)
    ::note  short only, tmp
    ::
    ++  path  ;~(pfix fas ;~(plug urs:ab (easy ~)))
    ++  file-path
      ;~  pfix
        fas
        (more fas (cook crip (star ;~(less fas prn))))
      ==
    ::  +mang: un/managed indicator prefix
    ::
    ++  mang
      ;~  pose
        (cold %| (jest '~/'))
        (cold %& (easy ~))
      ==
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
    =/  copy-help=tape
      ;:  weld
        ";copy-stack [who (@p)] [stack-name] [keep-learned] "
        "(add subscribed stacks to main library)"
      ==
    :~
      [%help leaf+";help"]
      [%all-reviews leaf+";all-reviews"]
      [%stacks leaf+";stacks"]
      [%delete-item leaf+";delete-item [stack-name] [item-id]"]
      [%delete-stack leaf+";delete-stack [stack-name]"]
      [%add-stack leaf+";add-stack [stack-name]"]
      [%import leaf+";import [who (@p)] [stack-name]"]
      [%copy-stack leaf+copy-help]
      [%import-file leaf+";import-file [path to tab separated file]"]
      [%settings leaf+";settings"]
    ==
  ::  +work: run user command
  ::
  ++  work
    |=  job=command
    ^-  (quip card _state)
    |^  ?-  -.job
          %width         (set-width +.job)
          %help          help
          %all-reviews   all-reviews
          %stacks        stacks
          %delete-item   (delete-item +.job)
          %add-stack     (add-stack +.job)
          %delete-stack  (delete-stack +.job)
          %import        (import +.job)
          %copy-stack    (copy-stack +.job)
          %import-file   (import-file +.job)
          %settings      show-settings
        ==
    ::  +act: build action card
    ::
    ++  act
      |=  [what=term mutation=action]
      ^-  (quip card _state)
      =/  epoch  (scry-for @da %seer /idempotency-epoch)
      =/  operation  (scot %uv (shax (jam [eny now.bowl sole-id mutation])))
      =/  session-ref  (scot %uv (jam sole-id))
      :_  state
      :~  (print:sh-out "submitting {(trip operation)}")
          :*  %pass
              /cli-command/[what]/(scot %da epoch)/[operation]/[session-ref]
              %agent
              [our-self %seer]
              %poke
              %seer-action
              (command-vase epoch operation mutation)
          ==
      ==
    ::
    ++  show-settings
      ^-  (quip card _state)
      :_  state
      :~  (print:sh-out "width: {(scow %ud width)}")
      ==
    ::
    ++  delete-item
      |=  [stack=@tas item=@t]
      ^-  (quip card _state)
      (act %delete-item [%delete-item stack item])
    ::
    ++  delete-stack
      |=  [stack=@tas who=(unit @p)]
      ^-  (quip card _state)
      (act %delete-stack [%delete-stack (fall who our-self) stack])
    ::
    ::    +add-stack: add a stack
    ::
    ::  add a stack to the main library
    ::
    ++  add-stack
      |=  stack=@tas
      ^-  (quip card _state)
      (act %add-stack [%new-stack stack stack ~])
    ::
    ++  import
      |=  [who=@p stack=@t]
      ^-  (quip card _state)
      (act %import [%import who (string-to-symbol (trip stack))])
    ::
    ++  copy-stack
      |=  [who=@p stack=@t keep-learned=?]
      ^-  (quip card _state)
      (act %copy-stack [%copy-stack who (string-to-symbol (trip stack)) keep-learned])
    ::
    ++  import-file
      |=  =path
      ^-  (quip card _state)
      (act %import-file [%import-file path])
    ::
    ::  +set-width: configure cli printing width
    ::
    ++  set-width
      |=  w=@ud
      [~ state(width w)]
    ::
    ::  ++stacks: list of stacks
    ::
    ++  stacks
      ^-  (quip card _state)
      =/  stacks  (scry-for (map @tas stack) %seer /all)
      :_  state
      %+  turn  ~(tap by stacks)
      |=  [name=@tas =stack]
      (print:sh-out "{(trip name)}: {<(lent items.stack)>}")
    ::  +all-reviews: show items needing review
    ::
    ++  all-reviews
      ^-  (quip card _state)
      =/  reviews  (scry-for (list review) %seer /review)
      =/  json
        :-  %a
        %+  turn  reviews
        review-to-json
      =/  print-card=card
        (print:sh-out "review: {(trip (en:json:html json))}")
      [print-card^~ state]
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
  |_  [=sole-id session]
  ::
  ++  make
    |=  =^sole-id
    %_  ..make
      sole-id  sole-id
      +<+      (get-session sole-id)
    ==
  ++  effex
    |=  effect=shoe-effect:shoe
    ^-  card
    [%shoe ~[sole-id] effect]
  ::  +effect: emit console effect card
  ::
  ++  effect
    |=  effect=sole-effect:shoe
    ^-  card
    (effex %sole effect)
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
    :+  &  %seer-line
    ^-  tape
    "[r]> "
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
::note  anything that uses this breaks moons support, because moons don't sync
::      full app state rn
::
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
