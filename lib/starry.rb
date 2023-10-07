require 'base64'

module Starry

  class SerializeError < ::StandardError; end
  class ParseError < ::StandardError; end

  class << self

    def serialize(input)
      case input
      when {}, []
        return nil
      when Hash
        serialize_dictionary(input)
      when Enumerable
        serialize_list(input)
      else
        serialize_item(input)
      end
    end

    def serialize_list(input)
      input.map do |item|
        serialize_item_or_inner_list(item)
      end.join(', ')
    end

    def serialize_parameters(input)
      input.transform_keys(&:to_s).map do |key, value|
        if value == true
          ";#{ serialize_key(key) }"
        else
          ";#{ serialize_key(key) }=#{ serialize_bare_item(value) }"
        end
      end.join('')
    end

    def serialize_key(input)
      unless input.match?(/\A[a-z*][a-z0-9_\-.*]*\z/)
        raise SerializeError, "The given value #{ input.inspect } contains characters that are not allowed as a key for dictionary / parameters in HTTP Structured Field."
      end
      input
    end

    def serialize_dictionary(input)
      input.transform_keys(&:to_s).map do |key, value|
        if value == true
          serialize_key(key)
        elsif value.kind_of?(Item) && value.value == true
          "#{ serialize_key(key) }#{ serialize_parameters(value.parameters) }"
        else
          "#{ serialize_key(key) }=#{ serialize_item_or_inner_list(value) }"
        end
      end.join(', ')
    end

    def serialize_item(input)
      if input.kind_of?(Item)
        input.to_s
      else
        serialize_bare_item(input)
      end
    end

    def serialize_bare_item(input)
      case input
      when Integer
        if input.abs >= 10 ** 15
          raise SerializeError, "Integer value in HTTP Structured Field must have an absolute value less than 10 ** 15, but #{ input } given."
        end
        input.to_s
      when Float
        x = input.round(3, half: :even)
        if x.abs >= 10 ** 12
          raise SerializeError, "Numeric value in HTTP Structured Field must have an absolute value less than 10 ** 15, but #{ input } given."
        end
        x.to_s
      when String
        if input.encoding == Encoding::ASCII_8BIT
          ":#{ Base64.strict_encode64(input) }:"
        else
          unless input.match?(/\A[\u0020-\u007E]*\z/)
            raise SerializeError, "String value in HTTP Structured Field must consist of only ASCII printable characters, but given value #{ input.inspect } does not meet that."
          end
          "\"#{ input.gsub(/\\|"/) { "\\#{ _1 }" } }\""
        end
      when Symbol
        unless input.to_s.match?(/\A[A-Za-z*][!#$%&'*+\-.^_`|~0-9A-Za-z:\/]*\z/)
          raise SerializeError, "The given value #{ input.inspect } contains characters that are not allowed as Token in HTTP Structured Field."
        end
        input.to_s
      when true
        '?1'
      when false
        '?0'
      else
        raise SerializeError, "The given value #{ input.inspect } cannnot be used as a bare item of HTTP Structured Field."
      end
    end

    private def serialize_item_or_inner_list(input)
      case input
      when InnerList
        input.to_s
      when Hash
        raise SerializeError, "Hash cannnot be used as an item of HTTP Structured Field, but #{ input.inspect } given."
      when Enumerable
        InnerList.new(input).to_s
      when Item
        case input.value
        when Hash
          raise SerializeError, "Hash cannnot be used as an item of HTTP Structured Field, but #{ input.value.inspect } given."
        when Enumerable
          InnerList.new(input.value, input.parameters).to_s
        else
          input.to_s
        end
      else
        serialize_bare_item(input)
      end
    end

    def parse_list(input)
      ensure_ascii_only(input)
      Parser.new(input).parse(:list)
    end

    def parse_dictionary(input)
      ensure_ascii_only(input)
      Parser.new(input).parse(:dictionary)
    end

    def parse_item(input)
      ensure_ascii_only(input)
      Parser.new(input).parse(:item)
    end

    private def ensure_ascii_only(input)
      unless input.ascii_only?
        raise ParseError, "Input string contains unexpected non-ASCII character."
      end
    end
  end
end

require_relative 'starry/inner_list'
require_relative 'starry/item'
require_relative 'starry/parser'
require_relative 'starry/version'
