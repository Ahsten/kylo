const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const Termios = std.posix.termios;
const posix = std.posix;

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

        raw_termios.lflag.ECHO = false;

        try posix.tcsetattr(self.in.handle, std.posix.TCSA.FLUSH, raw_termios);
    }
};

pub fn main() !void {
    var editor = Editor{
        .in = std.io.getStdIn(),
    };
    _ = try editor.enableRawMode();
    var char: u8 = undefined;
    while (true) {
        char = try stdin.readByte();
        if (char == 'q') break;
        try stdout.print("{c}\n", .{char});
    }
}
