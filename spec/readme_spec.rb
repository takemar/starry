require 'pp'

RSpec::Matchers.define :be_like do |pattern, *subpatterns|
  match do |actual|
    Regexp.new("\\A#{ Regexp.escape(pattern) % subpatterns }\\z", Regexp::MULTILINE).match(actual)
  end
end

RSpec.describe 'README' do
  describe 'Parsing' do
    example 'Basic case: Proxy-Status field (RFC 9209)' do
      actual = Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')
      expected = <<~'EOS'
        [#<Starry::Item:0x%s
          @parameters={"error"=>:http_request_error},
          @value=:"r34.example.net">,
         #<Starry::Item:0x%s @parameters={}, @value=:ExampleCDN>]
      EOS
      expect(actual.pretty_inspect).to be_like(expected, '[0-9a-z]*', '[0-9a-z]*')
    end

    example 'Retrieving bare value of item' do
      actual = Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[1].value
      expected = ':ExampleCDN'
      expect(actual.pretty_inspect.chomp).to eq(expected)
    end

    example 'Retrieving parameters hash of item' do
      actual = Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN')[0].parameters
      expected = '{"error"=>:http_request_error}'
      expect(actual.pretty_inspect.chomp).to eq(expected)
    end

    example 'Using `symbolize_names` option' do
      actual = Starry.parse_list('r34.example.net; error=http_request_error, ExampleCDN', symbolize_names: true)[0].parameters
      expected = '{:error=>:http_request_error}'
      expect(actual.pretty_inspect.chomp).to eq(expected)
    end

    example 'More complex case: Signature-Input field (draft-ietf-httpbis-message-signatures)' do
      actual = Starry.parse_dictionary(
        'sig1=("@method" "@authority" "@path" "content-digest" "content-type" ' \
        '"content-length");created=1618884475;keyid="test-key-ecc-p256", ' \
        'proxy_sig=("@method" "@authority" "@path" "content-digest" "content-type" ' \
        '"content-length" "forwarded");created=1618884480;keyid="test-key-rsa";' \
        'alg="rsa-v1_5-sha256";expires=1618884540'
      )
      expected = <<~'EOS'
        {"sig1"=>
          #<Starry::InnerList:0x%s
           @parameters={"created"=>1618884475, "keyid"=>"test-key-ecc-p256"},
           @value=
            [#<Starry::Item:0x%s @parameters={}, @value="@method">,
             %s
             #<Starry::Item:0x%s
              @parameters={},
              @value="content-length">]>,
         "proxy_sig"=>
          #<Starry::InnerList:0x%s
           @parameters=
            {"created"=>1618884480,
             "keyid"=>"test-key-rsa",
             "alg"=>"rsa-v1_5-sha256",
             "expires"=>1618884540},
           @value=
            [#<Starry::Item:0x%s @parameters={}, @value="@method">,
             %s
             #<Starry::Item:0x%s @parameters={}, @value="forwarded">]>}
      EOS
      hex = '[0-9a-z]*'
      expect(actual.pretty_inspect).to be_like(expected, hex, hex, '.*', hex, hex, hex, '.*', hex)
    end
  end

  describe 'Serializing' do
    example 'list' do
      actual = Starry.serialize([
        Starry::Item.new(:'r34.example.net', { 'error' => :http_request_error }),
        :ExampleCDN
      ])
      expected = "r34.example.net;error=http_request_error, ExampleCDN"
      expect(actual).to eq(expected)
    end

    example 'dictionary' do
      actual = Starry.serialize({
        'sig-b22' => Starry::InnerList.new(
          ['@authority', 'content-digest', Starry::Item.new('@query-param', { name: 'Pet' })],
          { created: 1618884473, keyid: 'test-key-rsa-pss', tag: 'header-example' }
        )
      })
      expected = "sig-b22=(\"@authority\" \"content-digest\" \"@query-param\";name=\"Pet\");created=1618884473;keyid=\"test-key-rsa-pss\";tag=\"header-example\""
      expect(actual).to eq(expected)
    end
  end
end
