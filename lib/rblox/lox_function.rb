# frozen_string_literal: true

require_relative 'error'
require_relative 'callable'
require_relative 'environment'

module Rblox
  class LoxFunction < Callable
    attr_reader :declaration, :closure

    def initialize(declaration, closure = nil, is_initializer: false)
      super(declaration.params.size)

      @declaration = declaration
      @closure = closure

      @is_initializer = is_initializer
    end

    def call(interpreter, arguments)
      environment = Environment.new(closure)

      declaration.params.zip(arguments).each do |param, arg|
        environment.define(param, arg)
      end

      begin
        interpreter.execute_block(declaration.body, environment)
      rescue Rblox::Return => e
        return @closure&.get_at(0, 'this') if initializer?

        return e.value
      end

      @closure&.get_at(0, 'this') if initializer?
    end

    def bind(instance)
      environment = Environment.new(@closure)
      environment.define('this', instance)

      LoxFunction.new(declaration, environment, is_initializer: @is_initializer)
    end

    def bind_call(instance, interpreter, arguments) = bind(instance).call(interpreter, arguments) # rubocop:disable Performance/BindCall

    def initializer? = @is_initializer

    def to_s = "function #{@declaration.name.lexeme}"
  end
end
