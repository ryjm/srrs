|%
::
+$  items   $+(items-map (map @tas item))
+$  action
  $%  $:  %new-stack
          name=@tas
          title=@t
          =items
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
::  +stack-info: stack information
::
::     all metadata about a stack.
::
::    .owner: owner of the stack
::    .name: name of the stack
::    .title: title of the stack
::    .items: items in the stack
::    .edit: permissions for editing the stack
::    .date-created: date the stack was created
::    .date-modified: date the stack was last modified
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
+$  edit-config     $?(%none %item %all)
::
::    $stack: stack
::
::  main stack data structure. contains all metadata and review data
::  for a stack.
::
::  .info: stack information
::  .items: items in the stack
::  .review-items: review information
::  .contributors: list of contributors and their permissions
::  .subscribers: set of subscribers
::  .last-update: date of last update
+$  stack
  $:  info=$+(info-or-error (each stack-info $+(error tang)))
      name=@tas
      =items
      review-items=items
      contributors=[mod=?(%white %black) who=(set @p)]
      subscribers=(set @p)
      last-update=@da
  ==
::
+$  item
  $:  =content
      =learn
      last-review=(unit @da)
      name=@tas
  ==
::
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
+$  learn 
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
      [%new-stack =term]
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
  $:  =content
      =learn
      name=@tas
  ==
--
