
## 1

```rust
shard Sh1 {
  contract C0 {
    fn method0() {
      sync(C1)
      compute("C0.end")
    }
  }
  contract C1 {
    fn method1() {
      async(C2, callback)
      async(C3, callback)
      compute("C1.end")
    }

    fn callback() {
      compute("C1.cb")
    }
  }

  contract C2 {
    fn method2() {
      compute("C2")
    }
  }

  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
}

```

`C0` makes a sync call to `C1`. `C1`, `C2` (async), and `C3` (async) are executed as in [aa(i,i)](aa(i,i).md). After the callbacks, `C0` continues the execution.

Execution order:

```
C0 > C1 > C2 > C1.callback > C3 > C1.callback > C0.remaining 
```

## 2

`C0` or `C1` fails after the async call registration: async calls are cancelled, and everything is reverted.
