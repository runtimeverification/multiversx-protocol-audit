requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module ISSUE-SIMPLE-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> (.Bag => #mkGlobalTokenSetting(addr(Shr1, A1), TokId, ) ) </global-token-settings>
          
      <shards>
        <shard>
          <shard-id> Shr1 </shard-id>
        // ACCOUNTS
        // -------------------------------------------------------------------------------
        
          <accounts>
            <account>
              <account-name> A1 </account-name>
              <esdt-balances> BALS => BALS [ TokId <- Supply ] /* > */ </esdt-balances>
              ...
            </account>
                
          </accounts>
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL((issue(addr(Shr1, A1), TokId, Supply) ) #as Tx) => .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
              (.Bag => #mkTokenSetting(TokId))
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L => (L ; // send builtin call to metachain
                       #success ; Tx ;
                        // receive the initial supply
                       #success ; transfer(#systemAct, addr(Shr1, A1), TokId, Supply, false) )
          </logs>
          ...
        </shard>
      </shards>
      requires #metachainShardId =/=Shard Shr1
       andBool 0 <Int Supply // >
       andBool notBool( TokId in_keys( BALS ) )
       

endmodule