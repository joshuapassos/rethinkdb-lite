require "./database_file"
require "./btree"

class Table
  @db : DatabaseFile

  def self.create(path : String)
    db = DatabaseFile.create(path)
    btree = nil
    db.write do |w|
      btree = BTree.create(w)

      header = w.get(0u32)
      header.as_header.value.table_btree_pos = btree.pos
    end

    new db, btree.not_nil!
  end

  def self.open(path : String)
    db = DatabaseFile.open(path)
    btree_pos = 0u32
    db.read do |r|
      btree_pos = r.get(0u32).as_header.value.table_btree_pos
    end

    new db, BTree.new(btree_pos)
  end

  def initialize(@db : DatabaseFile, @btree : BTree)
  end

  def insert(obj)
    k = BTree.make_key obj["id"]
    @db.write do |w|
      data = Data.create(w, obj)
      @btree.insert(w, k, data.pos)
    end
  end

  def get(key)
    k = BTree.make_key key
    row = nil
    @db.read do |r|
      pos = @btree.query(r, k)
      if pos != 0u32
        row = Data.new(r.get(pos)).read(r)
      end
    end
    row
  end
end
