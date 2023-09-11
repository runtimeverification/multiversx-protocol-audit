requires "verification.k"

module REVERT-SPEC
    imports VERIFICATION

    // if the transfer fails, accounts cell is reverted
    // Sender shard: ShrId or meta
    // Recv shard:   ShrId or meta
    // Sender or recv is ShrId
    // claim
    //   <is-running> ShrId => #no </is-running>
    //   <meta-steps> . </meta-steps>
    //   <meta-incoming> _ => ?_ </meta-incoming>
    //   <shards>
    //     <shard>
    //       <shard-id> ShrId </shard-id>

    //       <current-tx> transfer(_,_,_,_,_) #as Tx => #nullTx </current-tx>
    //       <steps> . </steps>
    //       <out-txs> .TxList </out-txs>
    //       <snapshot> #emptySnapshot </snapshot>
          
    //     // ACCOUNTS
    //     // -------------------------------------------------------------------------------
    //       <accounts> ACTS => ?ACTS2 </accounts>
        
    //     // ACTIONS
    //     // --------------------------------------------------------------------------------
    //       <user-txs> _ => ?_ </user-txs>
    //       <incoming-txs> _ => ?_ </incoming-txs>
          
    //       <token-settings> _ => ?_ </token-settings>
          
    //       <logs> L => (L ; ?Status ; Tx ) </logs>
    //     </shard>

    //   </shards>
    //   requires ( #txSenderShard(Tx) ==Shard ShrId 
    //       orBool #txSenderShard(Tx) ==Shard #metachainShardId
    //     )
    //    andBool ( #txDestShard(Tx) ==Shard ShrId 
    //       orBool #txDestShard(Tx) ==Shard #metachainShardId
    //     )
    //     // the reason why it is in shard ShrId
    //    andBool ( ShrId ==Shard #txSenderShard(Tx)
    //       orBool ShrId ==Shard #txDestShard(Tx)
    //     )
    //   ensures ?Status ==K #success orBool ACTS ==K ?ACTS2



    // Sender shard: ShrId
    // Recv shard:   #metachainShardId (cannot send to meta)
    // this transfer should always fail
    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,_,_,_) #as Tx => #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
          <snapshot> #emptySnapshot </snapshot>
          
          <token-settings> _ => ?_ </token-settings>
          
          <logs> L => (L ; #failure(?_) ; Tx ) </logs>
          ...
        </shard>

      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) ==Shard #metachainShardId
      
    // if the transfer fails, accounts cell is reverted
    // Same shard transfer
    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> IN => ?IN2 </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,_,_,_) #as Tx => #nullTx </current-tx>
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
          
          <logs> L => (L ; ?Status ; Tx ) </logs>
        </shard>
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) ==Shard ShrId
      ensures ?Status ==K #success
       orBool (ACTS ==K ?ACTS2 andBool IN ==K ?IN2 )

    // From ShrId to ShrId2
    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> _ => ?_ </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,_,_,_) #as Tx => #nullTx </current-tx>
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
          
          <logs> L => (L ; ?Status ; Tx ) </logs>
        </shard>
        <shard>
          <shard-id> ShrId2 </shard-id>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>        
          <incoming-txs> IN => ?IN2 </incoming-txs>
          ...  
        </shard>
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId
       andBool #txDestShard(Tx) ==Shard ShrId2
      ensures ?Status ==K #success
       orBool (ACTS ==K ?ACTS2 andBool IN ==K ?IN2 )

    // From ShrId2 to ShrId
    claim
      <is-running> ShrId => #no </is-running>
      <meta-steps> . </meta-steps>
      <meta-incoming> _ => ?_ </meta-incoming>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>

          <current-tx> transfer(_,_,_,_,_) #as Tx => #nullTx </current-tx>
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
          
          <logs> L => (L ; ?Status ; Tx ) </logs>
        </shard>
        <shard>
          <shard-id> ShrId2 </shard-id>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>        
          <incoming-txs> IN => ?IN2 </incoming-txs>
          ...  
        </shard>
      </shards>
      requires #txSenderShard(Tx) ==Shard ShrId2
       andBool #txDestShard(Tx) ==Shard ShrId
      ensures ( ?Status ==K #success
        andBool IN ==K ?IN2 )
       orBool ( ?Status =/=K #success 
        andBool ACTS ==K ?ACTS2 
        andBool push(IN, ShrId, #mkReturnTx(Tx)) ==K ?IN2 )
endmodule
     