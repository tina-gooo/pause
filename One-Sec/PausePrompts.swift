//
//  PausePrompts.swift
//  One-Sec
//
//  Created by Christina Go on 10/25/26.
//
import Foundation

enum PausePrompts {
    static let all: [String] = [
        "Feel the weight of your body against the chair.",
        "Touch your thumb to each fingertip, one by one.",
        "What was the first thing you ate today?",
        "What did you come here to do?",
        "What is one thing you learned from your last scroll?",
        "Are you looking for information, connection, entertainment, or relief?",
        "Notice the next sound you hear, without naming it.",
        "What emotion did the last post leave you with?",
        "What would make the next five minutes feel worthwhile?",
        "Did anything you just consumed change your mind?",
        "Relax your jaw. Let your tongue rest.",
        "What are you hoping this app will make you feel?",
        "Find one detail in your surroundings you have never noticed.",
        "Is your mind asking for stimulation or rest?",
        "Recall one detail from your morning.",
        "What would you regret never making time for?",
        "Let yourself feel bored for just a moment?",
        "What is something you use every day but know almost nothing about?",
        "What is one thing you can recall without reopening the feed?",
        "What was the last song you listened to?",
        "Notice the temperature of the air on your skin.",
        "What color is your current shirt and pants",
        "What was the last thing that made you laugh?",
        "What are you avoiding by opening this app?",
        "Do you actually wanna be here?",
        "Your time is priceless. Would you spend it here?"
    ]
    
    static func random() -> String {
        all.randomElement() ?? "Take one slow breath."
    }
}
