import SwiftUI

/// One day of history: the date as the section heading, then that day's transcripts, newest first.
struct HistoryDayView: View {
    let day: Date
    let entries: [HistoryEntry]
    let canCopy: Bool
    let copy: (HistoryEntry) -> Bool
    let delete: (HistoryEntry) -> Void

    var body: some View {
        SettingsGroup(title: title) {
            ForEach(entries) { entry in
                HistoryEntryView(entry: entry, canCopy: canCopy,
                                 copy: { copy(entry) }, delete: { delete(entry) })
                if entry.id != entries.last?.id { RowDivider() }
            }
        }
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        if calendar.isDate(day, equalTo: Date(), toGranularity: .year) {
            return day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
        return day.formatted(.dateTime.month(.wide).day().year())
    }
}
