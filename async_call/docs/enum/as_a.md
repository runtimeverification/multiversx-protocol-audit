# Async and sync calls in the same contract


```rust
contract C0 {
  fn method0() {
    async(C2, callback)
    sync(C1)
  }

  fn callback() { }
}

contract C1 {
  fn method1() {
    async(C3, callback)
  }

  fn callback() { }
}

contract C2 {
  fn method2() { }
}

contract C3 {
  fn method2() { }
}
```

In this example, `C0` registers an async call to `C2` and then calls `C1` synchronously.
Execution order of the async calls varies depending on whether they are cross-shard or not.

## Intra-shard

Since local calls are executed after the runtime completion of the caller, `C2` will be executed after `C3` 

```
1. C0
   1. register C2
   2. sync call to C1
      1. register C3
      2. execute C3 and the callback  <<< C3
   3. execute C2 and the callback     <<< C2
```

## Cross-shard

If `C0` and `C1` are in `Shard1`, and `C2` and `C3` are in `Shard2`; `C2` will be executed before `C3` because the order is preserved.

```
1. C0
   1. register C2
   2. sync call to C1
      1. register C3
2. execute C2 and the callback  <<< C2
3. execute C3 and the callback  <<< C3
```
