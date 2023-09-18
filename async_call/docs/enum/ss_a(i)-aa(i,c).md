
## 1

```rust
shard Sh1 {
  contract C0 {
    fn method0() {
      sync(C1)
      sync(C2)
      compute("C0.end")
    }
  }

  contract C1 {
    fn method1() {
      async(C3, callback)
    }

    fn callback() {  }
  }

  contract C2 {
    fn method2() {
      async(C4, callback)
      async(C5, callback)
    }

    fn callback() {  }
  }

  contract C3 {
    fn method3() {
    }
  }

  contract C4 {
    fn method4() { }
  }
}

shard Sh2 {
  contract C5 {
    fn method5() { }
  }
}

```

Everything is run as in [ss_a(i)-a(i)](ss_a(i)-a(i).md), except `C2` registers a second async call to a cross-shard contract, `C5`. The async call to `C5` is executed after runtime completion of `C0`. 

Execution order:

```
1. C0
   1. sync C1
      1. register C3
      2. C3
      3. callback
   2. sync C2
      1. register C4
      2. register C5
      3. C4
      4. callback
   3. compute("C0.end")
2. cross-shard C5
   1. create SCR
3. execute C2.callback
4. notify parents
```