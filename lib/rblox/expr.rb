# frozen_string_literal: true

module Rblox
  module Expr
    BaseExpr = Module.new

    variants = {
      Assign: %i[name value],
      Binary: %i[left operator right],
      Call: %i[callee paren arguments],
      Get: %i[object name],
      Grouping: %i[expression],
      Literal: %i[value],
      Logical: %i[left operator right],
      Set: %i[object name value],
      Super: %i[keyword method],
      This: %i[keyword],
      Unary: %i[operator right],
      Variable: %i[name]
    }

    variants.each do |klass_name, fields|
      klass = Class.new do
        include(BaseExpr)

        attr_reader(*fields)

        define_method(:initialize) do |*args|
          if args.size != fields.size
            raise ArgumentError, "wrong number of arguments (given #{args.size}, expected #{fields.size})"
          end

          fields.zip(args).each do |field, arg|
            instance_variable_set("@#{field}", arg)
          end
        end

        define_method(:accept) do |visitor|
          visitor_method = "visit_#{klass_name.to_s.downcase}_expr"
          visitor.send(visitor_method, self)
        end
      end

      const_set("#{klass_name}Expr", klass)
    end
  end
end
