import AppKit

/// Every representation of every pasteboard item, plus the change count at capture time.
struct ClipboardSnapshot {
    let changeCount: Int
    private let items: [[NSPasteboard.PasteboardType: Data]]

    static func capture(_ pasteboard: NSPasteboard) -> ClipboardSnapshot {
        let items = (pasteboard.pasteboardItems ?? []).map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { result, type in
                if let data = item.data(forType: type) { result[type] = data }
            }
        }
        return ClipboardSnapshot(changeCount: pasteboard.changeCount, items: items)
    }

    /// Writes the saved items back. Returns the new change count.
    @discardableResult
    func restore(to pasteboard: NSPasteboard) -> Int {
        pasteboard.clearContents()
        let restored = items.map { representations in
            let item = NSPasteboardItem()
            for (type, data) in representations { item.setData(data, forType: type) }
            return item
        }
        if !restored.isEmpty { pasteboard.writeObjects(restored) }
        return pasteboard.changeCount
    }
}
