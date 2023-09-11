## Intra shard

```rust
shard 1 {
  sc A {
    method methodA {
      compute("A")
      async(B, methodB, cbAB)
      compute("A done")
    }

    callback cbAB { 
      compute("callback B->A")
    }

  }

  sc B {
    method methodB {
      compute("B")
    }
  }
}
```

User calls SC A

```mermaid
sequenceDiagram
  
  User ->> SC A: call(A, methodA)
  SC A ->>+ SC A: runSCCall(User->A, methodA)

  SC A ->> SC A: compute("A")
  
  SC A ->> SC A: newAsyncCall(A->B, methodB, cbAB)
  note right of SC A: registered an async call

  SC A ->> SC A: compute("A done")
  
  note over SC A, SC B: execute the async call and cb locally

  SC A ->>+ SC B: execOnDestCtx(A->B, methodB)
  SC B ->> SC B: compute("B")
  SC B ->>- SC A: VMOutput

  SC A ->>+ SC A: execOnDestCtx(B->A, cbAB)
  SC A ->> SC A: compute("callback B->A")
  SC A ->>- SC A: callback VMOutput

  SC A ->>- SC A: done
```

## Multi-level Intra shard

```rust
shard 1 {
  sc A {
    method methodA {
      setStorage("my_int", 1)
      async(B, methodB, cbAB)
    }

    callback cbAB(res) { 
      match res {
        Ok => compute("done");
        Err => compute("failed")
    }

  }

  sc B {
    method methodB {
      async(B, methodB)
    }
  }

  sc C {
    method methodB { }
  }
}
```

User calls SC A

```mermaid
sequenceDiagram
  participant User
  participant SC A
  participant SC B
  
  User ->> SC A: call(A, methodA)
  SC A ->>+ SC A: runSCCall(User->A, methodA)

  SC A ->> SC A: setStorage("x", 1)
  
  SC A ->> SC A: newAsyncCall(A->B, methodB, cbAB)
  note right of SC A: registered an async call
  
  note over SC A, SC B: execute the async call and cb locally

  SC A ->>+ SC B: execOnDestCtx(A->B, methodB)
  SC B ->> SC B: newAsyncCall(B->C, methodC) REJECT!!!
  SC B ->>- SC A: VMOutput with error

  SC A ->>+ SC A: execOnDestCtx(B->A, cbAB)
  SC A ->> SC A: compute("failed")
  SC A ->>- SC A: callback VMOutput

  SC A ->>- SC A: done

  note over SC A, SC B: my_int == 1, changes in methodA are not reverted
```

## Intra and cross shard

```
shard 1 {
  sc A {
    method methodA {
      compute("A")
      async(B, methodB, cbAB)
      async(C, methodC, cbAC)
      compute("A done")
    }

    callback cbAB { 
      compute("callback B->A")
    }

    callback cbAC { 
      compute("callback C->A")
    }
  }

  sc C {
    method methodC {
      compute("C")
    }
  }
}

shard 2 {
  sc B {
    method methodB {
      compute("B")
    }
  }
}
```

User calls SC A

```mermaid
sequenceDiagram
  participant User
  participant Shard1
  participant Metachain
  participant Shard2
  
  User ->> Shard1: call(A, methodA)
  Shard1 ->>+ Shard1: runSCCall(User->A, methodA)

  Shard1 ->> Shard1: compute("A")
  
  Shard1 ->> Shard1: newAsyncCall(A->B, methodB, cbAB)
  Shard1 ->> Shard1: newAsyncCall(A->C, methodC, cbAC)
  note right of Shard1: registered 2 async calls

  Shard1 ->> Shard1: compute("A done")
  
  Shard1 ->>+ Shard1: execOnDestCtx(A->C, methodC)
  Shard1 ->>- Shard1: compute("C")

  Shard1 ->>+ Shard1: execOnDestCtx(C->A, cbAC)
  Shard1 ->>- Shard1: compute("callback C->A")
  note right of Shard1: executed async call<br/>and cb locally

  Shard1 ->>- Metachain: outputTransfer(A->B, methodB)
  
  Metachain ->> Shard2: outputTransfer(A->B, methodB)
  note over Metachain: output transfer propagated to Shard2 via metachain


  Shard2 ->>+ Shard2: runSCCall(A->B, methodB)

  Shard2 ->> Shard2: compute("B")

  Shard2 ->>- Metachain:  SCR()
  Metachain ->> Shard1: SCR()
  
  Shard1 ->>+ Shard1: runSCCall(B->A, cbAB)
  Shard1 ->> Shard1: compute("callback B->A")
  Shard1 ->>- Shard1: notifyParent
```

