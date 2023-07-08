const std = @import("std"); 
const File = @import("std").fs.File;
const toBytes = @import("std").mem.toBytes;
const sliceAsBytes = @import("std").mem.sliceAsBytes;

// const RiffChunk = struct {
//     chunkId: i8,
//     chunkSize: i32
// } 

// const FmtData = struct{
//     fmtId: [4]u8,
//     // code 1 = PCM, 3 = IEEE float
//     fmtCode: u16,
//     channels: u16,
//     sampleRate: u32,
//     avgbps: u32,
//     bitAlign: u16,
//     bits: u16,
// }

pub const WavHeader = struct {
    riffId: []const u8 = "RIFF",
    riffSize: u32,
    waveType: []const u8 = "WAVE",
    fmtId: []const u8 = "fmt ",
    fmtSize: u32,
    // code 1 = PCM, 3 = IEEE float
    fmtCode: u16,
    channels: u16,
    sampleRate: u32 = 44100,
    avgbps: u32,
    bitAlign: u16,
    bits: u16,
    waveId: []const u8 = "data",
    waveSize: u32,

    fn writeWaveHeader(self: *WavHeader, file: File) !void
    {
        _ = try file.write(self.riffId[0..]);
        _ = try file.write(&toBytes(self.riffSize));
        _ = try file.write(self.waveType[0..]);
        _ = try file.write(self.fmtId[0..]);
        _ = try file.write(&toBytes(self.fmtSize));
        _ = try file.write(&toBytes(self.fmtCode));
        _ = try file.write(&toBytes(self.channels));
        _ = try file.write(&toBytes(self.sampleRate));
        _ = try file.write(&toBytes(self.avgbps));
        _ = try file.write(&toBytes(self.bitAlign));
        _ = try file.write(&toBytes(self.bits));
        _ = try file.write(self.waveId[0..]);
        _ = try file.write(&toBytes(self.waveSize));
    }

    pub fn writeWaveFile(self: *WavHeader, sampleBuffer: []i16) !void {
        const file = try std.fs.cwd().createFile(
            "testFile.wav",
            .{ .read = true },
        );
        defer file.close();

        _ = try self.writeWaveHeader(file);
        _ = try file.write(sliceAsBytes(sampleBuffer));
    }
};

    // const Writer = std.io.Writer(
    //     *WavHeader,
    //     error{EndOfBuffer},
    //     appendWrite,
    // );

    // fn appendWrite(
    //     self: *WavHeader,
    //     data: []const u8
    // )

    // fn writer(self: *MyByteList) Writer {
    //     return .{ .context = self };
    // }