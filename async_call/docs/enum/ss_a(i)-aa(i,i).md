
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

    fn callback() { }
  }

  contract C2 {
    fn method2() {
      async(C4, method4, callback)
      async(C5, method5, callback)
    }

    fn callback() { }
  }

  contract C3 {
    fn method3() { }
  }

  contract C4 {
    fn method4() { }
  }

  contract C5 {
    fn method5() { }
  }
}

```

Everything is run as in [ss_a(i)-a(i)](ss_a(i)-a(i).md), except `C2` registers 2 async calls, and the async call to `C5` runs after `C4` and the callback. 
