/?  309
/-  *seer, chat-store
/+  *seer, *seer-json

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
  ++  txt
  ?+    -.del  [(crip (en-json json))]~
      %update-stack
    [(crip "<stack updated>: {(trip name.data.del)}")]~
      %update-review
    [(crip "<reviews updated>")]~
  ==
  ++  tank
      ^-  ^tank
      :+  %rose
      [[' ' ~] ['`' '<' '|' ~] ['|' '>' '`' ~]]
      ?+    -.del  [leaf+(en-json json)]~
          %add-item
        :~  leaf+"<stack>: {(trip stack.del)}"
            leaf+"<item added>: {(trip name.data.del)}"
            leaf+"<front>: {(trip snippet.content.data.del)}"
        ==
          %update-stack
        :~  leaf+"<updated stack>: {(trip name.data.del)}"
        ==
      ==
  ++  letter
    ^-  letter:chat-store
    [%text (crip ~(ram re tank))]
  --
::
++  grab
  |%
  ++  noun  primary-delta
  --
::
--
