/-  publish
|%
::
+$  action
  $%  $:  %new-stack
          name=@tas
          title=@t
          items=(map @tas note:publish)
          edit=edit-config
          perm=perm-config
      ==
  ::
      $:  %new-item
          stak=@tas
          name=@tas
      ==
  ::
      $:  %schedule-item
          stak=@tas
          item=@tas
          scheduled=@da
      ==
  ::
      [%raise-item stak=@tas item=@tas]
      [%answered-item stak=@tas item=@tas answer=recall-grade]
  ::
      [%delete-stack stak=@tas]
      [%delete-item stak=@tas item=@tas]
  ::
      [%edit-stack name=@tas title=@t]
  ::
      $:  %edit-item
          who=@p
          stak=@tas
          name=@tas
          title=@t
          perm=perm-config
          content=@t
      ==
  ::
      [%invite stak=@tas title=@t who=(list ship)]
      [%reject-invite who=@p stak=@tas]
  ::
      [%serve stak=@tas]
      [%unserve stak=@tas]
  ::
      [%subscribe who=@p stak=@tas]
      [%unsubscribe who=@p stak=@tas]
  ::
      [%read who=@p stak=@tas item=@tas]
      [%add-books books=(map @tas notebook:publish)]
  ==
::
+$  stack-info
  $:  owner=@p
      title=@t
      filename=@tas
      allow-edit=edit-config
      date-created=@da
      last-modified=@da
  ==
::
+$  item-info
  $:  author=@p
      stack=@tas
      name=@tas
      date-created=@da
      last-modified=@da
      =learned-status
  ==
::
::
+$  perm-config  [read=rule:clay write=rule:clay]
::

+$  edit-config     $?(%item %all %none)
::
+$  rumor  delta
::
+$  srrs-dir  (map path srrs-file)
::
+$  srrs-file
  $%  [%udon @t]
      [%srrs-info stack-info]
  ==
::
+$  stack
  $:  stack=(each stack-info tang)
      name=@tas
      items=(map @tas note:publish)
      status=(map @tas learned-status)
      order=[pin=(list @tas) unpin=(list @tas)]
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  recall-grade  $?(%again %hard %good %easy)
::
+$  learned-status
  $:  ease=@rs
      interval=@rs
      box=@
  ==
::
+$  delta
  $%  [%stack who=@p stack=@tas dat=(each stack-info tang)]
      [%total who=@p stack=@tas dat=stack]
      [%remove who=@p stack=@tas item=(unit @tas)]
  ==
::
+$  update
  $%  [%invite add=? who=@p stack=@tas title=@t]
      [%unread add=? keys=(set [who=@p stak=@tas item=@tas])]
  ==
--
