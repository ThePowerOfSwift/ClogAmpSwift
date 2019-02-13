//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import AppKit

class MainView: NSViewController {
    
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    var sSortBy        = "title"
    var bSortAsc       = true
    
    weak var playerView: PlayerView?
    weak var songTableView: SongTableView?
    weak var positionTableView: PositionTableView?
    
    override func viewWillDisappear() {
        self.playerView?.getSong()?.saveChanges()
    }
    
    override func keyDown(with event: NSEvent) {
        
//        let keyPressed = (event.characters ?? "").lowercased()
//        print("Key: \(keyPressed) - Code: \(event.keyCode)")
        
        switch event.keyCode {
            case 30: // +
                self.playerView!.increaseSpeed()
            case 44: // -
                self.playerView!.decreaseSpeed()
            case 45: // N
                self.playerView!.resetSpeed()
            case 35: // P
                self.playerView!.play()
            case 1: // S
                self.playerView!.stop()
            case 49: // Space
                self.playerView!.pause()
            case 3: // F
                self.playerView!.jump(5)
//            case 48: // Tab
//                
            case 11: // B
                self.playerView!.jump(-5)
            default:
                self.interpretKeyEvents([event])
        }

    }
    
    override func viewDidAppear() {
        self.playerView        = self.children[0] as? PlayerView
        self.songTableView     = self.children[1] as? SongTableView
        self.positionTableView = self.children[2] as? PositionTableView
        
        self.playerView?.mainView        = self
        self.songTableView?.mainView     = self
        self.positionTableView?.mainView = self
        
        super.viewDidAppear()
    }
    
    @IBAction func play(_ sender: AnyObject) {
        self.playerView?.play()
    }
    
    @IBAction func pause(_ sender: AnyObject) {
        self.playerView?.pause()
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        self.playerView?.stop()
    }
    
    @IBAction func increaseSpeed(_ sender: AnyObject) {
        self.playerView?.increaseSpeed()
    }
    
    @IBAction func decreaseSpeed(_ sender: AnyObject) {
        self.playerView?.decreaseSpeed()
    }
    
    @IBAction func resetPlayerSpeed(_ sender: AnyObject) {
        self.playerView?.resetSpeed()
    }
    
    @IBAction func playerForward(_ sender: AnyObject) {
        self.playerView?.jump(5)
    }
    
    @IBAction func playerBack(_ sender: AnyObject) {
        self.playerView?.jump(5)
    }
    
    @IBAction func focusFilterField(_ sender: Any) {
        self.songTableView?.searchField.becomeFirstResponder()
    }
    
    /*
     --- Store ---
     
     UserDefaults.standard.set(true, forKey: "Key") //Bool
     UserDefaults.standard.set(1, forKey: "Key")  //Integer
     UserDefaults.standard.set("TEST", forKey: "Key") //setObject
     
     --- Retrieve ---
     
     UserDefaults.standard.bool(forKey: "Key")
     UserDefaults.standard.integer(forKey: "Key")
     UserDefaults.standard.string(forKey: "Key")
     
     --- Remove ---
     
     UserDefaults.standard.removeObject(forKey: "Key")
     
     --- Remove all Keys ---
     
     if let appDomain = Bundle.main.bundleIdentifier {
     UserDefaults.standard.removePersistentDomain(forName: appDomain)
     }
     
    */
    
}

extension MainView: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.positionTableView?.visible = false
        
        if(tabViewItem?.identifier as? String == "positions"){
            if(tabViewItem?.tabState == NSTabViewItem.State.selectedTab){
                self.positionTableView?.visible = true
            }
        }
    }
}