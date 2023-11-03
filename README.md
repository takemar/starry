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

Use `Starry.serialize`.

// TODO: Example code
