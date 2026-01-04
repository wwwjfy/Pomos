//
//  ContentView.swift
//  Pomos
//
//  Created by Assistant on 2025-12-15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showingGiveUpAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Timer Display
            Text(timeString(from: viewModel.secondsRemaining))
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .padding()

            // Status Info
            if let endAt = viewModel.endAt, viewModel.mode == .working || viewModel.mode == .breaking {
                Text("Ends at \(formatTime(endAt))")
                    .foregroundColor(.secondary)
            } else {
                Text(" ") // Placeholder to keep layout stable
            }

            // Finished Count
            Text("Finished: \(viewModel.finishedCount)")
                .font(.headline)

            // Controls
            HStack(spacing: 15) {
                switch viewModel.mode {
                case .initial:
                    Button("Start") {
                        viewModel.startSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.space)

                case .working:
                    Button("Give Up") {
                        showingGiveUpAlert = true
                    }
                    .alert("", isPresented: $showingGiveUpAlert) {
                                Button("Yes") {
                                    viewModel.giveUp()
                                }
                                .buttonStyle(.plain)
                                .keyboardShortcut(.defaultAction)
                                Button("It's a slip", role: .cancel) {}
                                .keyboardShortcut(.cancelAction)
                            } message: {
                                Text("Are you sure?")
                            }
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.space)

                case .finished:
                    Button("Break") {
                        viewModel.takeBreak()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.space)

                case .breaking:
                    Button("Skip") {
                        viewModel.skipBreak() // Or "Start"? Logic says "Skip" -> Back to work/Start
                    }
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.space)
                }
            }

            Divider()

            // Settings
            HStack {
                Text("Duration:")
                Picker("", selection: $viewModel.sessionDuration) {
                    Text("25 min").tag(25 * 60)
                    Text("50 min").tag(50 * 60)
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 400)
        .task {
            await viewModel.setupAsync()
        }
    }

    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d : %02d", minutes, seconds)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
