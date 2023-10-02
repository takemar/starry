require 'forwardable'

class Stella::InnerList

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
      Stella.serialize_item(item)
    end
    "(#{ members.join(' ') })#{ Stella.serialize_parameters(parameters) }"
  end
end
