import XCTest
@testable import SwiftMySQLClient

class MySQLClientTests: XCTestCase {
    func testConnect() {
        let credentials = URLCredential(user: "snack", password: "snack", persistence: .none)
        let configuration = MySQL.ClientConfiguration(host: "localhost", database: "snacktracker", credentials: credentials)
        let connection = MySQL.Connection(configuration: configuration)
        do {
            try connection.open()
            print("{INTEGRATION TEST} connection opened")
            var resultSet = try connection.issue(.query, with: "SELECT @@version_comment")
            print("[SELECT @@version_comment] \(resultSet)")
            resultSet = try connection.issue(.query, with: "SELECT * FROM snack")
            print("[SELECT * FROM snack] \(resultSet)")
            resultSet = try connection.issue(.ping)
            print("[PING] \(resultSet)")
            resultSet = try connection.issue(.query, with: "INSERT INTO snack (name, description, price) VALUES ('Smarties', 'Canadas version of M&Ms', 100)")
            print("[INSERT] \(resultSet)")
            resultSet = try connection.issue(.query, with: "UPDATE snack SET price = 50 where id = 1")
            print("[UPDATE] \(resultSet)")
            print("{INTEGRATION TEST} query completed")
            try connection.close()
            print("{INTEGRATION TEST} connection closed")
        } catch {
            XCTFail("Encountered error: \(error)")
            return
        }
    }

    func testPreparedStatement() {
        let credentials = URLCredential(user: "snack", password: "snack", persistence: .none)
        let configuration = MySQL.ClientConfiguration(host: "localhost", database: "snacktracker", credentials: credentials)
        let connection = MySQL.Connection(configuration: configuration)
        do {
            try connection.open()
            print("{INTEGRATION TEST} connection opened")
            let preparedStatement = try connection.prepareStatement(with: "SELECT * FROM snack where id = ?")
            print("[PREPARE] \(preparedStatement)")
            let resultSet = preparedStatement.execute(with: [1])
            print("{INTEGRATION TEST} query completed")
            try connection.close()
            print("{INTEGRATION TEST} connection closed")
        } catch {
            XCTFail("Encountered error: \(error)")
            return
        }
    }


    static var allTests : [(String, (MySQLClientTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
        ]
    }
}

/*
//
/// A class that wraps the MySQLDriver library in case we need to change it later.
internal final class MySQLConnector {
    /// The underlying socket connection to the database.
    internal func connect() throws {
        try connection.open()
        Log.info("{MySQL} connection opened")
    }
    
    /**
     Attempts to disconnect from the MySQL database.
     */
    internal func disconnect() throws {
        try connection.close()
        Log.info("{MySQL} connection closed")
    }
    
    // MARK: - CRUD
    
    /**
     Issues a `SELECT` statement on the given table with the specified constraints, if any.
     
     - parameter table: The table on which to issue the `SELECT`.
     - parameter constraints: A list of key/value pairs with which to constrain the query.
     - returns: A `Result` where `success` includes a list of key/value pairs representing rows, `failure` includes an `Error`.
     */
    internal func select(from table: String, with constraints: [String : Any]) -> SnackTrackerCommon.Result<[[String : Any]]> {
        //do {
        // Prepare the SELECT statement in the correct format.
        var statement = "SELECT * FROM \(table)" // TODO: (TL) Columns
        
        // Attempt to see if there's LIMIT/OFFSET and other constraints.
        var limitClause = ""
        var constraintClause = ""
        for (key, value) in constraints {
            if key == Datastore.Constants.limit || key == Datastore.Constants.offset {
                limitClause.append(" \(key) \(value)")
            } else if constraintClause.isEmpty {
                // First one doesn't need a comma.
                constraintClause = "\(key) = ?"
            } else {
                // All others do (is it cheaper to substring?).
                constraintClause = ", \(key) = ?"
            }
        }
        // If we found at least one constraint, add it with the WHERE keyword.
        if !constraintClause.isEmpty {
            statement.append(" WHERE \(constraintClause)")
        }
        // TODO: (TL) statement.append(groupClause)
        // TODO: (TL) statement.append(orderClause)
        statement.append(limitClause)
        
        // Since callers can include LIMIT/OFFSET we need to remove these.
        let ammendedConstraints = constraints.filter { element in
            element.key != Datastore.Constants.limit && element.key != Datastore.Constants.offset
        }
        return .failure(NSError(domain: "io.tulip.snacktracker.unimplemented", code: 0, description: "This feature is not implemented"))
        /*
         // Send the statement to the DB with the values of the constraint dictionary
         let resultSet = try issue(statement, with: ammendedConstraints.map({ $0.1 }))
         
         // If we can't read the resultSet, it likely means no rows matched the query, return `success` and an empty list.
         guard let rows = try resultSet?.readAllRows() else {
         return .success([])
         }
         // If we can read the resultSet, return the results.
         return .success(rows)
         } catch {
         // If an error was encountered along the way, return `failure`.
         return .failure(error)
         }
         */
    }
    
    /**
     Issues an `INSERT` statement on the given table with the specified values.
     
     - parameter table: The table in which to INSERT the values.
     - parameter values: A list of key/value pairs representing the column names and new values to INSERT into the database.
     - returns: A `Result` where `success` represents the number of rows affected by the query, `failure` includes an `Error`.
     */
    public func insert(into table: String, _ values: [String : Any]) -> SnackTrackerCommon.Result<UInt64> {
        // TODO: (TL) Allow multiple inserts
        guard !values.isEmpty else {
            return .failure(Errors.emptyInsert)
        }
        
        // Prepare the keys and values separately but equally.
        var keysClause = ""
        var valuesClause = ""
        for (key, _) in values {
            keysClause.append("\(key),")
            valuesClause.append("?,")
        }
        // TODO: (TL) Utility function to remove the last character in a String
        // Resulting string resembles key1,key2,key3, -> remove the trailing comma.
        keysClause = keysClause.substring(to: keysClause.index(before: keysClause.endIndex))
        // Resulting string resembles ?,?,?, -> remove the trailing comma.
        valuesClause = valuesClause.substring(to: valuesClause.index(before: valuesClause.endIndex))
        
        // Prepare the INSERT statement in the correct format.
        let statement = "INSERT INTO \(table) (\(keysClause)) values (\(valuesClause))"
        return .failure(NSError(domain: "io.tulip.snacktracker.unimplemented", code: 0, description: "This feature is not implemented"))
        /*
         do {
         // Send the statement to the DB with the values of the constraint dictionary.
         if let result = try issue(statement, with: values.map({ $0.1 })) {
         // If we have affected rows, assume success for now as upper layers will validate the number.
         return .success(result.affectedRows)
         }
         // An unknown error occurred, return a general error.
         return .failure(Errors.insertFailed)
         } catch {
         // If an error was encountered along the way, return `failure`.
         return .failure(error)
         }
         */
    }
    
    /**
     Issues an `UPDATE` statement on the given table with the specified values.
     
     - parameter table: The table in which to UPDATE the values.
     - parameter values: A list of key/value pairs representing the column names and new values to UPDATE the existing record.
     - returns: A `Result` where `success` represents the number of rows affected by the query, `failure` includes an `Error`.
     */
    public func update(_ table: String, _ values: [String : Any]) -> SnackTrackerCommon.Result<UInt64> {
        // TODO: (TL) Allow multiple updates?
        guard !values.isEmpty else {
            return .failure(Errors.emptyUpdate)
        }
        return .failure(NSError(domain: "io.tulip.snacktracker.unimplemented", code: 0, description: "This feature is not implemented"))
        /*
         // Prepare the key/value pairs and value array
         let (fieldClause, constraints) = extractConstraints(from: values)
         
         // TODO: (TL) INCOMPLETE - Allow for proper primary keys
         let statement = "UPDATE \(table) SET \(fieldClause) WHERE id = ? LIMIT 1"
         do {
         // Send the statement to the DB with the values of the constraint dictionary.
         // TODO: (TL) + [1] == id field
         if let result = try issue(statement, with: constraints + [1]) {
         // If we have affected rows, assume success for now as upper layers will validate the number.
         return .success(result.affectedRows)
         }
         // An unknown error occurred, return a general error.
         return .failure(Errors.updateFailed)
         } catch {
         // If an error was encountered along the way, return `failure`.
         return .failure(error)
         }
         */
    }
    
    /**
     Issues a `DELETE` statement on the given table with the specified values.
     
     - parameter table: The table on which to perform the `DELETE`.
     - parameter values: A list of key/value pairs representing the column names and values to constrain the `DELETE`.
     - returns: A `Result` where `success` represents the number of rows affected by the query, `failure` includes an `Error`.
     */
    public func delete(_ table: String, _ values: [String : Any]) -> SnackTrackerCommon.Result<UInt64> {
        // TODO: (TL) Allow multiple deletes?
        guard !values.isEmpty else {
            return .failure(Errors.emptyDelete)
        }
        
        // Prepare the key/value pairs and value array
        // let (fieldClause, constraints) = extractConstraints(from: values)
        
        // let statement = "DELETE FROM \(table) WHERE \(fieldClause) LIMIT 1"
        return .failure(NSError(domain: "io.tulip.snacktracker.unimplemented", code: 0, description: "This feature is not implemented"))
        /*
         do {
         // Send the statement to the DB with the values of the constraint dictionary.
         if let result = try issue(statement, with: constraints) {
         // If we have affected rows, assume success for now as upper layers will validate the number.
         return .success(result.affectedRows)
         }
         // An unknown error occurred, return a general error.
         return .failure(Errors.deleteFailed)
         } catch {
         // If an error was encountered along the way, return `failure`.
         return .failure(error)
         }
         */
    }
    
    // MARK: - Private Functions
    /*
     /**
     This is a helper function that issues the actual query to the database. It takes a statement as a String and prepares it and issues it to the database returning the `Result`, if any.
     
     - parameter statement: The statement to prepare into a `MySQL.Statement`.
     - parameter values: The statement is prepared with placeholder ?, the values replace the placeholders.
     - returns: A MySQL.Result if available, `nil` otherwise.
     */
     private func issue(_ statement: String, with values: [Any]? = nil) throws -> MySQLDriver.Result? {
     let select: MySQL.Statement
     let result: MySQLDriver.Result
     if let values = values, !values.isEmpty {
     Log.debug("\(statement) | \(values)")
     select = try connection.prepare(statement)
     result = try select.query(values)
     } else {
     Log.debug(statement)
     select = try connection.prepare(statement)
     result = try select.query([])
     }
     return result
     }
     
     /**
     This is a helper function that unrolls a string formatted as `key1 = ?, key2 = ?` and an array of values from the supplied dictionary.
     
     - parameter values: A list of key/value pairs representing the column names and new values to augment the existing record.
     - returns: A tuple containing the field string and the list of values to populate the ? entries.
     */
     private func extractConstraints(from values: [String : Any]) -> (fieldClause: String, constraints: [Any]) {
     var fieldClause = ""
     for (key, _) in values {
     fieldClause.append("\(key) = ?,")
     }
     // Resulting string resembles key1 = ?, key2 = ?, -> remove the tailing comma.
     fieldClause = fieldClause.substring(to: fieldClause.index(before: fieldClause.endIndex))
     
     // Peel off only the values using `map`.
     return (fieldClause: fieldClause, constraints: values.map({ $0.1 }))
     }
     
     // TODO: (TL) TEMPORARY --v
     private func temporarySetup() throws {
     let truncate = try connection.prepare("TRUNCATE TABLE snack")
     try truncate.exec([])
     Log.info("{MySQL} Cleared")
     let insert = try connection.prepare("INSERT INTO snack(name, description, price) VALUES(?,?, ?)")
     try insert.exec(["Reese's Pieces", "Tasty Peanut-butter and chocolate", 100])
     Log.info("{MySQL} \"Reese's Pieces\" record inserted")
     try insert.exec(["Chips", "Tasty, fried, salty potatoes", 50])
     Log.info("{MySQL} \"Chips\" record inserted")
     }
     
     private func temporaryValidation() throws {
     let select = try connection.prepare("SELECT * FROM snack")
     let result = try select.query([])
     let rows = try result.readAllRows()
     Log.info("{MySQL} Validation: \(String(describing: rows!))")
     }
     // TODO: (TL) TEMPORARY --^
     */
}
*/
