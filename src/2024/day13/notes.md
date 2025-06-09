### Part 1

Part 1 was already tricky. When I first saw it, it reminded be of the coin change problem that can be solved using dynamic programming. I tried to implement it, but things went wrong since we're keeping track of two values (`x` and `y`), so the 1D DP approach didn't work---it was overkill.

**_Would it work with a 2D DP approach?_** <br>
I think it would, but I'm not sure how it would perform as complexity grows.

I did some research and found out about [Cramer's Rule](https://en.wikipedia.org/wiki/Cramer's_rule) which can be used to solve this problem. I spent around 40 minutes trying to figure out the gist on how the math works, and I barely understood it since it involved topics like matrices which I haven't applied in a practical scenario. <br>
From my understanding, the buttons A and B are vectors in a 2D space, and we need to find out how many times we need to press those buttons in order to get the target position. Apparently, this is a 2x2 linear system that can be solved with Cramer's Rule.
Since Cramer's Rule gives the unique solution for the linear system, then it would also be the minimum number of presses since **no other combinations of presses would work**.

**_How is it that there's exactly one solution?_** <br>
It's because we compute for the [determinant](https://en.wikipedia.org/wiki/Determinant).

> "The determinant is nonzero if and only if the matrix is invertible and the corresponding linear map is an isomorphism."

For this problem, the buttons have unique values, so if we plug them in a 2x2 linear system:

```
| A.x B.x | = | 94 22 |
| A.y B.y |   | 34 67 |
```

It would give us exactly one solution.

**_What if the determinant is zero?_** <br>
It would mean that the matrix has no inverse or the points of buttons A and B are colinear. So it could either have no solution or infinitely many solutions. This can easily be spotted since we need to divide by the determinant, and dividing by zero is impossible.

***Why does it work?*** <br>
When we swap one of the determinant's columns (`a` or `b`) with the target value and divide by the original determinant, we get exactly how much of `a` or `b` is needed (how much button presses are needed).

### Part 2

Thanks to Cramer's Rule, the only thing needed here is to simply add 10 trillion to the prizes' positions.
Even with larger values, the execution time is still ~3 ms since we compute the minimum number of tokens at constant time (for each machine).

The time complexity is `O(n)`.
