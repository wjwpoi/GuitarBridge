import Foundation

// MARK: - iCloud Key-Value Store
/// iCloud 键值存储封装
/// 使用 NSUbiquitousKeyValueStore 实现跨设备同步
@MainActor
final class CloudStore {
    static let shared = CloudStore()
    
    private let store = NSUbiquitousKeyValueStore.default
    
    private init() {
        // 监听 iCloud 变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 设置值
    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }
    
    /// 获取值
    func get(forKey key: String) -> Any? {
        return store.object(forKey: key)
    }
    
    /// 获取字符串
    func getString(forKey key: String) -> String? {
        return store.string(forKey: key)
    }
    
    /// 获取布尔值
    func getBool(forKey key: String) -> Bool {
        return store.bool(forKey: key)
    }
    
    /// 获取整数
    func getInt(forKey key: String) -> Int {
        return Int(store.longLong(forKey: key))
    }
    
    /// 获取 Double
    func getDouble(forKey key: String) -> Double {
        return store.double(forKey: key)
    }
    
    /// 删除值
    func remove(forKey key: String) {
        store.removeObject(forKey: key)
        store.synchronize()
    }
    
    /// 同步
    func synchronize() {
        store.synchronize()
    }
    
    // MARK: - Private Methods
    
    @objc private func iCloudDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        switch changeReason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // 服务器变化或初始同步
            NotificationCenter.default.post(name: .cloudStoreDidChange, object: nil)
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            #if DEBUG
            print("[CloudStore] iCloud quota exceeded")
            #endif
        case NSUbiquitousKeyValueStoreAccountChange:
            #if DEBUG
            print("[CloudStore] iCloud account changed")
            #endif
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let cloudStoreDidChange = Notification.Name("cloudStoreDidChange")
}

// MARK: - CloudStore Keys
enum CloudStoreKey: String {
    case volume = "audioVolume"
    case crossfadeDuration = "crossfadeDuration"
    case selectedToneMode = "toneMode"
    case lastPracticeDate = "lastPracticeDate"
    case totalPracticeMinutes = "totalPracticeMinutes"
}
