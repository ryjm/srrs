/-  srrs, *publish
|=  [enabled=? =agent:gall]
=|  bowl-print=_|
^-  agent:gall
|^
|_  =bowl:gall
+*  this  .
    ag    ~(. agent bowl)
::
++  on-init
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-init")
  =^  cards  agent  on-init:ag
  [cards this]
::
++  on-save
  ^-  vase
  %-  (print bowl "{<dap.bowl>}: on-save")
  on-save:ag
::
++  on-load
  |=  old-state=vase
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-load")
  =^  cards  agent  (on-load:ag old-state)
  [cards this]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-poke with mark {<mark>}")
  ?:  ?=(%memo mark)
    ?-  !<(?(%enabled %bowl) vase)
      %enabled  `this(enabled !enabled)
      %bowl  `this(bowl-print !bowl-print)
    ==
  =^  cards  agent  (on-poke:ag mark vase)
  =/  publish-state  on-save:ag
  =/  books  (slop !>(%add-books) (slap publish-state [%limb %books]))
  =/  memo-cards=(list card:agent:gall)
  :~
      [%pass /memo %agent [our.bowl %srrs] %poke %srrs-action books]
  ==
  [(weld memo-cards cards) this]
::
++  on-watch
  |=  =path
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-watch on path {<path>}")
  =^  cards  agent  (on-watch:ag path)
  [cards this]
::
++  on-leave
  |=  =path
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-leave on path {<path>}")
  =^  cards  agent  (on-leave:ag path)
  [cards this]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  %-  (print bowl "{<dap.bowl>}: on-peek on path {<path>}")
  (on-peek:ag path)
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-agent on wire {<wire>}, {<-.sign>}")
  =^  cards  agent  (on-agent:ag wire sign)
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-arvo on wire {<wire>}, {<[- +<]:sign-arvo>}")
  %-  (print bowl "{<dap.bowl>}: state: {<on-save:ag>}")
  ~&  [%test 'test']
  =^  cards  agent  (on-arvo:ag wire sign-arvo)
  =/  publish-state  on-save:ag
  =/  books=vase
  (slop !>(%add-books) (slap publish-state [%limb %books]))
  =/  memo-cards=(list card:agent:gall)
  :~
      [%pass /memo %agent [our.bowl %srrs] %poke %srrs-action books]
  ==
  [(weld memo-cards cards) this]

::
++  on-fail
  |=  [=term =tang]
  ^-  (quip card:agent:gall agent:gall)
  %-  (print bowl "{<dap.bowl>}: on-fail with term {<term>}")
  =^  cards  agent  (on-fail:ag term tang)
  [cards this]
--
::
++  print
  |=  [=bowl:gall =tape]
  ^+  same
  =?  .  bowl-print
    %-  (slog >bowl< ~)
    .
  ?.  enabled  same
  %-  (slog leaf+tape ~)
  same
--
