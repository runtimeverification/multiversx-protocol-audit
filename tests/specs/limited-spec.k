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
    

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-limited> _ => true </global-token-limited>
              <global-token-owner> addr(Shr1, A1) </global-token-owner>
              <global-token-props> ... canAddSpecialRoles P|-> true ... </global-token-props>
              <global-esdt-roles> 
                .SetMap 
                  =>
                ESDTRoleTransfer S|-> SetItem(addr(Shr1, A1))
              </global-esdt-roles>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
          <accounts>
            <account>
              <account-name> A1 </account-name>
              <esdt-roles> 
                .SetMap 
                  =>
                TokId S|-> SetItem(ESDTRoleTransfer)
              </esdt-roles>
              ...
            </account>
            ...
          </accounts>
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL( setSpecialRole(addr(Shr1, A1), addr(Shr1, A1), TokId, ESDTRoleTransfer, true) #as Tx) => .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> _ => true </limited>
              ...
            </token-setting>
            ...
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L => (L ; // send builtin call to metachain
                       #success ; Tx ;
                       // set role
                       #success ; setESDTRole(TokId, addr(Shr1, A1), ESDTRoleTransfer , true) ;
                        // execute the builtin call from metachain
                       #success ; setGlobalSetting(Shr1, TokId, limited, true) )
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
              <limited> _ => true </limited>
              ...
            </token-setting>
            ...
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L2 => (L2 ;
                        // execute the builtin call from metachain
                       #success ; setGlobalSetting(Shr2, TokId, limited, true) )
          </logs>
          ...
        </shard>
      </shards>
      requires Shr1 =/=Shard Shr2

endmodule