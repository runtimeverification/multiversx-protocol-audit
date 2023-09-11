requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module UPGRADE-FREEZE-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> addr(Shr1, A1) </global-token-owner>
              <global-token-props> Ps => #updateProps(Ps, {canFreeze: true})  </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> 
            TxL( controlChanges(  addr(Shr1, A1), TokId, {canFreeze: true}) #as Tx1)
            TxL( freeze(  addr(Shr1, A1), addr(Shr1, A2), TokId, true) #as Tx2) 
            => .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <frozen> _ => ?Frozen </frozen>
              ...
            </token-setting>
            ...
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L => (L ; // send builtin call to metachain
                       #success ; Tx1 ;
                       #success ; Tx2 ;
                        // receive the builtin call
                       #success ; doFreeze(TokId, addr(Shr1, A2), true) )
          </logs>
          ...
        </shard>
      </shards>
      requires #metachainShardId =/=Shard Shr1
       andBool hasProp(Ps, canUpgrade)
      ensures A2 in ?Frozen

    

endmodule