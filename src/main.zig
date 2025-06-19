const std = @import("std");
const reader = std.io.getStdIn().reader();
const writer = std.io.getStdOut().writer();
const Termios = std.posix.termios;
const posix = std.posix;
const ascii = std.ascii;
const stdin = std.io.getStdIn();

const Key = enum(u8) {
    ctrl_q = 17,
};

const EditorConfig = struct {
    orig_termios: ?Termios = null,
};

var editorConfig = EditorConfig{};

fn enableRawMode() !void {
    var raw_termios: Termios = undefined;
    if (editorConfig.orig_termios) |orig_termios| {
        raw_termios = orig_termios;
    } else {
        raw_termios = try posix.tcgetattr(stdin.handle);
        editorConfig.orig_termios = raw_termios;
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

    try posix.tcsetattr(stdin.handle, std.posix.TCSA.FLUSH, raw_termios);
}

fn disableRawMode() void {
    if (editorConfig.orig_termios) |termios| {
        posix.tcsetattr(stdin.handle, posix.TCSA.FLUSH, termios) catch |err| {
            std.debug.print("{any}\n", .{err});
            return;
        };
    }
}

fn closeEditor() void {
    disableRawMode();
    std.process.exit(0);
}

fn readKey() !u8 {
    var char: u8 = undefined;
    char = try reader.readByte();

    return char;
}

fn processKeyPress() !void {
    const char: u8 = try readKey();

    switch (char) {
        @intFromEnum(Key.ctrl_q) => {
            closeEditor();
        },
        else => try writer.print("{c}\r\n", .{char}),
    }
}

pub fn main() !void {
    try enableRawMode();
    defer disableRawMode();

    while (true) {
        try processKeyPress();
    }
}
