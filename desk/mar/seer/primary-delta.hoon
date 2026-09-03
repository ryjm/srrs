/?  309
/-  *seer
/+  *seer, *seer-json
=,  html
=,  format
::
|_  del=primary-delta
::
++  grow
  |%
  ++  json
    (primary-delta-to-json del)
  ++  txt
  ?+    -.del  [(en:json:html json)]~
      %update-stack
    [(crip "<stack updated>: {(trip name.data.del)}")]~
      %update-review
    [(crip "<reviews updated>")]~
  ==
  ++  tank
      ^-  ^tank
      :+  %rose
      [[' ' ~] ['`' '<' '|' ~] ['|' '>' '`' ~]]
      ?+    -.del  [leaf+(trip (en:json:html json))]~
          %add-item
        :~  leaf+"<stack>: {(trip stack.del)}"
            leaf+"<item added>: {(trip name.data.del)}"
            leaf+"<front>: {(trip snippet.content.data.del)}"
        ==
          %update-stack
        :~  leaf+"<updated stack>: {(trip name.data.del)}"
        ==
      ==
  --
::
++  grab
  |%
  ++  noun  primary-delta
  --
::
++  grad  %noun
::
--
