Just like on day 10, this one can be solved using DFS. 

For part 1, counting the area is pretty straightforward. For the perimeter, we count it if we're going out of bounds or if we're next to a different plant type.

Part 2 was a bit more tricky, and I tried to get fancy by using a set (via `AutoHashMap`), but that didn't work for concave/convex corners. I just used a brute force solution that looks pretty dirty, but it works well anyway.


