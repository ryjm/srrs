::  tell app to hook into memo apps
::
::  for apps that use lib/memo, :app +memo toggles memo hook.
::
:-  %say
|=  [* arg=?(~ [%bowl ~]) ~]
[%memo ?~(arg %enabled %bowl)]
