import XCTest
import SSHKit

final class SSHKitTests: XCTestCase {
    func testExample() throws {
        let session = SSHSession(options: .init(
            host: "138.197.14.72",
            port: 22
        ))
        try session.connect()
        defer { session.disconnect() }
        try session.verifyKnownHost()
        try session.auth()
        
        let channel = try session.channel()
        defer { channel.close() }
        try channel.open()
        print("$ ps aux")
        try channel.requestExec("ps aux")
        let res = channel.read()
        print(res)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
