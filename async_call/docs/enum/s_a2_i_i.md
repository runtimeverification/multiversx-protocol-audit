
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
      async(C2, callback2)
      async(C3, callback3)
      compute("C1.end")
    }

    fn callback2() {
      compute("C1.cb2")
    }
    fn callback3() {
      compute("C1.cb3")
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

`C0` makes a sync call to `C1`. `C1`, `C2` (async), and `C3` (async) are executed as in [a2_i_i](a2_i_i.md). After the callbacks, `C0` continues the execution.

## 2

`C0` or `C1` fails after the async call registration: async calls are cancelled, and everything is reverted.
