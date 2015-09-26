//
//  PassportTableViewController.swift
//  lock
//
//  Created by Richard on 2015/9/5.
//  Copyright (c) 2015年 Richard. All rights reserved.
//

import UIKit
import AVFoundation
import ILocky

class PassportTableViewController: UITableViewController, ILockyEventDelegate {
    var iLockyManager:ILockyBLEManager?=nil
    var soundUsePassport:NSURL?=nil
    var soundNotCloseEnough:NSURL?=nil
    var audioPlayer:AVAudioPlayer?=nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ILockyPassport.initialize()
        ILockyPassport.removeAllInvalidPassports()
        
        /** CAUTION: any passport should be genetered in our global server.
         ** this iLocky passport(key) generator is only for testing. it will be removed in near future.
         ********************************************************************************************/
        let passport = ILockyPassport.Builder()
            .setILockyId("54510016")
            .setDeviceId(ILockyPassport.getDeviceUuid())
            .setActionType(ILockyPassport.ACTION_TYPE_LOW_SECURITY_OPEN)
            .setStartTime(Int64(NSDate().timeIntervalSince1970*1000))
            .setEndTime(Int64(NSDate(timeIntervalSinceNow:36000).timeIntervalSince1970*1000))
            .setTimes(0)
            .setRevokePast(true)
        /********************************************************************************************/

        ILockyPassport.importPassport(passport, error: nil)
        ILocky.iLockyBLEManager.iLockyEventDelegate=self
        soundUsePassport=NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("open", ofType: "mp3")!)
        soundNotCloseEnough=NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("notclose", ofType: "wav")!)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onPassportUsed(passport:ILockyPassport) {
        var i=0
        self.tableView.reloadData()
        for p in ILockyPassport.getAlliLockyPassports() { //check which passport is used
            if p.isSame(passport) {
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) {
                    if let view = cell.viewWithTag(0) {
                        AFViewShaker(view: view).shake() // shake animation
                    }
                }
                  break
            }
            i++
        }
    }
    func onILockyAccessSuccess(passport:ILockyPassport) { // when successfully use iLocky passport
        audioPlayer=try? AVAudioPlayer(contentsOfURL: soundUsePassport!)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    func onILockyAccessFail(passport:ILockyPassport) { // when fail to use iLocky passport(eg. ble communication error, etc.)
        
    }
    func onNotCloseEnough() { // when smart phone is not close enough to iLocky device , play the warning sound
        audioPlayer=try? AVAudioPlayer(contentsOfURL: soundNotCloseEnough!)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()

    }
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return ILockyPassport.getAlliLockyPassports().count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LabelCell", forIndexPath: indexPath) 
        if let leadingColor = cell.viewWithTag(10) {
            if(ILockyPassport.getAlliLockyPassports()[indexPath.item].isValid()) {
                leadingColor.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            } else {
                leadingColor.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            }
            
        }
        let passportName = cell.viewWithTag(1) as! UILabel
        let iLockyID = cell.viewWithTag(2) as! UILabel
        
        passportName.text = ILockyPassport.getAlliLockyPassports()[indexPath.item].getPassportName()
        iLockyID.text = ILockyPassport.getAlliLockyPassports()[indexPath.item].getILockyID()
        if let times = cell.viewWithTag(3) as? UILabel {
            times.text = String(ILockyPassport.getAlliLockyPassports()[indexPath.item].getTimes())
        }
        let limit = ILockyPassport.getAlliLockyPassports()[indexPath.item].getTimesLimit()
        if let timesLimit = cell.viewWithTag(4) as? UILabel {
            timesLimit.text = limit==0 ? ("∞"):String(limit)
        }

        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // do nothing, just shake animation for that row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let view = tableView.cellForRowAtIndexPath(indexPath)?.viewWithTag(0) {
            AFViewShaker(view: view).shake()
        }
        let row = indexPath.row
        print("Row :\(row) clicked", terminator: "")
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            ILockyPassport.removePassport(ILockyPassport.getAlliLockyPassports()[indexPath.row])
            ILockyPassport.flush()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
