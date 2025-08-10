# frozen_string_literal: true

require_relative 'error'

module Rblox
  class Callable
    attr_reader :arity

    def initialize(arity)
      @arity = arity
    end

    def call(interpreter, arguments)
      raise NotImplementedError, "#{self.class} must implement the 'call' method."
    end
  end
end
