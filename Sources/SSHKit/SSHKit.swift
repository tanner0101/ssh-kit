import CSSHKit

/*
 ssh_options_set(my_ssh_session, SSH_OPTIONS_HOST, "localhost");
 ssh_options_set(my_ssh_session, SSH_OPTIONS_LOG_VERBOSITY, &verbosity);
 ssh_options_set(my_ssh_session, SSH_OPTIONS_PORT, &port);
 */
public struct SSHOptions {
    public let host: String?
    public var verbosity: Int32?
    public var port: Int?
    
    public init(host: String? = nil, verbosity: Int? = nil, port: Int? = nil) {
        self.host = host
        self.verbosity = SSH_LOG_NONE
        self.port = port
    }
}

public final class SSHSession {
    let session: ssh_session
    
    public init(options: SSHOptions = .init()) {
        guard let handle = ssh_new() else {
            fatalError("could not create SSH session")
        }
        if var host = options.host {
            ssh_options_set(handle, SSH_OPTIONS_HOST, &host)
        }
        if var verbosity = options.verbosity {
            ssh_options_set(handle, SSH_OPTIONS_LOG_VERBOSITY, &verbosity)
        }
        if var port = options.port {
            ssh_options_set(handle, SSH_OPTIONS_PORT, &port)
        }
        self.session = handle
    }
    
    public func connect() throws {
        guard ssh_connect(self.session) == SSH_OK else {
            throw SSHError(message: "could not connect: \(self.errorString)")
        }
    }
    
    public func verifyKnownHost() throws {
        var serverKey: ssh_key?
        guard ssh_get_server_publickey(self.session, &serverKey) == SSH_OK else {
            throw SSHError(message: "could not get server public key: \(self.errorString)")
        }
        #warning("TODO: get hash")
        let state = ssh_session_is_known_server(self.session)
        switch state {
        case SSH_KNOWN_HOSTS_OK: break
        default:
            throw SSHError(message: "unexpected known hosts state: \(state)")
        }
    }
    
    public func auth() throws {
        let username = "root"
        guard ssh_userauth_publickey_auto(
            self.session,
            username,
            nil
        ) == SSH_AUTH_SUCCESS.rawValue else {
            throw SSHError(message: "auth failed: \(self.errorString)")
        }
    }
    
    public final class Channel {
        let channel: ssh_channel
        
        public init(session: SSHSession) throws {
            guard let channel = ssh_channel_new(session.session) else {
                throw SSHError(message: "could not create channel")
            }
            self.channel = channel
        }
        
        public func open() throws {
            guard ssh_channel_open_session(self.channel) == SSH_OK else {
                throw SSHError(message: "could not open channel session")
            }
        }
        
        public func requestExec(_ cmd: String) throws {
            guard ssh_channel_request_exec(self.channel, cmd) == SSH_OK else {
                throw SSHError(message: "could not request exec")
            }
        }
        
        public func read() -> String {
            var result = Data()
            var buffer = Data(count: 1024)
            read: while true {
                let num = ssh_channel_read(self.channel, buffer.withUnsafeMutableBytes { $0 }, 1024, 0)
                if num <= 0 {
                    break read
                }
                result += Data(buffer[0..<num])
            }
            return String(data: result, encoding: .utf8) ?? "fail"
        }
        
        public func close() {
            ssh_channel_send_eof(self.channel)
            ssh_channel_close(self.channel)
        }
        
        deinit {
            ssh_channel_free(self.channel)
        }
    }
    
    public func channel() throws -> Channel {
        return try Channel(session: self)
    }
    
    public func disconnect() {
        ssh_disconnect(self.session)
    }
    
    var errorString: String {
        guard let error = ssh_get_error(UnsafeMutableRawPointer(self.session)) else {
            return "n/a"
        }
        return String(cString: error)
    }
    
    deinit {
        ssh_free(self.session)
    }
}

struct SSHError: Error {
    var message: String
}

import Foundation

extension SSHError: LocalizedError {
    var errorDescription: String? {
        return self.message
    }
}
