//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class AmplifyCommandErrorTests: XCTestCase {

    enum TestError: Error, Equatable {
        case unknown(String)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitFromTasksWithFailures() throws {
        let error = TestError.unknown("Test error")
        let recoveryMessage = "Recovery message"
        let tasksResults: [AmplifyCommandTaskResult] = [
            .failure(AmplifyCommandError(.folderNotFound, error: error, recoverySuggestion: recoveryMessage)),
            .success("Task 1 success message"),
            .success("Task 2 success message"),
        ]
        let wrappingError = AmplifyCommandError(from: tasksResults)

        XCTAssertEqual(wrappingError.underlyingErrors!.count, 1)
        XCTAssertNotNil(wrappingError.debugDescription)
    }

}
