::
::::  /hoon/info/seer/mar
  ::
/-  seer
!:
|_  stak=stack-info:seer
::
::
++  grow
  |%
  ++  mime
    :-  /text/x-seer-info
    (as-octs:mimes:html (of-wain:format txt))
  ++  txt
    ^-  wain
    :~  (cat 3 'owner: ' (scot %p owner.stak))
        (cat 3 'title: ' title.stak)
        (cat 3 'filename: ' filename.stak)
        (cat 3 'allow-edit: ' allow-edit.stak)
        (cat 3 'date-created: ' (scot %da date-created.stak))
        (cat 3 'last-modified: ' (scot %da last-modified.stak))
    ==
  --
++  grab
  |%
  ++  mime
    |=  [mite:eyre p=octs:eyre]
    (txt (to-wain:format q.p))
  ++  txt
    |=  txs=(pole @t)
    ^-  stack-info:seer
    ?>  ?=  $:  owner=@t
                title=@t
                filename=@t
                allow-edit=@t
                date-created=@t
                last-modified=@t
                *
             ==
           txs
    ::
    :*  %+  rash  owner.txs
        ;~(pfix (jest 'owner: ~') fed:ag)
    ::
        %+  rash  title.txs
        ;~(pfix (jest 'title: ') (cook crip (star next)))
    ::
        %+  rash  filename.txs
        ;~(pfix (jest 'filename: ') (cook crip (star next)))
    ::
      %+  rash  allow-edit.txs
      ;~  pfix
        (jest 'allow-edit: ')
        %+  cook  edit-config:seer
        ;~(pose (jest %post) (jest %comment) (jest %all) (jest %none))
      ==
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
    ==
  ++  noun  stack-info:seer
  --
++  grad  %mime
--
