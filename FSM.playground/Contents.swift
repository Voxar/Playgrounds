//: Playground - noun: a place where people can play

import UIKit

import PlaygroundSupport

/**
 
 Transition state
 
 
 */

enum State {
    case ready
    case started
    case playing
    case stopped

    static func canTransition(from: State, to: State) -> Bool {
        switch (from, to) {
        case (.ready, .started),
             (.started, .playing),
             (.started, .stopped),
             (.playing, .stopped):
            return true
        default:
            return false
        }
    }
}

class StateMachine {

    func canTransition(from: State, to: State) -> Bool {
        return State.canTransition(from: from, to: to)
    }

    typealias TransitionBlock = (()throws->())

    struct TransitionError: Error {}

    var state: State

    func transition(from fromState: State, to toState: State, block: TransitionBlock) throws {
        if !canTransition(from: fromState, to: toState) {
            throw TransitionError()
        }

        try block()

    }
}


