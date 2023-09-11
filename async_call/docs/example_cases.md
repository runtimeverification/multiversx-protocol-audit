## Case 1

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
      execOnDestCtx(D, methodD)
      compute("B done")
    }
  }
  sc D {
    method methodD {
      compute("D")
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
  Shard2 ->>+ Shard2: execOnDestCtx(B->D, methodD)
  Shard2 ->>- Shard2: compute("D")

  Shard2 ->> Shard2: compute("B done")

  Shard2 ->>- Metachain:  SCR()
  Metachain ->> Shard1: SCR()
  
  Shard1 ->>+ Shard1: runSCCall(B->A, cbAB)
  Shard1 ->> Shard1: compute("callback B->A")
  Shard1 ->>- Shard1: notifyParent
```


## Case 2

```
shard 1 {
  sc A {
    method methodA {
      compute("A1")
      execOnDestCtx(B, methodB)
      compute("A2")
    }
  }

  sc B {
    method methodB {
      compute("B1")
      async(C, methodC, cbB)
      compute("B2")
    }

    callback cbB {
      compute("callback")
    }
  }

  sc C {
    method methodC {
      compute("C")
    }
  }
  
}
```

```
A1 > B1 > register async > B2 > C > callback > A2
```

```mermaid
sequenceDiagram

  User ->> SC A: call(A, methodA)
  SC A ->>+ SC A: runSCCall(User->A, methodA)

  SC A ->> SC A: compute("A1")
  SC A ->>+ SC B: execOnDestCtx(<br/>A->B, methodB)
  SC B ->> SC B: compute("B1")
  
  
  SC B ->> SC B: newAsyncCall(B->C, methodC, cbB)
  SC B ->> SC B: compute("B2")
  
  SC B ->>+ SC C: execOnDestCtx(<br/>B->C, methodC)
  SC C ->> SC C : compute("C")
  SC C ->>- SC B : vmOutput

  SC B ->>+ SC B: execOnDestCtx(C->B, cbB)
  SC B ->> SC B: compute("callback")
  SC B ->>- SC B: vmOutput

  SC B ->>- SC A: vmOutput


  SC A ->> SC A: compute("A2")

  SC A ->>- SC A: vmOutput
```
