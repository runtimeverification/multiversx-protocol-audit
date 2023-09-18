
## 1

```rust
shard Sh1 {
  contract C0 {
    fn method0() {
      sync(C1)
      compute("C0.end")
    }
  }
  contract C1 {
    fn endpoint() {
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
  User ->>+ C0: call
  C0 ->>+ C1: sync call
  C1 ->> C1: register async(C2, C1.callback)
  C1 ->>- C1: compute(C1.end)
  
  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->> C2: compute(C2)
  C2 ->>- C1: VMOutput

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->> C1: compute(C1.cb)
  C1 ->>- C1: CbVMOutput
  
  C1 ->> C0: VMOutput
  C0 ->>- C0: compute(C0.end)
  C0 ->> C0: complete
  
```

## 2

`C1` fails after the async call registration: async all is cancelled as in [a(i)#4](a(i).md#4), and everything is reverted.

## 3

`C2` fails: The error is handled as in [a(i)#2](a(i).md#2). After the callback, `C0` continues to execute.

## 3

The callback fails: The error is handled as in [a(i)#3](a(i).md#3). After reverting the callback, `C0` continues to execute.

## 4

The callback fails: The error is handled as in [a(i)#3](a(i).md#3). After reverting the callback, `C0` continues to execute.

## 5

`C0` fails after the sync call: if `C0` fails after executing the async call and the callback locally, everything is reverted to the initial state, including the async call.

```mermaid
sequenceDiagram
  participant User
  participant C0
  participant C1
  participant C2
  
  note over C0, C2: state: S0

  User ->>+ C0: call
  C0 ->>+ C1: sync call
  C1 ->> C1: register async(C2, C1.callback)
  note over C0, C2: state: S1

  C1 ->>+ C2: execOnDestCtx(C1 -> C2)
  C2 ->>- C1: VMOutput
  note over C0, C2: state: S2

  C1 ->>+ C1: execOnDestCtx(C2 -> C1, callback)
  C1 ->>- C1: CbVMOutput
  note over C0, C2: state: S3

  C1 ->> C0: VMOutput

  C0 ->>- C0: throw_error()
  note over C0: revert to S0
  note over C0, C2: state: S0
```