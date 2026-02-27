import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()

    private var formattedTime: String {
        let minutes = viewModel.remainingSeconds / 60
        let seconds = viewModel.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Countdown display
            Text(formattedTime)
                .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                .foregroundColor(.primary)
                .tracking(-2)

            // End time label
            if !viewModel.endTimeText.isEmpty {
                Text(viewModel.endTimeText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Duration picker (only visible when idle)
            if viewModel.state == .idle {
                Picker("", selection: $viewModel.sessionMinutes) {
                    Text("25 min").tag(25)
                    Text("50 min").tag(50)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .labelsHidden()
                .onChange(of: viewModel.sessionMinutes) { _, newValue in
                    viewModel.configureSessionDuration(newValue)
                }
            }

            // Finished count
            HStack(spacing: 4) {
                Text("Finished")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(viewModel.finishedCount)")
                    .font(.system(size: 14, weight: .semibold))
            }

            // Action button
            Button(action: {
                if viewModel.state == .working {
                    viewModel.showGiveUpAlert()
                } else {
                    viewModel.onButtonClick()
                }
            }) {
                Text(viewModel.buttonTitle)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 140, height: 36)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(24)
        .frame(width: 380, height: 340)
    }
}
