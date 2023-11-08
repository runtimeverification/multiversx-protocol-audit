# Nested async calls

```
C1 -async-> C2 -async-> C3
```

```rust
contract C1 {
  fn method1() {
    async(C2, method2, callback1)
  }
  fn callback1() {}
}

contract C2 {
  fn method2() {
    async(C3, method3, callback2)
  }
  fn callback2() {}
}

contract C3 {
  fn method3() { }
}
```

Nested async calls are not allowed in Async Calls V2. Therefore, `C2` throws an error while attempting to register an async call to `C3`. The execution will be similar to [a_(i)](a_(i).md) or [a_(c)](a_(c).md).