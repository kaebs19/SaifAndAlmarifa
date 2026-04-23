//
//  GameSoundManager.swift
//  SaifAndAlmarifa
//
//  Created by Mohammed Saleh on 15/04/2026.
//
//  Path: SaifAndAlmarifa/Utilities/Managers/GameSoundManager.swift
//  مدير الأصوات للمباراة (AVAudioPlayer) — يدعم تشغيل متوازي بدون قطع
//  SoundManager (SystemSounds) يبقى للأصوات العامة مثل المتجر/الدعوات.

import Foundation
import AVFoundation

final class GameSoundManager {

    // MARK: - Singleton
    static let shared = GameSoundManager()

    // MARK: - Config
    @MainActor var isMuted: Bool = false
    @MainActor var volume: Float = 0.8

    // MARK: - Internal
    private var players: [String: AVAudioPlayer] = [:]
    private let queue = DispatchQueue(label: "game.sound", qos: .userInitiated)

    // MARK: - Init
    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            // ambient: يسمح بتشغيل الأصوات حتى لو المستخدم في وضع silent
            // ويختلط مع موسيقى خلفية أخرى
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("⚠️ [GameSound] Audio session config failed: \(error)")
            #endif
        }
    }

    // MARK: - Public

    /// تشغيل صوت من enum
    @MainActor
    func play(_ sound: GameSound, loop: Bool = false, volumeOverride: Float? = nil) {
        play(resource: sound.rawValue, loop: loop, volumeOverride: volumeOverride)
    }

    /// تشغيل صوت Power-Up
    @MainActor
    func playPowerUp(_ powerUp: PowerUpIcon) {
        play(resource: powerUp.soundName)
    }

    /// إيقاف صوت معيّن (مفيد للـ loop مثل heartbeat)
    @MainActor
    func stop(_ sound: GameSound) {
        players[sound.rawValue]?.stop()
        players[sound.rawValue] = nil
    }

    /// إيقاف كل الأصوات (عند إغلاق الشاشة أو mute)
    @MainActor
    func stopAll() {
        for (_, player) in players { player.stop() }
        players.removeAll()
    }

    // MARK: - Private
    private func play(resource: String, loop: Bool = false, volumeOverride: Float? = nil) {
        Task { @MainActor in
            guard !self.isMuted else { return }

            guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else {
                #if DEBUG
                print("⚠️ [GameSound] File not found: \(resource).mp3")
                #endif
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volumeOverride ?? self.volume
                player.numberOfLoops = loop ? -1 : 0
                player.prepareToPlay()
                player.play()
                self.players[resource] = player  // retain
            } catch {
                #if DEBUG
                print("⚠️ [GameSound] Play failed \(resource): \(error)")
                #endif
            }
        }
    }
}
