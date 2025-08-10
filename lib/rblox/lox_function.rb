# frozen_string_literal: true

require_relative 'error'
require_relative 'callable'

module Rblox
  class LoxFunction < Callable
    attr_reader :declaration, :closure

    def initialize(declaration, closure = nil)
      super(declaration.params.size)

      @declaration = declaration
      @closure = closure
    end

    def call(interpreter, arguments)
      environment = Environment.new(closure)

      declaration.params.zip(arguments).each do |param, arg|
        environment.define(param, arg)
      end

      interpreter.execute_block(declaration.body, environment)
    rescue Rblox::Return => e
      e.value
    end

    def bind(instance)
      environment = Environment.new(@closure)
      environment.define('this', instance)

      LoxFunction.new(declaration, environment)
    end

    def to_s = "function #{@declaration.name.lexeme}"
  end
end
