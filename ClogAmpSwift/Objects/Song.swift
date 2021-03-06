//
//  Song.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  MIT License
//

import Foundation

class Song {
    
    //  Properties
    var path: URL
    var filePathAsUrl: URL
    var title: String { didSet { self.titleChanged = true } }
    var artist: String { didSet { self.artistChanged = true } }
    var level: String { didSet { self.levelChanged = true } }
    var duration: Int
    var speed: Int { didSet { self.speedChanged = true } }
    var bpm: Int { didSet { self.bpmChanged = true } }
    var volume: Int { didSet { self.volumeChanged = true } }
    var hasPositions: Bool
    var positions: Array<Position> { didSet {
        if self.positions.count > 0 {
            self.hasPositions = true
        }else{
            self.hasPositions = false
        }
    } }
    var waitBeats: Int { didSet { self.waitBeatsChanged = true } }
    
    var titleChanged: Bool = false
    var artistChanged: Bool = false
    var levelChanged: Bool = false
    var speedChanged: Bool = false
    var bpmChanged: Bool = false
    var volumeChanged: Bool = false
    var positionsChanged: Bool = false
    var waitBeatsChanged: Bool = false
    
    var songChanged: Bool {
        return self.titleChanged     ||
               self.artistChanged    ||
               self.levelChanged     ||
               self.speedChanged     ||
               self.bpmChanged       ||
               self.volumeChanged    ||
               self.positionsChanged ||
               self.waitBeatsChanged
    }
    
    //MARK: Static Stuff
    static var songDict: Dictionary<String, Song> = [:] //Empty dictionary
    static func retrieveSong(path: URL) -> Song{        
        let stringPath = path.absoluteString.removingPercentEncoding!
        if let song = songDict[stringPath] {
            song.readBasicInfo()
            return song
        }else{
            let newSong = Song(path: path)
            songDict[stringPath] = newSong
            return newSong
        }
    }
    
    // Initializer
    init(path: URL) {
        //Initial Values
        self.path          = path
        if path.isFileURL == false{
            self.filePathAsUrl = URL(fileURLWithPath: self.path.absoluteString.removingPercentEncoding!)
        }else{
            self.filePathAsUrl = path
        }
        self.title           = path.deletingPathExtension().lastPathComponent
        self.artist          = ""
        self.level           = ""
        self.duration        = 0
        self.speed           = 0
        self.bpm             = 0
        self.volume          = 100
        self.hasPositions    = false
        self.positions       = []
        self.waitBeats       = 0
        
        self.readBasicInfo()
    } //init
    
    func readBasicInfo() {
        let stringPath = self.getValueAsString("path")
        
        //Read ID3 Info
        if let oId3Wrapper = Id3Wrapper(stringPath) {
            let map = oId3Wrapper.readBasicInfo()
            
            //Title
            self.title = map?.value(forKey: "title") as? String ?? ""
            if self.title == "" {
                self.title = self.path.deletingPathExtension().lastPathComponent
            }
            
            //Artist
            self.artist = map?.value(forKey: "artist") as? String ?? ""
            
            //Read Tempo
            if let sTempo = map?.value(forKey: "lastTempo") as? String{
                if(sTempo != ""){
                    if let dTempo = Double(sTempo) {
                        self.speed = lround(dTempo);
                    } else {
                        self.speed = 0;
                    }
                }
            }
            
            //Duration
            self.duration = Int(map?.value(forKey: "duration") as? Int ?? 0)
            
            //Read BPM
            self.bpm = Int(map?.value(forKey: "bpm") as? Int ?? 0)
            
            //Read Level
            self.level = map?.value(forKey: "cloggingLevel") as? String ?? ""
            
            //Has Positions
            self.hasPositions    = map?.value(forKey: "hasPositions") as? Bool ?? false
            
            //Read Wait Beats
            self.waitBeats = Int(map?.value(forKey: "waitBeats") as? Int ?? 0)
        }
    }
    
    func getValueAsString(_ property: String) -> String {
        switch property {
        case "path":
            return self.path.absoluteString.removingPercentEncoding!
        case "title":
            return self.title
        case "artist":
            return self.artist
        case "level":
            return self.level
        case "duration":
            let durMinutes = Int(Float(self.duration / 60).rounded(.down))
            let durSeconds = Int(Double(self.duration).truncatingRemainder(dividingBy: 60))
            
            let pntTime = durSeconds >= 10 ? "\(durMinutes):\(durSeconds)" : "\(durMinutes):0\(durSeconds)"
            return "\(pntTime)"
        case "speed":
            return "\(self.speed) %"
        case "bpm":
            return "\(self.bpm)"
        case "volume":
            return "\(self.volume)"
        case "hasPositions":
            return self.hasPositions ? "✓" : ""
        case "fileName":
            return self.path.lastPathComponent
        case "waitBeats":
            return "\(self.waitBeats)"
        default:
            return ""
        }
    } //func getValueAsString
    
    func getValueToCompare(_ property: String) -> Any {
        switch property {
        case "path":
            return self.path.absoluteString.removingPercentEncoding!
        case "title":
            return self.title
        case "artist":
            return self.artist
        case "level":
            return self.level
        case "duration":
            return self.duration
        case "speed":
            return self.speed
        case "bpm":
            return self.bpm
        case "volume":
            return self.volume
        case "hasPositions":
            return self.hasPositions ? "a" : "b"
        case "waitBeats":
            return self.waitBeats
        default:
            return ""
        }
    } //func getValueAsString
    
    func determineBassBPM( callback: @escaping (Float) -> Void ) {
        DispatchQueue.global(qos: .background).async {
            var bpm = BassWrapper.determineBPM(self.getValueAsString("path"), length: Int32(self.duration))
            
            var prefBpmUpperBound = UserDefaults.standard.integer(forKey: "prefBpmUpperBound")
            if prefBpmUpperBound == 0 {
                prefBpmUpperBound = 140
            }
            
            var prefBpmLowerBound = UserDefaults.standard.integer(forKey: "prefBpmLowerBound")
            if prefBpmLowerBound == 0 {
                prefBpmLowerBound = 70
            }
            
            if bpm > Float(prefBpmUpperBound) {
                bpm /= 2
            }else if bpm < Float(prefBpmLowerBound) {
                bpm *= 2
            }
            
            if bpm < 0 {
                bpm = 0
            }
            self.bpm = Int(lround(Double(bpm)))
            
            callback(bpm)
        }
    }
    
    func loadPositions(_ force: Bool = true) {
        if(force){
            //Force read? => Free previously read positions
            self.positions = []
            self.positionsChanged = false
            self.hasPositions = false
        }
        
        if let oId3Wrapper = Id3Wrapper(self.getValueAsString("path")){
            var sPositions = ""
            var count = 0
            while sPositions == "" && count < 10 {
                count += 1
                sPositions = oId3Wrapper.loadPositions()
                if(sPositions != ""){
                    //Split string into single lines ($LS = Line Separator)
                    let aLines = sPositions.components(separatedBy: "$LS")
                    
                    for line in aLines{
                        //Split string into single cells ($CS = Cell Separator)
                        let aCells = line.components(separatedBy: "$CS")
                        self.positions.append(Position(name: aCells[0], comment: aCells[1], jumpTo: aCells[2], time: (UInt(aCells[3]) ?? 0)))
                        self.hasPositions = true
                    }
                    
                    self.positionsChanged = false
                }
            }
        }

    } //func loadPositions
    
    func saveChanges() {
        if(!self.songChanged){ return; }
        
        //Save ID3 Info
        if let oId3Wrapper = Id3Wrapper(self.getValueAsString("path")){
            //-----------------------
            //------- Title ---------
            //-----------------------
            if(self.titleChanged){
                oId3Wrapper.saveTitle(self.title)
            }
            //-----------------------
            //------- Artist --------
            //-----------------------
            if(self.artistChanged){
                oId3Wrapper.saveArtist(self.artist)
            }
            //-----------------------
            //------- Level ---------
            //-----------------------
            if(self.levelChanged){
                oId3Wrapper.saveUserText("CloggingLevel", sValue: self.level)
            }
            //-----------------------
            //------- Speed ---------
            //-----------------------
            if(self.speedChanged){
                oId3Wrapper.saveUserText("LastTempo", sValue: "\(self.speed)")
            }
            //-----------------------
            //-------- BPM ----------
            //-----------------------
            if(self.bpmChanged){
                oId3Wrapper.removeAllBpms()
                oId3Wrapper.saveBPM(Int32(self.bpm))
            }
//            if(self.volumeChanged){
//
//            }
            //-----------------------
            //------ Positions ------
            //-----------------------
            if(self.positionsChanged){
                //Make sure they're in order
                self.sortPositions()
                
                var posString = ""
                
                //Prepare for the id3 wrapper
                for position in self.positions {
                    if(posString != ""){
                        posString.append("$LS") //$LS = Line Seperator
                    }
                    
                    posString.append(position.name)
                    posString.append("$CS") //$CS = Cell Seperator
                    posString.append(position.comment)
                    posString.append("$CS") //$CS = Cell Seperator
                    posString.append(position.jumpTo)
                    posString.append("$CS") //$CS = Cell Seperator
                    posString.append("\(position.time)")
                }
                
                oId3Wrapper.savePositions(posString)
            }
            //-----------------------
            //----- Wait Beats ------
            //-----------------------
            if(self.waitBeatsChanged){
                oId3Wrapper.saveUserText("CloggingBeatsWait", sValue: "\(self.waitBeats)")
            }
            
            //Reset change flags
            self.titleChanged     = false
            self.artistChanged    = false
            self.levelChanged     = false
            self.speedChanged     = false
            self.bpmChanged       = false
            self.volumeChanged    = false
            self.positionsChanged = false
            self.waitBeatsChanged = false
        }
    }
    
    func songFileExists() -> Bool {
        do {
            if try self.filePathAsUrl.checkResourceIsReachable() {
                return true
            }
        } catch {}
        
        return false
//        FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
    }
    
    func sortPositions() {
        self.positions.sort(by: { return $0.time < $1.time })
    }
}
