require 'delegate'
require 'cucumber/multiline_argument/data_table'
require 'cucumber/multiline_argument/doc_string'
require 'gherkin/rubify'

module Cucumber
  module MultilineArgument
    extend Gherkin::Rubify

    class << self
      def from_core(node)
        builder.describe(node)
      end

      def from(argument, location)
        argument = rubify(argument)
        case argument
        when String
          builder.doc_string(Core::Ast::DocString.new(argument, 'text/plain', location))
        when ::Gherkin::Formatter::Model::DocString
          builder.doc_string(Core::Ast::DocString.new(argument.value, argument.content_type, location.on_line(argument.line_range)))
        when Array
          location = location.on_line(argument.first.line..argument.last.line)
          builder.data_table(Core::Ast::DataTable.new(argument.map{ |row| row.cells }, location))
        when DataTable, DocString, None
          argument
        when nil
          None.new
        else
          raise ArgumentError, "Don't know how to convert #{argument.inspect} into a MultilineArgument"
        end
      end

      protected
      def builder
        @builder ||= Builder.new
      end

      class Builder
        attr_reader :result

        def describe(node)
          @result = None.new
          node.describe_to(self)
          @result
        end

        def doc_string(node, *args)
          @result = DocString.new(node)
        end

        def data_table(node, *args)
          @result = DataTable.new(node)
        end
      end
    end

    class None
      def append_to(array)
      end

      def describe_to(visitor)
      end
    end
  end
end

require 'cucumber/ast'