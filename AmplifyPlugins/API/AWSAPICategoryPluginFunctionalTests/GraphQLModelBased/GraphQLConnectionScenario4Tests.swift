//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

/*
 (Belongs to) A connection that is bi-directional by adding a many-to-one connection to the type that already have a one-to-many connection.
 ```
 type Post4 @model {
   id: ID!
   title: String!
   comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
 }

 type Comment4 @model
   @key(name: "byPost4", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
   post: Post4 @connection(fields: ["postID"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */
class GraphQLConnectionScenario4Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment4.self)
            ModelRegistry.register(modelType: Post4.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreateCommentAndGetCommentWithPost() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        Amplify.API.query(request: .get(Comment4.self, byId: comment.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedCommentOptional):
                    guard let queriedComment = queriedCommentOptional else {
                        XCTFail("Could not get comment")
                        return
                    }
                    XCTAssertEqual(queriedComment.id, comment.id)
                    XCTAssertEqual(queriedComment.post, post)
                    getCommentCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: complete this test with lazy loading of API (https://github.com/aws-amplify/amplify-ios/pull/845)
    func testCreateCommentAndGetPostWithComments() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        Amplify.API.query(request: .get(Post4.self, byId: post.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedPostOptional):
                    guard let queriedPost = queriedPostOptional else {
                        XCTFail("Could not get post")
                        return
                    }
                    XCTAssertEqual(queriedPost.id, post.id)
                    // XCTAssertNotNil(queriedPost.comments)
                    if let queriedComments = queriedPost.comments {
                        // TODO: Load Comments
                    }
                    getPostCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdateComment() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        comment.post = anotherPost
        Amplify.API.mutate(request: .update(comment)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let updatedComment):
                    XCTAssertEqual(updatedComment.post, anotherPost)
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
                updateCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetComment() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let deleteCommentSuccessful = expectation(description: "delete comment")
        Amplify.API.mutate(request: .delete(comment)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let deletedComment):
                    XCTAssertEqual(deletedComment.post, post)
                    deleteCommentSuccessful.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getCommentAfterDeleteCompleted = expectation(description: "get comment after deleted complete")
        Amplify.API.query(request: .get(Comment4.self, byId: comment.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let comment):
                    guard comment == nil else {
                        XCTFail("Should be nil after deletion")
                        return
                    }
                    getCommentAfterDeleteCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testListCommentsByPostID() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard createComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment4.keys.post.eq(post.id)
        Amplify.API.query(request: .list(Comment4.self, where: predicate)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let comments):
                    print(comments)
                    listCommentByPostIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func createPost(id: String = UUID().uuidString, title: String) -> Post4? {
        let post = Post4(id: id, title: title)
        var result: Post4?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createComment(id: String = UUID().uuidString, content: String, post: Post4) -> Comment4? {
        let comment = Comment4(id: id, content: content, post: post)
        var result: Comment4?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

extension Post4: Equatable {
    public static func == (lhs: Post4,
                           rhs: Post4) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
