import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    // Store screenshots (tools/mac_store_shots.sh): KOI_WINDOW=1440x900 sizes the content exactly,
    // so a 2x capture is Apple's 2880x1800 Mac format. Unset in normal launches.
    if let spec = ProcessInfo.processInfo.environment["KOI_WINDOW"] {
      let p = spec.split(separator: "x").compactMap { Double($0) }
      if p.count == 2 { windowFrame = self.frameRect(forContentRect: NSRect(x: 0, y: 0, width: p[0], height: p[1])) }
    }
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
