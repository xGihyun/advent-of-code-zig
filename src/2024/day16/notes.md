### Part 1

Another pathfinding problem, but using Dijkstra's Algorithm for the first time. I first thought that using BFS would be enough since each move is 1 point each, but with since a rotation adds 1000 points, then it won't work.
Dijkstra's Algorithm is what's needed for this kind of problem, and I just learned that Dijkstra's is just BFS but with a priority queue instead of a normal queue.

Implementing Dijkstra's wasn't too difficult. I may have overcomplicated the rotations with the use of enums when `DELTA_X` and `DELTA_Y` may have been enough, but it's still readable and it worked well.

### Part 2

After some trial and error with how to keep track of the optimal paths. What I ended up doing was doing the same thing on part 1 but with dynamic programming to keep track of the best scores and predecessors of a current state.
After computing the best scores, I used DFS to backtrack the paths that gave the best score and set `on_best_path` to `true`.

The number of tiles that reach the best path is just counting how many `true`s are there in the `on_best_path` array.
The code was messy, but I don't really feel like cleaning it up for now.
