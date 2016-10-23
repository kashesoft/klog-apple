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

public class Specification<T> {
    
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        preconditionFailure("This method must be overridden")
    }
    
    public func and(_ other: Specification<T>) -> Specification<T> {
        return AndSpecification<T>(self, other)
    }
    
    public func or(_ other: Specification) -> Specification<T> {
        return OrSpecification<T>(self, other)
    }
    
    public func not() -> Specification<T> {
        return NotSpecification<T>(self)
    }
    
}

public class AndSpecification<T>: Specification<T> {
    
    private let one: Specification<T>
    private let other: Specification<T>
    
    public init(_ x: Specification<T>, _ y: Specification<T>)  {
        self.one = x
        self.other = y
        super.init()
    }
    
    override public func isSatisfiedBy(_ candidate: T) -> Bool {
        return one.isSatisfiedBy(candidate) && other.isSatisfiedBy(candidate)
    }
    
}

public class OrSpecification<T>: Specification<T> {
    
    private let one: Specification<T>
    private let other: Specification<T>
    
    public init(_ x: Specification<T>, _ y: Specification<T>)  {
        self.one = x
        self.other = y
        super.init()
    }
    
    override public func isSatisfiedBy(_ candidate: T) -> Bool {
        return one.isSatisfiedBy(candidate) || other.isSatisfiedBy(candidate)
    }
    
}

public class NotSpecification<T>: Specification<T> {
    
    private let wrapped: Specification<T>
    
    public init(_ x: Specification<T>) {
        self.wrapped = x
        super.init()
    }
    
    override public func isSatisfiedBy(_ candidate: T) -> Bool {
        return !wrapped.isSatisfiedBy(candidate)
    }
    
}

public class FalseSpecification<T>: Specification<T> {
    
    override public init() {
        super.init()
    }
    
    override public func isSatisfiedBy(_ candidate: T) -> Bool {
        return false
    }
    
}

public class TrueSpecification<T>: Specification<T> {
    
    override public init() {
        super.init()
    }
    
    override public func isSatisfiedBy(_ candidate: T) -> Bool {
        return true
    }
    
}

public func &<T> (left: Specification<T>, right: Specification<T>) -> Specification<T> {
    return left.and(right)
}

public func |<T> (left: Specification<T>, right: Specification<T>) -> Specification<T> {
    return left.or(right)
}

public prefix func !<T> (specification: Specification<T>) -> Specification<T> {
    return specification.not()
}

public func ==<T> (left: Specification<T>, right: T) -> Bool {
    return left.isSatisfiedBy(right)
}

public func !=<T> (left: Specification<T>, right: T) -> Bool {
    return !left.isSatisfiedBy(right)
}
