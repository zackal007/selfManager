import Foundation
import UIKit

final class VersionUpdateManager: ObservableObject {
    static let shared = VersionUpdateManager()
    private let lastCheckKey = "version_last_check_date"
    private let lastPromptVersionKey = "version_last_prompt_version"
    private let lastPromptDateKey = "version_last_prompt_date"
    private let minPromptIntervalDays = 7

    struct UpdateInfo {
        let latestVersion: String
        let trackViewUrl: String
        let releaseNotes: String?
    }

    private struct LookupResponse: Decodable {
        let resultCount: Int
        let results: [AppResult]
    }

    private struct AppResult: Decodable {
        let version: String
        let trackViewUrl: String
        let releaseNotes: String?
    }

    func checkForUpdate(force: Bool = false, completion: @escaping (UpdateInfo?) -> Void) {
        let now = Date()
        if !force {
            if let last = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
                if now.timeIntervalSince(last) < 24 * 3600 {
                    completion(nil)
                    return
                }
            }
        }
        UserDefaults.standard.set(now, forKey: lastCheckKey)

        guard let bundleId = Bundle.main.bundleIdentifier else {
            completion(nil)
            return
        }
        let country = Locale.current.regionCode ?? "US"
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=\(country)"
        guard let url = URL(string: urlString) else { completion(nil); return }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let decoder = JSONDecoder()
            guard let resp = try? decoder.decode(LookupResponse.self, from: data), resp.resultCount > 0, let app = resp.results.first else {
                completion(nil)
                return
            }
            let latest = app.version
            let current = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
            if self.isVersion(latest, greaterThan: current) {
                if let lastVersion = UserDefaults.standard.string(forKey: self.lastPromptVersionKey), let lastDate = UserDefaults.standard.object(forKey: self.lastPromptDateKey) as? Date, lastVersion == latest {
                    if now.timeIntervalSince(lastDate) < Double(self.minPromptIntervalDays) * 24 * 3600 {
                        completion(nil)
                        return
                    }
                }
                UserDefaults.standard.set(latest, forKey: self.lastPromptVersionKey)
                UserDefaults.standard.set(now, forKey: self.lastPromptDateKey)
                completion(UpdateInfo(latestVersion: latest, trackViewUrl: app.trackViewUrl, releaseNotes: app.releaseNotes))
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    private func isVersion(_ lhs: String, greaterThan rhs: String) -> Bool {
        let la = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let ra = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let n = max(la.count, ra.count)
        for i in 0..<n {
            let l = i < la.count ? la[i] : 0
            let r = i < ra.count ? ra[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    func openAppStore(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}

