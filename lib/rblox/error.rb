# frozen_string_literal: true

module Rblox
  class Error < StandardError; end

  class ParseError < Error; end

  class RuntimeError < Error
    attr_reader :token

    def initialize(token, message)
      super(message)
      @token = token
    end
  end

  class Return < Error
    attr_reader :value

    def initialize(value)
      super("return = #{value}")
      @value = value
    end
  end
end
