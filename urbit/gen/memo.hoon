::  Tell app to hook into memo apps
::
::  For apps that use lib/memo, :app +memo toggles memo hook.
::
:-  %say
|=  [* arg=?(~ [%bowl ~]) ~]
[%memo ?~(arg %enabled %bowl)]
