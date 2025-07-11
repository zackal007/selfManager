//
//  ModelMigrations.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

typealias Goal = ModelSchemaV2.Goal
typealias GoalTask = ModelSchemaV2.GoalTask

enum ModelSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV1.Goal.self, ModelSchemaV1.GoalTask.self, Item.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        var tags: [String]
        var upperProject: [String]
        var subProject: [String]
        var recordNum: Int
        var category: String
        var createTime: Date
        var modifyTime: Date
        var visitTime: Date
        var dueDate: Date?

        @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
        var tasks: [GoalTask] = []

        init(name: String, description: String, progress: Double = 0.0, backgroundImage: String? = nil, tags: [String] = [], upperProject: [String] = [], subProject: [String] = [], recordNum: Int = 0, category: String = "", dueDate: Date? = nil) {
            self.id = UUID()
            self.name = name
            self.goalDescription = description
            self.progress = progress
            self.backgroundImage = backgroundImage
            self.tags = tags
            self.upperProject = upperProject
            self.subProject = subProject
            self.recordNum = recordNum
            self.category = category
            self.createTime = Date()
            self.modifyTime = Date()
            self.visitTime = Date()
            self.dueDate = dueDate
        }
    }

    @Model
    final class GoalTask {
        var id: UUID
        var title: String
        var isCompleted: Bool
        var createTime: Date

        var goal: Goal?

        init(title: String, isCompleted: Bool = false) {
            self.id = UUID()
            self.title = title
            self.isCompleted = isCompleted
            self.createTime = Date()
        }
    }
}

enum ModelSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV2.Goal.self, ModelSchemaV2.GoalTask.self, Item.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        var tags: [String]
        var upperProject: [String]
        var subProject: [String]
        var recordNum: Int
        var category: String
        var goalTypes: String
        var createTime: Date
        var modifyTime: Date
        var visitTime: Date
        var dueDate: Date?

        var goalType: GoalType {
            get { GoalType.from(string: goalTypes) }
            set { goalTypes = newValue.rawValue }
        }

        @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
        var tasks: [GoalTask] = []

        init(name: String, description: String, progress: Double = 0.0, backgroundImage: String? = nil, tags: [String] = [], upperProject: [String] = [], subProject: [String] = [], recordNum: Int = 0, category: String = "", goalType: GoalType = .shortTerm, dueDate: Date? = nil) {
            self.id = UUID()
            self.name = name
            self.goalDescription = description
            self.progress = progress
            self.backgroundImage = backgroundImage
            self.tags = tags
            self.upperProject = upperProject
            self.subProject = subProject
            self.recordNum = recordNum
            self.category = category
            self.goalTypes = goalType.rawValue
            self.createTime = Date()
            self.modifyTime = Date()
            self.visitTime = Date()
            self.dueDate = dueDate
        }
    }

    @Model
    final class GoalTask {
        var id: UUID
        var title: String
        var isCompleted: Bool
        var createTime: Date

        var goal: Goal?

        init(title: String, isCompleted: Bool = false) {
            self.id = UUID()
            self.title = title
            self.isCompleted = isCompleted
            self.createTime = Date()
        }
    }
}

enum ModelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ModelSchemaV1.self, ModelSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ModelSchemaV1.self,
        toVersion: ModelSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let goals = try? context.fetch(FetchDescriptor<ModelSchemaV2.Goal>())
            goals?.forEach {
                $0.goalTypes = GoalType.inferFromCategory($0.category).rawValue
            }
            try? context.save()
        }
    )
}