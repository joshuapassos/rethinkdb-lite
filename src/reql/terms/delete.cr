require "uuid"

module ReQL
  class DeleteTerm < Term
    register_type DELETE
    infix_inspect "delete"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : DeleteTerm)
      source = eval(term.args[0])

      writter = TableWriter.new

      source.each do |obj|
        row = obj.as_row
        writter.delete(row.table, row.key)
      end

      writter.summary
    end
  end
end
