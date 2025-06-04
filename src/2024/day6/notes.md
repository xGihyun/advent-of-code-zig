Part 1 wasn't too bad, although I may have gotten a bit fancy with the struct, but it's nothing complex.

Part 2 gave me a difficult time, my biggest mistake was:

- When performing the simulation with the new obstacle, I put the guard's position just before the position where the obstacle was placed. This would mean that placing an obstacle on a position that the guard has visited before would mess with the guard's original path.

The correct way to do it is to either:

- Simulate starting from the guard's original starting position (inefficient) or;
- Simulate start from the guard's current position, and only place the obstacle if it the guard hasn't visited that position.

I implemented the latter which gave me the correct answer. However, the execution time was still very slow (7~ seconds).
After some time, I got the idea of using a boolean array from YouTube, and it was drastically faster than my initial solution of using a hashmap.

This might be confusing at first since hashmaps are generally known to be fast, but that's specifically for finding stuff. The problem here wasn't finding an element, but maintaining the hashmap itself, especially the repeated allocation and deallocation.
