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

public struct Trace {
    
    private static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return timeFormatter
    }()
    
    let priority: Int
    let time: Date
    let source: Int
    let level: Int
    let origin: String
    let message: String
    
    init(
        priority: Int,
        source: Int,
        level: Int,
        file: StaticString = "",
        line: Int = 0,
        function: StaticString = "",
        message: String
    ) {
        self.priority = priority
        self.time = Date()
        self.source = source
        self.level = level
        self.origin = "\((String(describing: file) as NSString).lastPathComponent).\(line) \(String(describing: function))"
        self.message = message
    }
    
    init(fromString string: String) {
        self.priority = 0
        self.time = Trace.timeFormatter.date(from: string.substring(to: string.index(string.startIndex, offsetBy: 23))) ?? Date()
        self.source = 0
        self.level = 0
        self.origin = ""
        self.message = ""
    }
    
    func toString() -> String {
        return "\(timeTag()) [\(levelTag())] \(sourceTag()) > \(message)"
    }
    
    func timeTag() -> String {
        return Trace.timeFormatter.string(from: time)
    }
    
    func sourceTag() -> String {
        switch source {
        case Source.app:
            return "APP | \(origin)"
        case Source.cpu:
            return "CPU"
        case Source.ram:
            return "RAM"
        default:
            return ""
        }
    }
    
    func levelTag() -> String {
        switch level {
        case Level.fault:
            return "FAULT"
        case Level.error:
            return "ERROR"
        case Level.warn:
            return "WARN"
        case Level.info:
            return "INFO"
        case Level.debug:
            return "DEBUG"
        case Level.util:
            return "UTIL"
        default:
            return ""
        }
    }
    
}
