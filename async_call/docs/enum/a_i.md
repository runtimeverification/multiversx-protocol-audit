
## 1 

Successfull case

```rust

shard Sh1 {
  contract C1 {
    fn method1() {
      async(C2, callback)
      compute("C1.end")
    }

    fn callback() {
      compute("C1.cb")
    }
  }

  contract C2 {
    fn method2() {
      compute("C2")
    }
  }
  
}

```


```mermaid
sequenceDiagram
  User ->>+ C1: call
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: CbVMOutput
  
  C1 ->> C1: complete
```

## 2

The async call fails

```rust

shard Sh1 {
  contract C1 {
    fn endpoint() {
      async(C2, callback)
    }

    fn callback(res) {
      compute("C1.cb")
    }
  }

  contract C2 {
    fn endpoint() {
      compute("C2")
      throw_error()
    }
  }
  
}

```



```mermaid
sequenceDiagram
  participant User
  participant C1
  participant C2
  
  note over C1, C2: state: S0
  User ->>+ C1: call
  C1 ->>- C1: register async(C2, C1.callback)
  note over C1, C2: state: S1
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: compute(C2)
  note over C1, C2: state: S2
  C2 ->>- C2: throw_error()
  note over C2: rollback to S1
  note over C1, C2: state: S1
  C2 ->> C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: CbVMOutput
  C1 ->> C1: complete
  note over C1, C2: state: S3  
```

## 3

The callback fails

```rust

shard Sh1 {
  contract C1 {
    fn endpoint() {
      async(C2, callback)
    }

    fn callback(res) {
      compute("C1.cb")
      throw_error()
    }
  }

  contract C2 {
    fn endpoint() {
      compute("C2")
    }
  }
}
```

```mermaid
sequenceDiagram
  participant User
  participant C1
  participant C2
  
  note over C1, C2: state: S0
  User ->>+ C1: call
  C1 ->>- C1: register async(C2, C1.callback)
  note over C1, C2: state: S1
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: compute(C2)
  note over C1, C2: state: S2

  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  note over C1, C2: state: S3
  C1 ->>- C1: throw_error()
  note over C1: rollback to S2
  C1 ->> C1: complete
  note over C1, C2: state: S2
```

## 4

`C1` fails after async registration: the async call is cancelled, everything is reverted.