const std = @import("std");
const expect = @import("std").testing.expect;
const waveFile = @import("WaveFile.zig").WavHeader;
const sineWave = @import("SigGen.zig").sineWave;
const sineWave2 = @import("envGen.zig");
const EnvelopeAD = @import("envGen.zig").EnvelopeAD;

// pub fn main() !void {
//     // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
//     std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

//     // stdout is for the actual output of your application, for example if you
//     // are implementing gzip, then only the compressed bytes should be sent to
//     // stdout, not any debugging messages.
//     const stdout_file = std.io.getStdOut().writer();
//     var bw = std.io.bufferedWriter(stdout_file);
//     const stdout = bw.writer();

//     try stdout.print("Run `zig build test` to run the tests.\n", .{});

//     try bw.flush(); // don't forget to flush!
// }

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    defer {
        _ = gpa.deinit();
    }

    var envelope = EnvelopeAD{
        .peakAmp = 1,
        .attackRate = 0.6,
        .decayRate = 0.2, 
    };

    // const buf = sineWave(440.0, 1.0, allocator) catch unreachable;
    const buf = sineWave2.sineWaveWithCurveEnv(444.0, 1.0, &envelope, allocator) catch unreachable;
    defer allocator.free(buf);

    const sampleTotal = buf.len;
    // TODO: how to deal with this?  RIFF chunk is u32 max, zig complains about 
    const byteTotal: u32 = @truncate(u32, sampleTotal * 2);
    var wav_file = waveFile{
        .riffSize = byteTotal + @sizeOf(waveFile) - 8,
        .fmtCode = 1,
        .fmtSize = 16,
        .channels = 1,
        .bits = 16,
        .bitAlign = 16 / 8,
        .avgbps = 44100 * (16 / 8),
        .waveSize = byteTotal,
    };

    _ = wav_file.writeWaveFile(buf[0..]) catch unreachable;
}

fn addFive(x: u32) u32 {
    return x + 5;
}

// fn failingFunction() error{Oops}!void {
//     return error.Oops;
// }

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound
};

const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

fn failFn() error{Oops}!i32 {
    // try force returns an error if there is one
    try failingFunction();
    return 12;
}

// test "try" {
//     // catch |err| will pull out the error of the union, specifically?
//     var v = failFn() catch |err| {
//         try expect(err == error.Oops);
//         return;
//     };
//     // never reached
//     try expect(v == 12);
// }

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

fn increment(num: *u8) void {
    num.* += 1;
}

// ref => get value at memory pos
// deref => get memory pos

test "pointers" {
    var x: u8 = 1;
    increment(&x); // pointer to x
    try expect(x == 2);
}

test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}

// test "returning an error" {
//     failingFunction() catch |err| {
//         try expect(err == error.Oops);
//         return;
//     }
// }

// test "if statement" {
//     const a = true;
//     var x: u16 = 0;

//     // if (a) {
//     //     x += 1;
//     // } 
//     // else {
//     //     x += 2;
//     // }

//     x += if (a) 1 else 2;
//     try expect(x == 1);
// }

// test "while" {
//     var i: u8 = 2;
//     while (i < 100) {
//         i *= 2;
//     }
//     try expect(i == 128);
// }

// test "function" {
//     const y = addFive(0);
//     try expect(@TypeOf(y) == u32);
//     try expect(y == 5);
// }