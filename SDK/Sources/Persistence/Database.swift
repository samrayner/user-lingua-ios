// Database.swift

import Combine
import Foundation
import GRDB
import os.log
import Utilities

struct Database: Initializable {
    private static let sqlLogger = OSLog(subsystem: "UserLingua", category: "SQL")

    static func makeConfiguration(_ base: Configuration = Configuration()) -> Configuration {
        var config = base
        config.publicStatementArguments = true

        if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
            config.prepareDatabase { db in
                db.trace {
                    // It's ok to log statements publicly. Sensitive
                    // information (statement arguments) are not logged
                    // unless config.publicStatementArguments is set.
                    os_log("%{public}@", log: sqlLogger, type: .debug, String(describing: $0))
                }
            }
        }

        return config
    }

    private let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true

        migrator.registerMigration("initialTables") { db in
            try db.create(table: "strings") { t in
                t.column("value", .text).notNull()
                t.column("format", .text).notNull()
                t.column("arguments", .text).notNull()
                t.column("recognizableValue", .text).notNull()
                t.column("recordedAt", .datetime).notNull()
            }

            try db.create(table: "formats") { t in
                t.column("format", .text).notNull()
                t.column("arguments", .text).notNull()
                t.column("recognizableValue", .text).notNull()
                t.column("recordedAt", .datetime).notNull()
            }
        }

        return migrator
    }()

    let writer: any DatabaseWriter
    var reader: DatabaseReader { writer }

    private init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }

    public init() {
        let queue = try! DatabaseQueue(configuration: Self.makeConfiguration())
        try! self.init(queue)
    }
}
