/?  309
/-  *srrs, *chat-store
/+  *srrs, *srrs-json

=,  html
=,  format
::
|_  del=primary-delta
::
++  grow
  |%
  ++  json
    ^-  ^json
    (primary-delta-to-json del)
  ++  txt  [(crip (en-json json))]~
  ++  tank
      ^-  ^tank
      :+  %rose
      [[' ' ~] ['`' '<' '|' ~] ['|' '>' '`' ~]]
      ?+    -.del  [leaf+(en-json json)]~
          %add-item
        :~  leaf+"stack: {(trip stack.del)}"
            leaf+"item added: {(trip item.del)}"
            leaf+"front: {(trip snippet.content.data.del)}"
        ==
      ==
  ++  letter
    ^-  ^letter
    [%text (crip ~(ram re tank))]
  --
::
++  grab
  |%
  ++  noun  primary-delta
  --
::
--
