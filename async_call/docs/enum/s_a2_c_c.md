
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
}

shard Sh2 {
  contract C2 {
    fn method2() {
      compute("C2")
    }
  }
}

shard Sh3 {
  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
}

```

`C0` and `C1` are executed as in [s_a_c](s_a_c.md), except `C1` registers 2 async calls.

1. If any error occurs, everything is reverted.
2. If `C0` and `C1` succeeds, output transfers are sent to `Sh2` and `Sh3` via Metachain at the end of `C0`.
3. Cross-shard calls and their callbacks are executed as in [a2_c_c](a2_c_c.md).
4. Once both callbacks are done, `C1` reaches logical completion, and notifies `C0`.
