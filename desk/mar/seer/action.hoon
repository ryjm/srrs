/?  309
/-  *seer
/+  *seer-json
=,  format
::
|_  packet=command
::
++  grow
  |%
  ++  tank  >[schema.packet epoch.packet operation.packet digest.packet]<
  --
::
++  grab
  |%
  ++  noun  command
  ++  json
    |=  jon=^json
    (json-to-command jon)
  --
++  grad  %noun
--
