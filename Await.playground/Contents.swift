//: Playground - noun: a place where people can play

import UIKit


enum PlaybackCommand {
    case play
    case pause
    case resume
    case stop
    
    case seek(TimeInterval, previousState: PlaybackState)
}


/// The current state of a PlaybackControllable object
indirect enum PlaybackState {
    // not in a state to receive commands
    case uninitialized
    
    case playing
    case paused
    case stopped
    case seeking
    
    // is transitioning between states
    case transitioning(from: PlaybackState, to: PlaybackState)

    // Can not be reused
    case invalidated
 
    static func == (l: PlaybackState, r: PlaybackState) -> Bool {
        switch (l, r){
        case (.uninitialized, .uninitialized),
             (.playing, .playing),
             (.paused, .paused),
             (.stopped, .stopped),
             (.seeking, .seeking),
             (.invalidated, .invalidated):
            return true
        case (.transitioning(from: let a0, to: let a1), .transitioning(from: let b0, to: let b1)):
            return a0 == b0 && a1 == b1
        case (_, _):
            return false
        }
    }
}



enum PlaybackCommandResult {
    case success
    case error(Error)
}


/// Objects that can control playback
protocol PlaybackController: class {
    func execute(command: PlaybackCommand, on controllable: PlaybackControllable, complete: (PlaybackCommandResult)->())
    
    func state(for controllable: PlaybackControllable) -> PlaybackState
    
    var listeners: [PlaybackControllerListener] { get set }
    
    func controllableFor(identifier: String) -> PlaybackControllable
}

extension PlaybackController {
    func notify(listeners: [PlaybackControllerListener], block: (PlaybackControllerListener)->()) {
        for listener in listeners { block(listener) }
    }
    
    func notify(controllable: PlaybackControllable, didChangeStateFrom oldState: PlaybackState, to newState: PlaybackState) {
        notify(listeners: listeners, block: {
            $0.playbackController(self, controllable: controllable, didChangeStateFrom: oldState, to: newState)
        })
    }
    
    func press(_ command: PlaybackCommand, on controllable: PlaybackControllable, complete: (PlaybackCommandResult)->()) {
        notify(listeners: listeners, block: { $0.playbackController(self, willPress: command, on: controllable) })
        execute(command: command, on: controllable) { result in
            notify(listeners: listeners, block: { $0.playbackController(self, didPress: command, on: controllable, with: result) })
            complete(result)
        }
    }
    
    func add(listener: PlaybackControllerListener) {
        listeners.append(listener)
    }
    
    func remove(listener: PlaybackControllerListener) {
        listeners = listeners.filter { $0 !== listener }
    }
}

/// Listens to playback control events
protocol PlaybackControllerListener: class {
    func playbackController(_ controller: PlaybackController, willPress command: PlaybackCommand, on controllable: PlaybackControllable)
    func playbackController(_ controller: PlaybackController, didPress command: PlaybackCommand, on controllable: PlaybackControllable, with result: PlaybackCommandResult)
    
    func playbackController(_ controller: PlaybackController, controllable: PlaybackControllable, stateDidChange from oldState: PlaybackState, to newState: PlaybackState)
}


/// Object that can be controlled by PlaybackCommands through a PlaybackController
protocol PlaybackControllable {
    
}

/// Manages player objects
protocol PlayerHandler: PlaybackController {
    
}

/// Manages mapi playback sessions
protocol PlaybackSessionHandler: PlaybackController {
    
}

extension PlaybackCommand {
    var resultingState: PlaybackState {
        switch self {
        case .play:
            return .playing
        case .pause:
            return .paused
        case .resume:
            return .playing
        case .stop:
            return .stopped
        case .seek(_, previousState: let oldState):
            return oldState
        }
    }
}

extension PlaybackState {
    var revertedTransitioningState: PlaybackState {
        switch self {
        case .transitioning(from: let fromState, to: _):
            return fromState
        default:
            return self
        }
    }
}


class PlayerHandlerImplementation: PlayerHandler {
    var listeners: [PlaybackControllerListener] = []
    
    class Player: PlaybackControllable {
        var state: PlaybackState = .stopped
    }
    
    
    func setState(_ newState: PlaybackState, on player: Player) {
        let oldState = player.state
        player.state = newState
        notify(controllable: player, didChangeStateFrom: oldState, to: newState)
    }
    
    func execute(command: PlaybackCommand, on controllable: PlaybackControllable, complete: (PlaybackCommandResult)->()) {
        print("press \(String(describing: command)) on \(controllable)")
        switch controllable {
        case let tape as Player:
            setState(.transitioning(from: tape.state, to: command.resultingState), on: tape)
            setState(.command.resultingState, on: tape)
            complete(.success)
        default:
            fatalError("can not handle controllable")
        }
    }
    
    func state(for controllable: PlaybackControllable) -> PlaybackState {
        return (controllable as? Player)?.state ?? .stopped
    }
    
    func controllableFor(identifier: String) -> PlaybackControllable {
        return Player()
    }
}

struct Errors: Error {}

class SessionHandler: PlaybackSessionHandler {
    var listeners: [PlaybackControllerListener] = []
    class Session: PlaybackControllable {
        var state: PlaybackState = .stopped
    }
    
    func execute(command: PlaybackCommand, on controllable: PlaybackControllable, complete: (PlaybackCommandResult) -> ()) {
        let session = controllable as! Session
        print("press \(String(describing: command)) on \(controllable)")
        session.state = command.resultingState
        notify(controllable: session, didChangeStateTo: session.state)
        complete(.success)
    }
    
    func state(for controllable: PlaybackControllable) -> PlaybackState {
        guard let session = controllable as? Session else { fatalError("not my kind of controllable") }
        return session.state
    }
    
    
    func controllableFor(identifier: String) -> PlaybackControllable {
        return Session()
    }
}


class Listener: PlaybackControllerListener {
    func playbackController(_ controller: PlaybackController, willPress command: PlaybackCommand, on controllable: PlaybackControllable) {
        print("will press \(command) on \(controllable), state is \(controller.state(for: controllable))" )
    }
    
    func playbackController(_ controller: PlaybackController, didPress command: PlaybackCommand, on controllable: PlaybackControllable, with result: PlaybackCommandResult) {
        print("did press \(command) on \(controllable), state is \(controller.state(for: controllable))")
    }
    
    func playbackController(_ controller: PlaybackController, controllable: PlaybackControllable, stateDidChange from oldState: PlaybackState, to newState: PlaybackState) {
        print("\(controllable) state is now \(newState)")
    }
}


class Manager: PlaybackController, PlaybackControllerListener {
    var listeners: [PlaybackControllerListener] = []
    
    let sessionHandler: PlaybackController = SessionHandler()
    let playerHandler: PlaybackController = PlayerHandlerImplementation()
    
    func execute(command: PlaybackCommand, on controllable: PlaybackControllable, complete: (PlaybackCommandResult) -> ()) {
        let item = controllable as! Item
        
        sessionHandler.press(command, on: item.session) { result in
            switch result {
            case .success:
                playerHandler.press(command, on: item.player, complete: {result in
                    complete(result)
                })
            case .error(_):
                complete(result)
            }
        }
    }
    
    
    func state(for controllable: PlaybackControllable) -> PlaybackState {
        let item = controllable as! Item
        return playerHandler.state(for: item.player)
    }
    
    struct Item: PlaybackControllable {
        let session: PlaybackControllable
        let player: PlaybackControllable
    }
    
    var managedItems: [Item] = []
    
    func controllableFor(identifier: String) -> PlaybackControllable {
        return Item(session: sessionHandler.controllableFor(identifier: identifier),
                    player: playerHandler.controllableFor(identifier: identifier) )
    }
    
    
    func playbackController(_ controller: PlaybackController, controllable: PlaybackControllable, stateDidChange from oldState: PlaybackState, to newState: PlaybackState) {
        
        for item in managedItems.flatMap({[$0.session, $0.player}).filter({$0 == controllable}) {
            notify(controllable: <#T##PlaybackControllable#>, didChangeStateTo: <#T##PlaybackState#>)
        }
    }
    
}

let manager = Manager()
manager.add(listener: Listener())

let tape = manager.controllableFor(identifier: "Hello")
manager.press(.play, on: tape) { (result) in
    print("pressing play on tape gave \(result), state is now \(manager.state(for: tape))")
}



//
//
//
//class CachedValue<T> {
//    var stored: T
//    var lastFetchTime: TimeInterval = 0
//    let maxAge: TimeInterval
//    var fetching: Bool = false
//    var onChange: ()->() = {}
//    let queue: DispatchQueue
//
//    typealias RefreshComplete = (T?, Error?)->()
//    typealias RefreshFunc = (@escaping RefreshComplete)->()
//
//    let refreshFunc: RefreshFunc
//
//    init(initialValue: T, maxAge: TimeInterval, queue: DispatchQueue = .main, refresher: @escaping RefreshFunc) {
//        self.stored = initialValue
//        self.maxAge = maxAge
//        self.refreshFunc = refresher
//        self.queue = queue
//    }
//
//    func fetch() {
//        if fetching { return }
//
//        fetching = true
//        self.refreshFunc { [weak self] (value, _) in
//            if let `self` = self, let value = value {
//                self.stored = value
//                self.lastFetchTime = Date.timeIntervalSinceReferenceDate
//                self.onChange()
//            }
//            self?.fetching = false
//        }
//    }
//
//    var get: T {
//        if !fetching && abs(Date.timeIntervalSinceReferenceDate - lastFetchTime) > maxAge {
//            fetch()
//        }
//        return stored
//    }
//}
//
//class Model {
//    private let remoteResourceValue = CachedValue(initialValue: UIImage(), maxAge: 100, queue: .main) { (complete) in
//        URLSession.shared.dataTask(with: URL(string: "https://www.smashingmagazine.com/wp-content/uploads/2015/06/10-dithering-opt.jpg")!, completionHandler: { (data, _, error) in
//            let image: UIImage? = data == nil ? nil : UIImage(data: data!)
//            complete(image, error)
//        }).resume()
//    }
//
//    var remoteResource: UIImage {
//        return remoteResourceValue.get
//    }
//}
//print("hej")
//let m = Model()
//m.remoteResource
//sleep(2)
//m.remoteResource
//
//var counter = 0
//print("setup")
//let v = CachedValue(initialValue: 0, maxAge: 0.1) { (complete) in
//    counter += 1
//    complete(counter, nil)
//}
//print("set change func")
//v.onChange = {
//    print("changed to", v.get)
//}
//print("get 1")
//print("get is", v.get)
//print("get 2")
//print("get is", v.get)
//print("get 3")
//print("get is", v.get)
//print("end")


//
//
//protocol ThemeType {
//    var someProperty: (color: UIColor, font: UIFont) { get }
//    var thisThing: (UIColor) { get }
//}
//
//
//class BoxerTheme: ThemeType {
//    var someProperty = (color: UIColor.red, font: UIFont.systemFont(ofSize: 12))
//    var thisThing = (UIColor.red)
//}
//
//class ComhemTheme: ThemeType {
//    var thisThing = (UIColor.red)
//    var someProperty = (color: UIColor.red, font: UIFont.systemFont(ofSize: 12))
//
//}
//
//struct Style {
//    struct Color {
//        let hexvalue: String
//
//        static var white: Color {
//            Color(hexvalue: "ffffff")
//        }
//
//        static var black: Color {
//            Color(hexvalue: "000000")
//        }
//    }
//
//    struct Font {
//        let name: String
//        let size: CGFloat
//        let allcaps: Bool
//
//        static var sectionTitle: Font {
//            return Font(name: "Bold", size: 14, allcaps: true)
//        }
//    }
//
//    struct Background {
//        let color: Color
//
//        static var sectionTitle: Background {
//            Background(color: .white)
//        }
//
//    }
//
//
//    struct Foreground {
//        let color: Color
//        let font: Font
//
//        static var sectionTitle: Foreground {
//            return Foreground(color: .black, font: .sectionTitle)
//        }
//    }
//    let background: Background
//    let foreground: Foreground
//}
//
//struct HomeViewStyle {
//    var sectionTitle = Style(background: .sectionTitle, foreground: .sectionTitle)
//}
//
//
//enum Font {
//    case defaultText
//    case specialText
//}
//
//class ComHemTheme {
//    func resolve(font: Font) -> UIFont {
//        switch font {
//        case .defaultText:
//            return UIFont.boldSystemFont(ofSize: 12)
//        case .specialText: return resolve(font: .defaultText)
//        }
//    }
//}
//
//
//class BoxerTheme {
//    func resolve(font: Font) -> UIFont {
//        switch font {
//        case .defaultText:
//            return UIFont.boldSystemFont(ofSize: 12)
//        case .specialText: return resolve(font: .defaultText)
//        }
//    }
//}
//
//
//struct HomeVeiw {
//
//    let tableViewCellTextColor: UIColor
//    let tableViewCellTextFont: UIFont
//
//    struct ForegroundStyle {
//        let font: Font
//        let color: Color
//    }
//
//    let tableViewCellText: ForegroundStyle
//}
//
//
//
//extension UIView {
//    func applyStyle() {
//
//    }
//}
//
//class Theme {
//
//    static let defaultBackground = (color: UIColor.red)
//    static let defaultForeground = (color: UIColor.white, font: UIFont.systemFont(ofSize: 14))
//    static let defaultSectionHeader = (background: defaultBackground, foreground: defaultForeground)
//    static let defaultTitle = (font: UIFont.systemFont(ofSize: 10), color: UIColor.red)
//
//    struct HomeView {
//        let sectionHeader = (background: defaultBackground,
//                             font: defaultSectionHeader)
//
//        let tableViewCell = (backgroundColor: defaultBackground)
//        let collectionViewCell = (background: defaultBackground,
//                                  titleFont: defaultTitle)
//    }
//
//    enum Component {
//        case menu
//        case menuItem
//        case menuSection
//
//        case alertViewTransparantLayerBackground
//    }
//
//    enum ComponentState {
//        case normal
//        case highlighted
//        case selected
//        case disabled
//    }
//
//
//    init() {
//
//    }
//}
//
//
//
//
//
//
//enum RequestState<T> {
//    case waiting
//    case running
//    case complete(value: T)
//    case failed(error: Error)
//    case canceled
//}
//
//class Request<T> {
//    var queue = DispatchQueue.main
//    var group = DispatchGroup()
//
//    var state: RequestState<T> = .waiting
//
//    func start() {
//        group.notify(queue: queue) {
//            self.state = .running
//        }
//    }
//
//    func cancel() {
//        group.notify(queue: queue) {
//            self.state = .canceled
//        }
//    }
//
//    func retry() {
//        group.notify(queue: queue) {
//            switch self.state {
//            case .waiting, .failed, .canceled:
//                self.start()
//                break
//            case .complete, .running:
//                break
//            }
//        }
//    }
//
//    func complete(_ value: T) {
//        group.notify(queue: queue) {
//            self.state = .complete(value: value)
//        }
//    }
//
//    func failed(error: Error) {
//        group.notify(queue: queue) {
//            self.state = .failed(error: error)
//        }
//    }
//}
//
//
//
//class DataRequest: Request<Data> {
//    override func start() {
//        super.start()
//        URLSession.shared.dataTask(with: URL(string: "http://google.com")!) { [weak self] data, _, error in
//            if let data = data {
//                self?.complete(data)
//            } else {
//                self?.failed(error: error!)
//            }
//        }
//    }
//}
//
//let req = DataRequest()
//
//
//class Async<T> {
//    let group: DispatchGroup
//    let queue: DispatchQueue
//    var value: T?
//    var error: Error?
//
//    var await: T? {
//        group.wait()
//        return value
//    }
//
//    deinit {
//        group.leave()
//    }
//
//    func await( block: (T?, Error?) -> Void ) {
//        group.wait()
//        block(value, error)
//    }
//
//    typealias CompleteBlock = (T)->Void
//    typealias CommitBlock = (T) -> Void
//    typealias FailBlock = (Error) -> Void
//    typealias CommitValueBlock = (@escaping CommitBlock, @escaping FailBlock) -> Void
//    typealias ReturnValueBlock = ()->T
//    typealias ReturnValueBlockThrows = () throws -> T
//
//    init(queue: DispatchQueue = DispatchQueue.global(),
//         group: DispatchGroup = DispatchGroup()) {
//        self.queue = queue
//        self.group = group
//    }
//
//    convenience init(queue: DispatchQueue = DispatchQueue.global(),
//                     group: DispatchGroup = DispatchGroup(),
//                     block: CommitValueBlock? = nil) {
//        self.init(queue: queue, group: group)
//
//        if let block = block {
//            async(block)
//        }
//    }
//
//    convenience init(queue: DispatchQueue = DispatchQueue.global(),
//                     group: DispatchGroup = DispatchGroup(),
//                     block: ReturnValueBlock? = nil) {
//        self.init(queue: queue, group: group)
//
//        if let block = block {
//            async { commit, _ in
//                commit(block())
//            }
//        }
//    }
//
//    func begin() -> Async<T> {
//        group.enter()
//        return self
//    }
//
////    func async(_ block: @escaping ReturnValueBlock) {
////        group.enter()
////        queue.async(group: group) {
////            self.complete(value: block())
////        }
////    }
//
//
//    func async(_ block: @escaping CommitValueBlock) -> Async<T> {
//        group.enter()
//        queue.async(group: group) {
//            block({ value in
//                self.complete(value: value)
//            }, { error in
//                self.complete(error: error)
//            })
//        }
//        return self
//    }
//
//    func complete() {
//        print("Something bad happened")
//        group.leave()
//    }
//
//    func complete(value: T) {
//        self.value = value
//        group.leave()
//    }
//
//    func complete(error: Error) {
//        print("got error", error)
//        self.error = error
//        group.leave()
//    }
//
//
////    func then<O>(block: @escaping (T)->Async<O>) -> Async<O> {
////        print("yes")
////        return block(value!)
////    }
//
//    func map<O>(_ block: @escaping (T)->O) -> Async<O> {
//        let future = Async<O>(queue: self.queue)
//
//        future.async { commit, fail in
//            if let myValue = self.await {
//                let thenValue = block(myValue)
//                commit(thenValue)
//            } else if let error = self.error {
//                fail(error)
//            } else {
//                future.complete()
//            }
//        }
//        return future
//    }
//}
//
//func fetch(url: URL) -> Async<Data> {
//    return Async<Data>().async({ commit, fail in
//        let task = URLSession.shared.dataTask(with: url) { data, _, error in
//            if let data = data {
//                commit(data)
//            } else if let error = error {
//                fail(error)
//            }
//        }
//        task.resume()
//    })
//}
//
//
//class PAsync<T> {
//    var value: T?
//    init(block: () throws -> T) throws {
//
//    }
//    func then<R>(block:(T) throws -> R) throws -> PAsync<R> {
//        return try PAsync<R> {
//            return try block(try await())
//        }
//    }
//    func await() throws -> T {
//        return value!
//    }
//}
//
//
//func get(url: String) throws -> Data {
//    return Data()
//}
//func parse(data: Data) throws -> [String:Any] {
//    return [:]
//}
//struct Model{}
//func map(json: [String:Any]) throws -> Model {
//    return Model()
//}
//
//let model = try PAsync{try get(url: "http://google.com")}
//    .then{try parse(data: $0)}
//    .then{try map(json: $0)}
//    .await
//
//
//let future = fetch(url: URL(string: "http://google.com")!)
//
//func asyncMethod(input: Int) -> Async<Int> {
//    return Async{return input + 10}
//}
//
//let errors = Async<Int?>().begin()
//errors.complete(error: NSError.init(domain: "hej", code: 2, userInfo: nil))
//
//print(errors.await)
//print(future.await)
//
//let then = future.map { (data) -> Int in
//    return 10
//}
//
//print(then.await)
//
//let fortyfive = Async{ return 45 }
//let fiftyfive = fortyfive.map {$0+10}
//let sixtyfive = fiftyfive.map(asyncMethod)
//
//let value = fortyfive.await
//fiftyfive.await
//sixtyfive.await
//
//print("Done")
//
//
//protocol Test {
//    func fetch(request: URLRequest) -> Async<Data>
//    func parse(data: Data) -> Async<[String:Any]>
//    func promote(json: [String:Any]) -> Async<Model>
//}
//
//
//
//func fetchSynchronously() -> String {
//    return "Hello world"
//}
//
//
//let data = Async(queue: DispatchQueue.main){ fetchSynchronously() }
//
//
//print(data.await)
//
//
//
//
//
//
//
//
//
//
