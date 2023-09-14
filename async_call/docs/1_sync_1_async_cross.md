

## 1 sync, 1 async call


```rust
shard S1 {

  trait C0 {
    storage = 0
    fn endpoint() {
      inc_storage()
      sync(C1)
      inc_storage()
    }
  }

  trait C1 {
    storage = 0
    fn endpoint() {
      inc_storage()
      async(C2, callback)
      inc_storage()
    }
    fn callback(res) {
      inc_storage()
    }
  }
}

shard S2 {
  trait C2 {
    storage = 0
    fn endpoint() {
      inc_storage()
    }
  }  
}
```

```
User -> C0 -sync-> C1 -> C0.remaining ~~> C2 ~~> C1.callback
```

Final storage after successful eecution:

```
C0 = 2
C1 = 3
C2 = 1
```

The following scenarios examine cases where any of these steps fail.

### The async call fails


```rust
shard S1 {

  trait C0 {
    storage = 0
    fn endpoint() {
      inc_storage()
      sync(C1)
      inc_storage()
    }
  }

  trait C1 {
    storage = 0
    fn endpoint() {
      inc_storage()
      async(C2, callback)
      inc_storage()
    }

    fn callback(res) {
      inc_storage()
    }
  }
}

shard S2 {
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
  participant User
  participant C0
  participant C1
  participant C2
  
  User ->>+ C0: call
  note over C0, C2: storage: C0 = 0, C1 = 0, C2 = 0
  
  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 1

  C0 ->>+ C1: execOnDestCtx(C0 -> C1)
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 1
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: inc_storage()

  note over C1: storage: C1 = 2
  
  C1 ->>- C0: VMOutput
  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 2
  
  note over C0, C2: storage: C0 = 2, C1 = 2, C2 = 0

  C0 ->>- C0: runtime completion
  C0 ->>+ C2: OutputTransfer via Metachain
  C2 ->> C2: inc_storage()
  note over C2: storage: C2 = 1
  
  C2 ->>- C2: throw_error()
  note over C2: rollback C2's state
  note over C0, C2: storage: C0 = 2, C1 = 2, C2 = 0
  C2 ->> C1: SCR via Metachain
  
  C1 ->>+ C1: execute callback
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 3

  C1 ->>- C0: notify parent
  note over C0, C2: storage: C0 = 2, C1 = 3, C2 = 0
  
   
```

### The callback fails


```rust
shard S1 {

  trait C0 {
    storage = 0
    fn endpoint() {
      inc_storage()
      sync(C1)
      inc_storage()
    }
  }

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
}

shard S2 {
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
  participant User
  participant C0
  participant C1
  participant C2
  
  User ->>+ C0: call
  note over C0, C2: storage: C0 = 0, C1 = 0, C2 = 0
  
  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 1

  C0 ->>+ C1: execOnDestCtx(C0 -> C1)
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 1
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: inc_storage()

  note over C1: storage: C1 = 2
  
  C1 ->>- C0: VMOutput
  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 2
  
  note over C0, C2: storage: C0 = 2, C1 = 2, C2 = 0

  C0 ->>- C0: runtime completion
  C0 ->>+ C2: OutputTransfer via Metachain
  C2 ->> C2: inc_storage()
  note over C2: storage: C2 = 1
  
  C2 ->>- C1: SCR via Metachain
  note over C0, C2: storage: C0 = 2, C1 = 2, C2 = 1
  
  C1 ->>+ C1: callback()
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 3
  C1 ->>- C1: throw_error()
  note over C1: rollback to pre-callback state
  note over C0, C2: storage: C0 = 2, C1 = 2, C2 = 1
  
  C1 ->> C0: notify parent
   
```

### The root call fails after sync call


```rust

shard S1 {

  trait C0 {
    storage = 0
    fn endpoint() {
      inc_storage()
      sync(C1)
      inc_storage()
      throw_error()
    }
  }

  trait C1 {
    storage = 0
    fn endpoint() {
      inc_storage()
      async(C2, callback)
      inc_storage()
    }

    fn callback(res) {
      inc_storage()
    }
  }
}

shard S2 {
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
  participant User
  participant C0
  participant C1
  participant C2
  
  User ->>+ C0: call
  note over C0, C2: storage: C0 = 0, C1 = 0, C2 = 0
  
  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 1

  C0 ->>+ C1: execOnDestCtx(C0 -> C1)
  C1 ->> C1: inc_storage()
  note over C1: storage: C1 = 1
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->> C1: inc_storage()

  note over C1: storage: C1 = 2
  
  C1 ->>- C0: VMOutput

  C0 ->> C0: inc_storage()
  note over C0: storage: C0 = 2

  C0 ->>- C0: throw_error()
  note over C0, C2: rollback everything to the initial state
  
  
  note over C0, C2: storage: C0 = 0, C1 = 0, C2 = 0
```