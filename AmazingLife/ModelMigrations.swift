//
//  ModelMigrations.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import Foundation
import SwiftData

typealias Goal = ModelSchemaV5.Goal
typealias GoalTask = ModelSchemaV5.GoalTask

enum ModelSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV1.Goal.self, ModelSchemaV1.GoalTask.self, Item.self, Record.self, Contact.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        @Attribute(.externalStorage)
        var tags: [String]
        @Attribute(.externalStorage)
        var upperProject: [String]
        @Attribute(.externalStorage)
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

enum TaskStatus: Int, Codable {
    case todo = 0
    case inProgress = 1
    case done = 2
}



enum ModelSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 2, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV3.Goal.self, ModelSchemaV3.GoalTask.self, Item.self, Record.self, User.self, Contact.self, Asset.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        @Attribute(.externalStorage)
        var tags: [String]
        @Attribute(.externalStorage)
        var upperProject: [String]
        @Attribute(.externalStorage)
        var subProject: [String]
        var recordNum: Int
        var category: String
        var goalTypes: String
        var createTime: Date
        var modifyTime: Date
        var visitTime: Date
        var dueDate: Date?
        @Attribute(.externalStorage)
        var relatedContactIds: [UUID] = []
        var importance: Int = 1
        
        var goalType: GoalType {
            get { GoalType.from(string: goalTypes) }
            set { goalTypes = newValue.rawValue }
        }

        @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
        var tasks: [GoalTask] = []

        init(name: String, description: String, progress: Double = 0.0, backgroundImage: String? = nil, tags: [String] = [], upperProject: [String] = [], subProject: [String] = [], recordNum: Int = 0, category: String = "", goalType: GoalType = .shortTerm, dueDate: Date? = nil, relatedContactIds: [UUID] = [], importance: Int = 1) {
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
            self.relatedContactIds = relatedContactIds
            self.importance = importance
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
    static var models: [any PersistentModel.Type] { [ModelSchemaV2.Goal.self, ModelSchemaV2.GoalTask.self, Item.self, Record.self, Contact.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        @Attribute(.externalStorage)
        var tags: [String]
        @Attribute(.externalStorage)
        var upperProject: [String]
        @Attribute(.externalStorage)
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

// 新增ModelSchemaV4，支持回收站功能
enum ModelSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 3, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV4.Goal.self, ModelSchemaV4.GoalTask.self, Item.self, Record.self, User.self, Contact.self, Asset.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        var tagsString: String = ""
        var upperProjectString: String = ""
        var subProjectString: String = ""
        var recordNum: Int
        var category: String
        var goalTypes: String
        var createTime: Date
        var modifyTime: Date
        var visitTime: Date
        var dueDate: Date?
        var relatedContactIdsString: String = ""
        var importance: Int = 1
        
        // 回收站相关字段
        var isDeleted: Bool = false
        var deletedDate: Date?
        
        // 计算属性，用于获取和设置标签数组
        var tags: [String] {
            get {
                return tagsString.isEmpty ? [] : tagsString.components(separatedBy: ",")
            }
            set {
                tagsString = newValue.joined(separator: ",")
            }
        }
        
        // 计算属性，用于获取和设置上级项目数组
        var upperProject: [String] {
            get {
                return upperProjectString.isEmpty ? [] : upperProjectString.components(separatedBy: ",")
            }
            set {
                upperProjectString = newValue.joined(separator: ",")
            }
        }
        
        // 计算属性，用于获取和设置子项目数组
        var subProject: [String] {
            get {
                return subProjectString.isEmpty ? [] : subProjectString.components(separatedBy: ",")
            }
            set {
                subProjectString = newValue.joined(separator: ",")
            }
        }
        
        // 计算属性，用于获取和设置相关联系人ID数组
        var relatedContactIds: [UUID] {
            get {
                return relatedContactIdsString.isEmpty ? [] : relatedContactIdsString.components(separatedBy: ",").compactMap { UUID(uuidString: $0) }
            }
            set {
                relatedContactIdsString = newValue.map { $0.uuidString }.joined(separator: ",")
            }
        }
        
        var goalType: GoalType {
            get { GoalType.from(string: goalTypes) }
            set { goalTypes = newValue.rawValue }
        }

        @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
        var tasks: [GoalTask] = []

        init(name: String, description: String, progress: Double = 0.0, backgroundImage: String? = nil, tags: [String] = [], upperProject: [String] = [], subProject: [String] = [], recordNum: Int = 0, category: String = "", goalType: GoalType = .shortTerm, dueDate: Date? = nil, relatedContactIds: [UUID] = [], importance: Int = 1) {
            self.id = UUID()
            self.name = name
            self.goalDescription = description
            self.progress = progress
            self.backgroundImage = backgroundImage
            self.tagsString = tags.joined(separator: ",")
            self.upperProjectString = upperProject.joined(separator: ",")
            self.subProjectString = subProject.joined(separator: ",")
            self.recordNum = recordNum
            self.category = category
            self.goalTypes = goalType.rawValue
            self.createTime = Date()
            self.modifyTime = Date()
            self.visitTime = Date()
            self.dueDate = dueDate
            self.relatedContactIdsString = relatedContactIds.map { $0.uuidString }.joined(separator: ",")
            self.importance = importance
            self.isDeleted = false
            self.deletedDate = nil
        }
        
        // 软删除方法
        func moveToTrash() {
            self.isDeleted = true
            self.deletedDate = Date()
            self.modifyTime = Date()
        }
        
        // 从回收站恢复
        func restoreFromTrash() {
            self.isDeleted = false
            self.deletedDate = nil
            self.modifyTime = Date()
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

enum ModelSchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)
    static var models: [any PersistentModel.Type] { [ModelSchemaV5.Goal.self, ModelSchemaV5.GoalTask.self, Item.self, Record.self, Contact.self] }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var goalDescription: String
        var progress: Double
        var backgroundImage: String?
        var tagsString: String = ""
        var upperProjectString: String = ""
        var subProjectString: String = ""
        var recordNum: Int
        var category: String
        var goalTypes: String
        var createTime: Date
        var modifyTime: Date
        var visitTime: Date
        var dueDate: Date?
        var relatedContactIdsString: String = ""
        var importance: Int
        var isDeleted: Bool
        var deletedDate: Date?

        var tags: [String] {
            get { tagsString.isEmpty ? [] : tagsString.components(separatedBy: ",") }
            set { tagsString = newValue.joined(separator: ",") }
        }

        var upperProject: [String] {
            get { upperProjectString.isEmpty ? [] : upperProjectString.components(separatedBy: ",") }
            set { upperProjectString = newValue.joined(separator: ",") }
        }

        var subProject: [String] {
            get { subProjectString.isEmpty ? [] : subProjectString.components(separatedBy: ",") }
            set { subProjectString = newValue.joined(separator: ",") }
        }

        var relatedContactIds: [UUID] {
            get { relatedContactIdsString.isEmpty ? [] : relatedContactIdsString.components(separatedBy: ",").compactMap { UUID(uuidString: $0) } }
            set { relatedContactIdsString = newValue.map { $0.uuidString }.joined(separator: ",") }
        }

        var goalType: GoalType {
            get { GoalType.from(string: goalTypes) }
            set { goalTypes = newValue.rawValue }
        }

        @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
        var tasks: [GoalTask] = []

        init(name: String, description: String, progress: Double = 0.0, backgroundImage: String? = nil, tags: [String] = [], upperProject: [String] = [], subProject: [String] = [], recordNum: Int = 0, category: String = "", goalType: GoalType = .shortTerm, dueDate: Date? = nil, relatedContactIds: [UUID] = [], importance: Int = 1) {
            self.id = UUID()
            self.name = name
            self.goalDescription = description
            self.progress = progress
            self.backgroundImage = backgroundImage
            self.tagsString = tags.joined(separator: ",")
            self.upperProjectString = upperProject.joined(separator: ",")
            self.subProjectString = subProject.joined(separator: ",")
            self.recordNum = recordNum
            self.category = category
            self.goalTypes = goalType.rawValue
            self.createTime = Date()
            self.modifyTime = Date()
            self.visitTime = Date()
            self.dueDate = dueDate
            self.relatedContactIdsString = relatedContactIds.map { $0.uuidString }.joined(separator: ",")
            self.importance = importance
            self.isDeleted = false
            self.deletedDate = nil
        }

        func moveToTrash() {
            self.isDeleted = true
            self.deletedDate = Date()
            self.modifyTime = Date()
        }

        func restoreFromTrash() {
            self.isDeleted = false
            self.deletedDate = nil
            self.modifyTime = Date()
        }
    }

    @Model
    final class GoalTask {
        var id: UUID
        var title: String
        var isCompleted: Bool
        var statusRaw: Int = TaskStatus.todo.rawValue
        var createTime: Date
        var goal: Goal?

        var status: TaskStatus {
            get { TaskStatus(rawValue: statusRaw) ?? .todo }
            set { statusRaw = newValue.rawValue }
        }

        init(title: String, isCompleted: Bool = false) {
            self.id = UUID()
            self.title = title
            self.isCompleted = isCompleted
            self.statusRaw = isCompleted ? TaskStatus.done.rawValue : TaskStatus.todo.rawValue
            self.createTime = Date()
        }
    }
}

enum ModelMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ModelSchemaV1.self, ModelSchemaV2.self, ModelSchemaV3.self, ModelSchemaV4.self, ModelSchemaV5.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5]
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

    static let migrateV2toV3 = MigrationStage.lightweight(fromVersion: ModelSchemaV2.self, toVersion: ModelSchemaV3.self)
    
    static let migrateV3toV4 = MigrationStage.lightweight(fromVersion: ModelSchemaV3.self, toVersion: ModelSchemaV4.self)

    static let migrateV4toV5 = MigrationStage.lightweight(fromVersion: ModelSchemaV4.self, toVersion: ModelSchemaV5.self)
}
