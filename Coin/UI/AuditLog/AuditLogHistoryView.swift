//
//  AuditLogHistoryView.swift
//  Coin
//

import SwiftUI

struct AuditLogHistoryView: View {

    @State private var vm: AuditLogHistoryViewModel
    @Environment(AlertManager.self) private var alert

    init(entity: AuditLogEntity, entityID: String, accountGroupID: UUID?) {
        self._vm = State(initialValue: AuditLogHistoryViewModel(entity: entity, entityID: entityID, accountGroupID: accountGroupID))
    }

    var body: some View {
        List {
            ForEach(vm.logs) { log in
                NavigationLink {
                    AuditLogDetails(log: log)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.method.title)
                            .font(.headline)
                        Text(log.datetimeCreate, format: .dateTime.day().month().year().hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear {
                    vm.loadMoreIfNeeded(currentItem: log)
                }
            }
            if vm.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .overlay {
            if vm.logs.isEmpty && !vm.isLoadingNextPage {
                ContentUnavailableView("Нет истории изменений", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("История изменений")
        .task {
            do {
                try await vm.loadFirstPage()
            } catch {
                alert.error(error)
            }
        }
        .refreshable {
            do {
                try await vm.loadFirstPage()
            } catch {
                alert.error(error)
            }
        }
    }
}


extension AuditLogMethod {
    var title: String {
        switch self {
        case .create: return "Создание"
        case .update: return "Изменение"
        case .delete: return "Удаление"
        }
    }
}

#Preview {
    NavigationStack {
        AuditLogHistoryView(entity: .account, entityID: UUID().uuidString, accountGroupID: nil)
    }
}
