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

public class Console {

    private let asynchronous: Bool
    private let traceSpec: Specification<Trace>
    
    public init(
        asynchronous: Bool,
        traceSpec: Specification<Trace>
    ) {
        self.asynchronous = asynchronous
        self.traceSpec = traceSpec
    }
    
    func forword(trace: Trace, withDispatchQueue dispatchQueue: DispatchQueue) {
        if !traceSpec.isSatisfiedBy(trace) {
            return
        }
        if asynchronous {
            dispatchQueue.async {
                print(trace.toString())
            }
        } else {
            print(trace.toString())
        }
        
    }
    
}
