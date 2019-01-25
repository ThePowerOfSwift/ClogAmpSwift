//
//  PlayerDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//  MIT License
//

import AppKit

protocol PlayerDelegate: class {
    func loadSong(song: Song)
    func getSong() -> Song?
    func play()
    func pause()
    func stop()
    func increaseSpeed()
    func decreaseSpeed()
    func handlePositionSelected(_ index: Int)
}
