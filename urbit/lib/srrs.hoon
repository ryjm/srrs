/-  *srrs
/+  elem-to-react-json, publish
|%
++  time-to-atom
  |=  time=@d
  ^-  @
  (yule (yell time))
::
++  time-to-rs
  |=  time=@d
  ^-  @rs
  (sun:rs (time-to-atom time))
::
++  rs-to-time
  |=  time=@rs
  ^-  @dr
  (abs:si (need (toi:rs time)))
::
++  stack-info-to-json
  |=  con=stack-info
  ^-  json
  %-  pairs:enjs:format
  :~  :-  %owner          [%s (scot %p owner.con)]
      :-  %title          [%s title.con]
      :-  %allow-edit     [%s allow-edit.con]
      :-  %date-created   (time:enjs:format date-created.con)
      :-  %last-modified  (time:enjs:format last-modified.con)
      :-  %filename       [%s filename.con]
  ==
::
++  tang-to-json
  |=  tan=tang
  %-  wall:enjs:format
  %-  zing
  %+  turn  tan
  |=  a=tank
  (wash [0 80] a)
::
++  string-to-symbol
  |=  tap=tape
  ^-  @tas
  %-  crip
  %+  turn  tap
  |=  a=@
  ?:  ?|  &((gte a 'a') (lte a 'z'))
          &((gte a '0') (lte a '9'))
      ==
    a
  ?:  &((gte a 'A') (lte a 'Z'))
    (add 32 a)
  '-'
::
++  item-to-json
  |=  =item
  ^-  json
  %-  pairs:enjs:format
  :~  content+(note-full-json:publish filename.content.item content.item)
      learn+(status-to-json learn.item)
  ==
::
++  stack-build-to-json
  |=  bud=(each stack-info tang)
  ^-  json
  ?:  ?=(%.y -.bud)
    (stack-info-to-json +.bud)
  (tang-to-json +.bud)
::
++  status-to-json
  |=  status=learned-status
  ^-  json
  %-  pairs:enjs:format
  :~  :-  %ease  [%s (scot %rs ease.status)]
      :-  %interval  [%s (scot %dr interval.status)]
      :-  %box  [%s (scot %u box.status)]
  ==
::
++  stack-status-to-json
  |=  stack=stack
  ^-  json
  :-  %o
  %+  roll  ~(tap in ~(key by items.stack))
  |=  [item=@tas out=(map @t json)]
  =/  status-build  (~(got by status.stack) item)
  %+  ~(put by out)
    item
  (status-to-json status-build)
::
++  total-build-to-json
  |=  stack=stack
  ^-  json
  %-  pairs:enjs:format
  :~  info+(stack-build-to-json stack.stack)
  ::
    :+  %items
      %o
    %+  roll  ~(tap in ~(key by items.stack))
    |=  [item=@tas out=(map @t json)]
    =/  item-build  (~(got by items.stack) item)
    %+  ~(put by out)
      item
    (item-to-json item-build)
  ::
    :-  %order
    %-  pairs:enjs:format
    :~  pin+a+(turn pin.order.stack |=(s=@tas [%s s]))
        unpin+a+(turn ~(tap in ~(key by items.stack)) |=(s=@tas [%s s]))
    ==
  ::
    :-  %contributors
    %-  pairs:enjs:format
    :~  mod+s+mod.contributors.stack
        :+  %who
          %a
        %+  turn  ~(tap in who.contributors.stack)
        |=  who=@p
        (ship:enjs:format who)
    ==
  ::
    :+  %subscribers
      %a
    %+  turn  ~(tap in subscribers.stack)
    |=  who=@p
    ^-  json
    (ship:enjs:format who)
  ::
    [%last-update (time:enjs:format last-update.stack)]
  ==
--
