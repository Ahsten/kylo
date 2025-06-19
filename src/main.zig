const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const Termios = std.posix.termios;
const posix = std.posix;
const ascii = std.ascii;

const Key = enum(u8) {
    ctrl_q = 17,
};

const Editor = struct {
    const Self = @This();
    orig_termios: ?Termios = null,
    in: std.fs.File,

    fn enableRawMode(self: *Self) !void {
        var raw_termios: Termios = undefined;
        if (self.orig_termios) |orig_termios| {
            raw_termios = orig_termios;
        } else {
            raw_termios = try posix.tcgetattr(self.in.handle);
            self.orig_termios = raw_termios;
        }

        const VMIN = 5;
        const VTIME = 6;

        raw_termios.iflag.BRKINT = false;
        raw_termios.iflag.ICRNL = false;
        raw_termios.iflag.INPCK = false;
        raw_termios.iflag.ISTRIP = false;
        raw_termios.iflag.IXON = false;
        raw_termios.iflag.IUTF8 = false;

        raw_termios.oflag.OPOST = false;

        raw_termios.cflag.CSIZE = posix.CSIZE.CS8;

        raw_termios.lflag.ECHO = false;
        raw_termios.lflag.ICANON = false;
        raw_termios.lflag.IEXTEN = false;
        raw_termios.lflag.ISIG = false;

        raw_termios.cc[VMIN] = 0;
        raw_termios.cc[VTIME] = 1;

        try posix.tcsetattr(self.in.handle, std.posix.TCSA.FLUSH, raw_termios);
    }

    fn disableRawMode(self: *Self) !void {
        if (self.orig_termios) |termios| {
            try posix.tcsetattr(self.in.handle, posix.TCSA.FLUSH, termios);
        }
    }
};

pub fn main() !void {
    var editor = Editor{
        .in = std.io.getStdIn(),
    };

    try editor.enableRawMode();

    var char: u8 = undefined;
    while (true) {
        char = try stdin.readByte();
        if (ascii.isControl(char)) {
            try stdout.print("{d}\r\n", .{char});
        }
        try stdout.print("{c}\r\n", .{char});

        if (char == @intFromEnum(Key.ctrl_q)) {
            try editor.disableRawMode();
            break;
        }
    }

    try editor.disableRawMode();
}
