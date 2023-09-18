
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
}

shard Sh2 {
  contract C3 {
    fn method3() {
      compute("C3")
    }
  }
}

```


```mermaid
sequenceDiagram
  participant User
  participant C1
  participant C2
  participant Metachain
  participant C3
  
  User ->>+ C1: call
  C1 ->> C1: register async(C2, C1.callback2)
  C1 ->> C1: register async(C3, C1.callback3)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: execOnDestCtx(C1->C2)
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2->C1, callback2)
  C1 ->> C1: compute(C1.cb3)
  C1 ->>- C1: CbVMOutput
  
  C1 ->>+ C3: OutputTransfer(C1 -> C3)<br/>via Metachain
  C3 ->> C3: compute(C3)
  C3 ->>- C1: SCR via Metachain

  C1 ->>+ C1: execute(C3->C1, callback3)
  C1 ->> C1: compute(C1.cb3)
  C1 ->>- C1: CbVMOutput

  C1 ->> C1: complete
```

## Failure cases

Errors in one async call does not affect the other async call. Even if the execution of C2 in the first shard fails, the async call to C3 will be executed on the second shard. 