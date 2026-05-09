import SwiftUI

struct SettingsView: View {
    @AppStorage("scanLargeFileThreshold") private var largeFileThreshold = 500
    @AppStorage("stageReminderDays") private var stageReminderDays = 7
    @AppStorage("preferStageFirst") private var preferStageFirst = true
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Mode", selection: $appAppearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Review") {
                Stepper("Large file threshold: \(largeFileThreshold) MB", value: $largeFileThreshold, in: 50...2000, step: 50)
                Toggle("Prefer Stage before final action", isOn: $preferStageFirst)
            }

            Section("Stage") {
                Stepper("Reminder after \(stageReminderDays) days", value: $stageReminderDays, in: 1...30)
            }

            Section("About") {
                LabeledContent("App", value: "theMClean Go")
                LabeledContent("Version", value: "0.1.0")
                Text("Designed for iPhone and iPad file review. It cannot scan iOS system caches or other apps.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
