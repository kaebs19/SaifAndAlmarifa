//
//  SoundManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/SoundManager.swift
//  تأثيرات صوتية — تستخدم System Sounds (جاهزة بدون ملفات إضافية)

import Foundation
import AudioToolbox

enum SoundManager {

    // MARK: - System Sound IDs (iOS built-in)
    enum Effect {
        case playerJoined      // نغمة قصيرة للانضمام
        case playerLeft        // نغمة منخفضة للمغادرة
        case roomFull          // تنبيه نجاح عند امتلاء الغرفة
        case matchFound        // نجاح طويل
        case countdown         // tick كل ثانية
        case messageReceived   // tap خفيف

        var systemId: SystemSoundID {
            switch self {
            case .playerJoined:    return 1336    // tink
            case .playerLeft:      return 1322    // quiet
            case .roomFull:        return 1025    // fanfare-ish
            case .matchFound:      return 1025
            case .countdown:       return 1104    // keyboard tap
            case .messageReceived: return 1003    // received
            }
        }
    }

    // MARK: - Public
    static func play(_ effect: Effect) {
        AudioServicesPlaySystemSound(effect.systemId)
    }

    /// صوت + اهتزاز (معاً)
    static func playWithHaptic(_ effect: Effect) {
        AudioServicesPlayAlertSound(effect.systemId)
    }
}
