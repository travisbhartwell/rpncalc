const std = @import("std");

// Shameless based on the Zig tokenizer:
// https://github.com/ziglang/zig/blob/ec63411905ca66dc4dd874b4cde257b0043442e6/lib/std/zig/tokenizer.zig

pub const TokenType = enum {
    const Self = @This();

    integer_literal,

    plus,
    minus,
    asterisk,
    slash,

    eof,
    invalid,

    pub fn lexeme(token_type: Self) ?[]const u8 {
        return switch (token_type) {
            .integer_literal, .eof, .invalid => null,

            .plus => "+",
            .minus => "-",
            .asterisk => "*",
            .slash => "/",
        };
    }

    pub fn symbol(token_type: Self) []const u8 {
        return token_type.lexeme() orelse @tagName(token_type);
    }

    // Convenience method, first for matching operators
    pub fn isTokenType(token_type: Self, potential_lexeme: []const u8) bool {
        const maybe_type_lexeme = token_type.lexeme();

        if (maybe_type_lexeme == null) {
            return false;
        }

        const type_lexeme = maybe_type_lexeme.?;

        return std.mem.eql(u8, type_lexeme, potential_lexeme);
    }
};

pub const Location = struct {
    start: usize,
    end: usize,
};

pub const Token = struct {
    const Self = @This();

    token_type: TokenType,
    location: Location,
    text: ?[]const u8 = null,
};

const token_delimitter = " ";

pub const Tokenizer = struct {
    const Self = @This();

    token_iter: std.mem.TokenIterator(u8),

    pub fn init(buffer: [:0]const u8) Self {
        return Self{
            .token_iter = std.mem.tokenize(u8, buffer, token_delimitter),
        };
    }

    pub fn next(self: *Self) Token {
        const token_start: usize = self.token_iter.index;
        const maybe_token_text: ?[]const u8 = self.token_iter.next();

        if (maybe_token_text == null) {
            return Token{
                .token_type = .eof,
                .location = Location{
                    .start = token_start,
                    .end = undefined,
                },
            };
        }

        var token_text: []const u8 = maybe_token_text.?;

        for (std.enums.values(TokenType)) |token_type| {
            if (token_type.isTokenType(token_text)) {
                return Token{ .token_type = token_type, .location = Location{ .start = token_start, .end = self.token_iter.index }, .text = token_text };
            }
        }

        return Token{ .token_type = .invalid, .location = Location{ .start = token_start, .end = self.token_iter.index }, .text = token_text };
    }
};

test "tokenizes operators" {
    const input_string = "+ * - /";
    const expected_values = [_]TokenType{ .plus, .asterisk, .minus, .slash, .eof };

    var tokenizer = Tokenizer.init(input_string);

    for (expected_values) |expected_token| {
        var token = tokenizer.next();
        var index = tokenizer.token_iter.index;
        var token_text = token.text;

        if (token_text == null) {
            std.debug.print("Expected token '{s}', got token '{s}' at index {d}\n", .{ expected_token.symbol(), token.token_type.symbol(), index });
        } else {
            std.debug.print("Expected token '{s}', got token '{s}' at index {d} from text '{s}'\n", .{ expected_token.symbol(), token.token_type.symbol(), index, token.text });
        }

        try std.testing.expect(token.token_type == expected_token);
    }
}

test "tokenizes unknown tokens" {
    const input_string = "@";
    const expected_values = [_]TokenType{ .invalid, .eof };

    var tokenizer = Tokenizer.init(input_string);

    for (expected_values) |expected_token| {
        var token = tokenizer.next();
        var index = tokenizer.token_iter.index;
        var token_text = token.text;

        if (token_text == null) {
            std.debug.print("Expected token '{s}', got token '{s}' at index {d}\n", .{ expected_token.symbol(), token.token_type.symbol(), index });
        } else {
            std.debug.print("Expected token '{s}', got token '{s}' at index {d} from text '{s}'\n", .{ expected_token.symbol(), token.token_type.symbol(), index, token.text });
        }

        try std.testing.expect(token.token_type == expected_token);
    }
}
