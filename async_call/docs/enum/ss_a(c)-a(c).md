
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
}

shard Sh2 {
  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
}

shard Sh3 {
  contract C4 {
    fn method4() {
      compute("C4")
    }
  }
}

```

`C0` makes two sync calls to `C1` and `C2`, both registers an async call.
* After the runtime completion of `C0`, output transfers are sent to the destination shards.
* `C3` and `C4` run as in [aa(c,c)](aa(c,c).md).
  * If they are in the same shard, they run sequentially preserving the registration order.
  * Otherwise, they run in parallel.

If an error occurs in `C0`, `C1` or `C2`, everything is reverted. 

## 2

`C0` or `C1` fails after the async call registration: async all is cancelled, and everything is reverted.
