require 'base32'
require './lib/stella'

class NotImplementedTypeError < StandardError; end

def parse_test(data, type)
  case type
  when 'item'
    parse_test_item(data)
  when 'list'
    parse_test_list(data)
  when 'dictionary'
    parse_test_dictionary(data)
  else
    raise 'unknown type'
  end
end

def parse_test_item(data)
  Stella::Item.new(parse_test_bare_item(data.first), parse_test_parameters(data.last))
end

def parse_test_list(data)
  data.map do |v|
    parse_test_item_or_inner_list(v)
  end
end

def parse_test_dictionary(data)
  data.map do |k, v|
    [k, parse_test_item_or_inner_list(v)]
  end.to_h
end

def parse_test_bare_item(data)
  case data
  when Hash
    case data['__type']
    when 'token'
      data['value'].to_sym
    when 'binary'
      Base32.decode(data['value']).force_encoding(Encoding::ASCII_8BIT)
    when 'date', 'displaystring'
      raise NotImplementedTypeError
    else
      raise 'unknown type'
    end
  when Integer, Float, String, true, false
    data
  else
    raise "unknown test format"
  end
end

def parse_test_parameters(data)
  data.map do |k, v|
    [k, parse_test_bare_item(v)]
  end.to_h
end

def parse_test_item_or_inner_list(data)
  if data.first.kind_of?(Array)
    parse_test_inner_list(data)
  else
    parse_test_item(data)
  end
end

def parse_test_inner_list(data)
  Stella::InnerList.new(
    data.first.map { parse_test_item(_1) },
    parse_test_parameters(data.last.to_h),
  )
end
