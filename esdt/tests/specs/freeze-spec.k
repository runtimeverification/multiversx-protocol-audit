requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module FREEZE-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> addr(Shr1, A1) </global-token-owner>
              <global-token-props> ... canFreeze P|-> true ... </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL( freeze(  addr(Shr1, A1), addr(Shr1, A2), TokId, true) #as Tx) => .TxList </user-txs>
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
                       #success ; Tx ;
                        // execute the builtin call from metachain
                       #success ; doFreeze(TokId, addr(Shr1, A2), true) )
          </logs>
          ...
        </shard>
      </shards>
      ensures A2 in ?Frozen

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> addr(Shr1, A1) </global-token-owner>
              <global-token-props> ... canFreeze P|-> true ... </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL( freeze(  addr(Shr1, A1), addr(Shr1, A2), TokId, false) #as Tx) => .TxList </user-txs>
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
                       #success ; Tx ;
                        // execute the builtin call from metachain
                       #success ; doFreeze(TokId, addr(Shr1, A2), false) )
          </logs>
          ...
        </shard>
      </shards>
      ensures notBool (A2 in ?Frozen)

endmodule