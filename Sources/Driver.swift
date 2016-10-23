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

public class Driver {
    
    let fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    func filePath() -> String {
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return documentsPath + "/" + fileName
    }
    
    func fileMediaType() -> String {
        preconditionFailure("This method must be overridden")
    }
    
    func readTraces() -> [Trace] {
        preconditionFailure("This method must be overridden")
    }
    
    func read(afterTrace trace: Trace, count: Int) -> [Trace] {
        preconditionFailure("This method must be overridden")
    }
    
    func read(beforeTrace trace: Trace, count: Int) -> [Trace] {
        preconditionFailure("This method must be overridden")
    }
    
    func write(trace: Trace) {
        preconditionFailure("This method must be overridden")
    }
    
    func clear() {
        preconditionFailure("This method must be overridden")
    }
    
    func remove() {
        preconditionFailure("This method must be overridden")
    }
    
}
