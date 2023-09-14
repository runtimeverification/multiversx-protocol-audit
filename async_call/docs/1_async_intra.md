
## 1 async call

```rust

shard S1 {
  trait C1 {
    fn endpoint() {
      compute("C1.1")
      async(C2, callback)
      compute("C1.2")
    }

    fn callback() {
      compute("C1.cb")
    }
  }

  trait C2 {
    fn endpoint() {
      compute("C2")
    }
  }
  
}

```


```mermaid
sequenceDiagram
  User ->>+ C1: call
  C1 ->> C1: compute(C1.1)
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: compute(C1.2)
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: CbVMOutput
  
  C1 ->>- C1: complete
```

## 1 async call, call fails


```rust

shard S1 {
  trait C1 {
    storage = 0
    fn endpoint() {
      inc_storage()
      async(C2, callback)
      inc_storage()
    }

    fn callback(res) {
      compute("C1.cb")
    }
  }

  trait C2 {
    storage = 0
    fn endpoint() {
      inc_storage()
      throw_error()
    }
  }
  
}

```



```mermaid
sequenceDiagram
  User ->>+ C1: call
  note over C1, C2: storage: C1 = 0, C2 = 0
  C1 ->> C1: inc_storage()
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: inc_storage()
  note over C1, C2: storage: C1 = 2, C2 = 0
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: inc_storage()
  note over C1, C2: storage: C1 = 2, C2 = 1
  C2 ->> C2: throw_error()
  note over C2: rollback C2's state
  note over C1, C2: storage: C1 = 2, C2 = 0
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: CbVMOutput
  
  C1 ->>- C1: complete
  note over C1, C2: storage: C1 = 2, C2 = 0
```

## 1 async call, callback fails


```rust

shard S1 {
  trait C1 {
    storage = 0
    fn endpoint() {
      inc_storage()
      async(C2, callback)
      inc_storage()
    }

    fn callback(res) {
      inc_storage()
      throw_error()
    }
  }

  trait C2 {
    storage = 0
    fn endpoint() {
      inc_storage()
    }
  }
  
}

```



```mermaid
sequenceDiagram
  User ->>+ C1: call
  note over C1, C2: storage: C1 = 0, C2 = 0
  C1 ->> C1: inc_storage()
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 2
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: inc_storage()
  note over C2: storage: C2 = 1
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 3
  C1 ->> C1: throw_error()
  note over C1: rollback C1's state to pre-callback
  note over C1: storage: C1 = 2
  C1 ->>- C1: CbVMOutput
  
  C1 ->>- C1: complete
  note over C1, C2: storage: C1 = 2, C2 = 1
```

