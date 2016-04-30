//
//  InterfaceController.swift
//  StudyBox Watch App Extension
//
//  Created by Kacper Cz on 11.04.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//

import WatchKit
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var detailLabel: WKInterfaceLabel!
    
    let titleTextNotAvailable = "Nie można rozpocząć testu"
    let titleTextSuccess = "👍"
    let titleTextFailure = "👎"
    
    let detailTextNotAvailable = "Nie zostały wybrane żadne talie do synchronizacji z zegarkiem lub nie zostały one jeszcze zsynchronizowane."
    let detailTextError = "Błąd w otrzymanych danych. Zsynchronizuj talie ponownie."
    let detailTextSuccess = "Masz dobrą pamięć!"
    let detailTextFailure = "Następnym razem się uda."
    
    var storedFlashcards = [WatchFlashcard]()
    
    var userAnswer: Bool?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        WatchManager.sharedManager.startSession()
        updateStoredFlashcards()
        updateButtonAndLabels()
    }
    
    override func willActivate() {
        super.willActivate()
        
        if let userAnswer = userAnswer {
            titleLabel.setHidden(false)
            detailLabel.setHidden(false)
            
            titleLabel.setText(userAnswer ? titleTextSuccess : titleTextFailure)
            detailLabel.setText(userAnswer ? detailTextSuccess : detailTextFailure)
        }
    }
    
    func didAnswerCorrect(answer: Bool) {
        self.userAnswer = answer
    }
    
    @IBAction func startButtonPress() {
        let random = randomFlashcard()
        presentControllerWithNames(["QuestionViewController", "AnswerViewController"], contexts:
            [["segue": "pagebased", "question": random.question, "tip": random.tip],
                ["segue": "pagebased", "answer": random.answer, "dismissContext": self]])
    }
    
    @IBAction func refreshButtonPress() {
        updateStoredFlashcards()
        updateButtonAndLabels()
        self.userAnswer = nil
    }
    
    func randomFlashcard() -> WatchFlashcard {
        return storedFlashcards[Int(arc4random_uniform(UInt32(storedFlashcards.count)))]
    }
    
    func updateStoredFlashcards() {
        storedFlashcards = WatchManager.sharedManager.getDataFromRealm()
    }
    
    func updateButtonAndLabels() {
        if storedFlashcards.isEmpty {
            startButton.setHidden(true)
            detailLabel.setText(detailTextNotAvailable)
            titleLabel.setText(titleTextNotAvailable)
        } else {
            startButton.setHidden(false)
            titleLabel.setHidden(true)
            detailLabel.setHidden(true)
        }
    }
}
