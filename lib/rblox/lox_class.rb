# frozen_string_literal: true

require_relative 'callable'
require_relative 'lox_instance'

module Rblox
  class LoxClass < Callable
    attr_reader :name, :methods

    def initialize(name, methods)
      super(methods['init']&.arity || 0)

      @name = name.is_a?(Token) ? name.lexeme : name.to_s
      @methods = methods
    end

    def call(interpreter, arguments) = instantiate(interpreter, arguments)

    def instantiate(interpreter, arguments)
      instance = LoxInstance.new(self)

      initializer = find_method('init')
      initializer&.bind_call(instance, interpreter, arguments)

      instance
    end

    def find_method(name) = @methods[name]

    def to_s = "class #{@name}"
  end
end
