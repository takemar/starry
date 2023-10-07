require 'base64'
require 'forwardable'
require 'strscan'

class Starry::Parser

  extend Forwardable

  def initialize(input, symbolize_names: false)
    @s = StringScanner.new(input)
    @symbolize_names = symbolize_names
  end

  def parse(type)
    consume_sp
    output = (
      case type
      when :list
        parse_list
      when :dictionary
        parse_dictionary
      when :item
        parse_item
      else
        raise ArgumentError
      end
    )
    consume_sp
    unless @s.eos?
      parse_error(:eos)
    end
    output
  end

  def parse_list
    output = []
    until eos?
      output << parse_item_or_inner_list
      consume_ows
      return output if eos?
      expect(',')
      consume_ows
      parse_error if eos?
    end
    output
  end

  def parse_item_or_inner_list
    if check('(')
      parse_inner_list
    else
      parse_item
    end
  end

  def parse_inner_list
    output = []
    expect('(')
    until eos?
      consume_sp
      if scan(')')
        parameters = parse_parameters
        return Starry::InnerList.new(output, parameters)
      end
      output << parse_item
      unless check(/[ )]/)
        parse_error([' ', ')'])
      end
    end
    parse_error(')')
  end

  def parse_dictionary
    output = {}
    until eos?
      key = parse_key
      if scan('=')
        value = parse_item_or_inner_list
      else
        parameters = parse_parameters
        value = Starry::Item.new(true, parameters)
      end
      output[key] = value
      consume_ows
      return output if eos?
      expect(',')
      consume_ows
      parse_error if eos?
    end
    output
  end

  def parse_item
    value = parse_bare_item
    parameters = parse_parameters
    Starry::Item.new(value, parameters)
  end

  def parse_bare_item
    case
    when check(/[-0-9]/)
      parse_integer_or_decimal
    when check('"')
      parse_string
    when check(/[A-Za-z*]/)
      parse_token
    when check(':')
      parse_byte_sequence
    when check('?')
      parse_boolean
    else
      parse_error
    end
  end

  def parse_parameters
    output = {}
    until eos?
      break unless scan(';')
      consume_sp
      key = parse_key
      if scan('=')
        value = parse_bare_item
      else
        value = true
      end
      output[key] = value
    end
    output
  end

  def parse_key
    parse_error unless check(/[a-z*]/)
    output = scan(/[a-z0-9_\-.*]*/)
    if @symbolize_names
      output.to_sym
    else
      output
    end
  end

  def parse_integer_or_decimal
    unless output = scan(/-?(\d+)(\.\d+)?/)
      parse_error
    end
    if @s[2]
      if @s[1].size > 12 || @s[2].size > 4
        parse_error
      end
      output.to_f
    else
      if @s[1].size > 15
        parse_error
      end
      output.to_i
    end
  end

  def parse_string
    expect('"')
    output = scan(/([\u0020-\u0021\u0023-\u005b\u005d-\u007e]|\\[\\"])*/)
    expect('"')
    output.gsub(/\\([\\"])/, '\1')
  end

  def parse_token
    check(/[A-Za-z*]/)
    scan(/[!#$%&'*+\-.^_`|~0-9A-Za-z:\/]*/).to_sym
  end

  def parse_byte_sequence
    expect(':')
    output = scan(/[A-Za-z0-9+\/=]*/)
    expect(':')
    Base64.decode64(output)
  end

  def parse_boolean
    unless scan(/\?([01])/)
      parse_error
    end
    @s[1] == '1'
  end

  private

  def_delegators :@s, :check, :scan, :eos?

  def expect(regexp)
    scan(regexp) || parse_error(regexp)
  end

  def consume_sp
    scan(/ */)
  end

  def consume_ows
    scan(/[ \t]*/)
  end

  def parse_error(_ = nil)
    raise Starry::ParseError
  end

end
