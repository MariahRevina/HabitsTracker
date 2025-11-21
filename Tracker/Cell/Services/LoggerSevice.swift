import Logging

final class LoggerService {
    
    static let shared = LoggerService()
    
    private let logger: Logger
    
    private init() {
        self.logger = Logger(label: "com.MariahRevina.Tracker")
    }
    
    func error (_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        logger.error("\(message)", file: file, function: function, line: line)
    }
    func warning(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        logger.warning("\(message)", file: file, function: function, line: line)}
    func trace(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        logger.trace("\(message)", file: file, function: function, line: line)
    }
}
