//
//  AuditLogHistoryView.swift
//  Coin
//

import SwiftUI

struct AuditLogDetails: View {
    let log: AuditLog

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Действие")
                    Spacer()
                    Text(log.method.title)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Дата")
                    Spacer()
                    Text(log.datetimeCreate, format: .dateTime.day().month().year().hour().minute().second())
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Устройство")
                    Spacer()
                    Text(log.deviceID)
                        .foregroundStyle(.secondary)
                }
            }
            if let before = log.snapshotBeforePretty, let after = log.snapshotAfterPretty {
                Section(header: Text("Изменения")) {
                    DiffView(old: before, new: after)
                }
            } else if let before = log.snapshotBeforePretty {
                Section(header: Text("Слепок до удаления")) {
                    Text(before)
                        .font(.system(.footnote, design: .monospaced))
                        .copyableOnTap(before)
                }
            } else if let after = log.snapshotAfterPretty {
                Section(header: Text("Слепок после создания")) {
                    Text(after)
                        .font(.system(.footnote, design: .monospaced))
                        .copyableOnTap(after)
                }
            }
        }
        .navigationTitle("Запись #\(log.id)")
    }
}
