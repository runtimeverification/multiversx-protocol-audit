
Test cases in this folder aim to cover all possible scenarios with the following limitations:

* The call graph between contracts forms a tree
* A node in this tree can be one of these:
  * sync internal node: calls 1 or 2 internal nodes synchronously
  * async internal node: calls 1 or 2 internal nodes asynchronously
  * leaf node: doesn't make any sync or async calls
* Maximum tree depth is 3

## Generating possible cases and naming 

```k
syntax Tree ::= async Shard | async2 Shard Shard 
              | sync Tree | sync2 Tree Tree

syntax Shard ::= intra | cross
```

### Examples

[aa(i,i)](aa(i,i).md): A contract that sends 2 cross-shard async calls

```k
syntax Tree ::= "aa(c,c)"      [function]
rule a2_c_c => async2 cross cross
```

All cases without symmetries

1. [a(i)](a(i).md)
2. [a(c)](a(c).md)
3. [aa(i,i)](aa(i,i).md)
4. [aa(i,c)](aa(i,c).md)
5. [aa(c,c)](aa(c,c).md)
6. [s_a(i)](s_a(i).md)
7. [s_a(c)](s_a(c).md)
8. [s_aa(i,i)](s_aa(i,i).md)
9. [s_aa(i,c)](s_aa(i,c).md)
10. [s_aa(c,c)](s_aa(c,c).md)
11. [ss_a(i)-a(i)](ss_a(i)-a(i).md)
12. [ss_a(i)-a(c)](ss_a(i)-a(c).md)
13. [ss_a(c)-a(c)](ss_a(c)-a(c).md)
14. [ss_a(i)-aa(i,i)](ss_a(i)-aa(i,i).md)
15. [ss_a(i)-aa(i,c)](ss_a(i)-aa(i,c).md)
16. [ss_a(i)-aa(c,c)](ss_a(i)-aa(c,c).md)
17. [ss_a(c)-aa(i,i)](ss_a(c)-aa(i,i).md)

The following cases are more complex variants of the above.

1. `ss_a(c)-aa(i,c)`: similar to [ss_a(c)-aa(i,i)](ss_a(c)-aa(i,i).md) and [ss_a(i)-aa(i,c)](ss_a(i)-aa(i,c).md)  
2. `ss_a(c)-aa(c,c)`
3. `ss_aa(i,i)-aa(i,i)`
4. `ss_aa(i,i)-aa(i,c)`
5. `ss_aa(i,i)-aa(c,c)`
6. `ss_aa(i,c)-aa(i,c)`
7. `ss_aa(i,c)-aa(c,c)`
8. `ss_aa(c,c)-aa(c,c)`

## Corner cases

Corner cases that are not covered in the above enumeration:

1. [as_a](as_a.md): Async call and sync call in the same contract