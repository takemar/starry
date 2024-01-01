require 'forwardable'

class Starry::InnerList

  attr_accessor :value, :parameters

  include Enumerable
  extend Forwardable
  def_delegator :value, :each

  def initialize(value = [], parameters = {})
    @value = value
    @parameters = parameters
  end

  def ==(other)
    self.class == other.class && self.value == other.value && self.parameters == other.parameters
  end

  def to_s
    members = self.map do |item|
      Starry.serialize_item(item)
    end
    "(#{ members.join(' ') })#{ Starry.serialize_parameters(parameters) }"
  end

  alias deconstruct to_a

  def deconstruct_keys(keys)
    { value: @value, parameters: @parameters }
  end
end
