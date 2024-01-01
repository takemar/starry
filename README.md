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

# Retrieving bare value of item
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[1].value
# => :ExampleCDN

# Retrieving parameters hash of item
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[0].parameters
# => {"error"=>:http_request_error}

# Using `symbolize_names` option
Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN', symbolize_names: true)[0].parameters
# => {:error=>:http_request_error}

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

If an Item or an Inner List has parameters, create a new `Starry::Item` or `Starry::InnerList` class object and use it. Their constructor takes a value as its first argument and a parameters hash as its second argument. Keys of the parameters hash can be either strings or symbols. Note that non-parameterized values can be contained without such a wrapping object.

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
    - Keys can be either `String` or `Symbol`. When parsing, the symbolize_names option indicates which is to be used.
    - When serializing, be aware of the syntax; see the RFC for details.
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

## Pattern matching

`Starry::Item` and `Starry::InnerList` support [pattern matching](https://docs.ruby-lang.org/en/master/syntax/pattern_matching_rdoc.html).

```ruby
require 'starry'

# `Starry::Item` can be matched with hash pattern using `value` and `parameters` keys.
case Starry.parse_item('r34.example.net; error=http_request_error')
in value:, parameters:
  "v: #{ value }, p: #{ parameters }"
else
  raise "not matched"
end
# => "v: r34.example.net, p: {\"error\"=>:http_request_error}"

# The same applies to `Starry::InnerList`.
inner_list = Starry.parse_dictionary(
  'sig-b25=("date" "@authority" "content-type");created=1618884473;' \
  'keyid="test-shared-secret"'
)['sig-b25']
case inner_list
in value:, parameters:
  "v: #{ value.map(&:value) }, p: #{ parameters }"
else
  raise "not matched"
end
# => "v: [\"date\", \"@authority\", \"content-type\"], p: {\"created\"=>1618884473, \"keyid\"=>\"test-shared-secret\"}"

# `Starry::InnerList` can be also matched with array pattern.
# Note that parameters cannot be available for matching in array pattern.
case inner_list
in first, second, *rest
  "first: #{ first.value }, second: #{ second.value }, rest: #{ rest.map(&:value) }"
else
  raise "not matched"
end
# => "first: date, second: @authority, rest: [\"content-type\"]"
```
