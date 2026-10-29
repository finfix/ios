//
//  ChangePassword.swift
//  Coin
//
//  Created by Илья on 29.10.2026.
//

import SwiftUI

struct ChangePassword: View {
    
    @Environment(AlertManager.self) private var alert
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ChangePasswordViewModel()
    
    @State var shouldDisableUI = false
    @State var shouldShowSuccess = false
    
    var body: some View {
        Form {
            Section {
                SecureField("Старый пароль", text: $vm.oldPassword)
                    .textContentType(.password)
            }
            Section {
                SecureField("Новый пароль", text: $vm.newPassword)
                    .textContentType(.newPassword)
                SecureField("Повторите новый пароль", text: $vm.repeatPassword)
                    .textContentType(.newPassword)
            } footer: {
                if !vm.repeatPassword.isEmpty && vm.newPassword != vm.repeatPassword {
                    Text("Пароли не совпадают")
                        .foregroundColor(.red)
                }
            }
            Section {
                Button("Сменить пароль") {
                    Task {
                        shouldDisableUI = true
                        defer { shouldDisableUI = false }
                        
                        do {
                            try await vm.changePassword()
                        } catch {
                            alert.error(error)
                            return
                        }
                        
                        withAnimation(.spring()) {
                            shouldShowSuccess = true
                        }
                    }
                }
                .disabled(!vm.isValid)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(shouldDisableUI)
        .overlay {
            if shouldShowSuccess {
                CheckmarkPopover()
                    .onAppear {
                        Task {
                            try await Task.sleep(for: .seconds(1))
                            dismiss()
                        }
                    }
            }
        }
        .navigationTitle("Смена пароля")
    }
}

#Preview {
    ChangePassword()
        .environment(AlertManager(handle: {_ in }))
}
