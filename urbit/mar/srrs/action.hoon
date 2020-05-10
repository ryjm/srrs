/?  309
/-  *srrs
/+  *srrs-json
=,  format
::
|_  act=action
::
++  grow
  |%
  ++  tank  >act<
  --
::
++  grab
  |%
  ++  noun  action
  ++  json
    |=  jon=^json
    (json-to-action jon)
  --
--
