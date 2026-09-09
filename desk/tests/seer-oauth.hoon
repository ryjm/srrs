::  tests for /lib/seer-oauth: pkce, token codecs, pasted credentials,
::  renewal state, and the credential headers.
::
/-  *seer
/+  *test, oa=seer-oauth, net=seer-net
|%
++  fixed-now  ~2026.9.2
++  json-object
  |=  fields=(list [@t json])
  ^-  json
  (pairs:enjs:format fields)
::  +jwt: an unsigned compact token whose payload is the given claims
::
++  jwt
  |=  claims=json
  ^-  @t
  =/  segment  |=(text=@t (base64url:oa (met 3 text) text))
  (rap 3 (segment '{"alg":"none","typ":"JWT"}') '.' (segment (en:json:html claims)) '.' 'sig' ~)
++  epoch-seconds
  |=  at=@da
  ^-  @ud
  (div (sub at ~1970.1.1) ~s1)
++  in-one-hour  (add fixed-now ~h1)
++  account-jwt
  %-  jwt
  %-  json-object
  :~  ['exp' (numb:enjs:format (epoch-seconds in-one-hour))]
      ['https://api.openai.com/auth' (json-object ~[['chatgpt_account_id' s+'acct-1']])]
  ==
++  id-jwt
  %-  jwt
  %-  json-object
  :~  ['exp' (numb:enjs:format (epoch-seconds in-one-hour))]
      ['email' s+'person@example.com']
      ['https://api.openai.com/auth' (json-object ~[['chatgpt_account_id' s+'acct-1']])]
  ==
++  oauth-account
  |=  [refresh=@t expires=(unit @da) renewal=account-renewal]
  ^-  provider-account
  [%oauth 'access' refresh 'acct' expires 'scope' fixed-now renewal]
++  idle-renewal
  ^-  account-renewal
  [~ 0 *@da '' %.n]
++  header-count
  |=  [headers=header-list:http name=@t]
  ^-  @ud
  (lent (skim headers |=([key=@t value=@t] =(name (lower:net key)))))
::
++  test-pkce-matches-rfc-7636
  ^-  tang
  =/  verifier  'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'
  =/  digest  (sha256-bytes:oa verifier)
  =/  keys  (pkce:oa `@uvJ`0xdead.beef)
  =/  other  (pkce:oa `@uvJ`0xcafe)
  =/  derived  (sha256-bytes:oa verifier.keys)
  ;:  weld
    (expect-eq !>('E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM') !>((base64url:oa p.digest q.digest)))
    (expect-eq !>(43) !>((met 3 verifier.keys)))
    (expect-eq !>((base64url:oa p.derived q.derived)) !>(challenge.keys))
    (expect-eq !>(%.n) !>(=(verifier.keys state.keys)))
    (expect-eq !>(%.n) !>(=(verifier.keys verifier.other)))
    (expect-eq !>(%.n) !>(=(state.keys state.other)))
    (expect-eq !>(~) !>((find "=" (trip challenge.keys))))
    (expect-eq !>(~) !>((find "+" (trip challenge.keys))))
    (expect-eq !>(~) !>((find "/" (trip challenge.keys))))
  ==
::
++  test-jwt-expiry
  ^-  tang
  =/  expiring  (jwt (json-object ~[['exp' (numb:enjs:format 1.800.000.000)] ['sub' s+'x']]))
  =/  no-exp  (jwt (json-object ~[['sub' s+'x']]))
  =/  absurd  (jwt (json-object ~[['exp' (numb:enjs:format 300.000.000.000)]]))
  ;:  weld
    (expect-eq !>(`(add ~1970.1.1 (mul 1.800.000.000 ~s1))) !>((jwt-expiry:oa expiring)))
    (expect-eq !>(`in-one-hour) !>((jwt-expiry:oa account-jwt)))
    (expect-eq !>(~) !>((jwt-expiry:oa no-exp)))
    (expect-eq !>(~) !>((jwt-expiry:oa absurd)))
    (expect-eq !>(~) !>((jwt-expiry:oa 'sk-not-a-jwt')))
    (expect-eq !>(~) !>((jwt-expiry:oa 'a.b')))
    (expect-eq !>(~) !>((jwt-expiry:oa 'a.!!!.c')))
    (expect-eq !>(['acct-1' 'person@example.com']) !>((jwt-account:oa id-jwt)))
    (expect-eq !>(['acct-1' '']) !>((jwt-account:oa account-jwt)))
    (expect-eq !>(['' '']) !>((jwt-account:oa 'opaque')))
  ==
::
++  test-parse-usercode
  ^-  tang
  ;:  weld
    (expect-eq !>(`['dev-1' 'ABCD-EFGH' 5]) !>((parse-usercode:oa '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH","interval":5}')))
    (expect-eq !>(`['dev-1' 'ABCD-EFGH' 5]) !>((parse-usercode:oa '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH"}')))
    (expect-eq !>(`['dev-1' 'ABCD-EFGH' 2]) !>((parse-usercode:oa '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH","interval":1}')))
    (expect-eq !>(`['dev-1' 'ABCD-EFGH' 60]) !>((parse-usercode:oa '{"device_auth_id":"dev-1","user_code":"ABCD-EFGH","interval":500}')))
    (expect-eq !>(~) !>((parse-usercode:oa '{"user_code":"ABCD-EFGH"}')))
    (expect-eq !>(~) !>((parse-usercode:oa '{"device_auth_id":"dev-1"}')))
    (expect-eq !>(~) !>((parse-usercode:oa 'not json')))
  ==
::
++  test-parse-poll
  ^-  tang
  ;:  weld
    (expect-eq !>([%code 'code-1' 'ver-1']) !>((parse-poll:oa 200 '{"authorization_code":"code-1","code_verifier":"ver-1"}')))
    (expect-eq !>([%code 'code-1' '']) !>((parse-poll:oa 200 '{"authorization_code":"code-1"}')))
    (expect-eq !>([%pending ~]) !>((parse-poll:oa 200 '{"status":"waiting"}')))
    (expect-eq !>([%pending ~]) !>((parse-poll:oa 202 '{"status":"pending"}')))
    (expect-eq !>([%pending ~]) !>((parse-poll:oa 403 '{"error":"authorization_pending","detail":"Device code pending"}')))
    (expect-eq !>([%failed %expired]) !>((parse-poll:oa 403 '{"error":"device code expired"}')))
    (expect-eq !>([%failed %denied]) !>((parse-poll:oa 400 '{"error":"access_denied"}')))
    (expect-eq !>([%failed %device-auth-disabled]) !>((parse-poll:oa 403 '{"error":"device auth is disabled for this account"}')))
    (expect-eq !>([%failed %unreachable]) !>((parse-poll:oa 503 'bad gateway')))
    (expect-eq !>([%failed %denied]) !>((parse-poll:oa 401 '{"error":"unauthorized"}')))
  ==
::
++  test-parse-token-response
  ^-  tang
  =/  codex-body
    %-  en:json:html
    %-  json-object
    :~  ['access_token' s+account-jwt]
        ['refresh_token' s+'ref-1']
        ['id_token' s+id-jwt]
        ['token_type' s+'Bearer']
    ==
  =/  claude-body
    %-  en:json:html
    %-  json-object
    :~  ['access_token' s+'sk-ant-oat01-access']
        ['refresh_token' s+'sk-ant-ort01-refresh']
        ['expires_in' (numb:enjs:format 3.600)]
        ['account' (json-object ~[['uuid' s+'user-1'] ['email_address' s+'person@example.com']])]
        ['organization' (json-object ~[['uuid' s+'org-1'] ['name' s+'Org']])]
        ['scope' s+'user:inference user:profile']
    ==
  =/  codex  (need (parse-token-response:oa %codex fixed-now codex-body))
  =/  claude  (need (parse-token-response:oa %claude fixed-now claude-body))
  =/  short  (need (parse-token-response:oa %claude fixed-now '{"access_token":"at","expires_in":10}'))
  ;:  weld
    (expect-eq !>(account-jwt) !>(access.codex))
    (expect-eq !>('ref-1') !>(refresh.codex))
    (expect-eq !>(`in-one-hour) !>(expires.codex))
    (expect-eq !>('acct-1') !>(account.codex))
    (expect-eq !>('person@example.com') !>(label.codex))
    (expect-eq !>('sk-ant-oat01-access') !>(access.claude))
    (expect-eq !>('sk-ant-ort01-refresh') !>(refresh.claude))
    (expect-eq !>(`(add fixed-now ~h1)) !>(expires.claude))
    (expect-eq !>('user-1') !>(account.claude))
    (expect-eq !>('person@example.com') !>(label.claude))
    (expect-eq !>('user:inference user:profile') !>(scopes.claude))
    (expect-eq !>(~) !>(expires.short))
    (expect-eq !>('') !>(refresh.short))
    (expect-eq !>(~) !>((parse-token-response:oa %codex fixed-now '{"refresh_token":"only"}')))
    (expect-eq !>(~) !>((parse-token-response:oa %codex fixed-now '{"access_token":""}')))
    (expect-eq !>(~) !>((parse-token-response:oa %claude fixed-now 'garbage')))
  ==
::
++  test-parse-pasted
  ^-  tang
  =/  auth-json
    %-  en:json:html
    %-  json-object
    :~  ['OPENAI_API_KEY' ~]
        :-  'tokens'
        %-  json-object
        :~  ['id_token' s+id-jwt]
            ['access_token' s+account-jwt]
            ['refresh_token' s+'ref-1']
            ['account_id' s+'acct-from-file']
        ==
        ['last_refresh' s+'2026-09-01T00:00:00Z']
    ==
  =/  credentials-json
    %-  en:json:html
    %-  json-object
    :~  :-  'claudeAiOauth'
        %-  json-object
        :~  ['accessToken' s+'sk-ant-oat01-access']
            ['refreshToken' s+'sk-ant-ort01-refresh']
            ['expiresAt' (numb:enjs:format (mul 1.000 (epoch-seconds in-one-hour)))]
            ['scopes' a+~[s+'user:inference' s+'user:profile']]
            ['subscriptionType' s+'max']
        ==
    ==
  =/  codex  (need (parse-pasted:oa %codex fixed-now (rap 3 '  ' auth-json '\0a' ~)))
  =/  claude  (need (parse-pasted:oa %claude fixed-now credentials-json))
  =/  setup  (need (parse-pasted:oa %claude fixed-now 'sk-ant-oat01-setup-token\0a'))
  =/  claude-key  (need (parse-pasted:oa %claude fixed-now 'sk-ant-api03-key'))
  =/  codex-key  (need (parse-pasted:oa %codex fixed-now 'sk-proj-key'))
  =/  codex-jwt  (need (parse-pasted:oa %codex fixed-now account-jwt))
  ;:  weld
    (expect-eq !>(%oauth) !>(method.codex))
    (expect-eq !>(account-jwt) !>(access.codex))
    (expect-eq !>('ref-1') !>(refresh.codex))
    (expect-eq !>(`in-one-hour) !>(expires.codex))
    (expect-eq !>('acct-from-file') !>(account.codex))
    (expect-eq !>('person@example.com') !>(label.codex))
    (expect-eq !>(%oauth) !>(method.claude))
    (expect-eq !>('sk-ant-oat01-access') !>(access.claude))
    (expect-eq !>('sk-ant-ort01-refresh') !>(refresh.claude))
    (expect-eq !>(`in-one-hour) !>(expires.claude))
    (expect-eq !>('user:inference user:profile') !>(scopes.claude))
    (expect-eq !>(%setup-token) !>(method.setup))
    (expect-eq !>('sk-ant-oat01-setup-token') !>(access.setup))
    (expect-eq !>('') !>(refresh.setup))
    (expect-eq !>(~) !>(expires.setup))
    (expect-eq !>(%api-key) !>(method.claude-key))
    (expect-eq !>(%api-key) !>(method.codex-key))
    (expect-eq !>('sk-proj-key') !>(access.codex-key))
    (expect-eq !>(%oauth) !>(method.codex-jwt))
    (expect-eq !>(`in-one-hour) !>(expires.codex-jwt))
    (expect-eq !>('acct-1') !>(account.codex-jwt))
    (expect-eq !>(~) !>((parse-pasted:oa %codex fixed-now '   ')))
    (expect-eq !>(~) !>((parse-pasted:oa %codex fixed-now 'two words')))
    (expect-eq !>(~) !>((parse-pasted:oa %codex fixed-now '{"tokens":{"refresh_token":"only"}}')))
    (expect-eq !>(~) !>((parse-pasted:oa %codex fixed-now '{"access_token":""}')))
  ==
::
++  test-renewal-state
  ^-  tang
  =/  idle  idle-renewal
  =/  fresh  (oauth-account 'refresh' `in-one-hour idle)
  =/  soon  (oauth-account 'refresh' `(add fixed-now ~m3) idle)
  =/  passed  (oauth-account 'refresh' `(sub fixed-now ~m1) idle)
  =/  no-refresh  (oauth-account '' `(add fixed-now ~m3) idle)
  =/  no-expiry  (oauth-account '' ~ idle)
  =/  cooling  (oauth-account 'refresh' `(add fixed-now ~m3) idle(retry-at (add fixed-now ~s30)))
  =/  cooled  (oauth-account 'refresh' `(add fixed-now ~m3) idle(retry-at (sub fixed-now ~s1)))
  =/  terminal  (oauth-account 'refresh' `(add fixed-now ~m3) idle(terminal %.y))
  =/  renewing  (oauth-account 'refresh' `in-one-hour idle(active `[1 (add fixed-now ~s30)]))
  =/  key  fresh(method %api-key, expires `(sub fixed-now ~d1))
  =/  setup  fresh(method %setup-token, expires `(sub fixed-now ~d1))
  ;:  weld
    (expect-eq !>(%usable) !>((renewal-state:oa fresh fixed-now)))
    (expect-eq !>(%renew) !>((renewal-state:oa fresh (sub in-one-hour ~m4))))
    (expect-eq !>(%usable) !>((renewal-state:oa fresh (sub in-one-hour ~m6))))
    (expect-eq !>(%renew) !>((renewal-state:oa soon fixed-now)))
    (expect-eq !>(%renew) !>((renewal-state:oa passed fixed-now)))
    (expect-eq !>(%expired) !>((renewal-state:oa no-refresh fixed-now)))
    (expect-eq !>(%usable) !>((renewal-state:oa no-expiry fixed-now)))
    (expect-eq !>(%cooldown) !>((renewal-state:oa cooling fixed-now)))
    (expect-eq !>(%renew) !>((renewal-state:oa cooled fixed-now)))
    (expect-eq !>(%terminal) !>((renewal-state:oa terminal fixed-now)))
    (expect-eq !>(%renewing) !>((renewal-state:oa renewing fixed-now)))
    (expect-eq !>(%usable) !>((renewal-state:oa key fixed-now)))
    (expect-eq !>(%usable) !>((renewal-state:oa setup fixed-now)))
  ==
::
++  test-auth-headers-never-mix-credentials
  ^-  tang
  =/  codex-oauth  (oauth-account 'refresh' `in-one-hour idle-renewal)
  =/  codex-key  codex-oauth(method %api-key, account '')
  =/  claude-oauth  codex-oauth
  =/  claude-key  codex-oauth(method %api-key)
  =/  claude-setup  codex-oauth(method %setup-token)
  =/  rows=(list [provider=ai-provider account=provider-account])
    :~  [%codex codex-oauth]
        [%codex codex-key]
        [%claude claude-oauth]
        [%claude claude-key]
        [%claude claude-setup]
    ==
  =/  exclusive=tang
    %-  zing
    %+  turn  rows
    |=  [provider=ai-provider account=provider-account]
    =/  headers  (auth-headers:oa provider account)
    (expect-eq !>(1) !>((add (header-count headers 'authorization') (header-count headers 'x-api-key'))))
  =/  codex-headers  (auth-headers:oa %codex codex-oauth)
  =/  codex-key-headers  (auth-headers:oa %codex codex-key)
  =/  claude-headers  (auth-headers:oa %claude claude-oauth)
  =/  claude-key-headers  (auth-headers:oa %claude claude-key)
  ;:  weld  exclusive
    (expect-eq !>(`'Bearer access') !>((header:net codex-headers 'authorization')))
    (expect-eq !>(`'acct') !>((header:net codex-headers 'chatgpt-account-id')))
    (expect-eq !>(~) !>((header:net codex-key-headers 'chatgpt-account-id')))
    (expect-eq !>(`'Bearer access') !>((header:net claude-headers 'authorization')))
    (expect-eq !>(`'oauth-2025-04-20') !>((header:net claude-headers 'anthropic-beta')))
    (expect-eq !>(`'access') !>((header:net claude-key-headers 'x-api-key')))
    (expect-eq !>(~) !>((header:net claude-key-headers 'anthropic-beta')))
    (expect-eq !>(codex-api-url:net) !>((generation-url:oa %codex codex-key)))
    (expect-eq !>(codex-oauth-url:net) !>((generation-url:oa %codex codex-oauth)))
    (expect-eq !>(codex-catalog-api:net) !>((catalog-url:oa %codex codex-key)))
    (expect-eq !>(claude-messages-url:net) !>((generation-url:oa %claude claude-key)))
  ==
::
++  test-authorize-link-and-pasted-code
  ^-  tang
  =/  link  (trip (claude-authorize-link:oa 'chal' 'nonce-1'))
  =/  exchange  (claude-exchange-request:oa 'code-1' 'nonce-1' 'ver-1')
  =/  exchange-body  (fall (decode:net q:(need body.exchange)) ~)
  =/  poll  (poll-request:oa 'dev-1' 'ABCD')
  =/  poll-body  (fall (decode:net q:(need body.poll)) ~)
  =/  codex-exchange  (codex-exchange-request:oa 'code-1' 'ver-1')
  =/  form  (trip q:(need body.codex-exchange))
  ;:  weld
    (expect-eq !>(%.y) !>(=((trip claude-authorize-url:oa) (scag (lent (trip claude-authorize-url:oa)) link))))
    (expect-eq !>(%.y) !>(?=(^ (find "code_challenge=chal" link))))
    (expect-eq !>(%.y) !>(?=(^ (find "code_challenge_method=S256" link))))
    (expect-eq !>(%.y) !>(?=(^ (find "state=nonce-1" link))))
    (expect-eq !>(%.y) !>(?=(^ (find (trip claude-client-id:oa) link))))
    (expect-eq !>(['code-1' 'nonce-1']) !>((split-pasted-code:oa 'code-1#nonce-1')))
    (expect-eq !>(['code-1' '']) !>((split-pasted-code:oa 'code-1')))
    (expect-eq !>(%'POST') !>(method.exchange))
    (expect-eq !>(claude-token-url:oa) !>(url.exchange))
    (expect-eq !>(`'code-1') !>((get-string:net exchange-body 'code')))
    (expect-eq !>(`'nonce-1') !>((get-string:net exchange-body 'state')))
    (expect-eq !>(`'ver-1') !>((get-string:net exchange-body 'code_verifier')))
    (expect-eq !>(codex-poll-url:oa) !>(url.poll))
    (expect-eq !>(`'dev-1') !>((get-string:net poll-body 'device_auth_id')))
    (expect-eq !>(`'ABCD') !>((get-string:net poll-body 'user_code')))
    (expect-eq !>(codex-token-url:oa) !>(url.codex-exchange))
    (expect-eq !>(%.y) !>(?=(^ (find "grant_type=authorization_code" form))))
    (expect-eq !>(%.y) !>(?=(^ (find "code_verifier=ver-1" form))))
    (expect-eq !>(%.y) !>(?=(^ (find "code=code-1" form))))
  ==
--
