::
::::  /hoon/item-info/srrs/mar
  ::
/-  srrs
!:
|_  item=item-info:srrs
::
::
++  grow
  |%
  ++  mime
    :-  /text/x-srrs-item-info
    (as-octs:mimes:html (of-wain:format txt))
  ++  txt
    ^-  wain
    :~  (cat 3 'author: ' (scot %p author.item))
        (cat 3 'name: ' name.item)
        (cat 3 'stack: ' stack.item)
        (cat 3 'date-created: ' (scot %da date-created.item))
        (cat 3 'last-modified: ' (scot %da last-modified.item))
        (cat 3 'ease: ' (scot %rs ease.learned-status.item))
        (cat 3 'interval: ' (scot %rs interval.learned-status.item))
        (cat 3 'box: ' (scot %u box.learned-status.item))
    ==
  --
++  grab
  |%
  ++  mime
    |=  [mite:eyre p=octs:eyre]
    (txt (to-wain:format q.p))
  ++  txt
    |=  txs=(pole @t)
    ^-  item-info:srrs
    ?>  ?=  $:  author=@t
                name=@t
                stack=@t
                date-created=@t
                last-modified=@t
                ease=@t
                interval=@t
                box=@t
                *
             ==
           txs
    ::
    =/  result
    :*  %+  rash  author.txs
        ;~(pfix (jest 'author: ~') fed:ag)
    ::
        %+  rash  name.txs
        ;~(pfix (jest 'name: ') (cook crip (star next)))
    ::
        %+  rash  stack.txs
        ;~(pfix (jest 'stack: ') (cook crip (star next)))
    ::
        %+  rash  date-created.txs
        ;~  pfix
          (jest 'date-created: ~')
          (cook year when:so)
        ==
    ::
        %+  rash  last-modified.txs
        ;~  pfix
          (jest 'last-modified: ~')
          (cook year when:so)
        ==
      %-  learned-status:srrs
      :*  %+  rash  ease.txs
          ;~(pfix (jest 'ease: ') nuck:so)
          %+  rash  interval.txs
          ;~(pfix (jest 'interval: ') nuck:so)
          %+  rash  box.txs
          ;~(pfix (jest 'box: ') nud)
      ==
    ==
    ~!  result  result
  ++  noun  item-info:srrs
  --
++  grad  %mime
--
