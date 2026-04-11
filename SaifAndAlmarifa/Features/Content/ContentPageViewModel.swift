//
//  ContentPageViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Features/Content/ContentPageViewModel.swift

import Foundation
import Combine

// MARK: - ViewModel مشترك لكل صفحات المحتوى
@MainActor
final class ContentPageViewModel: ObservableObject {

    // MARK: - State
    @Published var content: ContentPageData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let service = ContentService.shared

    // MARK: - جلب المحتوى
    func load(_ key: ContentPageKey) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            content = try await service.getPage(key)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
