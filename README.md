# Starry

Starry is a Ruby library for [HTTP Structured Field Values (RFC 8941)](https://www.rfc-editor.org/rfc/rfc8941.html).

## Install

Add the following line to your `Gemfile`:

```ruby
gem "starry"
```

Or just `gem install starry`.

## Basic Usage

### Parsing

Use an appropriate one of `Starry.parse_list`, `Starry.parse_dictionary`, or `Starry.parse_item`.

```ruby
require 'starry'

# Basic case: Proxy-Status field (RFC 9209)
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')
# =>
# [#<Starry::Item:0x0000000105a82658
#   @parameters={"error"=>:http_request_error},
#   @value=:"r34.example.net">,
#  #<Starry::Item:0x0000000105a81cd0 @parameters={}, @value=:ExampleCDN>]

# Retrieving bare value
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[1].value
# => :ExampleCDN

# Retrieving parameters
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[0].parameters
# => {"error"=>:http_request_error}

# More complex case: Signature-Input field (draft-ietf-httpbis-message-signatures)
Starry.parse_dictionary(
  'sig1=("@method" "@authority" "@path" "content-digest" "content-type" ' \
  '"content-length");created=1618884475;keyid="test-key-ecc-p256", ' \
  'proxy_sig=("@method" "@authority" "@path" "content-digest" "content-type" ' \
  '"content-length" "forwarded");created=1618884480;keyid="test-key-rsa";' \
  'alg="rsa-v1_5-sha256";expires=1618884540'
)
# =>
# {"sig1"=>
#   #<Starry::InnerList:0x0000000107dc8c70
#    @parameters={"created"=>1618884475, "keyid"=>"test-key-ecc-p256"},
#    @value=
#     [#<Starry::Item:0x0000000107dcab88 @parameters={}, @value="@method">,
#      ...,
#      #<Starry::Item:0x0000000107dc9648
#       @parameters={},
#       @value="content-length">]>,
#  "proxy_sig"=>
#   #<Starry::InnerList:0x0000000107dc5a98
#    @parameters=
#     {"created"=>1618884480,
#      "keyid"=>"test-key-rsa",
#      "alg"=>"rsa-v1_5-sha256",
#      "expires"=>1618884540},
#    @value=
#     [#<Starry::Item:0x0000000107dc8450 @parameters={}, @value="@method">,
#      ...,
#      #<Starry::Item:0x0000000107dc6b00 @parameters={}, @value="forwarded">]>}
```

### Serializing

Use `Starry.serialize`. This single method is used for all three types: List, Dictionary, and Item.

If an Item or an Inner List has parameters, create a new `Starry::Item` or `Starry::InnerList` class object and use it. Non-parameterized values can be contained without such a wrapping object. Also, note that keys of the parameters hash can be either strings or symbols.

```ruby
require 'starry'

Starry.serialize([
  Starry::Item.new(:'r34.example.net', { 'error' => :http_request_error }),
  :ExampleCDN
])
# => "r34.example.net;error=http_request_error, ExampleCDN"

Starry.serialize({
  'sig-b22' => Starry::InnerList.new(
    ['@authority', 'content-digest', Starry::Item.new('@query-param', { name: 'Pet' })],
    { created: 1618884473, keyid: 'test-key-rsa-pss', tag: 'header-example' }
  )
})
# => "sig-b22=(\"@authority\" \"content-digest\" \"@query-param\";name=\"Pet\");created=1618884473;keyid=\"test-key-rsa-pss\";tag=\"header-example\""
```

## Further Topics

### Type mappings

The Structured Field Values specification defines several data types. Here we describe which Ruby class is used for each of them in this library.

- For **Lists**, `Array` is used.
- For **Inner Lists**, `Starry::InnerList` is used.
    - If it is not parameterized, `Array` may also be used when serializing.
- For **parameters**, `Hash` is used.
- For **Dictionaries**, `Hash` is used.
- For **Items**, `Starry::Item` is used.
    - When serializing, `Starry::Item` is not necessarily needed if the value is not parameterized. See the description and examples above.
- For **Integer** values, `Integer` is used.
    - Note that its absolute value is limited to less than `10**15`.
- For **Decimal** values, `Float` is used.
    - Note that its absolute value is limited to less than `10**12`. Also, it is rounded to three decimal places when serialized.
- For **String** values, `String` with encoding other than `ASCII_8BIT` is used.
    - Note that only ASCII printable characters are allowed.
- For **Token** values, `Symbol` is used.
    - Be aware of the syntax when serializing; see the RFC for details.
- For **Byte Sequence** (binary) values, `String` with encoding `ASCII_8BIT` is used.
- For **Boolean** values, `true` and `false` are used.
