### Part 1

Looked complex at first, but it wasn't too bad after writing a horrible brute force solution that somehow worked.

### Part 2

Pretty hard, and building on top of my part 1 solution certainly doesn't work.

It took me a while, but I've managed to solve it. I finally implemented [BFS](https://en.wikipedia.org/wiki/Breadth-first_search) properly for the first time thanks to this problem.
For moving left and right, the same code for part 1 still works. The tricky part was moving up and down, since I had to account for the adjacent boxes that aren't aligned.
Initially, I approached this by initializing a `DELTA_X` to be used in the BFS part, but I realized that ended up being my biggest mistake since I was already storing the whole box `[]`, so there was no point in checking the diagonals since all the boxes would touch each other anyway.

The code I wrote looks very messy, it might be the worst lines of code I've written in a while. However, it does work and performance isn't an issue.
