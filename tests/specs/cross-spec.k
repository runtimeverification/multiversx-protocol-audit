requires "../../esdt.md"
requires "domains.md"

module VERIFICATION
    imports K-EQUAL
    imports ESDT
    imports MAP
    imports MAP-SYMBOLIC

    rule #getInt( A |-> I:Int Rest:Map, A) => I 
      requires notBool( A in_keys(Rest)) [simplification]

    rule A +Int (0 -Int B) => A -Int B    [simplification]

endmodule

module CROSS-SPEC
    imports VERIFICATION

    // simple cross shard successful  
    claim <meta-transactions> . </meta-transactions>
     <shards>
      <shard>
        <shard-id> ShrId1 </shard-id>
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId |-> (BAL1 => BAL1 -Int Val) ... </esdt-balances>
            ...
          </account>
          ...
        </accounts>
        <transactions> transfer(accountAddr(ShrId1, A1), accountAddr(ShrId2, A2), TokId, Val, false) #as Tx => . </transactions>
        <current-tx> _ => ?_ </current-tx>
        
        <snapshot> #emptySnapshot </snapshot>
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen1 </frozen>
              ...
            </token-setting>
            ...
        </token-settings>
        <out-transfers> . => . </out-transfers>

        <logs> L => L ~> #success ~> Tx </logs>
        ...
      </shard>
      <shard>
        <shard-id> ShrId2 </shard-id>
        <accounts>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId |-> (BAL2 => BAL2 +Int Val) ... </esdt-balances>
            ...
          </account>
          ...
        </accounts>
        <transactions> . => . </transactions>
        <current-tx> _ => ?_ </current-tx>
        
        
        <snapshot> #emptySnapshot </snapshot>
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen2 </frozen>
              ...
            </token-setting>
            ...
        </token-settings>
        <out-transfers> . </out-transfers>

        <logs> L => L ~> #success ~> Tx </logs>
        ...
      </shard>
    </shards>
      requires ShrId1 =/=K ShrId2
       andBool ShrId1 =/=K #metachainShardId
       andBool ShrId2 =/=K #metachainShardId
       andBool notBool(A1 in Frozen1)
       andBool notBool(A2 in Frozen2)
       andBool 0 <Int Val
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2

endmodule

