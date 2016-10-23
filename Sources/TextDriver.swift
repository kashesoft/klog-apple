/*
 * Copyright (C) 2016 Andrey Kashaed
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

public class TextDriver : Driver, TransactionContext {
    
    fileprivate let fileEncoding: String.Encoding
    fileprivate let fileMaxSize: UInt64
    fileprivate let fileMarginSize: UInt64
    fileprivate let lineDelimiter: String
    fileprivate let chunkSize: Int
    
    public init(
        fileName: String,
        fileEncoding: String.Encoding = .utf8,
        fileMaxSize: UInt64 = 5*1024*1024,
        fileMarginSize: UInt64 = 100*1024,
        lineDelimiter: String = "\n",
        chunkSize: Int = 4096
    ) {
        self.fileEncoding = fileEncoding
        self.fileMaxSize = fileMaxSize
        self.fileMarginSize = fileMarginSize
        self.lineDelimiter = lineDelimiter
        self.chunkSize = chunkSize
        super.init(fileName: fileName)
    }
    
    override func fileMediaType() -> String {
        return "text/plain"
    }
    
    override func readTraces() -> [Trace] {
        var traces = [Trace]()
        onTransaction { (transaction) in
            while true {
                if let line = transaction.readLine() {
                    traces.append(Trace(fromString: line))
                } else {
                    break
                }
            }
        }
        return traces
    }
    
    override func read(afterTrace trace: Trace, count: Int) -> [Trace] {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        var traces = [Trace]()
        // TODO:
        return traces
    }
    
    override func read(beforeTrace trace: Trace, count: Int) -> [Trace] {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        var traces = [Trace]()
        // TODO:
        return traces
    }
    
    override func write(trace: Trace) {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        onTransaction { (transaction) in
            transaction.writeLine(trace.toString())
        }
    }
    
    override func clear() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        onTransaction { (transaction) in
            transaction.clearLines()
        }
    }
    
    override func remove() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        try? FileManager.default.removeItem(atPath: filePath())
    }
    
    private func onTransaction(_ onTransaction: (_ transaction: Transaction) -> Void) {
        let transaction = Transaction(context: self)
        transaction.begin()
        onTransaction(transaction)
        transaction.end()
    }
    
}

fileprivate protocol TransactionContext: class {
    func filePath() -> String
    var fileEncoding: String.Encoding { get }
    var chunkSize: Int { get }
    var lineDelimiter: String { get }
    var fileMaxSize: UInt64 { get }
    var fileMarginSize: UInt64 { get }
}

fileprivate class Transaction {
    
    private unowned let context: TransactionContext
    private var buffer: Data
    private var atEof: Bool
    private var fileHandle: FileHandle!
    
    init(context: TransactionContext) {
        self.context = context
        self.buffer = Data(capacity: context.chunkSize)
        self.atEof = false
    }
    
    func begin() {
        let filePath = context.filePath()
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        fileHandle = FileHandle(forUpdatingAtPath: filePath)
    }
    
    func end() {
        fileHandle.synchronizeFile()
        fileHandle.closeFile()
        fileHandle = nil
    }
    
    func readLine() -> String? {
        guard let delimData = context.lineDelimiter.data(using: context.fileEncoding) else {
            return nil
        }
        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: context.fileEncoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = fileHandle.readData(ofLength: context.chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer, encoding: context.fileEncoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    func writeLine(_ line: String) {
        guard let data = "\(line)\(context.lineDelimiter)".data(using: .utf8) else {
            return
        }
        let fileSize = fileHandle.seekToEndOfFile()
        let overweight = Int64(fileSize) + Int64(data.count) - Int64(context.fileMaxSize)
        if overweight > 0 {
            fileHandle.seek(toFileOffset: UInt64(overweight) + UInt64(context.fileMarginSize))
            let data = fileHandle.readDataToEndOfFile()
            fileHandle.truncateFile(atOffset: 0)
            fileHandle.write(data)
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
    }
    
    func clearLines() {
        fileHandle.truncateFile(atOffset: 0)
    }
    
}
