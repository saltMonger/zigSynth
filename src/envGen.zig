const mem = @import("std").mem;
const math = @import("std").math;

const std = @import("std");

const sampleScaleFactor = (1 << ((@sizeOf(f16) * 8) - 1)) - 1;
const sampleRate = 44100;
const sampleRateF = 44100.0;

pub const EnvelopeAD = struct {
    peakAmp: f32 = 0,
    attackRate: f32,
    decayRate: f32,

    attackTime: u32 = 0,
    decayTime: u32 = 0,
    decayStart: u32 = 0,
    envelopeIncr: f32 = 0,

    expX: f32 = 0,
    expB: f32 = 2,

    sign: i8 = 1,

    pub fn getSampleVolume(self: *EnvelopeAD, index: u32, volume: f32) f32 {
        if ((index < self.attackTime) or (index > self.decayStart))
        {
            return volume + self.envelopeIncr;
        }

        if (index == self.attackTime)
        {
            std.debug.print("attack time finished {s}", .{"now"});
            return self.peakAmp;
        }
        
        if (index == self.decayStart)
        {
            std.debug.print("decay started {s}", .{"now"});
            self.envelopeIncr = -volume / @intToFloat(f16, self.decayTime);
        }
        return volume;
    }

    pub fn getSampleVolumeExp(self: *EnvelopeAD, index: u32, volume: f32, range: f32, expIncr: *f32) f32 {
        if ((index < self.attackTime) or (index > self.decayStart))
        {
            const vol = range * math.pow(f32, self.expX, self.expB) * @intToFloat(f32, self.sign);
            self.expX += expIncr.*; 
            std.debug.print("vol is: {}\n", .{volume});
            return volume + vol;
        }
        
        if (index == self.attackTime) {
            return 1;
        }

        if (index == self.decayStart) {
            expIncr.* = -1 / @intToFloat(f32, self.decayTime);
            self.expX = 1;
            self.sign = -1; 
        }
        return volume;
    }
};

pub fn sineWaveWithEnv(frequency: f16, duration: f16, envelope: *EnvelopeAD, allocator: mem.Allocator) ![]i16 {
    std.debug.print("scale factor {}", .{sampleScaleFactor});
    const frqRad: f16 = math.tau / sampleRateF;
    const phaseIncr: f32 = frqRad * frequency;
    var phase: f32 = 0;
    var volume: f32 = 0; 
    const peakAmp: f32 = 1;
    const totalSamples: u32 = @floatToInt(u32, sampleRateF * duration);
    envelope.attackTime = @floatToInt(u32, envelope.attackRate * sampleRateF);
    envelope.decayTime = @floatToInt(u32, envelope.decayRate * sampleRateF);
    envelope.decayStart = totalSamples - envelope.decayTime;
    var buf = try allocator.alloc(i16, totalSamples);

    if (envelope.attackTime > 0) {
        envelope.envelopeIncr = peakAmp / @intToFloat(f32, envelope.attackTime);
    }

    std.debug.print("\nattackTime: {}\n", .{envelope.attackTime});
    std.debug.print("decayStart: {}\n", .{envelope.decayStart});
    std.debug.print("envelopeIncr: {}\n", .{envelope.envelopeIncr});

    // zig doesn't support for-loop with integer range lol
    // for ([0..totalSamples]) |index| {
    var index: u32 = 0;
    while (index < totalSamples): (index += 1) {
        volume = envelope.getSampleVolume(index, volume);

        //sine gen
        buf[index] = @floatToInt(i16, (volume * math.sin(phase)) * sampleScaleFactor);
        phase += phaseIncr;
        if (phase >= math.tau)
        {
            phase -= math.tau;
        }
    }

    return buf[0..];
}

pub fn sineWaveWithCurveEnv(frequency: f16, duration: f16, envelope: *EnvelopeAD, allocator: mem.Allocator) ![]i16 {    std.debug.print("scale factor {}", .{sampleScaleFactor});
    const frqRad: f16 = math.tau / sampleRateF;
    const phaseIncr: f32 = frqRad * frequency;
    var phase: f32 = 0;
    var volume: f32 = 0; 
    const peakAmp: f32 = 1;
    const totalSamples: u32 = @floatToInt(u32, sampleRateF * duration);
    envelope.attackTime = @floatToInt(u32, envelope.attackRate * sampleRateF);
    envelope.decayTime = @floatToInt(u32, envelope.decayRate * sampleRateF);
    envelope.decayStart = totalSamples - envelope.decayTime;
    const range = peakAmp /  @intToFloat(f32, totalSamples);
    var expIncr = 1 / @intToFloat(f32, envelope.attackTime);
    var buf = try allocator.alloc(i16, totalSamples);

    if (envelope.attackTime > 0) {
        envelope.envelopeIncr = peakAmp / @intToFloat(f32, envelope.attackTime);
    }

    std.debug.print("\nattackTime: {}\n", .{envelope.attackTime});
    std.debug.print("decayStart: {}\n", .{envelope.decayStart});
    std.debug.print("envelopeIncr: {}\n", .{envelope.envelopeIncr});
    std.debug.print("range: {}\n", .{range});


    // zig doesn't support for-loop with integer range lol
    // for ([0..totalSamples]) |index| {
    var index: u32 = 0; 
    var subIndex: u32 = 0;
    while (index < totalSamples): (index += 1) {
        volume = envelope.getSampleVolumeExp(index, volume, range, &expIncr);

        if ((index % 1000) == 0) {
            std.debug.print("subind: {}   ", .{subIndex});
            std.debug.print("exp incr: {}   ", .{expIncr});
            std.debug.print("volume: {}\n", .{volume});
            subIndex += 1;
        }

        //sine gen
        buf[index] = @floatToInt(i16, (volume * math.sin(phase)) * sampleScaleFactor);
        phase += phaseIncr;
        if (phase >= math.tau)
        {
            phase -= math.tau;
        }
    }

    return buf[0..];
}