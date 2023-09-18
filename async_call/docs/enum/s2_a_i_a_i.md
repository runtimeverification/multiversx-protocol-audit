
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
      async(C3, callback3)
      compute("C1.end")
    }

    fn callback3() {
      compute("C1.cb3")
    }
  }

  contract C2 {
    fn method2() {
      async(C4, callback3)
      compute("C2.end")
    }

    fn callback4() {
      compute("C2.cb4")
    }
  }

  contract C3 {
    fn method3() {
      compute("C3")
    }
  }

  contract C4 {
    fn method4() {
      compute("C4")
    }
  }
}

```

`C0` makes a sync call to `C1`. 
* `C1`, `C3` and the callback are executed as in [a_i](a_i.md). After the callback, `C0` calls `C2`.
* `C2`, `C4` and the callback are executed as in [a_i](a_i.md).

If an error occurs in `C0`, `C1` or `C2`, everything is reverted. 

## 2

`C0` or `C1` fails after the async call registration: async all is cancelled, and everything is reverted.
