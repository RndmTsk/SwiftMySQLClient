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
            var resultSet = try connection.query("SELECT @@version_comment")
            print("[SELECT @@version_comment] \(resultSet)")
            resultSet = try connection.query("SELECT * FROM snack")
            print("[SELECT * FROM snack] \(resultSet)")
            resultSet = try connection.query("INSERT INTO snack (name, description, price) VALUES ('Smarties', 'Canadas version of M&Ms', 100)")
            print("[INSERT] \(resultSet)")
            resultSet = try connection.query("UPDATE snack SET price = 50 where id = 1")
            print("[UPDATE] \(resultSet)")
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

    func testPreparedStatement() {
        let credentials = URLCredential(user: "snack", password: "snack", persistence: .none)
        let configuration = MySQL.ClientConfiguration(host: "localhost", database: "snacktracker", credentials: credentials)
        let connection = MySQL.Connection(configuration: configuration)
        do {
            try connection.open()
            print("{INTEGRATION TEST} connection opened")
            var preparedStatement = try connection.prepareStatement(with: "SELECT * FROM snack where id = ?")
            print("[STMT PREPARE] \(preparedStatement)")
            let resultSet = try preparedStatement.execute(with: [1])
            print("[STMT EXECUTE] \(resultSet)")
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
