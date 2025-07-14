# frozen_string_literal: true

module Rblox
  class Stmt
    variants = {
      'Block' => %w[statements],
      'Class' => %w[name superclass methods],
      'Expression' => %w[expression],
      'Function' => %w[name params body],
      'If' => %w[condition then_branch else_branch],
      'Print' => %w[expression],
      'Return' => %w[keyword value],
      'Var' => %w[name initializer],
      'While' => %w[condition body]
    }

    variants.each do |klass_name, fields|
      klass = Data.define(*fields) do
        define_method :accept do |visitor|
          visitor_method = "visit_#{klass_name.downcase}_stmt"
          visitor.send(visitor_method, self)
        end
      end

      const_set(klass_name, klass)
    end
  end
end
