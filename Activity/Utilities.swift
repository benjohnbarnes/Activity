//
//  Copyright © 2019 Splendid Things. All rights reserved.
//

/*
 # Issues
 
 `just` and `transform` might not be great names as they're likely to colide. They can be clarified by
 prefixing the module name though?
 
 Handling of processing and completion queues could be greatly improved I think. Similarly the zip queue.
 
 I tried returning `some Activity` from the utility functions to make implementation opaque. This made
 Swift's compiler crash.

 I'm using `AnyActivity` in utility implementations here which might not be ideal. It'd probably be preferable to
 build private `struct`s conforming to `Activity` and return those from the utility functions.
 
 
 */

import Dispatch

func just<Out>(_ value: Out) -> AnyActivity<Void, Out> {
    return AnyActivity { _, completion in
        completion(value)
    }
}

func transform<In, Out>(_ tranform: @escaping (In) -> Out) -> AnyActivity<In, Out> {
    return AnyActivity { input, completion in
        let transformed = tranform(input)
        completion(transformed)
    }
}

//MARK:-

extension Activity {
    
    func then<Next: Activity>(_ next: Next) -> AnyActivity<In, Next.Out> where Next.In == Out {
        return AnyActivity { input, completion in
            self.perform(on: input) { selfOut in
                next.perform(on: selfOut, completion)
            }
        }
    }

    func map<T>(_ t: @escaping (Out) -> T) -> AnyActivity<In, T> {
        return self.then(transform(t))
    }

    func adapt<U>(_ t: @escaping (U) -> In) -> AnyActivity<U, Out> {
        return transform(t).then(self)
    }
}

//MARK:- Queue

extension Activity {

    var completeOnMain: AnyActivity<In, Out> {
        return complete(on: .main)
    }
    
    func complete(on queue: DispatchQueue) -> AnyActivity<In, Out> {
        return AnyActivity<In, Out> { input, completion in
            self.perform(on: input) { result in
                queue.async {
                    completion(result)
                }
            }
        }
    }
    
    var processOnGlobal: AnyActivity<In, Out> {
        return process(on: .global())
    }

    func process(on queue: DispatchQueue) -> AnyActivity<In, Out> {
        return AnyActivity<In, Out> { input, completion in
            queue.async {
                self.perform(on: input, completion)
            }
        }
    }
}

//MARK:- Parallel

func together<A: Activity, B: Activity>(_ a: A, b: B) -> AnyActivity<(A.In, B.In), (A.Out, B.Out)> {
    return AnyActivity { input, completion in
        let zipping = DispatchGroup()
        
        var aOut: A.Out? = nil
        zipping.enter()
        a.perform(on: input.0) { aOut = $0 }
        
        var bOut: B.Out? = nil
        zipping.enter()
        b.perform(on: input.1) { bOut = $0 }
        
        zipping.notify(queue: .global()) {
            let result = (aOut!, bOut!)
            completion(result)
        }
    }
}


