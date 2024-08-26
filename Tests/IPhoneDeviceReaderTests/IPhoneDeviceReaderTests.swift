import XCTest
import LoggerFactory
@testable import IPhoneDeviceReader

final class IPhoneDeviceReaderTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testMount() throws {
        let bridge = IPHONE()
        for id in bridge.devices() {
            print(id)
            if let device = bridge.device() {
                print(device.represent())
                print(device.name)
            }
        }
        let mp = "/Users/kelvinwong/Documents/iOSMount"
        if bridge.mounted(path: mp) {
            bridge.unmountFuse()
        }
        let mounted = bridge.mount(path: mp)
        print(mounted)
        if(mounted) {
            for folder in bridge.folders(mountPoint: mp, in: "/DCIM") {
                print(folder)
            }
        }
        if bridge.mounted(path: mp) {
            bridge.unmountFuse()
        }
    }
}
