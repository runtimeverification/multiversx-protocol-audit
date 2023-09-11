requires "verification.k"

module TOTAL-BALANCE-SPEC
    imports VERIFICATION

    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> _ => ?_ </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,TokId,_,_) #as Tx => #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
          <snapshot> #emptySnapshot </snapshot>
          
        // ACCOUNTS
        // -------------------------------------------------------------------------------
          <accounts> ACTS => ?ACTS2 </accounts>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> _ => ?_ </user-txs>
          <incoming-txs> _ => ?_ </incoming-txs>
          
          <token-settings> _ => ?_ </token-settings>
          
          <logs> L => (L ; ?_ ; Tx ) </logs>
        </shard>
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) ==Shard ShrId
       ensures #getBalance( #totalBalance(<accounts> ACTS   </accounts>), TokId) 
         ==Int #getBalance( #totalBalance(<accounts> ?ACTS2 </accounts>), TokId)

    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> _ => ?_ </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,TokId2,_,_) #as Tx => #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
          <snapshot> #emptySnapshot </snapshot>
          
        // ACCOUNTS
        // -------------------------------------------------------------------------------
          <accounts> ACTS => ?ACTS2 </accounts>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> _ => ?_ </user-txs>
          <incoming-txs> _ => ?_ </incoming-txs>
          
          <token-settings> _ => ?_ </token-settings>
          
          <logs> L => (L ; ?_ ; Tx ) </logs>
        </shard>
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) ==Shard ShrId
       andBool TokId =/=K TokId2
       ensures #getBalance( #totalBalance(<accounts> ACTS   </accounts>), TokId) 
         ==Int #getBalance( #totalBalance(<accounts> ?ACTS2 </accounts>), TokId)

endmodule
