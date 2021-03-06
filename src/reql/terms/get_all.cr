module ReQL
  class GetAllTerm < Term
    register_type GET_ALL
    infix_inspect "get_all"

    def compile
      expect_args_at_least 2
      expect_maybe_options "index"
    end
  end

  class Evaluator
    def eval(term : GetAllTerm)
      table = eval(term.args[0]).as_table
      keys = eval(term.args[1..-1]).array_value

      storage = table.storage

      index = term.options["index"]?.try { |x| Datum.new(x).string_value } || storage.primary_key

      GetAllStream.new(storage, keys, index)
    end
  end
end
