# Nested async calls

```
C1 -async-> C2 -async-> C3
```

```rust
contract C1 {
  fn method() {
    async(C2)
  }
  fn callback() {}
}

contract C2 {
  fn method() {
    async(C3)
  }
  fn callback() {}
}

contract C3 {
  fn method() { }
}
```

Nested async calls are not allowed in Async Calls V2. Therefore, `C2` throws an error while attempting to register an async call to `C3`. The execution will be similar to [a_(i)](a_(i).md) or [a_(c)](a_(c).md).