# Advent of Code

My solutions written in [Zig](https://ziglang.org/).

Not all solutions are here, as I haven't finished it yet. I'm currently working on AOC 2024.

## How to Use

Make sure to install the latest stable version of Zig.
This repository currently uses version `0.14.0`.

Verify the installation and version of Zig:

```bash
$ zig version
0.14.0
```

Clone this repository, then build and run:

```bash
zig build run -- <year> <day> <part>
```

For example:

```bash
$ zig build run -- 2024 1 1
1234567 # Or whatever the correct answer is
```


> [!IMPORTANT]
> Each `day{N}/` folder should have an `input.txt` that contains the official input.
> Since sharing of inputs is prohibited, you must create your own. 

You may also run the tests I've included if available:

```bash
$ zig test src/2024/day9/part1.zig
All 2 tests passed.
```
