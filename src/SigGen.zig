const mem = @import("std").mem;
const math = @import("std").math;

const std = @import("std");

const sampleScaleFactor = (1 << ((@sizeOf(f16) * 8) - 1)) - 1;

pub fn sineWave(frequency: f16, duration: f16, allocator: mem.Allocator) ![]i16 {
    std.debug.print("scale factor {}", .{sampleScaleFactor});
    const frqRad: f16 = math.tau / 44100.0;
    const phaseIncr: f32 = frqRad * frequency;
    var phase: f32 = 0;
    const volume: f16 = 1; 
    const totalSamples: u32 = @floatToInt(u32, 44100.0 * duration);
    var buf = try allocator.alloc(i16, totalSamples);

    // zig doesn't support for-loop with integer range lol
    // for ([0..totalSamples]) |index| {
    var index: u32 = 0;
    while (index < totalSamples): (index += 1) {
        // TODO: scale to i16
        buf[index] = @floatToInt(i16, (volume * math.sin(phase)) * sampleScaleFactor);
        phase += phaseIncr;
        if (phase >= math.tau)
        {
            phase -= math.tau;
        }
    }

    return buf[0..];
} 