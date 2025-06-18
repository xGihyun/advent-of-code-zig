### Part 1

Another pathfinding problem, but using Dijkstra's Algorithm for the first time. I first thought that using BFS would be enough since each move is 1 point each, but with since a rotation adds 1000 points, then it won't work.
Dijkstra's Algorithm is what's needed for this kind of problem, and I just learned that Dijkstra's is just BFS but with a priority queue instead of a normal queue.

Implementing Dijkstra's wasn't too difficult. I may have overcomplicated the rotations with the use of enums when `DELTA_X` and `DELTA_Y` may have been enough, but it's still readable and it worked well.
