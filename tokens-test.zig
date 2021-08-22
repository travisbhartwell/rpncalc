const std = @import("std");

const expect = std.testing.expect;
const mem = std.mem;

test "gets tokens" {
    const input_string = "5 10 15 + *";
    const tokens = [_][]const u8{ "5", "10", "15", "+", "*" };

    var token_iter: mem.TokenIterator(u8) = mem.tokenize(u8, input_string, " ");

    for (tokens) |expected_token| {
        var token = token_iter.next().?;
        var index = token_iter.index;
        std.debug.print("Expected '{s}', got '{s}' at index {d} with character {c}\n", .{ token, expected_token, index, input_string[index - 1] });
        try expect(mem.eql(u8, token, expected_token));
    }
}
