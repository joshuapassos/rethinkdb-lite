# UNRELEASED (0.2.0)

- Implement r.db("rethinkdb").table("db_config").insert({name: "aa"}) to create databases.
- Replace storage engine with RocksDB, improving write performance by a factor of 10x.
- Use `sock.sync = false` for socket IO, improving simple query performance by a factor of 15x.
- Fixes and improvements on sending query responses.
- Upgrade from Crystal 0.24.1 to Crystal 0.32.1.
- Remove Datum::Type recursive type to improve code quality and avoid compiler bugs. Term::Type still needs to be removed.

# 0.1.0 - 2018-01-15

- First release.