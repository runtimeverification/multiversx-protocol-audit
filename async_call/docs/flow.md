## [Call SC Method](https://github.com/multiversx/mx-chain-vm-go/blob/69e712b5198b297dce715677bcbe27a1c7913c83/vmhost/hostCore/execution.go#L1147)

```mermaid
flowchart TB
  callScMethod([Call SC Method])
  callFunctionAndExecuteAsync[[Call Function & Execute Async]]
  callFunctionAndExecuteAsync2[[Call Function & Execute Async]]
  callFunctionAndExecuteAsync3[[Call Function & Execute Async]]
  switchCallType{Call type}

  callScMethod-->switchCallType

  switchCallType--direct call--> callFunctionAndExecuteAsync --> f1((( )))
  switchCallType--async call--> callFunctionAndExecuteAsync2 --> f2((( )))
  
  switchCallType--callback--> readCtxStorage[Load async context from storage]
  readCtxStorage--> getCallback[Get callback function]
  getCallback-->callFunctionAndExecuteAsync3
  callFunctionAndExecuteAsync3--> notifyParent[Notify parent - child is complete] --> f3((( )))
    
```

## [Call Function & Execute Async](https://github.com/multiversx/mx-chain-vm-go/blob/69e712b5198b297dce715677bcbe27a1c7913c83/vmhost/hostCore/execution.go#L1235)


```mermaid
flowchart TB
  start(( ))-->verifyAllowedFunctionCall[Verify allowed function call]

  verifyAllowedFunctionCall-->CallSCFunction
  
  
  subgraph CallSCFunction[Call SC function]
    direction TB
    start1(( ))-->wasm
    wasm[Run WASM]-->register[Register async call]-->wasm
    wasm-->execOnDestContext[Execute on dest. ctx.]-->wasm
    wasm--->finish((( )))

  end

  CallSCFunction --> AsyncExecute

  subgraph AsyncExecute[Execute async calls]
    direction TB

    subgraph executeLocals[for each intra-shard call]
      direction TB
      execLocal[Execute on dest. ctx. Call]
      execLocal --> execLocalCb[ Execute on dest. ctx. Callback]
    end

    executeLocals --> executeCross

    subgraph executeCross[for each cross shard call]
      direction TB
      outTransfer[Create output transfer]
    end

  end

  AsyncExecute -->done((( )))

```

## Cross-shard execution

```mermaid
flowchart

  user([ User ]) ==> execute

  subgraph Shards
    subgraph Shard1
      execute[Execute SC call] 
        --> localAsync[Execute local async calls] 
        --> output[Create output transfers] 
      
      executeCb[Execute callback] --> notify[Notify parent: child is complete]
    end

    
    subgraph Shard2
      executeAsync[Execute async call] 
        --> scr[Create SC result]
    end

    style Shards stroke-width:2px,color:#fff,stroke-dasharray: 5 5
  end
  output ==>|output transfers via Metachain | executeAsync
  scr ==>| SCR via Metachain| executeCb
```
