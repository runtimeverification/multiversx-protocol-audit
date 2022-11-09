requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module LIMITED-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
      <shards>
        <shard>
          <shard-id> ShrId </shard-id>
        
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> .TxList </user-txs>
          <incoming-txs> 
            #metachainShardId M|-> (TxL(setGlobalSetting(ShrId, TokId, limited, Val)) => .TxList) 
          </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> _ => Val </limited>
              ...
            </token-setting>
            ...
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L => (L ; // send builtin call to metachain
                       #success ; setGlobalSetting(ShrId, TokId, limited, Val) )
          </logs>
          ...
        </shard>

      </shards>
    

endmodule