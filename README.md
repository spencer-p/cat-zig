# cat-zig
## A Zig implementation of cat(1) for \*nix

[Zig](https://ziglang.org/) is a systems programming language that aims to
compete with C. A good litmus test for systems programming languages is how easy
it is to write common Unix utilities, and `cat(1)` is arguably the simplest of
these.

For this exercise, I chose to target Zig 0.6.0 as a stable release. I am doing
things the Unix way and relying on the standard open/close, read/write syscalls
instead of the standard library (see TODO for a idiomatic version). Finally, I'm
aiming for feature parity with the PDP 11 version of cat, which as far as I know
was shipped with the first Unix. [You can read about this version in depth at
TwoBitHistory](https://twobithistory.org/2018/11/12/cat.html).

## Feature requirements

1. Read the contents of the filenames passed as arguments and write them to
   standard output, in order.
1. If no arguments are supplied, read from standard input.
1. The special filename `-` is treated as standard input.
1. Standard input can be read from multiple times.
1. Buffer the reads and writes. This is not strictly a requirement, but good
   practice so you don't spend all your execution time in an interrupt sequence.
   The standard C version of cat does not make this buffering explicit, but
   these sorts of I/O optimizations are important.

## Takeways: The Good

 - **Error handling**: Zig makes error handling explicit. It is actually difficult
   to write code that ignores an error. The possibility for an error to occur is
   notated at function callsite and in the function's return value.
 - **Structs are fun**: In C, making a data type to obscure complexity is in
   itself complex. There's a lot of work to make it happen. In most other
   languages, new ideas like objects and classes have to be dreamt up. In Zig,
   adding a new struct is easy. It feels as tightly coupled as Python (with
   universal calling syntax and methods scoped inside the definition), and as
   homely as C (static types, curly braces, static definitions (I think?)).
 - **Defer**: Defer elimates many resource-leaking bugs. Every language should
   have it.
 - **Strong types**: C's type system is far more loose than many understand.
   Having types with defined widths and well defined operations (and casting!)
   is a huge plus.
 - **Optional types**: Optional types are super useful! No further comment.
 - **Error unions**: I might prefer multiple return types, but having an error
   type and being able to couple it with other return types is great.

## Takeaways: The Bad
 - **Program arguments are painful**: How do I read program arguments in Zig?
   Well, the standard library offers `std.process.ArgsIterator`, which has a
   `next()` method that returns `?NextError![]u8`. This touches on a few issues.
   What is this thing and why is it so different from other languages?  How do I
   use it?  What is that return type? How do I iterate on it?
 - **No strings**: Zig doesn't have a string type. It has a `[]u8` type, or a
   slice of bytes, which is *okay*. This is why arguments are not supplied
   easily: They would have to be converted between C-style strings and Zig
   slices. There is a bit of fighting the compiler around the differences
   between C-style strings, `[]u8`, `[*]u8`, `[5]u8` (an array of `u8` of length
   5) and `[]const u8`. In general, I found it not bad to upcast "strings" to a
   constant slice. Another important issue with a lack of a string type (or type
   for a single unicode codepoint) is the multitude of bugs that will be
   introduced by anybody that needs to *do* anything with non-ASCII text.
 - **What's going on with loops?** Zig has two loop constructs, `for` and
   `while`, neither of which look like any C or Algol derived language. Both of
   these loop constructs are difficult to understand at first and my impression
   is that they are littered with special cases. The traditional control flow
   for these keywords is dead simple, and you can easily figure out how to
   achieve the execution order you want. Zig's loops seem to obfuscate the state
   changes and conditions that are checked on each iteration.

## Conclusion

Zig is exciting! I'm looking forward to a 1.0 release with fewer pain points.
