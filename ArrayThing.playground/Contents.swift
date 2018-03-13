//: Playground - noun: a place where people can play

import UIKit


protocol AnyStorage {
    func store(_ value: Data?) throws
    func load() throws -> Data?
}

protocol StorageType: AnyStorage {
    associatedtype Value
    func store(_ value: Value?) throws
    func load() throws -> Value?
}


class Storage<T>: StorageType {

    typealias Value = T where T: StorageType.Value
    func store(_ value: Data?) throws {
        
    }
    
    func load() throws -> Data? {
        return nil
    }
    
}

let q: Storage<Int>;
extension StorageType {
    func store(_ value: String?) throws {
        
    }
    
    func load() throws -> String? {
        return "OK"
    }
}

extension StorageType where Value == Int {
    func store(_ value: Int?) throws {
        
    }
    
    func load() throws -> Int? {
        return 321
    }
}
//
//protocol Vault {
//    class VaultStorage: AnyStorage {
//        typealias Value = Any
//
//        var v: Value? = nil
//
//        func store<T>(_ value: T?) throws {
//            v = value
//        }
//
//        func load<T>() throws -> T? {
//            return v
//        }
//    }
//
//    func storage<T>(forKey: String) -> VaultStorage<T> {
//
//    }
//}

let a = Storage<String>()
try! a.store("Hej")
try! a.load()

let b = Storage<Int>()
try! b.store(123)
try! b.load()

//protocol DataStore {
//    func store(data: Data?) throws
//    func loadData() throws -> Data?
//}
//
//
//class MyDataStore: DataStore {
//    var data: Data? = nil
//    func store(data: Data?) throws {
//        self.data = data
//    }
//
//    func loadData() throws -> Data? {
//        return self.data
//    }
//
//}
//
//extension DataStore {
//    func store(_ string: String?) throws {
//        try store(data: string.flatMap{$0.data(using: .utf8)})
//    }
//
//    func load() throws -> String? {
//        return (try loadData()).flatMap { String(data: $0, encoding: .utf8)}
//    }
//}
//
//
////extension DataStore where T ==  {
////    func store<T: Encodable>(_ encodable: T?) throws {
////
////        if let encodable = encodable {
////            let data = try JSONEncoder().encode(encodable)
////            try store(data: data)
////        } else {
////            try store(data: nil)
////        }
////    }
////
////    func load<T: Decodable>(_ type: T.Type = T.self) throws -> T? {
////        if let data = try loadData() {
////            return try JSONDecoder().decode(T.self, from: data)
////        } else {
////            return nil
////        }
////    }
////}
//
//class Vault {
//
//    class Storage<T>: DataStore {
//        let userDefaults: UserDefaults
//        let key: String
//
//        init(userDefaults: UserDefaults, key: String) {
//            self.userDefaults = userDefaults
//            self.key = key
//        }
//
//        func store(data: Data?) throws {
//            userDefaults.set(data, forKey: key)
//        }
//
//        func loadData() throws -> Data? {
//            return userDefaults.data(forKey: key)
//        }
//    }
//
//    let userDefaults: UserDefaults
//
//    init(userDefaults: UserDefaults) {
//        self.userDefaults = userDefaults
//    }
//
////    func storage(forKey key: String) -> DataStore {
////        return Storage(userDefaults: userDefaults, key: key)
////    }
//
//    func storage<T>(forKey key: String) -> Storage<T> {
//        return Storage(userDefaults: userDefaults, key: key)
//    }
//}
//
//
//var store: DataStore = MyDataStore()
//try? store.store("hej")
//try? store.load()
//
//struct Hej: Codable {
//    let message: String
//}
//struct Test: Codable{let q: String}
//try! store.store(Hej(message: "Hej Voxar!"))
//try! store.load(Hej.self)
//
//let storeVault = Vault(userDefaults: .standard)
//let storeHej = storeVault.storage(forKey: "hej") as Vault.Storage<String>
//try! storeHej.store("Hello")
//
//let loadVault = Vault(userDefaults: .standard)
//let loadHej = loadVault.storage(forKey: "hej") as Vault.Storage<String>
//try! loadHej.load()
//
//let vault = Vault(userDefaults: .standard)
//let testStorage: Vault.Storage<Int> = vault.storage(forKey: "test")
//try! testStorage.store(11)
//try! testStorage.load()
//
////
////class Thing<T>: Collection {
////    typealias ListType = Array<T>
////    var array: ListType = []
////
////    func didInsert(item: ListType.Element, at index: ListType.Index) {
////
////    }
////
////    func didRemove(item: ListType.Element, at index: ListType.Index) {
////
////    }
////
////    func didUpdate(item: ListType.Element, at index: ListType.Index) {
////
////    }
////
////    func didMove(itemFromIndex fromIndex: ListType.Index, toIndex: ListType.Index) {
////
////    }
////}
//
//
