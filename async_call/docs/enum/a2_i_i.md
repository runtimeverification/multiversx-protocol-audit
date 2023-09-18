
## 2 async call

```rust

shard Sh1 {
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
  
  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
  
}

```


```mermaid
sequenceDiagram
  User ->>+ C1: call
  C1 ->> C1: register async(C2, C1.callback2)
  C1 ->> C1: register async(C3, C1.callback3)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: execOnDestCtx(C1->C2)
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2->C1, callback2)
  C1 ->> C1: compute(C1.cb2)
  C1 ->>- C1: CbVMOutput
  
  C1 ->>+ C3: execOnDestCtx(C1->C3)
  C3 ->> C3: compute(C3)
  C3 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C3->C1, callback3)
  C1 ->> C1: compute(C1.cb3)
  C1 ->>- C1: CbVMOutput

  C1 ->> C1: complete
```

## Failure cases

Errors in one async call does not affect the other async call. An error in C2 doesn't cancel the async call to C3. Errors in async calls are handled independently as in [a_i.md](a_i.md).