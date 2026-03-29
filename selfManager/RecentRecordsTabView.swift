import SwiftUI

struct RecentRecordsTabView: View {
    let allRecords: [Record]
    let dateFormatter: DateFormatter
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(allRecords.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.sorted { $0.createTime > $1.createTime }) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecordRowView(record: record, dateFormatter: dateFormatter)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RecentRecordsTabView_Previews: PreviewProvider {
    static var previews: some View {
        RecentRecordsTabView(
            allRecords: [],
            dateFormatter: DateFormatter()
        )
    }
}