import Foundation

enum TimerState {
    case idle       // Initial state, showing configured duration
    case working    // Working
    case finished   // Work finished, ready for break
    case breaking   // Taking a break
}
