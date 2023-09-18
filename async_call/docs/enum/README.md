
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

[a2_c_c](a2_c_c.md): A contract that sends 2 cross-shard async calls

```k
syntax Tree ::= "a2_c_c"      [function]
rule a2_c_c => async2 cross cross
```

All cases without symmetries

1. [x] A I
1. [x] A C
1. [x] A2 I I
1. [x] A2 I C
1. [x] A2 C C
1. [x] S (A I)
1. [x] S (A C)
1. [x] S (A2 I I)
1. [x] S (A2 I C)
1. [x] S (A2 C C)
1. [x] S2 (A I) (A I)
1. [ ] S2 (A I) (A C)
1. [ ] S2 (A I) (A2 I I)
1. [ ] S2 (A C) (A C)
1. [ ] S2 (A I) (A2 I C)
1. [ ] S2 (A C) (A2 I I)
1. [ ] S2 (A I) (A2 C C)
1. [ ] S2 (A C) (A2 I C)
1. [ ] S2 (A2 I I) (A2 I I)
1. [ ] S2 (A C) (A2 C C)
1. [ ] S2 (A2 I I) (A2 I C)
1. [ ] S2 (A2 I I) (A2 C C)
1. [ ] S2 (A2 I C) (A2 I C)
1. [ ] S2 (A2 I C) (A2 C C)
1. [ ] S2 (A2 C C) (A2 C C)

