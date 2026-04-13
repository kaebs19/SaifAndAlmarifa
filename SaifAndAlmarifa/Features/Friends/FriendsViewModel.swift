//
//  FriendsViewModel.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 14/04/2026.
//

import Foundation
import Combine

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var requests: [FriendRequest] = []
    @Published var searchResults: [FriendSearchResult] = []
    @Published var searchText = ""
    @Published var friendCodeText = ""
    @Published var isLoading = false
    @Published var selectedTab = 0 // 0=أصدقاء, 1=طلبات, 2=بحث

    private let network: NetworkClient = NetworkManager.shared
    private let toast = ToastManager.shared

    func onAppear() async {
        isLoading = true; defer { isLoading = false }
        async let f = network.request(FriendsEndpoint.List())
        async let r = network.request(FriendsEndpoint.Requests())
        friends = (try? await f) ?? []
        requests = (try? await r) ?? []
    }

    func search() async {
        guard searchText.count >= 2 else { return }
        searchResults = (try? await network.request(FriendsEndpoint.Search(query: searchText))) ?? []
    }

    func sendRequest(to userId: String) async {
        do {
            try await network.requestVoid(FriendsEndpoint.SendRequest(userId: userId))
            HapticManager.success(); toast.success("تم إرسال الطلب")
        } catch { toast.error("فشل إرسال الطلب") }
    }

    func addByCode() async {
        guard !friendCodeText.isEmpty else { return }
        do {
            try await network.requestVoid(FriendsEndpoint.AddByCode(code: friendCodeText))
            HapticManager.success(); toast.success("تم إرسال الطلب"); friendCodeText = ""
        } catch let e as APIError { toast.error(e.errorDescription ?? "فشل") }
        catch { toast.error(error.localizedDescription) }
    }

    func accept(_ req: FriendRequest) async {
        do {
            try await network.requestVoid(FriendsEndpoint.Accept(id: req.friendshipId))
            requests.removeAll { $0.id == req.id }; HapticManager.success(); toast.success("تمت الموافقة")
            await onAppear()
        } catch { toast.error("فشلت الموافقة") }
    }

    func reject(_ req: FriendRequest) async {
        do {
            try await network.requestVoid(FriendsEndpoint.Reject(id: req.friendshipId))
            requests.removeAll { $0.id == req.id }; toast.info("تم الرفض")
        } catch { toast.error("فشل الرفض") }
    }

    func remove(_ friend: Friend) async {
        guard let fid = friend.friendshipId else { return }
        do {
            try await network.requestVoid(FriendsEndpoint.Remove(id: fid))
            friends.removeAll { $0.id == friend.id }; toast.info("تمت الإزالة")
        } catch { toast.error("فشلت الإزالة") }
    }
}
