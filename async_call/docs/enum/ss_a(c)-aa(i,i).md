
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

  contract C4 {
    fn method4() {
    }
  }

  contract C5 {
    fn method5() { }
  }
}

shard Sh2 {
  contract C3 {
    fn method3() { }
  }
}

```

Everything is run as in [ss_a(i)-aa(i,c)](ss_a(i)-aa(i,i).md), except `C3` is on another shard. The async call to `C3` is executed after runtime completion of `C0`. 

Execution order:

```
1. C0
   1. sync C1
      1. register C3
   2. sync C2
      1. register C4
      2. register C5
      3. C4
      4. callback
      3. C5
      4. callback
   3. compute("C0.end")
2. cross-shard C3
   1. create SCR
3. execute C1.callback
4. notify parents
```