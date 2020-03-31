/-  srrs
/+  srrs, cram, elem-to-react-json
/=  args  /$  ,[beam *]
/=  result
  /^  [item-info:srrs manx @t]
  /;
  |=  $:  item-front=(map knot cord)
          item-content=manx
          item-raw=wain
          ~
      ==
      :+  (front-to-item-info:srrs item-front)
        item-content
      (of-wain:format (slag 11 item-raw))
::
  /.  /&front&/udon/
      /&elem&/udon/
      /&txt&/udon/
  ==
result
