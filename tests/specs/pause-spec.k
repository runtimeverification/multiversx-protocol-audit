requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module PAUSE-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-paused> _ => true </global-token-paused>
              <global-token-owner> addr(Shr1, A1) </global-token-owner>
              <global-token-props> ... canPause P|-> true ... </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL( pause(  addr(Shr1, A1), TokId, true) #as Tx) => .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <paused> _ => true </paused>
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
                       #success ; setGlobalSetting(Shr1, TokId, paused, true) )
          </logs>
          ...
        </shard>
        ///////////////////////////////////////////////////////////////////////////////////
        <shard>
          <shard-id> Shr2 </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <paused> _ => true </paused>
              ...
            </token-setting>
            ...
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L2 => (L2 ;
                        // execute the builtin call from metachain
                       #success ; setGlobalSetting(Shr2, TokId, paused, true) )
          </logs>
          ...
        </shard>
      </shards>
      requires Shr1 =/=Shard Shr2
    

endmodule