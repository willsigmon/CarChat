import Foundation

/// Randomized, personality-driven microcopy throughout the app.
/// Keeps the experience feeling fresh and alive — never robotic.
enum Microcopy {

    // MARK: - Voice State Labels

    enum Status {
        private static let idlePhrases = [
            "Ready when you are",
            "What's on your mind?",
            "Tap to talk",
            "Let's chat",
            "Say something",
            "Go ahead, I'm here",
        ]

        private static let listeningPhrases = [
            "I'm all ears",
            "Listening...",
            "Go ahead...",
            "I hear you",
            "Keep going...",
        ]

        private static let processingPhrases = [
            "Hmm, let me think...",
            "One sec...",
            "Working on it...",
            "Thinking...",
            "Mulling it over...",
            "On it...",
        ]

        private static let speakingPhrases = [
            "Here's what I've got",
            "Speaking...",
            "Check this out",
            "So here's the thing...",
        ]

        private static let errorPhrases = [
            "Oops, hit a bump",
            "Something went wrong",
            "Let's try that again",
        ]

        static func label(for state: VoiceSessionState) -> String {
            switch state {
            case .idle: idlePhrases.randomElement()!
            case .listening: listeningPhrases.randomElement()!
            case .processing: processingPhrases.randomElement()!
            case .speaking: speakingPhrases.randomElement()!
            case .error: errorPhrases.randomElement()!
            }
        }
    }

    // MARK: - Empty States

    enum EmptyState {
        static let historyTitles = [
            "No conversations yet",
            "Quiet in here...",
            "Your road trip awaits",
            "Nothing here yet",
        ]

        static let historySubtitles = [
            "Tap Talk to start your first conversation.",
            "Head over to Talk and say hello.",
            "Your conversations will show up here.",
            "Start a chat — I'll remember it for you.",
        ]

        static var historyTitle: String {
            historyTitles.randomElement()!
        }

        static var historySubtitle: String {
            historySubtitles.randomElement()!
        }
    }

    // MARK: - Greetings (idle state personality)

    enum Greeting {
        private static let timeOfDayGreetings: [String] = {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12:
                return [
                    "Good morning! Where are we headed?",
                    "Morning! Ready to roll?",
                    "Rise and drive!",
                ]
            case 12..<17:
                return [
                    "Afternoon! Need anything?",
                    "Hey there, what's up?",
                    "Good afternoon! How's the drive?",
                ]
            case 17..<21:
                return [
                    "Evening! Heading home?",
                    "Good evening! What can I help with?",
                    "Hey! How was your day?",
                ]
            default:
                return [
                    "Night owl! Where to?",
                    "Late night drive? I'm here.",
                    "Burning the midnight oil?",
                ]
            }
        }()

        static var greeting: String {
            timeOfDayGreetings.randomElement()!
        }
    }

    // MARK: - Loading Messages

    enum Loading {
        private static let phrases = [
            "Warming up...",
            "Getting ready...",
            "Almost there...",
            "Setting the stage...",
            "Tuning in...",
        ]

        static var message: String {
            phrases.randomElement()!
        }
    }

    // MARK: - Settings Subtitles

    enum Settings {
        static let aiProviders = "Choose your copilot's brain"
        static let voice = "How I sound when I talk back"
        static let personas = "Different personalities for different vibes"
        static let about = "The fine print"
    }
}
