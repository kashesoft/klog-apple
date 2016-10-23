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
#if os(iOS)
import UIKit
import MessageUI
#elseif os(macOS)
import AppKit
#endif

open class Log {
    
    private static var rootLog: Log?
    private static var sources: Int = Source.app
    
    public static func setLogs(_ logs: Log...) {
        var nextLog: Log! = nil
        for log in Array(logs.reversed()) {
            log.nextLog = nextLog
            nextLog = log
        }
        Log.rootLog = nextLog
    }
    
    public static func fault(
        message: String,
        priority: Int = Priority.highest,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.fault,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    public static func error(
        message: String,
        priority: Int = Priority.higher,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.error,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    public static func warn(
        message: String,
        priority: Int = Priority.high,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.warn,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    public static func info(
        message: String,
        priority: Int = Priority.low,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.info,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    public static func debug(
        message: String,
        priority: Int = Priority.lower,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.debug,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    public static func util(
        message: String,
        priority: Int = Priority.lowest,
        file: StaticString = #file,
        line: Int = #line,
        function: StaticString = #function
        ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: Source.app,
                level: Level.util,
                file: file,
                line: line,
                function: function,
                message: message
            )
        )
    }
    
    static func fault(
        source: Int,
        message: String,
        priority: Int = Priority.highest
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.fault,
                message: message
            )
        )
    }
    
    static func error(
        source: Int,
        message: String,
        priority: Int = Priority.higher
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.error,
                message: message
            )
        )
    }
    
    static func warn(
        source: Int,
        message: String,
        priority: Int = Priority.high
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.warn,
                message: message
            )
        )
    }
    
    static func info(
        source: Int,
        message: String,
        priority: Int = Priority.low
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.info,
                message: message
            )
        )
    }
    
    static func debug(
        source: Int,
        message: String,
        priority: Int = Priority.lower
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.debug,
                message: message
            )
        )
    }
    
    static func util(
        source: Int,
        message: String,
        priority: Int = Priority.lowest
    ) {
        rootLog?.forward(
            trace: Trace(
                priority: priority,
                source: source,
                level: Level.util,
                message: message
            )
        )
    }
    
    public static func setSources(_ sources: Int) {
        Log.sources = sources
        SystemMonitor.monitor(sources: Log.sources)
    }
    
    public static func addSources(_ sources: Int) {
        Log.sources |= sources
        SystemMonitor.monitor(sources: Log.sources)
    }
    
    public static func removeSources(_ sources: Int) {
        Log.sources &= ~sources
        SystemMonitor.monitor(sources: Log.sources)
    }

    private let name: String
    private let driver: Driver
    private let traceSpec: Specification<Trace>
    private let console: Console?
    private let mailer: Mailer
    private var nextLog: Log?
    private let dispatchQueue: DispatchQueue
    
    public init(
        name: String,
        driver: Driver,
        traceSpec: Specification<Trace> = TraceSpec.defaultSpec(),
        console: Console? = Console(asynchronous: false, traceSpec: TraceSpec.defaultSpec()),
        mailer: Mailer
    ) {
        self.name = name
        self.driver = driver
        self.traceSpec = traceSpec
        self.console = console
        self.mailer = mailer
        self.dispatchQueue = DispatchQueue(label: name)
    }
    
    public func clear() {
        dispatchQueue.async { [weak self] in
            self?.driver.clear()
        }
    }
    
    public func remove() {
        dispatchQueue.async { [weak self] in
            self?.driver.remove()
        }
    }
    
    #if os(iOS)
    
    public func sendByMail(
        controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController,
        delegate: MFMailComposeViewControllerDelegate?
    ) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        guard let controller = controller else {
            return
        }
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = delegate
        mailController.setSubject(mailer.subject)
        mailController.setMessageBody(mailer.message, isHTML: false)
        mailController.setToRecipients(mailer.recipients)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: driver.filePath())) else {
            return
        }
        mailController.addAttachmentData(data, mimeType: driver.fileMediaType(), fileName: driver.fileName)
        controller.present(mailController, animated: true)
    }
    
    #elseif os(macOS)
    
    #endif
    
    private func forward(trace: Trace) {
        console?.forword(trace: trace, withDispatchQueue: dispatchQueue)
        if traceSpec.isSatisfiedBy(trace) {
            write(trace: trace)
        }
        if let nextLog = nextLog {
            nextLog.forward(trace: trace)
        }
    }
    
    private func write(trace: Trace) {
        dispatchQueue.async { [weak self] in
            self?.driver.write(trace: trace)
        }
    }

}
