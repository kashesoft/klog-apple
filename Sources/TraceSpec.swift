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

public class TraceSpec : Specification<Trace> {
    
    static func defaultSpec() -> Specification<Trace> {
        return TraceSpec(priority: Priority.lowest, sources: Source.app | Source.cpu | Source.ram, levels: Level.fault | Level.error | Level.warn | Level.info | Level.debug | Level.util)
    }
    
    private let priority: Int
    private let sources: Int
    private let levels: Int
    
    public init(priority: Int, sources: Int, levels: Int) {
        self.priority = priority
        self.sources = sources
        self.levels = levels
    }
    
    override public func isSatisfiedBy(_ trace: Trace) -> Bool {
        return self.priority <= trace.priority && (sources & trace.source) == trace.source && (levels & trace.level) == trace.level
    }
    
}
