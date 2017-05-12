# SwiftMySQLClient

A Swift MySQL Socket Client

## Version Support

MySQL 8.0 is currently the only tested version, in theory it could work with earlier versions that support `Client Protocol 41`.

## Planned Features

* Prepared Statement support (currently prepared statements can be created and executed, but no results are returned).
* Result Set column data type auto-mapping
* Connection pooling
* Re-configuration support
* Re-issueable Result Sets

## Documentation

The SwiftMySQLClient module provides a `Connection` class that is used to issue queries, statements and other various commands to a connected *MySQL* server.

#### ClientConfiguration

Before creating a connection a configuration needs to be created. At minimum, a connection requires a `host`.

* If no `credentials` are provided, the server will assume the username is `root` with no password is attempting to connect. To specify a `username` and `password`, construct a `URLCredential`.
* If no `port` is specified, the default `port` `3306` is assumed.
* Optionally a `database` can be specified to be used in the initial connection, otherwise a `use database` statement can be sent at a later time.

```
// A complete configuration constructor
let configuration = MySQL.ClientConfiguration(host: "localhost", port: 3306, database: "swift_sample" credentials: credentials)
```

### Connection

Creating a connection requires a `ClientConfiguration` (see above). The connection is not automatically opened (see below).

```
// Given the configuration from above:
let connection = MySQL.Connection(configuration: configuration)
```

#### Opening & Closing

Opening and closing a connection requires use of the `try` mechanism in Swift as they have the potential encounter socket or authorization errors.

```
// Given the connection above:

// 1. Open a connection
do {
	try connection.open()
} catch {
	// Handle error
}

// 2. Close a connection
do {
	try connection.close()
} catch {
	// Handle error
}
```

#### Queries

To issue a simple query, use any of the `query`, `insert`, `update` or `delete` convenience functions. Each of these returns a `Result<ResultSet>` - see Result Sets below for more details.

```
let result = connection.query("SELECT * FROM birds WHERE name = 'Swift'")
```

### Statements

`Statement`s are similar to `PreparedStatement`s in that you can use the `?` operator to represent placeholder values, however, they do not register themselves with the server. All placeholder interpolation is done in Swift which allows them to be more flexible.

When `executing` a statement, a `Result<ResultSet>` is returned - see Result Sets below for more details.

NOTE: `Statements` must currently be created as mutable objects as they keep track of the last parameters they used.

```
// Using the connection from above:
var statement = connection.createStatement(with: "SELECT * FROM ? WHERE name = '?'")
let result = statement.execute(with: ["birds", "Swift"])
```

### Prepared Statements

WARNING: Prepared Statements are a WIP feature

`PreparedStatement`s are a special construct that registers the query with the server to allow easy re-issuing of the contained query in addition to optimizations of the query itself.

Creating a `PreparedStatement` issues a registration request with the *MySQL* server, if successful a statement id is assigned to the contained query. Re-issuing the query is much like the `Statement` above, except that the data sent to the server is optimized - because the server knows about the query already.

When `executing` a prepared statement, a `Result<ResultSet>` is returned - see Result Sets below for more details.

NOTE: Unlike `Statement`s, `PreparedStatement`s have restrictions on which fields can be represented with placeholder characters.

NOTE: `PreparedStatement`s must currently be created as mutable objects as they keep track of the last parameters they used and need to be modified with the statement id returned from the *MySQL* server.

```
// Using the connection from above:
let prepareResult = connection.prepareStatement(with: "SELECT * FROM birds WHERE name = '?'")
// Creating a prepared statement can fail
guard var preparedStatement = prepareResult.value else {
	// Encountered an error, check prepareResult.error
	return
}

let result = preparedStatement.execute(with: ["Swift"])
```

### Result Sets
### Tests