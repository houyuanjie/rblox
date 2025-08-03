# frozen_string_literal: true

module Rblox
  class LoxInstance
    attr_reader :lox_class

    def initialize(lox_class)
      @lox_class = lox_class
    end

    def to_s = "instance #{@lox_class.name}"
  end
end
