
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
}

shard Sh2 {
  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
}

```

`C0`, `C1`, and `C2` are executed as in [s_a_i](s_a_i.md). Output transfers are sent after runtime completion of `C0`, then the async call to `C3` is executed as in the cross-shard execution of [s_a_i](s_a_i.md).

## 2

`C0` or `C1` fails after the async call registration: async all is cancelled, and everything is reverted.

## 3

`C2` or the callback fails: The error is handled as in [a_i#2](a_i.md#2) or [a_i#3](a_i.md#3).
