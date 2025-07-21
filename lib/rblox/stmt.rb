# frozen_string_literal: true

module Rblox
  module Stmt
    BaseStmt = Module.new

    variants = {
      Block: %i[statements],
      Class: %i[name superclass methods],
      Expression: %i[expression],
      Function: %i[name params body],
      If: %i[condition then_branch else_branch],
      Print: %i[expression],
      Println: %i[expression],
      Return: %i[keyword value],
      Var: %i[name initializer],
      While: %i[condition body]
    }

    variants.each do |klass_name, fields|
      klass = Class.new do
        include(BaseStmt)

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
          visitor_method = "visit_#{klass_name.to_s.downcase}_stmt"
          visitor.send(visitor_method, self)
        end
      end

      const_set("#{klass_name}Stmt", klass)
    end
  end
end
