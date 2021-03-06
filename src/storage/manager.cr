require "./table/*"
require "./kv"

module Storage
  class Manager
    property databases = {} of String => Database
    property kv : KeyValueStore
    property lock = Mutex.new

    class Database
      property info : KeyValueStore::DatabaseInfo
      property tables = Hash(String, Table).new

      def initialize(@info)
      end
    end

    class Table
      property info : KeyValueStore::TableInfo
      property db_name : String
      property indices = Hash(String, Index).new

      def initialize(@info, @db_name)
      end
    end

    class Index
      property info : KeyValueStore::IndexInfo

      def initialize(@info)
      end
    end

    def initialize(path : String)
      @kv = KeyValueStore.new(path)

      db_by_id = {} of UUID => Database
      @kv.each_db do |info|
        db = Database.new(info)
        @databases[info.name] = db
        db_by_id[info.id] = db
      end

      @kv.each_table do |info|
        db = db_by_id[info.db]
        table = db.tables[info.name] = Table.new(info, db.info.name)

        @kv.each_index(info.id) do |index_info|
          table.indices[index_info.name] = Index.new(index_info)
        end
      end

      unless @databases.has_key?("test")
        id = ReQL::Datum.new(UUID.random.to_s)
        get_table("rethinkdb", "db_config").not_nil!.replace(id) do
          {"id" => id, "name" => ReQL::Datum.new("test")}
        end
      end
    end

    def get_table(db_name, table_name) : AbstractTable?
      if db_name == "rethinkdb"
        case table_name
        when "server_config"
          return VirtualServerConfigTable.new(self)
        when "db_config"
          return VirtualDbConfigTable.new(self)
        when "table_config"
          return VirtualTableConfigTable.new(self)
        when "table_status"
          return VirtualTableStatusTable.new(self)
        else
          return nil
        end
      end

      table = @lock.synchronize { @databases[db_name]?.try &.tables[table_name]? }
      table.nil? ? nil : PhysicalTable.new(self, table)
    end

    def close
      @kv.close
    end

    def system_info
      @kv.system_info
    end
  end
end
