// PROTOTYPE, throwaway. Prints the Accessibility grant until it is on, then exits.
import ApplicationServices
import Foundation

setvbuf(stdout, nil, _IOLBF, 0)

let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
print("build \(version), path \(Bundle.main.bundlePath)")
let trustedAtLaunch = AXIsProcessTrusted()
print("trusted at launch: \(trustedAtLaunch)")
if !trustedAtLaunch {
    _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    for second in 1...180 {
        sleep(1)
        if AXIsProcessTrusted() { print("trusted after \(second) s"); exit(0) }
    }
    print("still not trusted after 180 s")
}
