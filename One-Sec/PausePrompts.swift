//
//  PausePrompts.swift
//  One-Sec
//
//  Created by Christina Go on 10/25/26.
//
import Foundation

enum PausePrompts {
    static let all: [String] = [
        // Body
        "Feel the weight of your body against the chair.",
        "Touch your thumb to each fingertip, one by one.",
        "Relax your jaw. Let your tongue rest.",
        "Notice the temperature of the air on your skin.",
        "Roll your shoulders back three times.",
        "Press your feet flat into the floor.",
        "Unclench your hands and spread your fingers wide.",
        "Drop your shoulders away from your ears.",
        "Stand up and stretch toward the ceiling.",
        "Look away from the screen and blink slowly five times.",
        "Tilt your head side to side, slowly.",
        "Press your palms together and feel the warmth.",

        // Senses
        "Notice the next sound you hear, without naming it.",
        "Find one detail in your surroundings you have never noticed.",
        "Find three blue things in the room.",
        "Look out a window and find the farthest thing you can see.",
        "Rub your fingertips together and notice the texture.",
        "Listen for the quietest sound in the room.",
        "Find something in the room that is perfectly round.",
        "Trace the outline of one object with your eyes.",

        // Small tasks
        "Drink a few sips of water.",
        "Straighten one thing on your desk.",
        "Write one word on paper that describes right now.",
        "Text someone a single emoji just to say hi.",
        "Delete one photo you don't need.",
        "Name five objects within arm's reach.",
        "Count backward from twenty by threes.",
        "Hum a few notes of any song you like.",
        "Smile with your eyes for three seconds.",
        "Whisper your own name out loud.",

        // Quick recall
        "What was the first thing you ate today?",
        "Recall one detail from your morning.",
        "What was the last song you listened to?",
        "What was the last thing that made you laugh?",
        "What is one thing you can recall without reopening the feed?",
        "Name one thing you're looking forward to this week.",

        // Curiosity and playful
        "What is something you use every day but know almost nothing about?",
        "Let yourself feel bored for just a moment.",
        "Imagine the most peaceful place you've ever been.",
        "Think of a word you love the sound of.",
        "Picture your favorite meal in full detail.",
        "Come up with a new name for the color of your shirt.",
        "Think of a place you'd like to wake up tomorrow.",
        "Imagine what your future self would do with the next ten minutes."
    ]
    
    static func random() -> String {
        all.randomElement() ?? "Take one slow breath."
    }
}
