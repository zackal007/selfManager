import Foundation
import WidgetKit

@Test
func testPingManagerWritesNamesToAppGroup() async throws {
    PingManager.shared.clearAll()

    let goal = Goal(name: "测试目标A", description: "desc")
    let contact = Contact(name: "联系人B")

    PingManager.shared.ping(goal: goal)
    PingManager.shared.ping(contact: contact)

    let defaults = UserDefaults(suiteName: "group.selfmanager.widget")
    let goalNames = defaults?.stringArray(forKey: "widget_pinned_goals_names") ?? []
    let contactNames = defaults?.stringArray(forKey: "widget_pinned_contacts_names") ?? []

    #expect(goalNames.contains("测试目标A"))
    #expect(contactNames.contains("联系人B"))

    PingManager.shared.unping(goalID: goal.id)
    PingManager.shared.unping(contactID: contact.id)

    let goalNamesAfter = defaults?.stringArray(forKey: "widget_pinned_goals_names") ?? []
    let contactNamesAfter = defaults?.stringArray(forKey: "widget_pinned_contacts_names") ?? []

    #expect(!goalNamesAfter.contains("测试目标A"))
    #expect(!contactNamesAfter.contains("联系人B"))
}
