requires "verification.k"

module TOTAL-BALANCE-CROSS-SPEC
    imports VERIFICATION




    claim
      <is-running> ShrId </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> _ => ?_ </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

        // Execution
          <current-tx> transfer(_,_,TokId,_,_) #as Tx</current-tx>
          <steps> . => #finalizeTransaction </steps>
          <snapshot> #emptySnapshot => ?_ </snapshot>
        
        // Results
          <out-txs> .TxList => ?OutTxs </out-txs>
          <accounts> ACTS => ?ACTS2 </accounts>
          
          <logs> _ => ?_ </logs>
          <token-settings> _ => ?_ </token-settings>  
          ...
        </shard>
        OtherShards
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) =/=Shard ShrId
       andBool #allEmpty(<shards> OtherShards </shards>)
       ensures #getBalance( #totalBalance(<accounts> ACTS   </accounts>), TokId) 
         ==Int #getBalance( #totalBalance(<accounts> ?ACTS2 </accounts>), TokId)
          +Int #balanceOut(ShrId, TokId, ?OutTxs)

    claim
      <is-running> Shr1 => #no </is-running>
      <meta-steps> . </meta-steps>
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        // Execution
          <current-tx> transfer(_,_,TokId,_,_) #as Tx => #nullTx </current-tx>
          <steps> . </steps>
          <snapshot> #emptySnapshot </snapshot>
        
        // Results
          <out-txs> .TxList </out-txs>
          <accounts> ACTS1 => ?ACTS1 </accounts>
          
          <logs> _ => ?_ </logs>
          <token-settings> _ => ?_ </token-settings>  
          ...
        </shard>
        <shard>
          <shard-id> Shr2 </shard-id>
        // Execution
          <incoming-txs> MQ => ?MQ </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
        
          <out-txs> .TxList </out-txs>
          <accounts> ACTS2 </accounts>
          ...
        </shard>
        
      </shards>
      requires #txSenderShard(Tx) ==Shard Shr1
       andBool #txDestShard(Tx) ==Shard Shr2
       ensures #getBalance( #totalBalance(<accounts>  ACTS1 </accounts>), TokId)
          +Int #getBalance( #totalBalance(<accounts>  ACTS2 </accounts>), TokId)
          +Int #balanceIn( Shr2 , TokId , MQ )

         ==Int #getBalance( #totalBalance(<accounts> ?ACTS1 </accounts>), TokId)
          +Int #getBalance( #totalBalance(<accounts> ACTS2 </accounts>), TokId)
          +Int #balanceIn( Shr2 , TokId , ?MQ )


endmodule
