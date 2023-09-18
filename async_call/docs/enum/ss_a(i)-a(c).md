
## 1

```rust
shard Sh1 {
  contract C0 {
    fn method0() {
      sync(C1)
      sync(C2)
      compute("C0.end")
    }
  }

  contract C1 {
    fn method1() {
      async(C3, callback)
      compute("C1.end")
    }

    fn callback() {
      compute("C1.cb")
    }
  }

  contract C2 {
    fn method2() {
      async(C4, callback)
      compute("C2.end")
    }

    fn callback() {
      compute("C2.cb")
    }
  }

  contract C3 {
    fn method3() { }
  }
}

shard Sh2 {
  contract C4 {
    fn method4() {
      compute("C4")
    }
  }
}

```

`C0` makes a sync call to `C1`. 
* `C1`, `C3` and the callback are executed as in [a(i)](a(i).md). After the callback, `C0` calls `C2`.
* `C2` runs as in [a(c)](a(c).md) and registers an async call. The output transfer is sent after runtime completion of `C0`.

If an error occurs in `C0`, `C1` or `C2`, everything is reverted. 

## 2

`C0` or `C1` fails after the async call registration: async all is cancelled, and everything is reverted.
