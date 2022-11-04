requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module ISSUE-SPEC
    imports VERIFICATION

    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue => (Shr1 M|-> .TxList) </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            (.Bag => #mkGlobalTokenSetting(accountAddr(Shr1, A1), TokId, Props) )
            OtherGlobalTokens
          </global-token-settings>
          
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
            ...
          </accounts>
        // ACTIONS
        // --------------------------------------------------------------------------------
          <user-txs> TxL((issue(accountAddr(Shr1, A1), TokId, Supply) Props) #as Tx) => .TxList </user-txs>
          <incoming-txs> .MQueue => (#metachainShardId M|-> .TxList) </incoming-txs>
          <current-tx> #nullTx </current-tx>
          <steps> . </steps>
          <out-txs> .TxList </out-txs>
        
        // TOKEN CONFIGURATION
        // --------------------------------------------------------------------------------
          <token-settings>
            (.Bag => #mkTokenSetting(TokId) )
            OtherTokens
          </token-settings>

        // OTHERS
        // --------------------------------------------------------------------------------
          <snapshot> #emptySnapshot </snapshot>
          <logs> L => (L ; // send builtin call to metachain
                       #success ; Tx ;
                        // receive the initial supply
                       #success ; transfer(#systemAct, accountAddr(Shr1, A1), TokId, Supply, false) )
          </logs>
          ...
        </shard>
      </shards>
      requires #metachainShardId =/=Shard Shr1
       andBool 0 <Int Supply // >
       andBool notBool( TokId in_keys( BALS ) )
       andBool notBool( TokId in( #tokenIds(<global-token-settings> OtherGlobalTokens </global-token-settings>) ) )
       andBool notBool( #tokenSettingExists(TokId, <token-settings> OtherTokens </token-settings>) )
endmodule