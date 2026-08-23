import Foundation
import UserNotifications

struct PrayerNotificationRequest {
  let id: Int
  let title: String
  let body: String
  let triggerAtMillis: TimeInterval
}

final class PrayerScheduler {
  static let shared = PrayerScheduler()

  private let notificationCenter = UNUserNotificationCenter.current()
  private let maxPendingNotifications = 40

  private init() {}

  func refreshSchedule(
    requests: [PrayerNotificationRequest],
    completion: @escaping (Error?) -> Void
  ) {
    let limitedRequests = Array(requests.prefix(maxPendingNotifications))

    notificationCenter.getPendingNotificationRequests { pendingRequests in
      let prayerIdentifiers = pendingRequests
        .map(\.identifier)
        .filter(Self.isPrayerNotificationIdentifier)

      if !prayerIdentifiers.isEmpty {
        self.notificationCenter.removePendingNotificationRequests(
          withIdentifiers: prayerIdentifiers
        )
      }

      let notificationRequests = limitedRequests.compactMap(self.makeNotificationRequest)

      if #available(iOS 15.0, *) {
        Task {
          do {
            try await self.addAll(notificationRequests)
            DispatchQueue.main.async { completion(nil) }
          } catch {
            DispatchQueue.main.async { completion(error) }
          }
        }
      } else {
        self.addAllWithDispatchGroup(notificationRequests, completion: completion)
      }
    }
  }

  private static func isPrayerNotificationIdentifier(_ identifier: String) -> Bool {
    guard let id = Int(identifier) else { return false }

    let prayerId = id / 100
    let occurrenceOffset = id % 100
    return (1...5).contains(prayerId) && (0..<8).contains(occurrenceOffset)
  }

  private func makeNotificationRequest(
    from request: PrayerNotificationRequest
  ) -> UNNotificationRequest? {
    let triggerDate = Date(timeIntervalSince1970: request.triggerAtMillis / 1000)
    guard triggerDate > Date() else { return nil }

    var dateComponents = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: triggerDate
    )
    dateComponents.calendar = Calendar.current
    dateComponents.timeZone = TimeZone.current

    let content = UNMutableNotificationContent()
    content.title = request.title
    content.body = request.body
    
    let isFajr = (request.id / 100) == 1
    let soundName = isFajr ? "y1001.mp3" : "y1000.mp3"
    content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))

    let trigger = UNCalendarNotificationTrigger(
      dateMatching: dateComponents,
      repeats: false
    )

    // Identifier matches Dart/Kotlin: prayerId * 100 + occurrenceOffset.
    return UNNotificationRequest(
      identifier: String(request.id),
      content: content,
      trigger: trigger
    )
  }

  @available(iOS 15.0, *)
  private func addAll(_ requests: [UNNotificationRequest]) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      for request in requests {
        group.addTask {
          try await self.notificationCenter.add(request)
        }
      }

      try await group.waitForAll()
    }
  }

  private func addAllWithDispatchGroup(
    _ requests: [UNNotificationRequest],
    completion: @escaping (Error?) -> Void
  ) {
    let group = DispatchGroup()
    let lock = NSLock()
    var firstError: Error?

    for request in requests {
      group.enter()
      notificationCenter.add(request) { error in
        if let error = error {
          lock.lock()
          if firstError == nil { firstError = error }
          lock.unlock()
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(firstError)
    }
  }
}
