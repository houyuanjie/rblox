# frozen_string_literal: true

module Rblox
  Token = Data.define(:type, :lexeme, :literal, :line) do
    def to_s = "#{type} #{lexeme} #{literal}"
  end
end
