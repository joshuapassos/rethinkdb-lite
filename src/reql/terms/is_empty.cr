module ReQL
  class IsEmptyTerm < Term
    register_type IS_EMPTY
    infix_inspect "is_empty"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : IsEmptyTerm)
      target = eval(term.args[0])

      if target.is_a? Stream
        target.start_reading
        begin
          return Datum.new(target.next_val.nil?)
        ensure
          target.finish_reading
        end
      end

      datum = target.as_datum

      if str = target.string_value?
        return Datum.new(str.empty?)
      end

      if hsh = target.hash_value?
        return Datum.new(hsh.empty?)
      end

      if bytes = target.bytes_value?
        return Datum.new(bytes.empty?)
      end

      return Datum.new(target.array_value.empty?)
    end
  end
end
