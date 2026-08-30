::
::  The structural subset of the MCP types that a third-party desk needs in
::  order to publish tools through /x/mcp/tools.  %mcp-server imports these
::  values by noun, so Seer does not need a runtime dependency on the %mcp
::  desk and remains independently installable.
::
|%
++  tool
  =<  tool
  |%
  +$  name  @t
  +$  desc  @t
  ::
  +$  parameters  (map name:parameter def:parameter)
  +$  required    (list name:parameter)
  ::
  +$  tool
    $:  =name
        =desc
        =parameters
        =required
        =thread-builder
    ==
  ::
  +$  thread-builder
    $-((map name:parameter argument) shed:khan)
  ::
  +$  argument
    $@  ~
    $%  [%string p=@t]
        [%number p=@ud]
        [%boolean p=?]
        [%array p=(list argument)]
        [%object p=(map @t argument)]
    ==
  ::
  +$  response
    $%  [%error message=@t data=(unit json)]
        $:  %result
            $%  [%structured =json]
                [%unstructured results=(list result)]
            ==
        ==
    ==
  ::
  +$  result
    $%  [%text text=@t]
        [%audio data=@t mime=@t]
        [%resource-link uri=@t name=@t desc=@t mime=@t]
        $:  %image
            data=@t
            mime=@t
            annotations=(unit [audience=(list @t) priority=@rs])
        ==
        $:  %resource
            uri=@t
            mime=@t
            text=@t
            annotations=(unit [audience=(list @t) priority=@rs modified=@t])
        ==
    ==
  ::
  ++  parameter
    |%
    +$  name  @t
    +$  type
      $?  %array
          %boolean
          %number
          %object
          %string
      ==
    +$  def
      $:  =type
          desc=@t
      ==
    --
  --
::
++  prompt
  =<  prompt
  |%
  +$  prompt
    $:  name=@t
        title=@t
        desc=@t
        arguments=(list argument)
        icons=(list icon)
        messages-builder=$-((map name:argument @t) (list message))
    ==
  ::
  ++  argument
    =<  argument
    |%
    +$  name  @t
    +$  argument
      $:  =name
          desc=@t
          required=?
      ==
    --
  ::
  +$  icon
    $:  src=@t
        mime-type=@t
        sizes=(list @t)
    ==
  ::
  +$  message
    $:  role=$?(%assistant %user)
        content=[type=$?(%audio %image %resource %text) text=(unit @t)]
    ==
  --
--
