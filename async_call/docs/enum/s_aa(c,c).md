
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

`C0` and `C1` are executed as in [s_a(c)](s_a(c).md), except `C1` registers 2 async calls.

1. If any error occurs, everything is reverted.
2. If `C0` and `C1` succeeds, output transfers are sent to `Sh2` and `Sh3` via Metachain at the end of `C0`.
3. Cross-shard calls and their callbacks are executed as in [aa(c,c)](aa(c,c).md). If `C2` and `C3` are in the same shard, they run in the order of registration.
4. Once both callbacks are done, `C1` reaches logical completion, and notifies `C0`.
