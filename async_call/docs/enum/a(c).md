
## 1 async call

```rust

shard Sh1 {
  contract C1 {
    fn method1() {
      async(C2, method2, callback)
      compute("C1.end")
    }

    fn callback() {
      compute("C1.cb")
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

```


```mermaid
sequenceDiagram
  participant User
  participant C1
  participant Metachain
  participant C2
  
  User ->>+ C1: call
  C1 ->> C1: register async(C2, method2, callback)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: OutputTransfer(C1 -> C2)<br/>via Metachain
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput via Metachain

  C1 ->>+ C1: execute(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: notify parent
  
  C1 ->> C1: complete
```

## 1 async call, call fails


```rust

shard Sh1 {
  contract C1 {
    fn method1() {
      async(C2, method2, callback)
    }

    fn callback(res) {
      compute("C1.cb")
    }
  }
}

shard Sh2 {
  contract C2 {
    fn method2() {
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
  participant Metachain
  participant C2

  User ->>+ C1: call
  C1 ->> C1: register async(C2, method2, callback)
  C1 ->>- C1: compute(C1.end)
  
  note over C2: state: S0
  C1 ->>+ C2: OutputTransfer(C1 -> C2)<br/>via Metachain
  C2 ->> C2: compute(C2)
  note over C2: state: S1
  C2 ->>- C2: throw_error()
  note over C2: rollback to S0
  
  C2 ->> C1: SCR via Metachain

  C1 ->>+ C1: execute(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: notify parent
  
  C1 ->> C1: complete
```

## 1 async call, callback fails


```rust

shard Sh1 {
  contract C1 {
    fn method1() {
      async(C2, method2, callback)
    }

    fn callback(res) {
      compute("C1.cb")
      throw_error()
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

```



```mermaid
sequenceDiagram

  participant User
  participant C1
  participant Metachain
  participant C2

  User ->>+ C1: call
  C1 ->> C1: register async(C2, method2, callback)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: OutputTransfer(C1 -> C2)<br/>via Metachain
  C2 ->> C2: compute(C2)
  C2 ->>- C1: SCR via Metachain

  note over C1: state: S0
  C1 ->>+ C1: execute(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)

  note over C1: state: S1
  C1 ->>- C1: throw_error()
  note over C1: rollback to S0
  note over C1: state: S0
  C1 ->> C1: notify parent
  
  C1 ->> C1: complete
```

