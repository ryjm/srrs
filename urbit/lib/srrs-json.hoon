/-  *srrs
/+  *srrs
|%
++  primary-delta-to-json
  |=  del=primary-delta
  ^-  json
  =,  enjs:format
  %+  frond  -.del
  ?-  -.del
      %add-item
    %+  frond  (scot %p who.del)
    %+  frond  stack.del
    (item-to-json data.del)
      %add-stack
    %+  frond  (scot %p who.del)
    %+  frond  stack.del
    (total-build-to-json data.del)
      %raise-item
    %+  frond  (scot %p who.del)
    %-  pairs
    :~  stak+s+stak.del
        item+s+item.del
    ==
      %update-review
    :-  %a
    %+  turn
      ~(tap in +.del)
    update-to-json
      %read
    %-  pairs
    :~  who+s+(scot %p who.del)
        stack+s+stack.del
        item+s+item.del
    ==
  ==
::
++  json-to-action
  |=  jon=json
  =,  dejs:format
  %-  action
  =<  (srrs-action jon)
  |%
  ++  srrs-action
    %-  of
    :~  new-stack+new-stack
        new-item+new-item
    ::
        delete-stack+delete-stack
        delete-item+delete-item
    ::
        edit-stack+edit-stack
        edit-item+edit-item
    ::
        schedule-item+schedule-item
        raise-item+raise-item
        answered-item+answered-item
    ::
        subscribe+subscribe
        unsubscribe+unsubscribe
    ::
        read+read
        update-review+update-review
    ==
  ::
  ++  new-stack
    %-  ot
    :~  name+so
        title+so
        items+item
        edit+edit-config
        perm+perm-config
    ==
  ::
  ++  new-item
    %-  ot
    :~  who+(su fed:ag)
        stak+so
        name+so
        title+so
        perm+perm-config
        front+so
        back+so
    ==
  ::
  ++  schedule-item
    %-  ot
    :~  stak+so
        item+so
        scheduled+di
    ==
  ::
  ++  raise-item
    %-  ot
    :~  who+(su fed:ag)
        stak+so
        item+so
    ==
  ::
  ++  answered-item
    %-  ot
    :~  stak+so
        item+so
        answer+recall-grade
    ==
  ::
  ++  delete-stack
    %-  ot
    :~  stak+so
    ==
  ::
  ++  delete-item
    %-  ot
    :~  stak+so
        item+so
    ==
  ::
  ++  edit-stack
    %-  ot
    :~  name+so
        title+so
    ==
  ::
  ++  edit-item
    %-  ot
    :~  who+(su fed:ag)
        stak+so
        name+so
        title+so
        perm+perm-config
        front+so
        back+so
    ==
  ::
  ++  recall-grade
    %-  su
    ;~(pose (jest %again) (jest %hard) (jest %good) (jest %easy))
  ::
  ++  edit-config
    %-  su
    ;~(pose (jest %item) (jest %all) (jest %none))
  ::
  ++  perm-config
      %-  ot
      :~  :-  %read
          %-  ot
          :~  mod+(su ;~(pose (jest %black) (jest %white)))
              who+whoms
          ==
          :-  %write
          %-  ot
          :~  mod+(su ;~(pose (jest %black) (jest %white)))
              who+whoms
      ==  ==
  ++  item
    |=  jon=json
    ?~  jon
      ~
    ((om same) jon)
  ::
  ++  update-review
    |=  jon=json
    ?~  jon
      ~
    ((om same) jon)
  ::
  ++  whoms
    |=  jon=json
    ^-  (set whom:clay)
    =/  x  ((ar (su fed:ag)) jon)
    %-  (set whom:clay)
    %-  ~(run in (sy x))
    |=(w=@ [& w])
  ::
  ++  invite
    %-  ot
    :~  stak+so
        title+so
        who+(ar (su fed:ag))
    ==
  ::
  ++  reject-invite
    %-  ot
    :~  who+(su fed:ag)
        stak+so
    ==
  ::
  ++  serve
    %-  ot
    :~  stak+so
    ==
  ::
  ++  unserve
    %-  ot
    :~  stak+so
    ==
  ::
  ++  subscribe
    %-  ot
    :~  who+(su fed:ag)
        stak+so
    ==
  ::
  ++  unsubscribe
    %-  ot
    :~  who+(su fed:ag)
        stak+so
    ==
  ::
  ++  read
    %-  ot
    :~  who+(su fed:ag)
        stak+so
        item+so
    ==
  ::
  --
--
