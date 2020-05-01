::
::::  /hoon/action/srrs/mar
  ::
/?  309
/-  *srrs
/+  publish, *srrs
=,  format
::
|_  del=primary-delta
::
++  grow
  |%
  ++  json
  %+  frond:enjs:format  -.del
  ?-  -.del
      %add-item
    %+  frond:enjs:format  (scot %p who.del)
    %+  frond:enjs:format  stack.del
    (item-to-json data.del)
      %add-stack
    %+  frond:enjs:format  (scot %p who.del)
    %+  frond:enjs:format  stack.del
    (total-build-to-json data.del)
       %read
    %-  pairs:enjs:format
    :~  who+s+(scot %p who.del)
        stack+s+stack.del
        item+s+item.del
    ==
  ==
  --
::
++  grab
  |%
  ++  noun  primary-delta
  --
--
