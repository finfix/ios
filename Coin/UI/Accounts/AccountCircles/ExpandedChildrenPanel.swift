//
//  AccountCircleView.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI
import OSLog
import Factory

/// Плавающая панель дочерних счетов — см. AccountCirclesViewModel.expandedParentAccount.
struct ExpandedChildrenPanel: View {
    @Binding var vm: AccountCirclesViewModel
    @Binding var path: NavigationPath
    let parentAccount: Account
    let anchorY: CGFloat?

    // Временный визуальный дебаг закрытия панели (Developer Tools → тумблер) — рисует границу
    // panelGlobalFrame и точку draggableLocation прямо на экране, плюс логирует в консоль каждое
    // срабатывание закрытия и его причину, чтобы понять, почему панель закрывается "как будто
    // сама по себе".
    @AppStorage("debugPanelClose") private var debugPanelClose = false

    // Небольшая задержка перед тем, как задник панели начинает закрывать её при наведении —
    // без неё панель закрывалась бы сама в момент открытия: палец в этот момент ещё стоит там
    // же, где был родитель в основной сетке, а эта точка теперь накрыта задником (он поверх
    // всего), и задник немедленно посчитал бы это "вышли за пределы панели".
    @State private var backdropCanClose = false
    // Размер самой карточки панели (ДО .padding/.position) — из него в body аналитически
    // вычисляется panelGlobalFrame. Раньше пытались измерить итоговый глобальный фрейм через
    // .onGeometryChange, повешенный ПОСЛЕ .position(x:y:) — но .position() превращает view в
    // "невидимую рамку на весь доступный размер" для целей layout, и GeometryReader после него
    // всегда мерил эту невидимую полноразмерную рамку (весь экран), а не реальный размер
    // карточки — отсюда и был баг "красная зона на весь экран, включая хэдер".
    @State private var cardSize: CGSize = .zero

    private func close(reason: String, panelGlobalFrame: CGRect) {
        if debugPanelClose {
            accountCirclesViewLogger.debug("ExpandedChildrenPanel closing: \(reason) — panelGlobalFrame=\(String(describing: panelGlobalFrame)) draggableLocation=\(String(describing: vm.draggableLocation)) backdropCanClose=\(backdropCanClose)")
        }
        withAnimation { vm.closeExpandedPanel() }
    }

    var body: some View {
        GeometryReader { proxy in
            let overlayOriginY = proxy.frame(in: .global).minY
            let overlayOriginX = proxy.frame(in: .global).minX
            let localY = (anchorY ?? proxy.frame(in: .global).midY) - overlayOriginY
            let clampedY = min(max(localY, 80), proxy.size.height - 80)
            // Аналитический расчёт вместо измерения через GeometryReader ПОСЛЕ .position() —
            // см. комментарий у cardSize. Мы сами знаем формулу центрирования (x: центр экрана,
            // y: clampedY), поэтому просто подставляем размер карточки (cardSize, измеренный ДО
            // .position()) в неё.
            let panelGlobalFrame = CGRect(
                x: proxy.size.width / 2 - cardSize.width / 2 + overlayOriginX,
                y: clampedY - cardSize.height / 2 + overlayOriginY,
                width: cardSize.width,
                height: cardSize.height
            )

            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    close(reason: "tap on backdrop", panelGlobalFrame: panelGlobalFrame)
                }
                // Задник "выигрывает" hit-test везде, кроме самих дочерних кружков (они рисуются
                // поверх и хватают события первыми) — значит, если задник стал targeted, палец
                // сейчас вне панели (в т.ч. в пустых промежутках между кружками), и панель нужно
                // закрыть — ровно то самое "вышел за пределы панели".
                .dropDestination(for: DraggedAccount.self) { _, _ in false } isTargeted: { targeted in
                    guard targeted, backdropCanClose else { return }
                    close(reason: "native dropDestination targeted backdrop", panelGlobalFrame: panelGlobalFrame)
                }
                .task(id: parentAccount.id) {
                    backdropCanClose = false
                    try? await Task.sleep(for: .milliseconds(400))
                    backdropCanClose = true
                }
                .onChange(of: vm.draggableLocation) { _, newLocation in
                    guard backdropCanClose, let newLocation, panelGlobalFrame != .zero,
                          !panelGlobalFrame.contains(newLocation) else { return }
                    close(reason: "manual draggableLocation outside panelGlobalFrame", panelGlobalFrame: panelGlobalFrame)
                }
                .overlay {
                    if debugPanelClose {
                        Rectangle()
                            .strokeBorder(Color.red, lineWidth: 2)
                            .frame(width: panelGlobalFrame.width, height: panelGlobalFrame.height)
                            .position(
                                x: panelGlobalFrame.midX - overlayOriginX,
                                y: panelGlobalFrame.midY - overlayOriginY
                            )
                            .allowsHitTesting(false)
                        // Точные числа panelGlobalFrame прямо на экране — чтобы не гадать по
                        // виду рамки, а видеть, что реально захватывается.
                        Text("panelGlobalFrame: \(String(describing: panelGlobalFrame))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .position(x: proxy.size.width / 2, y: 100)
                            .allowsHitTesting(false)
                        if let draggableLocation = vm.draggableLocation {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 14, height: 14)
                                .position(
                                    x: draggableLocation.x - overlayOriginX,
                                    y: draggableLocation.y - overlayOriginY
                                )
                                .allowsHitTesting(false)
                        }
                    }
                }
                .overlay {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(parentAccount.childrenAccounts) { child in
                                DraggableAccountCircleItem(
                                    vm: $vm,
                                    account: child,
                                    path: $path,
                                    isAlreadyOpened: true
                                )
                                .frame(width: 80)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 140)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    // Измеряем размер карточки ЗДЕСЬ — до .position(). GeometryReader/
                    // onGeometryChange, повешенный ПОСЛЕ .position(x:y:), мерил бы не реальный
                    // размер карточки, а "невидимую рамку на весь доступный размер", в которую
                    // .position() оборачивает view для целей layout (отсюда был баг "красная зона
                    // на весь экран, включая хэдер" — раньше onGeometryChange стоял после
                    // .position()).
                    .background {
                        GeometryReader { cardProxy in
                            Color.clear
                                .onAppear { cardSize = cardProxy.size }
                                .onChange(of: cardProxy.size) { _, newValue in
                                    cardSize = newValue
                                }
                        }
                    }
                    .position(
                        x: proxy.size.width / 2,
                        y: clampedY
                    )
                }
        }
    }
}
