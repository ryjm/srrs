::  tests for /lib/seer-net: destination policy, redirects, provider
::  response codecs, html extraction, and lenient json recovery.
::
/-  *seer
/+  *test, net=seer-net
|%
++  json-object
  |=  fields=(list [@t json])
  ^-  json
  (pairs:enjs:format fields)
::  +sse: one data line per event, blank-line separated, as a provider streams it
::
++  sse
  |=  events=(list json)
  ^-  @t
  %+  rap  3
  %+  turn  events
  |=(event=json (rap 3 'data: ' (en:json:html event) '\0a\0a' ~))
++  message-item
  |=  texts=(list @t)
  ^-  json
  %-  json-object
  :~  ['type' s+'response.output_item.done']
      :-  'item'
      %-  json-object
      :~  ['type' s+'message']
          ['content' a+(turn texts |=(text=@t (json-object ~[['type' s+'output_text'] ['text' s+text]])))]
      ==
  ==
++  completed-event
  |=  [input=@ud output=@ud]
  ^-  json
  %-  json-object
  :~  ['type' s+'response.completed']
      :-  'response'
      %-  json-object
      :~  :-  'usage'
          (json-object ~[['input_tokens' (numb:enjs:format input)] ['output_tokens' (numb:enjs:format output)]])
      ==
  ==
::
++  test-destination-policy
  ^-  tang
  ;:  weld
    (expect-eq !>(~) !>((destination-error:net 'https://example.com/')))
    (expect-eq !>(~) !>((destination-error:net 'http://docs.example.com:443/path?q=1')))
    (expect-eq !>(`%private-host) !>((destination-error:net 'http://localhost/')))
    (expect-eq !>(`%private-host) !>((destination-error:net 'http://localhost:80/x')))
    (expect-eq !>(`%private-host) !>((destination-error:net 'https://intranet.local/')))
    (expect-eq !>(`%ip-literal) !>((destination-error:net 'https://10.0.0.1/')))
    (expect-eq !>(`%port-not-allowed) !>((destination-error:net 'https://example.com:8080/')))
    (expect-eq !>(`%invalid-url) !>((destination-error:net 'https://user@example.com/')))
    (expect-eq !>(`%invalid-url) !>((destination-error:net 'ftp://x.example.com')))
    (expect-eq !>(`%invalid-url) !>((destination-error:net 'https://[::1]/')))
    (expect-eq !>(`%invalid-url) !>((destination-error:net 'https:///nohost')))
    (expect-eq !>(`%url-too-long) !>((destination-error:net (rap 3 'https://example.com/' (rep 3 (reap 4.100 'a')) ~))))
  ==
::
++  test-resolve-redirect
  ^-  tang
  ;:  weld
    (expect-eq !>(`'https://other.example/b') !>((resolve-redirect:net 'https://example.com/a' 'https://other.example/b')))
    (expect-eq !>(`'http://other.example/b') !>((resolve-redirect:net 'https://example.com/a' 'http://other.example/b')))
    (expect-eq !>(`'https://example.com/b?x=1') !>((resolve-redirect:net 'https://example.com/a/c' '/b?x=1')))
    (expect-eq !>(`'http://example.com:8080/b') !>((resolve-redirect:net 'http://example.com:8080/a' '/b')))
    (expect-eq !>(~) !>((resolve-redirect:net 'https://example.com/a' 'b')))
    (expect-eq !>(~) !>((resolve-redirect:net 'https://example.com/a' '')))
    (expect-eq !>(~) !>((resolve-redirect:net 'not a url' '/b')))
  ==
::
++  test-sse-events-and-responses-result
  ^-  tang
  =/  body
    %-  sse
    :~  (json-object ~[['type' s+'response.created']])
        (message-item ~['Hello, ' 'world'])
        (message-item ~['!'])
        (completed-event 10 5)
    ==
  ::  carriage returns, multi-line data, and the [DONE] sentinel are tolerated
  =/  ragged
    %+  rap  3
    :~  'event: message\0d\0a'
        'data: {"type":"response.output_item.done",\0d\0a'
        'data:  "item":{"type":"message","content":[{"type":"output_text","text":"split"}]}}\0d\0a'
        '\0d\0a'
        'data: {"type":"response.completed","response":{"usage":{"total_tokens":7}}}\0a\0a'
        'data: [DONE]\0a\0a'
    ==
  =/  tool
    %-  sse
    :~  (json-object ~[['type' s+'response.output_item.done'] ['item' (json-object ~[['type' s+'function_call'] ['name' s+'run']])]])
        (message-item ~['text'])
        (completed-event 1 1)
    ==
  =/  failed
    %-  sse
    :~  (message-item ~['partial'])
        (json-object ~[['type' s+'response.failed'] ['response' (json-object ~[['error' (json-object ~[['message' s+'rate limited']])]])]])
    ==
  =/  refused
    %-  sse
    :~  %-  json-object
        :~  ['type' s+'response.output_item.done']
            ['item' (json-object ~[['type' s+'message'] ['content' a+~[(json-object ~[['type' s+'refusal'] ['refusal' s+'no']])]]])]
        ==
        (completed-event 1 1)
    ==
  =/  events  (sse-events:net body)
  =/  result  (responses-result:net events)
  =/  ragged-result  (responses-result:net (sse-events:net ragged))
  =/  tool-result  (responses-result:net (sse-events:net tool))
  =/  failed-result  (responses-result:net (sse-events:net failed))
  =/  refused-result  (responses-result:net (sse-events:net refused))
  =/  truncated  (responses-result:net (sse-events:net (sse ~[(message-item ~['no completion'])])))
  ;:  weld
    (expect-eq !>(4) !>((lent events)))
    (expect-eq !>(`'Hello, world!') !>(text.result))
    (expect-eq !>(%.y) !>(completed.result))
    (expect-eq !>(`15) !>(usage.result))
    (expect-eq !>(%.n) !>(tool-call.result))
    (expect-eq !>(%.n) !>(refusal.result))
    (expect-eq !>(~) !>(error.result))
    (expect-eq !>(`'split') !>(text.ragged-result))
    (expect-eq !>(`7) !>(usage.ragged-result))
    (expect-eq !>(%.y) !>(completed.ragged-result))
    (expect-eq !>(%.y) !>(tool-call.tool-result))
    (expect-eq !>(`'text') !>(text.tool-result))
    (expect-eq !>(`'rate limited') !>(error.failed-result))
    (expect-eq !>(%.n) !>(completed.failed-result))
    (expect-eq !>(%.y) !>(refusal.refused-result))
    (expect-eq !>(~) !>(text.refused-result))
    (expect-eq !>(%.n) !>(completed.truncated))
    (expect-eq !>(`'no completion') !>(text.truncated))
  ==
::
++  test-messages-result
  ^-  tang
  =/  reply
    %-  en:json:html
    %-  json-object
    :~  ['type' s+'message']
        ['content' a+~[(json-object ~[['type' s+'text'] ['text' s+'Hello ']]) (json-object ~[['type' s+'text'] ['text' s+'world']])]]
        ['usage' (json-object ~[['input_tokens' (numb:enjs:format 3)] ['output_tokens' (numb:enjs:format 4)]])]
        ['stop_reason' s+'end_turn']
    ==
  =/  tooling
    %-  en:json:html
    %-  json-object
    :~  ['type' s+'message']
        ['content' a+~[(json-object ~[['type' s+'tool_use'] ['name' s+'bash']])]]
        ['stop_reason' s+'tool_use']
    ==
  =/  refusing
    %-  en:json:html
    %-  json-object
    :~  ['type' s+'message']
        ['content' a+~[(json-object ~[['type' s+'text'] ['text' s+'No.']])]]
        ['stop_reason' s+'refusal']
    ==
  =/  erroring
    '{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}'
  =/  result  (messages-result:net reply)
  =/  tool-result  (messages-result:net tooling)
  =/  refused  (messages-result:net refusing)
  =/  failed  (messages-result:net erroring)
  =/  garbage  (messages-result:net 'not json')
  ;:  weld
    (expect-eq !>(`'Hello world') !>(text.result))
    (expect-eq !>(`7) !>(usage.result))
    (expect-eq !>(%.y) !>(completed.result))
    (expect-eq !>(%.n) !>(tool-call.result))
    (expect-eq !>(%.n) !>(refusal.result))
    (expect-eq !>(~) !>(error.result))
    (expect-eq !>(%.y) !>(tool-call.tool-result))
    (expect-eq !>(~) !>(text.tool-result))
    (expect-eq !>(~) !>(usage.tool-result))
    (expect-eq !>(%.y) !>(refusal.refused))
    (expect-eq !>(`'Overloaded') !>(error.failed))
    (expect-eq !>(%.n) !>(completed.failed))
    (expect-eq !>(`'invalid-json') !>(error.garbage))
  ==
::
++  test-html-text
  ^-  tang
  =/  page
    '<p>Hello &amp; &lt;world&gt;</p><script>alert(1)</script><div>Next   line</div>'
  =/  rich
    %+  rap  3
    :~  '<!DOCTYPE html><html><head><title>Doc</title><style>p { color: red }</style></head>'
        '<body><!-- hidden --><h1>Head&#65;&#x42;</h1><p>one&nbsp;two</p><p>three</p><p>four</p>'
        '<noscript>fallback</noscript><a href="x">link</a><span>tail</span></body></html>'
    ==
  =/  unterminated  '<p>open <script>never closed'
  =/  extracted  (trip (html-text:net rich))
  ;:  weld
    (expect-eq !>('\0aHello & <world>\0a\0aNext line\0a') !>((html-text:net page)))
    (expect-eq !>(%.y) !>(?=(^ (find "Doc" extracted))))
    (expect-eq !>(%.y) !>(?=(^ (find "HeadAB" extracted))))
    (expect-eq !>(%.y) !>(?=(^ (find "one two" extracted))))
    (expect-eq !>(%.y) !>(?=(^ (find "three\0a\0afour" extracted))))
    (expect-eq !>(%.y) !>(?=(^ (find "link tail" extracted))))
    (expect-eq !>(~) !>((find "color" extracted)))
    (expect-eq !>(~) !>((find "hidden" extracted)))
    (expect-eq !>(~) !>((find "fallback" extracted)))
    (expect-eq !>(~) !>((find "\0a\0a\0a" extracted)))
    (expect-eq !>('\0aopen ') !>((html-text:net unterminated)))
    (expect-eq !>('plain text') !>((html-text:net 'plain   text')))
    (expect-eq !>(%.y) !>((is-html:net ~[['Content-Type' 'text/html; charset=utf-8']])))
    (expect-eq !>(%.n) !>((is-html:net ~[['content-type' 'text/plain']])))
    (expect-eq !>(%.n) !>((is-html:net ~)))
  ==
::
++  test-provider-json
  ^-  tang
  =/  fenced
    'Here is the answer:\0a```json\0a{"answer":"yes","citations":[]}\0a```\0aHope that helps.'
  =/  direct  '{"answer":"direct","citations":[]}'
  =/  fenced-json  (provider-json:net fenced)
  =/  direct-json  (provider-json:net direct)
  ;:  weld
    (expect-eq !>(%.y) !>(?=(^ fenced-json)))
    (expect-eq !>(`'yes') !>((get-string:net (fall fenced-json ~) 'answer')))
    (expect-eq !>(`'direct') !>((get-string:net (fall direct-json ~) 'answer')))
    (expect-eq !>(~) !>((provider-json:net 'no object here')))
    (expect-eq !>(~) !>((provider-json:net '[1,2,3]')))
    (expect-eq !>(~) !>((provider-json:net '{"unterminated": ')))
    (expect-eq !>(~) !>((get-string:net (fall (provider-json:net '{"answer": 5}') ~) 'answer')))
  ==
--
