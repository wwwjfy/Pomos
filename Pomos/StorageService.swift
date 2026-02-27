import Foundation

final class StorageService {
    static let shared = StorageService()

    private let sessionDurationKey = "PomosSessionDuration"
    private let defaultSessionDuration = 50 * 60 // 50 minutes in seconds

    private var plistURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pomosDir = appSupport.appendingPathComponent("Pomos")
        try? FileManager.default.createDirectory(at: pomosDir, withIntermediateDirectories: true)
        return pomosDir.appendingPathComponent("pomos.plist")
    }

    private init() {
        UserDefaults.standard.register(defaults: [sessionDurationKey: defaultSessionDuration])
    }

    // MARK: - Session Duration

    var sessionDuration: Int {
        get { UserDefaults.standard.integer(forKey: sessionDurationKey) }
        set { UserDefaults.standard.set(newValue, forKey: sessionDurationKey) }
    }

    // MARK: - Completed Count

    struct PomosData: Codable {
        var date: Date
        var finished: Int
    }

    func loadPomosData() -> PomosData {
        guard let data = try? Data(contentsOf: plistURL),
              let decoded = try? PropertyListDecoder().decode(PomosData.self, from: data) else {
            return PomosData(date: Date(), finished: 0)
        }
        return decoded
    }

    func savePomosData(_ data: PomosData) {
        guard let encoded = try? PropertyListEncoder().encode(data) else { return }
        try? encoded.write(to: plistURL)
    }

    func checkAndResetIfNewDay() -> Int {
        var data = loadPomosData()
        if !Calendar.current.isDateInToday(data.date) {
            data.date = Date()
            data.finished = 0
            savePomosData(data)
        }
        return data.finished
    }

    func incrementAndSave() -> Int {
        var data = loadPomosData()
        data.finished += 1
        data.date = Date()
        savePomosData(data)
        return data.finished
    }
}
