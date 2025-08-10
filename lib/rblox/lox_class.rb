# frozen_string_literal: true

require_relative 'callable'
require_relative 'lox_instance'

module Rblox
  class LoxClass < Callable
    attr_reader :name, :methods

    def initialize(name, methods)
      super(0)

      @name = name.is_a?(Token) ? name.lexeme : name.to_s
      @methods = methods
    end

    def call(interpreter, arguments) = instantiate(interpreter, arguments)

    def instantiate(_interpreter, _arguments)
      LoxInstance.new(self)
    end

    def find_method(name) = @methods[name]

    def to_s = "class #{@name}"
  end
end
