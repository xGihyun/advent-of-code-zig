Solving the problem itself wasn't too bad, the issue was the performance of my code.

Initially, I tried to generate every possible permutations of the given operation, and as expected, that was really slow.
So I proceeded to do the operations on the go, which worked pretty well.

However, there was still a major performance issue. 

Just like in Day 6, using `std.fmt.allocPrint()` to concatenate the number would repeatedly allocate and deallocate memory, leading to horrible performance.
I did some research after, then I found out that you could also concatenate numbers by doing some math operations which led to a ~98% increase in performance.

