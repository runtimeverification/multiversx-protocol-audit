requires "../../esdt.md"
requires "verification.k"

requires "domains.md"


module ISSUE-SIMPLE-SPEC
    imports VERIFICATION

    claim
      <meta>
        <meta-transactions>
          issue(accountAddr(Shr1, A1), TokId:Int, Supply) => .
        </meta-transactions>
        <global-token-settings> (.Bag =>
            <global-token-setting>
              <global-token-id>     TokId </global-token-id>
              <global-token-paused> false </global-token-paused>
              <global-token-owner>  accountAddr(Shr1, A1) </global-token-owner>
              <global-token-props>  ?_ </global-token-props>
            </global-token-setting>)
          </global-token-settings>
      </meta>    
      <shards>
      <shard>
        <shard-id> Shr1 </shard-id>
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> BALS:Map => ?BALS2 </esdt-balances>
            ...
          </account>
          ...    
        </accounts>
        <transactions> . </transactions>
        <current-tx> #nullTx </current-tx>
        <token-settings>
            (.Bag => <token-setting>
                       <token-setting-id> TokId </token-setting-id>
                       <limited> false </limited>
                       <paused> false </paused>
                       <frozen> .Set </frozen>
                     </token-setting>)
            
        </token-settings>
        <out-transfers> . </out-transfers>
        <snapshot> #emptySnapshot </snapshot>
        <logs> L => L ~> #success ~> transfer(#nullAct , accountAddr(Shr1, A1), TokId, Supply, false) </logs>
        ...
      </shard>
    </shards>
      requires #metachainShardId =/=K Shr1
       andBool 0 <Int Supply 
       andBool notBool( TokId in_keys( BALS ) )
      ensures Supply ==Int #getInt(?BALS2, TokId)
      

endmodule