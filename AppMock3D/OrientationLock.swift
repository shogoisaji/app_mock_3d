import SwiftUI

final class OrientationLocker {
    static let shared = OrientationLocker()
    private init() {}

    func lockToPortrait() {
        // iPhoneでは縦固定。iPadでも縦で固定したい場合は同様にPortraitを指定
        setOrientation(.portrait)
    }

    private func setOrientation(_ orientation: UIInterfaceOrientation) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let windowScene = scene as? UIWindowScene else { return }
        // try to set orientation using private selector (documented workaround)
        let selector = NSSelectorFromString("setInterfaceOrientation:")
        if windowScene.responds(to: selector) {
            windowScene.perform(selector, with: orientation)
        }
        // Also hint supported orientations by forcing root to update
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

// UIHostingController subclass that fixes orientations to portrait
final class PortraitHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var shouldAutorotate: Bool { false }
}