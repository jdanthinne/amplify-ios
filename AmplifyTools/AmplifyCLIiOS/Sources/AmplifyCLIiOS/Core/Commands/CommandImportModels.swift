//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum CommandImportModelsTasks {
    static func projectHasGeneratedModels(environment: AmplifyCommandEnvironment,
                                          args: CommandImportModels.TaskArgs) -> AmplifyCommandTaskResult {
        let modelsPath = environment.path(for: args.generatedModelsPath)
        if environment.directoryExists(atPath: modelsPath) {
            return .success("Amplify models folder found at \(modelsPath)")
        }

        let recoveryMsg = "We couldn't find any generated models at \(modelsPath). Please run amplify codegen models."
        return .failure(
            AmplifyCommandError(
                .folderNotFound,
                error: nil,
                recoverySuggestion: recoveryMsg))
    }

    static func addGeneratedModelsToProject(environment: AmplifyCommandEnvironment,
                                            args: CommandImportModels.TaskArgs) -> AmplifyCommandTaskResult {
        let models = environment.glob(pattern: "\(args.generatedModelsPath)/*.swift").map {
            environment.createXcodeFile(withPath: $0, ofType: .source)
        }

        do {
            try environment.addFilesToXcodeProject(projectPath: environment.basePath, files: models, toGroup: args.modelsGroup)
            return .success("Successfully added models \(models) to \(args.modelsGroup) group.")
        } catch {
            return .failure(AmplifyCommandError(.xcodeProject, error: error))
        }
    }
}

struct CommandImportModels: AmplifyCommand {
    struct CommandImportModelsArgs {
        let modelsGroup = "AmplifyModels"
        let generatedModelsPath = "amplify/generated/models"
    }

    typealias TaskArgs = CommandImportModelsArgs

    static var description = "Import Amplify models"

    var taskArgs = CommandImportModelsArgs()

    var tasks: [AmplifyCommandTask<CommandImportModelsArgs>] = [
        .run(CommandImportModelsTasks.projectHasGeneratedModels),
        .run(CommandImportModelsTasks.addGeneratedModelsToProject)
    ]

    func onFailure() {
    }
}
