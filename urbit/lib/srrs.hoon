/-  *srrs
/+  elem-to-react-json, publish
|%
::
::  ++  front-to-item-info
::    |=  fro=(map knot cord)
::    ^-  item-info
::    =/  got  ~(got by fro)
::    ~|  %invalid-frontmatter
::    :*  (slav %p (got %author))
::        (got %title)
::        (got %stack)
::        (got %filename)
::        (slav %da (got %date-created))
::        (slav %da (got %last-modified))
::    ==
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
++  item-info-to-json
  |=  info=item-info
  ^-  json
  %-  pairs:enjs:format
  :~  :-  %author        [%s (scot %p author.info)]
      :-  %date-created   (time:enjs:format date-created.info)
      :-  %last-modified  (time:enjs:format last-modified.info)
      :-  %name       [%s name.info]
      :-  %stack     [%s stack.info]
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
++  stack-build-to-json
  |=  bud=(each stack-info tang)
  ^-  json
  ?:  ?=(%.y -.bud)
    (stack-info-to-json +.bud)
  (tang-to-json +.bud)
::
++  item-build-to-json
  |=  bud=(each [item-info manx @t] tang)
  ^-  json
  ?:  ?=(%.y -.bud)
    %-  pairs:enjs:format
    :~  info+(item-info-to-json +<.bud)
        body+(elem-to-react-json +>-.bud)
        raw+[%s +>+.bud]
    ==
  (tang-to-json +.bud)
::
++  total-build-to-json
  |=  stack=stack
  ^-  json
  ~&  [%keys ~(key by items.stack)]
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
    %-  pairs:enjs:format
    :~  item+(note-full-json:publish item item-build)
    ==
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
