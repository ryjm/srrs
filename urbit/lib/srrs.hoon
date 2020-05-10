/-  *srrs
/+  elem-to-react-json, publish
|%
::
++  form-snippet
  |=  file=@t
  ^-  @t
  =/  front-idx     (add 3 (need (find ";>" (trip file))))
  =/  front-matter  (cat 3 (end 3 front-idx file) 'dummy text\0a')
  =/  body  (cut 3 [front-idx (met 3 file)] file)
  (of-wain:format (scag 1 (to-wain:format body)))
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
  :~  content+(content-full-json filename.content.item content.item)
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
  |=  [item-name=@tas out=(map @t json)]
  =/  =item  (~(got by items.stack) item-name)
  %+  ~(put by out)
    item-name
  (status-to-json learn.item)
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
::
++  update-to-json
  |=  update=update
  ^-  json
  %-  pairs:enjs:format
    :~  who+s+(scot %p who.update)
        stack+s+stack.update
        item+s+item.update
    ==
::
++  content-full-json
  |=  [content-name=@tas =content]
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  note-id+s+content-name
      author+s+(scot %p author.content)
      title+s+title.content
      date-created+(time date-created.content)
      snippet+s+snippet.content
      front+s+front.content
      back+s+back.content
      num-comments+(numb ~(wyt by comments.content))
      comments+(comments-page comments.content 0 50)
      read+b+read.content
      pending+b+pending.content
  ==
::
++  comments-page
  |=  [comments=(map @da comment) start=@ud end=@ud]
  ^-  json
  =/  coms=(list [@da comment])
    %+  sort  ~(tap by comments)
    |=  [[d1=@da comment] [d2=@da comment]]
    (gte d1 d2)
  %-  comments-list-json
  (scag end (slag start coms))
::
++  comments-list-json
  |=  comments=(list [@da comment])
  ^-  json
  =,  enjs:format
  :-  %a
  (turn comments comment-json)
::
++  comment-json
  |=  [date=@da com=comment]
  ^-  json
  =,  enjs:format
  %+  frond:enjs:format
    (scot %da date)
  %-  pairs
  :~  author+s+(scot %p author.com)
      date-created+(time date-created.com)
      content+s+content.com
      pending+b+pending.com
  ==
--
