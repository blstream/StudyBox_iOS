//
//  WatchManager.swift
//  StudyBox_iOS
//
//  Created by Kacper Cz on 22.04.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//

import WatchKit
import WatchConnectivity
import RealmSwift

class WatchManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = WatchManager()
    private let session: WCSession = WCSession.defaultSession()
    
    func startSession() {
        session.delegate = self
        session.activateSession()
    }
    
    //Return format: [(Question,Answer,Tip)]
    func getDataFromRealm() -> [WatchFlashcard] {
        var flashcardsFromRealm = [WatchFlashcard]()
        if let realm = try? Realm() {
            flashcardsFromRealm = realm.objects(WatchFlashcard).toArray()
        }
        return flashcardsFromRealm
    }
    
    func overwriteDataInRealm(applicationContext: [String : AnyObject]) {
        var flashcardsToSave = [WatchFlashcard]()
        
        if let realm = try? Realm() {
            do {
                try realm.write() {
                    if let flashcardsQ = applicationContext[Utils.WatchAppContextType.FlashcardsQuestions] as? [String],
                        let flashcardsA = applicationContext[Utils.WatchAppContextType.FlashcardsAnswers] as? [String],
                        let flashcardIDs = applicationContext[Utils.WatchAppContextType.FlashcardsIDs] as? [String],
                        let flashcardsTips = applicationContext[Utils.WatchAppContextType.FlashcardsTips] as? [[String]] {
                        for i in 0..<flashcardsQ.count {
                            flashcardsToSave.append(WatchFlashcard(serverID: flashcardIDs[i],
                                question: flashcardsQ[i],
                                answer: flashcardsA[i],
                                tips: convertToWatchTips(flashcardsTips[i])
                                ))
                        }
                        realm.deleteAll()
                        realm.add(flashcardsToSave)
                    }
                }
            } catch let e {
                debugPrint(e)
            }
        }
    }
    
    func convertToWatchTips(contents: [String]) -> List<WatchTip> {
        let tipsToSave = List<WatchTip>()
        for content in contents {
            tipsToSave.append(WatchTip(content: content))
        }
        return tipsToSave
    }
    
    func tipsForFlashcard(flashcardID: String) -> [String] {
        var tipsForFlashcard = [String]()
        if let realm = try? Realm(), flashcard = realm.objects(WatchFlashcard.self).filter("serverID = '\(flashcardID)'").first {
            for tip in flashcard.tips {
                tipsForFlashcard.append(tip.content)
            }
        }
        return tipsForFlashcard
    }
}

extension WatchManager {
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if !applicationContext.isEmpty {
            overwriteDataInRealm(applicationContext)
        }
    }
}
