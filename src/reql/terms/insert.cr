require "uuid"

module ReQL
  class InsertTerm < Term
    register_type INSERT
    infix_inspect "insert"
  end

  class Evaluator
    def eval(term : InsertTerm)
      table = eval term.args[0]
      expect_type table, Table
      table.check

      datum = eval term.args[1]
      expect_type datum, Datum

      result = Hash(String, Datum::Type).new
      result["deleted"] = 0i64
      result["replaced"] = 0i64
      result["skipped"] = 0i64
      result["unchanged"] = 0i64

      obj = datum.value.as(Hash)
      unless obj.has_key? "id"
        id = UUID.random.to_s
        obj["id"] = id
        result["generated_keys"] = Array(Datum::Type){id}
      end
      begin
        table.insert(obj)
      rescue err : RuntimeError
        result["inserted"] = 0i64
        result["errors"] = 1i64
        result["first_error"] = err.message
      else
        result["inserted"] = 1i64
        result["errors"] = 0i64
      end

      Datum.wrap(result)
    end
  end
end
