# frozen_string_literal: true

require_relative 'error'
require_relative 'callable'
require_relative 'lox_instance'

module Rblox
  class LoxClass < Callable
    attr_reader :name

    def initialize(name)
      # overloading with different parameter lists
      # steep the type checker does not seems to aware this
      #
      # steep:ignore:start
      super(0) do |interpreter, arguments|
        instantiate(interpreter, arguments)
      end
      # steep:ignore:end

      @name = name.is_a?(Token) ? name.lexeme : name.to_s
    end

    def instantiate(_interpreter, _arguments)
      LoxInstance.new(self)
    end

    def to_s = "class #{@name}"
  end
end
