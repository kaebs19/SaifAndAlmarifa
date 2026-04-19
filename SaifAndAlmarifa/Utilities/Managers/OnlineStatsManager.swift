//
//  OnlineStatsManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/OnlineStatsManager.swift
//  متابعة عدد اللاعبين المتصلين (global) — عبر Socket
//  السيرفر يبث "stats:online" دورياً (كل 30 ثانية مثلاً)

import Foundation
import Combine
import SwiftUI

@MainActor
final class OnlineStatsManager: ObservableObject {

    // MARK: - Singleton
    static let shared = OnlineStatsManager()

    // MARK: - Published
    @Published private(set) var onlineCount: Int = 0

    // MARK: - Dependencies
    private let socket = AppSocketManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        socket.onOnlineCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                // أنيميشن سلس للتغيّر
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.onlineCount = count
                }
            }
            .store(in: &cancellables)
    }
}

