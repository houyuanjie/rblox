# frozen_string_literal: true

module Rblox
  module Expr
    TYPES = {
      'Assign' => %w[name value],
      'Binary' => %w[left operator right],
      'Call' => %w[callee paren arguments],
      'Get' => %w[object name],
      'Grouping' => %w[expression],
      'Literal' => %w[value],
      'Logical' => %w[left operator right],
      'Set' => %w[object name value],
      'Super' => %w[keyword method],
      'This' => %w[keyword],
      'Unary' => %w[operator right],
      'Variable' => %w[name]
    }.freeze

    TYPES.each do |klass_name, fields|
      klass = Data.define(*fields) do
        define_method :accept do |visitor|
          visitor_method = "visit_#{klass_name.downcase}_expr"
          visitor.send(visitor_method, self)
        end
      end

      const_set(klass_name, klass)
    end
  end
end
