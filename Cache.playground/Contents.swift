//: Playground - noun: a place where people can play

import UIKit

enum State {
    case launched
    case loggingIn
}

class FlowControl {
    
}


//
//class Task<ResultType> {
//    var result: ResultType? = nil
//
//    func await() -> ResultType {
//
//    }
//
//    func then(block: ()->()) {
//
//    }
//}
//
//class ValueTask<Value>: Task {
//    let value: Value
//    init(value: Value) {
//        self.value = value
//    }
//
//    func await() -> Value {
//        return value
//    }
//}
//
//class AutoTask<CompleteBlock>: Task {
//    typealias WorkBlock = (CompleteBlock)->()
//    let work: WorkBlock
//
//    var thenBlocks: [CompleteBlock] = []
//
//    init(on queue: DispatchQueue = DefaultTaskQueue, block: @escaping WorkBlock) {
//        self.work = block
//    }
//
//    func then(block: CompleteBlock) -> Task {
//        thenBlocks.append(block)
//        return self
//    }
//}
//
//class TransformTask<TransformBlock>: Task {
//    typealias WorkBlock = (TransformBlock)->()
//    init(on queue: DispatchQueue = DefaultTaskQueue, block: @escaping WorkBlock) {
//
//    }
//}
//
//func req(url: URL) -> ValueTask<String> {
//    let a = AutoTask<(Data?, URLResponse?, Error?)->()> { complete in
//        print("aa")
//        URLSession.shared.dataTask(with: url, completionHandler: complete)
//    }
//    .then { (data, response, error) in
//        return ValueTask(value: "Hello")
//    }
//    return a
//}
//let task = req(url: URL(string: "http://google.com")!)
//print(task.await())
//
//class Request<Response>: Operation {
//    var response: Response? = nil
//    var error: Error? = nil
//
//    var isComplete: Bool {
//        return isFinished
//    }
//
//    var succeeded: Bool {
//        return isComplete && error == nil
//    }
//
//    var failed: Bool {
//        return isComplete && error != nil
//    }
//
//    func complete(response: Response?, error: Error?) {
//        if isCancelled { return }
//        if isFinished { return }
//
//        self.response = response
//        self.error = error
//    }
//
//    func complete(success: Response) {
//        complete(response: response, error: nil)
//    }
//
//    func fail(error: Error) {
//        complete(response: nil, error: error)
//    }
//}
//
//class BlockRequest<Response>: Request<Response> {
//    typealias MainBlock = (BlockRequest<Response>)->()
//    var block: MainBlock
//
//    init(block: @escaping MainBlock) {
//        self.block = block
//    }
//
//    override func main() {
//        block(self)
//    }
//}
//
//
//
//
//class RequestQueue: OperationQueue {
//    func add<Request: Operation>(request: Request) {
//        addOperation(request)
//    }
//
//    func cancelAllRequests() {
//        cancelAllOperations()
//    }
//}
//
//class Session {
//    func startSession() {
//
//    }
//
//    func endSession(id: String) {
//        print("ending \(id)")
//    }
//}
//
//func q(){
////    let endsession = endsession
////
////    endsession.requires(startsession)
////    startsession.onFail.add(endsession)
////
////    let path = [login, startsession.onFail{endsession}, play, showplayer]
////    path.onFail {
////        [endsession, ]
////    }
//    let a = [()->()]()
//}
//
//
//func a() {
//    let getInt = BlockRequest<Int>() { request in
//        request.complete(response: 666, error: nil)
//    }
//
//    let queue = RequestQueue()
//    queue.add(request: getInt)
//
//    print(getInt.response!)
//}
//a()
//sleep(1)
//
//let a: [Any] = [1,"två", [3]]
//let b = a.lazy.flatMap({$0 as? String}).first
//print(b)
//

protocol LoadedCacheListener {
    func loaderCache<Key, Value>(_ cache: Cache<Key, Value>, willLoadValueFor key: Key)
    func loaderCache<Key, Value>(_ cache: Cache<Key, Value>, didLoadValueFor key: Key)
}

class Notifier<ListenerType> {
    var listeners: [ListenerType] = []
    
    func add(listener: ListenerType) {
        listeners.append(listener)
    }
    
    func notifiy(block: (ListenerType)->()) {
        listeners.forEach(block)
    }
}

class Cache<Key: Hashable, Value> {
    class Store {
        let group = DispatchGroup()
        var store: [Key:Item] = [:]
        func get(_ key: Key) -> Item? {
            group.enter(); defer { group.leave() }
            return store[key]
        }

        func set(_ item: Item, forKey key: Key) {
            group.enter(); defer { group.leave() }
            store[key] = item
        }

        func remove(_ key: Key) {
            group.enter(); defer { group.leave() }
            store.removeValue(forKey: key)
        }
    }

    enum Option {
        case reloadAfter(TimeInterval)
        case deleteAfter(TimeInterval)
    }

    struct Item {
        let value: Value
        let options: [Option]
        let storeTime: Date
        let accessTime: Date

        var shouldReload: Bool {
            let now = Date()
            for option in options {
                switch option {
                case .reloadAfter(let time):
                    return (storeTime + time) < now
                default: break
                }
            }
            return false
        }

        var shouldDelete: Bool {
            let now = Date()
            for option in options {
                switch option {
                case .deleteAfter(let time):
                    return (storeTime + time) < now
                default: break
                }
            }
            return false
        }
    }

    let store = Store()
    let listeners = Notifier<LoadedCacheListener>()

    func get(_ key: Key) -> Value? {
        if let item = store.get(key) {
            if item.shouldDelete {
                store.remove(key)
                return nil
            }

            return item.value
        }
        return nil
    }

    typealias LoadComplete = (Value, [Option])->()
    func get(_ key: Key, orLoad loader: @escaping (@escaping LoadComplete)->() ) -> Value? {

        func load() {
            listeners.notifiy { $0.loaderCache(self, willLoadValueFor: key) }
            
            loader() { (value: Value, options: [Option]) -> () in
                self.set(value, forKey: key, options: options)
                self.listeners.notifiy { $0.loaderCache(self, didLoadValueFor: key) }
            }
        }

        if let item = store.get(key) {
            // if delete, load and return nil
            if item.shouldDelete {
                defer { load() }
                store.remove(key)
                return nil
            }

            // if reload, return current value and load
            if item.shouldReload {
                defer { load() }
                return item.value
            }

            // otherwise just return cached value
            return item.value
        }

        // nothing in cache: load
        load()

        // return eventual synchronous load
        return store.get(key)?.value
    }

    func set(_ value: Value, forKey key: Key, options: [Option]) {
        let now = Date()
        let item = Item(value: value, options: options, storeTime: now, accessTime: now)
        store.set(item, forKey: key)
    }
}

protocol LoadedValueListener {
    func loadedValue<T>(willLoad: LoadedValue<T>)
    func loadedValue<T>(didLoad: LoadedValue<T>)
}

class LoadedValue<Value> {

    class Store {
        let group = DispatchGroup()
        var store: Item? = nil

        func get() -> Item? {
            group.enter(); defer { group.leave() }
            return store
        }

        func set(_ item: Item) {
            group.enter(); defer { group.leave() }
            store = item
        }

        func remove() {
            group.enter(); defer { group.leave() }
            store = nil
        }
    }


    struct Item {
        let value: Value
        let options: [Option]
        let storeTime: Date
        let accessTime: Date

        var shouldReload: Bool {
            let now = Date()
            for option in options {
                switch option {
                case .reloadAfter(let time):
                    return (storeTime + time) < now
                default: break
                }
            }
            return false
        }

        var shouldDelete: Bool {
            let now = Date()
            for option in options {
                switch option {
                case .deleteAfter(let time):
                    return (storeTime + time) < now
                default: break
                }
            }
            return false
        }
    }

    enum Option {
        case reloadAfter(TimeInterval)
        case deleteAfter(TimeInterval)
    }

    var store = Store()
    let listeners = Notifier<LoadedValueListener>()

    func set(_ value: Value, options: [Option]) {
        let now = Date()
        store.set(Item(value: value, options: options, storeTime: now, accessTime: now))
    }

    typealias LoadComplete = (Value, [Option])->()
    func value(_ loader: @escaping (@escaping LoadComplete)->() ) -> Value? {

        func load() {
            listeners.notifiy { $0.loadedValue(willLoad: self) }
            loader() { (value: Value, options: [Option]) -> () in
                self.set(value, options: options)
                self.listeners.notifiy { $0.loadedValue(didLoad: self) }
            }
        }

        if let item = store.get() {
            // if delete, load and return nil
            if item.shouldDelete {
                defer { load() }
                store.remove()
                return nil
            }

            // if reload, return current value and load
            if item.shouldReload {
                defer { load() }
                return item.value
            }

            // otherwise just return cached value
            return item.value
        }

        // nothing in cache: load
        load()

        // return eventual synchronous load
        return store.get()?.value
    }
}

class ViewModel {
    let stringsCache = Cache<Int, [String]>()

    var valueStore = LoadedValue<String>()
    var value: String? {
        return valueStore.value { complete in
            // download from internets
            complete("Loaded loaderValue", [.reloadAfter(10), .deleteAfter(60)])
        }
    }
    
    func stringsForItemAt(index: Int) -> [String] {
        return stringsCache.get(index) { complete in
            print("Loading \(index)")
            complete(["\(index) Hello", "\(index) Beaver"], [.reloadAfter(0.1)])
        } ?? []
    }

}

struct Ob: LoadedCacheListener, LoadedValueListener {
    func loadedValue<T>(didLoad: LoadedValue<T>) {
        print("value did load")
    }
    
    func loadedValue<T>(willLoad: LoadedValue<T>) {
        print("value will load")
    }
    
    func loaderCache<Key, Value>(_ cache: Cache<Key, Value>, willLoadValueFor key: Key) where Key : Hashable {
        print("cache will load \(key)")
    }
    
    func loaderCache<Key, Value>(_ cache: Cache<Key, Value>, didLoadValueFor key: Key) where Key : Hashable {
        print("cache did load \(key)")
    }
}

let m = ViewModel()
let l = Ob()
m.stringsCache.listeners.add(listener: l)
m.valueStore.listeners.add(listener: l)

print(m.value as Any)
RunLoop.main.run(until: Date() + 0.1)
print(m.value as Any)
RunLoop.main.run(until: Date() + 0.1)
print(m.value as Any)

print(m.stringsForItemAt(index: 0))
print(m.stringsForItemAt(index: 1))
print(m.stringsForItemAt(index: 0))
print(m.stringsForItemAt(index: 1))
RunLoop.main.run(until: Date() + 0.1)
print(m.stringsForItemAt(index: 0))
print(m.stringsForItemAt(index: 1))
