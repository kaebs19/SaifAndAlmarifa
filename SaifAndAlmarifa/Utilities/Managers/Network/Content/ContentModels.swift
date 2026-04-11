//
//  ContentModels.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 09/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/Network/Content/ContentModels.swift

import Foundation

// MARK: - أنواع صفحات المحتوى
enum ContentPageKey: String, Identifiable {
    var id: String { rawValue }
    case privacyPolicy = "privacy_policy"
    case termsOfUse    = "terms_of_use"
    case aboutApp      = "about_app"
    case contactUs     = "contact_us"
}

// MARK: - استجابة محتوى نصي (سياسة/شروط/حول)
struct ContentPageData: Decodable {
    let key: String
    let value: ContentValue
}

struct ContentValue: Decodable {
    let content: String?
    // حقول اتصل بنا
    let email: String?
    let phone: String?
    let website: String?
    let twitter: String?
    let instagram: String?
}
