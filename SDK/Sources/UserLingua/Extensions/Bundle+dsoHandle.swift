import Foundation

extension Bundle {
    public convenience init?(dsoHandle: UnsafeRawPointer) {
        var dlInformation : dl_info = dl_info()
        let _ = dladdr(dsoHandle, &dlInformation)
        let path = String(cString: dlInformation.dli_fname)
        let url = URL(fileURLWithPath: path).deletingLastPathComponent()
        self.init(url: url)
    }
}
