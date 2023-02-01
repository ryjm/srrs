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
          stack-owner=@p
          who=@p
          stak=@tas
          name=@tas
          title=@tas
          perm=perm-config
          front=@t
          back=@t
      ==
  ::
      $:  %schedule-item
          stak=@tas
          item=@tas
          scheduled=@da
      ==
  ::
      [%raise-item who=@p stak=@tas item=@tas]
      [%answered-item owner=@p stak=@tas item=@tas answer=recall-grade]
      [%review-stack who=@p stak=@tas]
  ::
      [%delete-stack who=@p stak=@tas]
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
          front=@t
          back=@t
      ==
  ::
      [%read who=@p stak=@tas item=@tas]
      [%update-review ~]
  ::
      [%import who=@p stack=@tas]
      [%import-file =path]
  ::
      [%copy-stack owner=@p stak=@tas keep-learned=?]
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
      review-items=(map @tas item)
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item
  $:  =content
      learn=learned-status
      last-review=(unit @da)
      name=@tas
  ==
::
+$  stack-1
  $:  stack=(each stack-info tang)
      name=@tas
      items=(map @tas item-1)
      review-items=(map @tas item-1)
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item-1
  $:  content=content
      learn=learned-status
      name=@tas
  ==
+$  content
  $:  author=@p
      title=@t
      filename=@tas
      date-created=@da
      last-edit=@da
      read=?
      front=@t
      back=@t
      snippet=@t
      comments=(map @da comment)
      pending=?
  ==
::
+$  comment
  $:  author=@p
      date-created=@da
      content=@t
      pending=?
  ==
::
+$  recall-grade  $?(%again %hard %good %easy)
::
+$  learned-status
  $:  ease=@rs
      interval=@dr
      box=@
  ==
+$  review
  $:  who=@p
      stack=@tas
      item=@tas
  ==
::
+$  stack-delta
  $%  [%add-item who=@p stack=@tas data=item]
      [%add-review-item who=@p stack=@tas data=item]
      [%add-stack who=@p data=stack]
      ::
      [%delete-item who=@p stack=@tas item=@tas]
      [%delete-review-item who=@p stack=@tas item=@tas]
      [%delete-stack who=@p stack=@tas]
      ::
      [%update-stack who=@p data=stack]
      [%update-review (set review)]
  ==
::
+$  primary-delta
  $%  stack-delta
      [%read who=@p stack=@tas item=@tas]
  ==
--
