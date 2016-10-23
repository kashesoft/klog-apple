/*
 * Copyright (C) 2016 Andrey Kashaed
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import MessageUI

class FirstViewController: UIViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onPushFault(_ sender: UIButton) {
        Log.fault(message: "It is a fault message!")
    }
    
    @IBAction func onPushError(_ sender: UIButton) {
        Log.error(message: "It is a error message!")
    }
    
    @IBAction func onPushWarn(_ sender: UIButton) {
        Log.warn(message: "It is a warn message!")
    }
    
    @IBAction func onPushInfo(_ sender: UIButton) {
        Log.info(message: "It is a info message!")
    }
    
    @IBAction func onPushDebug(_ sender: UIButton) {
        Log.debug(message: "It is a debug message!")
    }
    
    @IBAction func onPushUtil(_ sender: UIButton) {
        Log.util(message: "It is a util message!")
    }
    
    @IBAction func onStartSystemCheck(_ sender: UIButton) {
        Log.setSources(Source.app | Source.cpu | Source.ram)
    }
    
    @IBAction func onStopSystemCheck(_ sender: UIButton) {
        Log.setSources(Source.app)
    }

    @IBAction func onPushSendLog(_ sender: UIButton) {
        MyLog.shared.sendByMail(controller: self, delegate: self)
    }
    
    @IBAction func onPushClearLog(_ sender: UIButton) {
        MyLog.shared.clear()
    }
    
    @IBAction func onPushRemoveLog(_ sender: UIButton) {
        MyLog.shared.remove()
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print("mail error = \(error)")
        controller.dismiss(animated: true)
    }

}
