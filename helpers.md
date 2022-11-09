
```k
requires "configuration.md"

module HELPERS
    imports CONFIGURATION

    syntax Bool ::= #isCrossShard(Transaction)          [function, functional]
    rule #isCrossShard(Tx) => #txSenderShard(Tx) =/=Shard #txDestShard(Tx)
    
    syntax Bool ::= #onDestShard(ShardId, Transaction)            [function, functional]
                  | #onSenderShard(ShardId, Transaction)          [function, functional]
    rule #onDestShard(Shr, Tx)   => Shr ==Shard #txDestShard(Tx)
    rule #onSenderShard(Shr, Tx) => Shr ==Shard #txSenderShard(Tx)
    
    syntax Bool ::= #checkSender(AccountName, Int, Int, Set, Bool) [function, functional]
                  | #checkDest(  AccountName,      Int, Set, Bool) [function, functional]
    rule #checkSender(SndName, Bal, Val, Frozen, Paused) => notBool Paused 
                                                    andBool notBool(SndName in Frozen) 
                                                    andBool 0 <Int Val                    // >
                                                    andBool Val <=Int Bal
    rule #checkDest(DestName, Val, Frozen, Paused) => notBool Paused 
                                              andBool notBool(DestName in Frozen) 
                                              andBool 0 <Int Val    // >

    
    syntax ShardId ::= #txDestShard(Transaction)        [function, functional]
                     | #txSenderShard(Transaction)      [function, functional]
    // builtin functions
    rule #txDestShard(transfer(_, ACT, _, _, _))   => accountShard(ACT)
    rule #txDestShard(doFreeze(_, ACT, _))        => accountShard(ACT)
    rule #txDestShard(setGlobalSetting(ShrId, _, _, _))       => ShrId
    // esdt SC calls
    rule #txDestShard(_:ESDTManage)                => #metachainShardId    
    //
    rule #txDestShard(#nullTx)                     => #metachainShardId

    // builtin functions
    rule #txSenderShard(transfer(ACT, _, _, _, _)) => accountShard(ACT)    
    rule #txSenderShard(doFreeze(_, _, _))         => #metachainShardId    
    rule #txSenderShard(setGlobalSetting(_, _, _, _))   => #metachainShardId    
    // esdt SC calls
    rule #txSenderShard(issue(ACT, _, _) _)        => accountShard(ACT)    
    rule #txSenderShard(freeze(ACT, _, _, _))      => accountShard(ACT)
    rule #txSenderShard(pause(ACT, _, _))          => accountShard(ACT)
    rule #txSenderShard(controlChanges(ACT, _) _)  => accountShard(ACT)
    //
    rule #txSenderShard(#nullTx)                   => #metachainShardId

    syntax Bool ::= ShardId "=/=Shard" ShardId        [function, functional]
    rule I:Int             =/=Shard J:Int                   => I =/=Int J
    rule _:Int             =/=Shard #metachainShardId       => true
    rule #metachainShardId =/=Shard _:Int                   => true
    rule #metachainShardId =/=Shard #metachainShardId       => false
    
    syntax Bool ::= ShardId "==Shard" ShardId        [function, functional]
    rule I:Int             ==Shard J:Int                   => I ==Int J
    rule _:Int             ==Shard #metachainShardId       => false
    rule #metachainShardId ==Shard _:Int                   => false
    rule #metachainShardId ==Shard #metachainShardId       => true     

endmodule
```