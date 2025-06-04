Part 1 was a breeze, but part 2 made me struggle due to how I came up with the solution for part 1.

I have two major mistakes in solving part 2:

1. I iterated through each file block from right to left (just like in part 1), the issue here is it caused the program to move the files that have already been moved once.
2. I tried to find the biggest space available on the left side of the file, even if the only thing that's needed is a size that's big enough. This caused smaller files with a bigger ID move to the biggest available space.

It took me a while to realize this since all of the test cases I've tried passed, but fixing those 2 issues made it work.
