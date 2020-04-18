const std = @import("std");
const os = std.os;
const warn = std.debug.warn;

const STDIN_NAME = "-";
const BUFFER_SIZE = 4096;

const Input = struct {
    fd: i32,

    pub fn init(name: []const u8) !Input {
        var self = Input{
            .fd = undefined,
        };

        if (std.mem.eql(u8, name, STDIN_NAME)) {
            // If the input is standardin, we have to use that.
            self.fd = os.STDIN_FILENO;
        } else {
            // In all normal cases, open the file for reading
            self.fd = try os.open(name, 0, os.O_RDONLY);
        }

        return self;
    }

    pub fn close(self: Input) void {
        // Do not do anything if we were reading standard input
        if (self.fd == os.STDIN_FILENO) {
            return;
        }

        // Get rid of the file descriptor
        os.close(self.fd);
    }

    pub fn dump(self: Input, buf: []u8) !void {
        while (os.read(self.fd, buf)) |bytes| {
            if (bytes == 0) {
                // Returning zero bytes signals EOF.
                return;
            }

            // Dump bytes to stdout
            _ = try os.write(os.STDOUT_FILENO, buf[0..bytes]);
        } else |err| {
            // Bubble up any bizarre errors while dumping.
            return err;
        }
    }
};

fn cat(buf: []u8, fname: []const u8) void {
    var file = Input.init(fname) catch |err| {
        warn("failed to open {} for reading: {}\n", .{ fname, err });
        return;
    };
    defer file.close();

    file.dump(buf) catch |err| {
        warn("failed to write contents of {}: {}\n", .{ fname, err });
    };
}

// Cats all args and returns the number of args catted.
fn cat_args(allocator: *std.mem.Allocator, buf: []u8) u32 {

    // Initialize reading the arguments & throw out the first one,
    // which is the program name.
    var args = std.process.args();
    _ = args.next(allocator);
    var argc: u32 = 0;

    // Loop through the arguments, aborting if the option fails
    while (args.next(allocator) orelse return argc) |arg| {
        argc += 1;
        cat(buf, arg);
    } else |err| {
        // TODO: How can this ever happen?
        warn("failed to read arguments: {}\n", .{err});
        return argc;
    }

    unreachable; // args.next errors to signal end of loop
}

pub fn main() !void {
    // One-off allocator from:
    // https://ziglang.org/documentation/0.5.0/#Choosing-an-Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    // Construct a buffer for syscall read/writes
    var buf = try allocator.alloc(u8, BUFFER_SIZE);

    // Cat the arguments we have
    var argc = cat_args(allocator, buf);

    // If there were no arguments, cat stdin
    if (argc == 0) {
        cat(buf, STDIN_NAME);
    }
}
