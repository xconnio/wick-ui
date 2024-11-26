import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first {
      window.minSize = NSSize(width: 600, height: 400)
    }
    super.applicationDidFinishLaunching(notification)
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
