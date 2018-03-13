//: Playground - noun: a place where people can play

import UIKit

protocol ApplicationListener: class {
    func applicationStateDidChange(_ application: Application)
}

class Application {
    var downloader: Downloader
    var state: State {
        didSet {
            
        }
    }
    var listeners = [ApplicationListener]()
    
    init(downloader: Downloader = Downloader(), state: State = State()) {
        self.downloader = downloader
        self.state = state
    }
    
    func add(listener: ApplicationListener) {
        listeners.append(listener)
    }
    
    func login(credentials: Credentials, handler: (Bool, Error?)->()) {
        enum Login {
            case initial(Credentials)
            case sendCredentials
        }
        let f = Flow<Login, LoginState>(.initial(credentials), LoginState()) { step, state in
            
        }
        f.entering(.initial) {
            
        }
        f.leaving(.initial) {
            
        }
        
        f.entering(.sendCredentials) {
            
        }
        
    }
    
    
}


class Flow<T: Equatable> {
    typealias StateChange = (T)->()
    
    var steps = [T]()
    var enterHandlers = [(T, StateChange)]()
    
    func next(_ state: T) {
        enter(state)
    }
    
    func enter(_ state: T) {
        steps.append(state)
        enterHandlers.forEach { item in
            let (t, handler) = item
            if t == state {
                handler(t)
            }
        }
    }
    
    func entering(_ state: T, handler: @escaping StateChange) {
        enterHandlers.append(state, handler)
    }
    
}


extension Application {
    
    class Downloader {
        func download(url: URL, handler: @escaping (Data?, Error?)->()) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                handler(data, error)
            }.resume()
        }
    }
    
}

extension Application {
    enum Credentials {
        case empty
        case token(String)
        case username(String, password: String)
    }
    
    struct State {
        let loginState = LoginState()
        struct LoginState {
            
        }
    }
}
