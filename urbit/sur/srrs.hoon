/-  publish
|%
::
+$  action
  $%  $:  %new-stack
          name=@tas
          title=@t
          items=(map @tas item)
          edit=edit-config
          perm=perm-config
      ==
  ::
      $:  %new-item
          who=@p
          stak=@tas
          name=@tas
          title=@tas
          perm=perm-config
          content=@t
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
+$  perm-config  [read=rule:clay write=rule:clay]
::

+$  edit-config     $?(%item %all %none)
::
+$  stack
  $:  stack=(each stack-info tang)
      name=@tas
      items=(map @tas item)
      status=(map @tas learned-status)
      order=[pin=(list @tas) unpin=(list @tas)]
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item
  $:  content=note:publish
      learn=learned-status
  ==
::
+$  recall-grade  $?(%again %hard %good %easy)
::
+$  learned-status
  $:  ease=@rs
      interval=@dr
      box=@
  ==
::
+$  stack-delta
  $%  [%add-item who=@p stack=@tas item=@tas data=item]
  ==
::
+$  primary-delta
  $%  stack-delta
      [%read who=@p stack=@tas item=@tas]
  ==
--
