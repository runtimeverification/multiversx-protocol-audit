
## 1

```rust
shard Sh1 {
  contract C0 {
    fn method0() {
      sync(C1, method1)
      sync(C2, method2)
      compute("C0.end")
    }
  }

  contract C1 {
    fn method1() {
      async(C3, method3, callback)
    }

    fn callback() {  }
  }

  contract C2 {
    fn method2() {
      async(C4, method4, callback)
      async(C5, method5, callback)
    }

    fn callback() {  }
  }

  contract C3 {
    fn method3() {
    }
  }
}

shard Sh2 {
  contract C4 {
    fn method4() { }
  }
  contract C5 {
    fn method5() { }
  }
}

```

Everything is run as in [ss_a(i)-aa(i,c)](ss_a(i)-aa(i,c).md), except both async calls in `C2` are cross-shard. The async calls to `C4` and `C5` run after runtime completion of `C0`.
`C4` and `C5` are executed as in [aa(c,c)](aa(c,c).md).
