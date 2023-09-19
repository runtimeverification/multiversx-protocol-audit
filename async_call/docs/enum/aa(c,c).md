## 2 async call, both cross shard, to same shard

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
}

shard Sh2 {
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
  participant User
  participant C1
  participant Shard2
  participant C2
  participant C3
  
  User ->>+ C1: call
  C1 ->> C1: register async(C2, C1.callback2)
  C1 ->> C1: register async(C3, C1.callback3)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->> Shard2: OutputTransfer(C1 -> C2)<br/>OutputTransfer(C1 -> C3)<br/>via Metachain

  Shard2 ->>+ C2: OutputTransfer(C1 -> C2) 
  C2 ->> C2: compute(C2)
  C2 ->>- Shard2: SCR2

  par C2 callback
    Shard2 ->> C1: SCR2
    C1 ->>+ C1: execute(C2->C1, callback2)
    C1 ->> C1: compute(C1.cb2)
    C1 ->>- C1: notify parent
  and C3 and its callback
    Shard2 ->>+ C3: OutputTransfer(C1 -> C3) 
    C3 ->> C3: compute(C3)
    C3 ->>- Shard2: SCR3
    Shard2 ->> C1: SCR3
  end
  C1 ->>+ C1: execute(C3->C1, callback3)
  C1 ->> C1: compute(C1.cb3)
  C1 ->>- C1: notify parent

  C1 ->> C1: complete
```

Execution order between `C2` and `C3` is preserved, i.e., `C2` is guaranteed to run before `C3`. Similarly, `SCR2` (result of `C2`) always arrives at `C1` before `SCR3`, so `callback2` is executed before `callback3`.

## 2 async call, both cross shard, different shards

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
}

shard Sh2 {
  contract C2 {
    fn method2() {
      compute("C2")
    }
  }
}

shard Sh3 {
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
  participant Metachain
  participant C2
  participant C3
  
  User ->>+ C1: call
  C1 ->> C1: register async(C2, C1.callback2)
  C1 ->> C1: register async(C3, C1.callback3)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ Metachain: OutputTransfer(C1 -> C2)<br/>OutputTransfer(C1 -> C3)

  par C2
  Metachain ->>+ C2: OutputTransfer(C1 -> C2) 
  C2 ->> C2: compute(C2)
  C2 ->>- C1: SCR via Metachain

  C1 ->>+ C1: execute(C2->C1, callback2)
  C1 ->> C1: compute(C1.cb2)
  C1 ->>- C1: notify parent

  and C3
  Metachain ->>+ C3: OutputTransfer(C1 -> C3) 
  C3 ->> C3: compute(C3)
  C3 ->>- C1: SCR via Metachain

  C1 ->>+ C1: execute(C3->C1, callback3)
  C1 ->> C1: compute(C1.cb3)
  C1 ->>- C1: notify parent

  end
  C1 ->> C1: complete
```

Async calls to `C2` and `C3` are executed in parallel. Execution order of `callback2` and `callback3` may vary.
