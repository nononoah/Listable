//
//  UpdateCallbacksTests.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 8/19/20.
//

@testable import ListableUI
import XCTest


class UpdateCallbacksTests : XCTestCase
{
    func test_add_and_perform() {
        
        self.testcase("shouldPerform is false") {
            let callbacks = UpdateCallbacks(.immediate)
            
            var callCount : Int = 0
            
            callbacks.add(if: false) {
                callCount += 1
            }
            
            XCTAssertEqual(callCount, 0)
            XCTAssertEqual(callbacks.calls.count, 0)
        }
        
        self.testcase("immediate") {
            let callbacks = UpdateCallbacks(.immediate)
            
            var callCount : Int = 0
            
            callbacks.add(if: true) {
                callCount += 1
            }
            
            XCTAssertEqual(callCount, 1)
            XCTAssertEqual(callbacks.calls.count, 0)
            
            callbacks.perform()
            
            XCTAssertEqual(callCount, 1)
            XCTAssertEqual(callbacks.calls.count, 0)
        }
        
        self.testcase("queued") {
            let callbacks = UpdateCallbacks(.queue)
            
            var callCount : Int = 0
            
            callbacks.add(if: true) {
                callCount += 1
            }
            
            XCTAssertEqual(callCount, 0)
            XCTAssertEqual(callbacks.calls.count, 1)
            
            callbacks.perform()
            
            XCTAssertEqual(callCount, 1)
            XCTAssertEqual(callbacks.calls.count, 0)
        }
    }
}
