### Part 1

A tough problem that's different from most of the previous problems that simply required some search algorithm.
Solving part 1 took a while, but after understanding each requirement, it's not that bad. Separating each instruction on their own function made this problem a lot easier. 

### Part 2

The hard part. It was easy to come up with a brute force solution, but it's definitely not gonna work unless you want to make your CPU suffer.
The solution was to do [bit shifting](https://en.wikipedia.org/wiki/Bitwise_operation), a topic I haven't applied practically. 
After learning how the solution works, it was surprising how simple it was. 
You simply build the correct value of `Register A` one digit at a time by testing each 3 bit number if it produces the correct value given the test `A` value using the current 3 bit number.
