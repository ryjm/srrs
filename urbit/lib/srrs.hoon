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
--
