Part 1 wasn't too bad with a brute force approach, I was initially worried about the performance issues, but it turned out to be fine for this.

However, part 2 is where my worries about performance came true. It took me around ~40 minutes trying to think of a proper solution, like trying a depth-first approach instead of a breadth-first like in part 1, but that would have the same issues.
I ended up thinking of dynamic programming as the only possible solution, but I'm really rusty in DP. While I don't like it, I ended up consulting with AI for some clues on how to approach this and came up with a bottom-up approach.

The current solution for part 2 counts for how many stones have each unique value rather than iterating through each stone and recomputing every value.
It iterates through each blink and we get the value it turns into based on the conditions. The new value's count would then be added by the previous count to prevent redundant calculations.
