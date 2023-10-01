require 'forwardable'

class Stella::InnerList

  attr_accessor :items, :parameters

  include Enumerable
  extend Forwardable
  def_delegator :items, :each

  def initialize(items = [], parameters = {})
    @items = items
    @parameters = parameters
  end

  def to_s
    members = self.map do |item|
      Stella.serialize_item(item)
    end
    "(#{ members.join(' ') })#{ Stella.serialize_parameters(parameters) }"
  end
end
