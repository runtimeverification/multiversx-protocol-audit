
```k
requires "configuration.md"

module HELPERS
    imports CONFIGURATION

    syntax Bool ::= #isCrossShard(Transaction)          [function, total]
    rule #isCrossShard(Tx) => #txSenderShard(Tx) =/=Shard #txDestShard(Tx)
    
    syntax ShardId ::= #txDestShard(Transaction)        [function, total]
                     | #txSenderShard(Transaction)      [function, total]
    // builtin functions
    rule #txDestShard(transfer(_, ACT, _, _, _))   => accountShard(ACT)
    rule #txDestShard(doFreeze(_, ACT, _))        => accountShard(ACT)
    rule #txDestShard(setGlobalSetting(ShrId, _, _, _))       => ShrId
    rule #txDestShard(setESDTRole(_, ACT, _, _))       => accountShard(ACT)
    rule #txDestShard(localMint(ACT, _, _))       => accountShard(ACT)
    rule #txDestShard(localBurn(ACT, _, _))       => accountShard(ACT)
    // esdt SC calls
    rule #txDestShard(_:ESDTManage)                => #metachainShardId    
    //
    rule #txDestShard(#nullTx)                     => #metachainShardId

    // builtin functions
    rule #txSenderShard(transfer(ACT, _, _, _, _))    => accountShard(ACT)    
    rule #txSenderShard(doFreeze(_, _, _))            => #metachainShardId    
    rule #txSenderShard(setGlobalSetting(_, _, _, _)) => #metachainShardId    
    rule #txSenderShard(setESDTRole(_, _, _, _))      => #metachainShardId  
    rule #txSenderShard(localMint(ACT, _, _))         => accountShard(ACT)  
    rule #txSenderShard(localBurn(ACT, _, _))         => accountShard(ACT)  
    // esdt SC calls
    rule #txSenderShard(issue(ACT, _, _) _)         => accountShard(ACT)    
    rule #txSenderShard(freeze(ACT, _, _, _))       => accountShard(ACT)
    rule #txSenderShard(pause(ACT, _, _))           => accountShard(ACT)
    rule #txSenderShard(controlChanges(ACT, _, _))  => accountShard(ACT)
    rule #txSenderShard(setSpecialRole(ACT, _, _, _, _)) => accountShard(ACT)
    //
    rule #txSenderShard(#nullTx)                   => #metachainShardId

    syntax Bool ::= ShardId "=/=Shard" ShardId        [function, total]
    rule I:Int             =/=Shard J:Int                   => I =/=Int J
    rule _:Int             =/=Shard #metachainShardId       => true
    rule #metachainShardId =/=Shard _:Int                   => true
    rule #metachainShardId =/=Shard #metachainShardId       => false
    
    syntax Bool ::= ShardId "==Shard" ShardId        [function, total]
    rule I:Int             ==Shard J:Int                   => I ==Int J
    rule _:Int             ==Shard #metachainShardId       => false
    rule #metachainShardId ==Shard _:Int                   => false
    rule #metachainShardId ==Shard #metachainShardId       => true     


    // Add or remove elements of a set
    syntax Set ::= setToggle(Set, KItem, Bool)      [function, total]
    rule setToggle(S, X, true)  => S |Set SetItem(X)
    rule setToggle(S, X, false) => S -Set SetItem(X)
    
    // Add or remove elements of a Set inside a Map
    syntax SetMap ::= setMapToggle(SetMap, KItem, KItem, Bool) [function, total]
    rule setMapToggle(M, Key, Val, P) => 
      M [Key <- setToggle( getSetItem(M, Key)
                         , Val
                         , P)] 
endmodule
```