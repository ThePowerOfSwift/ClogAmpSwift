//
//  PlayerView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//  MIT License
//

import AppKit
import AVFoundation

class PlayerView: ViewController {
    
    weak var mainView: MainView?
    
    /*
     * Outlets
     */
    
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var lengthField: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var volumeText: NSTextField!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var speedText: NSTextField!
    @IBOutlet weak var timeSlider: NSSlider!
    
    
    /*
     * Properties
     */
    var observer: Any?
    
    var currentSong: Song? {
        willSet(oNewSong) {
            self.currentSong?.saveChanges()
        }
        didSet {
            self.stop()
            self.deregisterPeriodicUpdates()
            self.currentSong!.loadPositions()
            self.avPlayer = Player(song: self.currentSong!)
            self.registerPeriodicUpdate()
            
            //Update UI
            //Text of selected song
            let title = self.currentSong!.getValueAsString("title")
            let duration = self.currentSong!.getValueAsString("duration")
            
            self.descriptionField.stringValue = "\(title) (\(duration))"
            //Speed, Volume, Time
            self.tick(single: true)
        }
    }
    
    var avPlayer: Player?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
     * General Stuff
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
//
//    override var representedObject: Any? {
//        didSet {
//            // Update the view, if already loaded.
//        }
//    }
    
    /*
     * Update related stuff
     */
    func registerPeriodicUpdate() {
        self.avPlayer?.addPeriodicTimeObserver() {
            [weak self] time in
            //Do stuff
            self?.updateTime(Double(time.value / Int64(time.timescale)))
            self?.updatePositionTable(single: false)
        }
    }
    
    func deregisterPeriodicUpdates() {
        self.avPlayer?.removeTimeObserver()
    }
    
    func tick(single: Bool, updateSongTab: Bool = false, updatePositionTab: Bool = true) {
        //Do Some Stuff while the track is playing to update the UI...
        self.updateTime()
        
        if(updatePositionTab){
            self.updatePositionTable(single: single)
        }
        
        if(single){
            self.updateRate()
            self.updateVolume()
        }
        
        if(updateSongTab){
            self.updateSongTable()
        }
        
//        //re-trigger the update while the player is playing
//        if(!single){
//            if(self.avPlayer?.isPlaying() ?? false){
//                self.delayWithSeconds(0.1) {
//                    self.tick(single: false)
//                }
//            }
//        }
    }
    
    func updateRate(){
        self.avPlayer?.updateRate()
        
        self.speedSlider.integerValue = self.currentSong?.speed ?? 0
        self.speedText.stringValue    = "\(self.currentSong?.speed ?? 0)%"
    }
    func updateTime(_ seconds: Double = -1) {
        var percent: Int = 0;
        if(self.currentSong != nil) {
            //Time Field: e.g. 3:24
            var currentTime = seconds
            if(currentTime == -1){
                currentTime = self.avPlayer?.getCurrentTime() ?? 0
            }
            
            let durMinutes = Int(Float(currentTime / 60).rounded(.down))
            let durSeconds = Int(Double(currentTime).truncatingRemainder(dividingBy: 60))

            self.lengthField.stringValue = durSeconds >= 10 ? "\(durMinutes):\(durSeconds)" : "\(durMinutes):0\(durSeconds)"
            
            //Position Slider
            let duration = self.avPlayer?.getDuration() ?? 0
            if(duration > 0.0){
                percent = lround(Double(currentTime / duration * 10000))
            }
        }
        
        self.timeSlider.integerValue = percent
    }
    
    func updateVolume(){
        self.avPlayer?.updateVolume()
        
        self.volumeSlider.integerValue = Int(self.currentSong?.volume ?? 100)
        self.volumeText.stringValue    = "\(self.currentSong?.volume ?? 100)%"
    }
    
    func updatePositionTable(single: Bool){
        self.mainView?.positionTableView?.refreshTable(single: single)
    }
    
    func updateSongTable(){
        self.mainView?.songTableView?.refreshTable()
    }
    
    /*
     * Actions
     */
    @IBAction func play(_ sender: Any) {
        self.play()
    }
    
    @IBAction func pause(_ sender: Any) {
        self.pause()
    }
    
    @IBAction func stop(_ sender: Any) {
        self.stop()
    }
    
    @IBAction func speedChanged(_ sender: NSSlider) {
        let int = sender.integerValue
        self.currentSong?.speed = int
        self.updateRate()
    }
    
    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.currentSong?.volume = UInt(sender.integerValue)
        self.updateVolume()
    }
    
    @IBAction func timeChanged(_ sender: NSSlider) {
//        let date = Date()
//        let calendar = Calendar.current
//        let hour = calendar.component(.hour, from: date)
//        let minutes = calendar.component(.minute, from: date)
//        let seconds = calendar.component(.second, from: date)
//        let nseconds = calendar.component(.nanosecond, from: date)
//        
//        print("timeChanged \(hour):\(minutes):\(seconds):\(nseconds)")
        
        self.deregisterPeriodicUpdates()
        let v1 = Double(sender.integerValue) / sender.maxValue
        let duration = self.avPlayer?.getDuration() ?? 0
        let time = duration * v1
        self.avPlayer?.seek(seconds: time){
            _ in
            self.updateTime()
            self.registerPeriodicUpdate()
        }
    }

    func handlePositionSelected(_ index: Int) {
        //Check the index is in range
        if(index == -1 || self.currentSong?.positions.count ?? -1 <= index){
            return
        }
        
        if let oPosition = self.currentSong?.positions[index] {
            self.avPlayer?.seek(seconds: Float64(oPosition.time / 1000)){
                _ in
                self.tick(single: true)
            }
        }
    } //func handlePositionSelected
    
    func loadSong(song: Song) {
        self.currentSong = song
    }
    func getSong() -> Song? {
        return self.currentSong
    }
    func play() {
        if(self.avPlayer?.isPlaying() ?? false){
            //If play is called while the song is playing, it should start over
            self.stop()
        }
        
//        self.avPlayer?.rate = 1.0
        self.avPlayer?.play()
        //Start the Update of the UI every .xxx seconds
        self.tick(single: false)
        
    }
    func pause() {
        if(self.avPlayer?.isPlaying() ?? false){
            self.avPlayer?.pause()
        }else{
            self.play()
        }
    }
    func stop() {
        self.avPlayer?.stop()
        self.tick(single: true)
    }
    func jump(_ seconds: Int) {
        self.avPlayer?.jump(seconds)
        self.updateTime()
        
        self.tick(single: true, updateSongTab: false, updatePositionTab: false)
    }
    func increaseSpeed() {
        if(self.currentSong?.speed == 40){
            return
        }
        self.currentSong?.speed += 1
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
    func decreaseSpeed() {
        if(self.currentSong?.speed == -40){
            return
        }
        self.currentSong?.speed -= 1
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
    func resetSpeed() {
        self.currentSong?.speed = 0
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
}