::
::::  /hoon/action/srrs/mar
  ::
/?  309
/-  srrs
/+  publish
=,  format
::
|_  act=action:srrs
::
++  grow
  |%
  ++  tank  >act<
  --
::
++  grab
  |%
  ++  noun  action:srrs
  ++  json
    |=  jon=^json
    %-  action:srrs
    =<  (action jon)
    |%
    ++  action
      %-  of:dejs
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
      %-  ot:dejs
      :~  name+so:dejs
          title+so:dejs
          items+item
          edit+edit-config
          perm+perm-config
      ==
    ::
    ++  new-item
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
          name+so:dejs
          title+so:dejs
          perm+perm-config
          content+so:dejs
      ==
    ::
    ++  schedule-item
      %-  ot:dejs
      :~  stak+so:dejs
          item+so:dejs
          scheduled+di:dejs
      ==
    ::
    ++  raise-item
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
          item+so:dejs
      ==
    ::
    ++  answered-item
      %-  ot:dejs
      :~  stak+so:dejs
          item+so:dejs
          answer+recall-grade
      ==
    ::
    ++  delete-stack
      %-  ot:dejs
      :~  stak+so:dejs
      ==
    ::
    ++  delete-item
      %-  ot:dejs
      :~  stak+so:dejs
          item+so:dejs
      ==
    ::
    ++  edit-stack
      %-  ot:dejs
      :~  name+so:dejs
          title+so:dejs
      ==
    ::
    ++  edit-item
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
          name+so:dejs
          title+so:dejs
          perm+perm-config
          content+so:dejs
      ==
    ::
    ++  recall-grade
      %-  su:dejs
      ;~(pose (jest %again) (jest %hard) (jest %good) (jest %easy))
    ::
    ++  edit-config
      %-  su:dejs
      ;~(pose (jest %item) (jest %all) (jest %none))
    ::
    ++  perm-config
        %-  ot:dejs
        :~  :-  %read
            %-  ot:dejs
            :~  mod+(su:dejs ;~(pose (jest %black) (jest %white)))
                who+whoms
            ==
            :-  %write
            %-  ot:dejs
            :~  mod+(su:dejs ;~(pose (jest %black) (jest %white)))
                who+whoms
        ==  ==
    ++  item
      |=  jon=^json
      ?~  jon
        ~
      ((om:dejs same) jon)
    ::
    ++  update-review
      |=  jon=^json
      ?~  jon
        ~
      ((om:dejs same) jon)
    ::
    ++  whoms
      |=  jon=^json
      ^-  (set whom:clay)
      =/  x  ((ar:dejs (su:dejs fed:ag)) jon)
      %-  (set whom:clay)
      %-  ~(run in (sy x))
      |=(w=@ [& w])
    ::
    ++  invite
      %-  ot:dejs
      :~  stak+so:dejs
          title+so:dejs
          who+(ar:dejs (su:dejs fed:ag))
      ==
    ::
    ++  reject-invite
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
      ==
    ::
    ++  serve
      %-  ot:dejs
      :~  stak+so:dejs
      ==
    ::
    ++  unserve
      %-  ot:dejs
      :~  stak+so:dejs
      ==
    ::
    ++  subscribe
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
      ==
    ::
    ++  unsubscribe
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
      ==
    ::
    ++  read
      %-  ot:dejs
      :~  who+(su:dejs fed:ag)
          stak+so:dejs
          item+so:dejs
      ==
    ::
    --
  --
--
