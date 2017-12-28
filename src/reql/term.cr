require "./executor/*"
require "./error"

module ReQL
  abstract class Term
    alias Type = Array(Type) | Bool | Float64 | Hash(String, Type) | Int64 | Int32 | String | Term | Nil

    getter args

    def initialize(@args : Array(Type), options : Hash(String, JSON::Type)?)
      compile
    end

    def compile
    end

    def self.parse(json : JSON::Type)
      if json.is_a? Hash
        hash = Hash(String, Type).new
        json.each do |(k, v)|
          hash[k] = Term.parse(v)
        end
        return hash.as(Type)
      elsif json.is_a? Array
        type_id = TermType.new(json[0].as(Int).to_i)
        args = json[1] ? json[1].as(Array).map { |e| Term.parse(e) } : [] of Type
        if type_id == TermType::MAKE_ARRAY
          args.as(Type)
        elsif klass = @@types[type_id]?
          klass.new(args, json[2]?.as(Hash(String, JSON::Type) | Nil)).as(Type)
        else
          raise CompileError.new("Don't know how to handle #{type_id} term")
        end
      else
        return json.as(Type)
      end
    end

    macro expect_args(count)
      if @args.size != {{count}}
        raise CompileError.new("Expected #{ {{count}}} arguments but found #{@args.size}")
      end
    end

    macro expect_args(min, max)
      if @args.size < {{min}} || @args.size > {{max}}
        raise CompileError.new("Expected between #{ {{min}}} and #{ {{max}}} arguments but found #{@args.size}")
      end
    end

    macro infix_inspect(name)
      def inspect(io)
        if @args.size == 0
          io << "r." << {{name}} << "()"
          return
        end

        if @args[0].is_a?(Term)
          @args[0].inspect(io)
        else
          io << "r("
          @args[0].inspect(io)
          io << ")"
        end

        io << "." << {{name}} << "("
        1.upto(@args.size - 1) do |i|
          @args[i].inspect(io)
          io << ", " unless i == @args.size - 1
        end
        io << ")"
      end
    end

    macro prefix_inspect(name)
      def inspect(io)
        io << "r." << {{name}} << "("
        @args.each_with_index do |e, i|
          e.inspect(io)
          io << ", " unless i == @args.size - 1
        end
        io << ")"
      end
    end

    @@types = {} of TermType => Term.class

    def self.add_type(k, v)
      @@types[k] = v
    end

    macro register_type(const)
      Term.add_type(TermType::{{const.id}}, self)
    end
  end

  class Evaluator
    property vars = {} of Int64 => Datum

    def eval(arr : Array)
      DatumArray.new(arr.map do |e|
        e = eval e
        expect_type e, Datum
        e.value.as(Datum::Type)
      end)
    end

    def eval(hsh : Hash)
      result = {} of String => Datum::Type
      hsh.each do |(k, v)|
        v = eval v
        expect_type v, Datum
        result[k] = v.value
      end
      DatumObject.new(result)
    end

    def eval(primitive : Bool)
      Datum.new(primitive)
    end

    def eval(str : String)
      DatumString.new(str)
    end

    def eval(num : Float64 | Int64 | Int32)
      DatumNumber.new(num)
    end

    def eval(x : Nil)
      DatumNull.new
    end

    macro expect_type(val, type)
      unless {{val}}.is_a? {{type.id}}
        raise QueryLogicError.new("Expected type #{{{type}}.reql_name} but found #{{{val}}.class.reql_name}")
      end
    end
  end

  enum TermType
    DATUM              =   1
    MAKE_ARRAY         =   2
    MAKE_OBJ           =   3
    VAR                =  10
    JAVASCRIPT         =  11
    UUID               = 169
    HTTP               = 153
    ERROR              =  12
    IMPLICIT_VAR       =  13
    DB                 =  14
    TABLE              =  15
    GET                =  16
    GET_ALL            =  78
    EQ                 =  17
    NE                 =  18
    LT                 =  19
    LE                 =  20
    GT                 =  21
    GE                 =  22
    NOT                =  23
    ADD                =  24
    SUB                =  25
    MUL                =  26
    DIV                =  27
    MOD                =  28
    FLOOR              = 183
    CEIL               = 184
    ROUND              = 185
    APPEND             =  29
    PREPEND            =  80
    DIFFERENCE         =  95
    SET_INSERT         =  88
    SET_INTERSECTION   =  89
    SET_UNION          =  90
    SET_DIFFERENCE     =  91
    SLICE              =  30
    SKIP               =  70
    LIMIT              =  71
    OFFSETS_OF         =  87
    CONTAINS           =  93
    GET_FIELD          =  31
    KEYS               =  94
    VALUES             = 186
    OBJECT             = 143
    HAS_FIELDS         =  32
    WITH_FIELDS        =  96
    PLUCK              =  33
    WITHOUT            =  34
    MERGE              =  35
    BETWEEN_DEPRECATED =  36
    BETWEEN            = 182
    REDUCE             =  37
    MAP                =  38
    FOLD               = 187
    FILTER             =  39
    CONCAT_MAP         =  40
    ORDER_BY           =  41
    DISTINCT           =  42
    COUNT              =  43
    IS_EMPTY           =  86
    UNION              =  44
    NTH                =  45
    BRACKET            = 170
    INNER_JOIN         =  48
    OUTER_JOIN         =  49
    EQ_JOIN            =  50
    ZIP                =  72
    RANGE              = 173
    INSERT_AT          =  82
    DELETE_AT          =  83
    CHANGE_AT          =  84
    SPLICE_AT          =  85
    COERCE_TO          =  51
    TYPE_OF            =  52
    UPDATE             =  53
    DELETE             =  54
    REPLACE            =  55
    INSERT             =  56
    DB_CREATE          =  57
    DB_DROP            =  58
    DB_LIST            =  59
    TABLE_CREATE       =  60
    TABLE_DROP         =  61
    TABLE_LIST         =  62
    CONFIG             = 174
    STATUS             = 175
    WAIT               = 177
    RECONFIGURE        = 176
    REBALANCE          = 179
    SYNC               = 138
    GRANT              = 188
    INDEX_CREATE       =  75
    INDEX_DROP         =  76
    INDEX_LIST         =  77
    INDEX_STATUS       = 139
    INDEX_WAIT         = 140
    INDEX_RENAME       = 156
    SET_WRITE_HOOK     = 189
    GET_WRITE_HOOK     = 190
    FUNCALL            =  64
    BRANCH             =  65
    OR                 =  66
    AND                =  67
    FOR_EACH           =  68
    FUNC               =  69
    ASC                =  73
    DESC               =  74
    INFO               =  79
    MATCH              =  97
    UPCASE             = 141
    DOWNCASE           = 142
    SAMPLE             =  81
    DEFAULT            =  92
    JSON               =  98
    TO_JSON_STRING     = 172
    ISO8601            =  99
    TO_ISO8601         = 100
    EPOCH_TIME         = 101
    TO_EPOCH_TIME      = 102
    NOW                = 103
    IN_TIMEZONE        = 104
    DURING             = 105
    DATE               = 106
    TIME_OF_DAY        = 126
    TIMEZONE           = 127
    YEAR               = 128
    MONTH              = 129
    DAY                = 130
    DAY_OF_WEEK        = 131
    DAY_OF_YEAR        = 132
    HOURS              = 133
    MINUTES            = 134
    SECONDS            = 135
    TIME               = 136
    MONDAY             = 107
    TUESDAY            = 108
    WEDNESDAY          = 109
    THURSDAY           = 110
    FRIDAY             = 111
    SATURDAY           = 112
    SUNDAY             = 113
    JANUARY            = 114
    FEBRUARY           = 115
    MARCH              = 116
    APRIL              = 117
    MAY                = 118
    JUNE               = 119
    JULY               = 120
    AUGUST             = 121
    SEPTEMBER          = 122
    OCTOBER            = 123
    NOVEMBER           = 124
    DECEMBER           = 125
    LITERAL            = 137
    GROUP              = 144
    SUM                = 145
    AVG                = 146
    MIN                = 147
    MAX                = 148
    SPLIT              = 149
    UNGROUP            = 150
    RANDOM             = 151
    CHANGES            = 152
    ARGS               = 154
    BINARY             = 155
    GEOJSON            = 157
    TO_GEOJSON         = 158
    POINT              = 159
    LINE               = 160
    POLYGON            = 161
    DISTANCE           = 162
    INTERSECTS         = 163
    INCLUDES           = 164
    CIRCLE             = 165
    GET_INTERSECTING   = 166
    FILL               = 167
    GET_NEAREST        = 168
    POLYGON_SUB        = 171
    MINVAL             = 180
    MAXVAL             = 181
  end
end

require "./terms/*"
