//
//  MessagesViewController.swift
//  MessagesExtension
//
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController, UITextFieldDelegate {
    
    var savedConversation: MSConversation?
    
    @IBOutlet weak var analyzerButton: UIButton!
    @IBAction func toggleAnalyzer(_ sender: Any) {
        self.requestPresentationStyle(.expanded)
    }
    
    @IBAction func sendAnalyzedMessage(_ sender: Any) {
        if (analyzedText.text != "") {
            
            let message = MSMessage()
            //layout that the message object will show
            let layout = MSMessageTemplateLayout()

                layout.caption = analyzedText.text
            //set the layout
            message.layout = layout

            //save the message in the current conversation context
            self.savedConversation?.insert(message,
                                           completionHandler: { (err) in

                                            print("ERROR \(err.debugDescription)")
            })

            if self.presentationStyle == .expanded {
                self.requestPresentationStyle(.compact)
            }
        }
    }
    @IBOutlet weak var analyzedText: UITextField!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func handleChangeText(_ sender: UITextField) {
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let randomNum:UInt32 = arc4random_uniform(100)
        let input: String! = sender.text
        if (input.characters.count > 2 && input.characters.count % 3 == 0) {
            let dict = [
                "documents": [
                    [
                        "language": "en",
                        "id": String(randomNum),
                        "text": input
                    ]
                ]
            ] as [String: Any]
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict) {
                let url = NSURL(string: "https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/sentiment")!
                let request = NSMutableURLRequest(url: url as URL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.addValue("09179f3ca9324a7eb77fc85ea4a9e892", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request as URLRequest){ data, response, error in
                    if error != nil{
                        print(error?.localizedDescription)
                        return
                    }
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                        let docs = json?["documents"] as! NSArray
                        let scoreAndId = docs[0] as! NSDictionary
                        let score = scoreAndId["score"] as! Float
                        if score != nil {
                            print("score")
                            DispatchQueue.main.async(execute: {
                                self.SentimentTracker.progress = score
                                if (Float(score) < 0.25) {
                                    self.SentimentTracker.progressTintColor = UIColor(red:0.72, green:0.11, blue:0.11, alpha:1.0)
                                    self.sendButton.tintColor = UIColor(red:0.72, green:0.11, blue:0.11, alpha:1.0)
                                } else if (Float(score) < 0.50) {
                                    self.SentimentTracker.progressTintColor = UIColor(red:0.96, green:0.49, blue:0.00, alpha:1.0)
                                    self.sendButton.tintColor = UIColor(red:0.96, green:0.49, blue:0.00, alpha:1.0)
                                } else if (Float(score) < 0.75) {
                                    self.SentimentTracker.progressTintColor = UIColor(red:0.98, green:0.75, blue:0.18, alpha:1.0)
                                    self.sendButton.tintColor = UIColor(red:0.98, green:0.75, blue:0.18, alpha:1.0)
                                } else if (Float(score) <= 1) {
                                    self.SentimentTracker.progressTintColor = UIColor(red:0.11, green:0.37, blue:0.13, alpha:1.0)
                                    self.sendButton.tintColor = UIColor(red:0.11, green:0.37, blue:0.13, alpha:1.0)
                                }
                            })
                        }
                    } catch let error as NSError {
                        print(error)
                    }
                }
                task.resume()
            }
        }
    }
    
    @IBOutlet weak var SentimentTracker: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SentimentTracker.transform = SentimentTracker.transform.scaledBy(x: 1, y: 3)

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        savedConversation = conversation
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        switch presentationStyle{
        case MSMessagesAppPresentationStyle.compact:
            self.analyzerButton.isHidden = false
            
            
        case MSMessagesAppPresentationStyle.expanded:
            self.analyzerButton.isHidden = true
        }
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }

}
