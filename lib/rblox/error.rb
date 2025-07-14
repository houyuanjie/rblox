# frozen_string_literal: true

module Rblox
  class Error < StandardError; end

  class RuntimeError < Error
    attr_reader :token

    def initialize(token, message)
      super(message)
      @token = token
    end
  end
end
