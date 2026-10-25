// brightness — get/set external display brightness via macOS DisplayServices (private API)
// Usage:
//   brightness          print current brightness (0.0–1.0) of the first external display
//   brightness 0.3      set all external displays to 0.3
//   brightness 0.3 1.5  fade all external displays to 0.3 over 1.5 seconds
import Foundation
import CoreGraphics

guard let h = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW),
      let setSym = dlsym(h, "DisplayServicesSetBrightness"),
      let getSym = dlsym(h, "DisplayServicesGetBrightness") else {
    fputs("DisplayServices not available\n", stderr); exit(1)
}
typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
let setB = unsafeBitCast(setSym, to: SetFn.self)
let getB = unsafeBitCast(getSym, to: GetFn.self)

var ids = [CGDirectDisplayID](repeating: 0, count: 16); var n: UInt32 = 0
CGGetActiveDisplayList(16, &ids, &n)
let externals = ids.prefix(Int(n)).filter { CGDisplayIsBuiltin($0) == 0 }
guard !externals.isEmpty else { fputs("no external display\n", stderr); exit(2) }

if let arg = CommandLine.arguments.dropFirst().first {
    guard let level = Float(arg), (0...1).contains(level) else {
        fputs("level must be 0.0–1.0\n", stderr); exit(1)
    }
    var seconds = 0.0
    if CommandLine.arguments.count > 2 {
        guard let s = Double(CommandLine.arguments[2]), s >= 0 else {
            fputs("seconds must be 0 or more\n", stderr); exit(1)
        }
        seconds = s
    }
    var starts = [CGDirectDisplayID: Float]()
    for id in externals { var v: Float = level; _ = getB(id, &v); starts[id] = v }
    var failed = false
    var last = [CGDirectDisplayID: Float]()
    let begin = DispatchTime.now().uptimeNanoseconds
    while true {
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - begin) / 1e9
        let linear = seconds > 0 ? min(1.0, elapsed / seconds) : 1.0
        // Smoothstep easing: slow start and end, so the change looks gradual.
        let t = Float(linear * linear * (3 - 2 * linear))
        for id in externals {
            let from = starts[id] ?? level
            let v = linear >= 1.0 ? level : from + (level - from) * t
            // Skip values the display cannot show as a separate step.
            if let l = last[id], abs(l - v) < 0.005, linear < 1.0 { continue }
            if setB(id, v) != 0 { failed = true }
            last[id] = v
        }
        if linear >= 1.0 { break }
        usleep(8_000)
    }
    if failed { fputs("set failed\n", stderr) }
    exit(failed ? 3 : 0)
} else {
    var v: Float = 0
    guard getB(externals[0], &v) == 0 else { fputs("get failed\n", stderr); exit(3) }
    print(String(format: "%.3f", v))
}
