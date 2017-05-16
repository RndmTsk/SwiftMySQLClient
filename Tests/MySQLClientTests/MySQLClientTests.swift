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
            tryQuery("SELECT @@version_comment", with: connection)
            tryQuery("SELECT * FROM snack", with: connection)
            tryQuery("INSERT INTO snack (name, description, price) VALUES ('Smarties', 'Canadas version of M&Ms', 100)", with: connection)
            tryQuery("UPDATE snack SET price = 100 where id = 1", with: connection)
            print("{INTEGRATION TEST} query completed")
            try connection.close()
            print("{INTEGRATION TEST} connection closed")
        } catch {
            XCTFail("Encountered error: \(error)")
            do {
                try connection.close()
            } catch {
                XCTFail("Encountered error: \(error)")
            }
            return
        }
    }

    func tryQuery(_ statement: String, with connection: MySQL.Connection) {
        switch connection.query(statement) {
        case .success(let resultSet):
            print("[\(statement)] Success: \(resultSet)")
        case .failure(let error):
            print("[\(statement)] Error: \(error)")
        }
    }

    func testStatement() {
        let credentials = URLCredential(user: "snack", password: "snack", persistence: .none)
        let configuration = MySQL.ClientConfiguration(host: "localhost", database: "snacktracker", credentials: credentials)
        let connection = MySQL.Connection(configuration: configuration)
        do {
            try connection.open()
            print("{INTEGRATION TEST} connection opened")
            var statement = connection.createStatement(with: "SELECT * from snack where id = ?")
            tryStatement(statement, with: [1])
            tryStatement(statement, with: [100])

            statement = connection.createStatement(with: "SELECT * FROM snack where price > ?")
            tryStatement(statement, with: [50])
            tryStatement(statement, with: [1000])
            
            print("{INTEGRATION TEST} query completed")
            try connection.close()
            print("{INTEGRATION TEST} connection closed")
        } catch {
            XCTFail("Encountered error: \(error)")
            do {
                try connection.close()
            } catch {
                XCTFail("Encountered error: \(error)")
            }
            return
        }
    }

    func tryStatement(_ statement: MySQL.Statement, with values: [Any]? = nil) {
        var statement = statement
        switch statement.execute(with: values) {
        case .success(let resultSet):
            print("[\(statement.description)] Success: \(resultSet)")
            for row in resultSet.data {
                print("Row: \(row)")
            }
            guard resultSet.data.count > 0 else {
                return
            }
            let firstRow = resultSet[0]
            for (columnName, columnValue) in firstRow {
                print("\(columnName): \(columnValue)")
            }
            let nameColumn = resultSet["name"]
            for (rowNumber, rowValue) in nameColumn.enumerated() {
                print("Name in Row #\(rowNumber) = \(rowValue)")
            }
        case .failure(let error):
            print("[\(statement.description)] Error: \(error)")
        }
    }

    func testPreparedStatement() {
        let credentials = URLCredential(user: "snack", password: "snack", persistence: .none)
        let configuration = MySQL.ClientConfiguration(host: "localhost", database: "snacktracker", credentials: credentials)
        let connection = MySQL.Connection(configuration: configuration)
        do {
            try connection.open()
            print("{INTEGRATION TEST} connection opened")
            switch connection.prepareStatement(with: "SELECT * FROM snack where id = ?") {
            case .success(var preparedStatement):
                print("[STMT PREPARE] Success: \(preparedStatement)")
                let result = preparedStatement.execute(with: [1])
                if let resultSet = result.value {
                    print("[STMT EXECUTE] Success: \(resultSet)")
                } else if let error = result.error {
                    print("[STMT EXECUTE] Error: \(error)")
                } else {
                    print("[STMT EXECUTE] Unknown error!")
                }
            case .failure(let error):
                print("[STMT PREPARE] Error: \(error)")
            }
            print("{INTEGRATION TEST} query completed")
            try connection.close()
            print("{INTEGRATION TEST} connection closed")
        } catch {
            XCTFail("Encountered error: \(error)")
            do {
                try connection.close()
            } catch {
                XCTFail("Encountered error: \(error)")
            }
            return
        }
    }


    static var allTests : [(String, (MySQLClientTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
        ]
    }
}
