require "../../duktape"

module ReQL
  class JsTerm < Term
    register_type JAVASCRIPT
    prefix_inspect "js"

    def compile
      expect_args 1
    end
  end

  class Evaluator
    def eval(term : JsTerm)
      code = eval(term.args[0]).string_value

      ctx = Duktape::Context.new

      flags = LibDuktape::COMPILE_EVAL | LibDuktape::COMPILE_NOSOURCE | LibDuktape::COMPILE_NOFILENAME | LibDuktape::COMPILE_SAFE
      if LibDuktape.eval_raw(ctx, code, code.bytesize, flags) != 0
        raise QueryLogicError.new String.new(LibDuktape.safe_to_lstring(ctx, -1, nil))
      end

      return ctx.get_datum
    end
  end
end
