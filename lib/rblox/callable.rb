# frozen_string_literal: true

require_relative 'error'

module Rblox
  class Callable
    attr_reader :arity

    def initialize(arity, &block)
      @arity = arity
      @block = block
    end

    def call(...) = @block.call(...)

    def self.function(declaration, closure = nil)
      new(declaration.params.size) do |interpreter, arguments|
        environment = Environment.new(closure)

        declaration.params.zip(arguments).each do |param, arg|
          environment.define(param.lexeme, arg)
        end

        begin
          interpreter.execute_block(declaration.body, environment)
        rescue Rblox::Return => e
          # if you `return`, you return value to this function's call-site, somewhere `Rblox::Callable.function(stmt)`
          # if you `next`, you pass value to this block's call-site, somewhere `callable.call(iptr,args)`
          # so, we need a `next` here
          next e.value
        end

        nil
      end
    end
  end
end
