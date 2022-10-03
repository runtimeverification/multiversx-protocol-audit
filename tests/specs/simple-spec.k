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

module SIMPLE-SPEC
    imports VERIFICATION

// simple single shard successful
    claim <meta-transactions> . </meta-transactions>
    <shards>
      <shard>
        <shard-id> ShrId </shard-id>
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId |-> (BAL1 => BAL1 -Int Val) ... </esdt-balances>
            ...
          </account>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId |-> (BAL2 => BAL2 +Int Val) ... </esdt-balances>
            ...
          </account>
          ...    
        </accounts>
        <transactions> transfer(accountAddr(ShrId, A1), accountAddr(ShrId, A2), TokId, Val, false) #as Tx => . </transactions>
        <current-tx> _ => ?_ </current-tx>
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen </frozen>
              ...
            </token-setting>
            //...
        </token-settings>
        <out-transfers> . </out-transfers>
        <snapshot> #emptySnapshot </snapshot>
        <logs> L => L ~> #success ~> Tx </logs>
        ...
      </shard>
    </shards>
      requires A1 =/=K A2
       andBool #metachainShardId =/=K ShrId
       andBool notBool(A1 in Frozen)
       andBool notBool(A2 in Frozen)
       andBool 0 <Int Val 
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2

// simple single shard destination is frozen
    claim <meta-transactions> . </meta-transactions>
     <shards>
      <shard>
        <shard-id> ShrId </shard-id>
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId |-> BAL1 ... </esdt-balances>
            ...
          </account>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId |-> BAL2 ... </esdt-balances>
            ...
          </account>
          ...    
        </accounts>
        <transactions> transfer(accountAddr(ShrId, A1), accountAddr(ShrId, A2), TokId, Val, false) #as Tx => . </transactions>
        <current-tx> _ => ?_ </current-tx>
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen </frozen>
              ...
            </token-setting>
            //...
        </token-settings>
        <out-transfers> . </out-transfers>
        <snapshot> #emptySnapshot </snapshot>
        <logs> L => L ~> #failure(#ErrESDTIsFrozenForAccount) ~> Tx </logs>
        ...
      </shard>
    </shards>
      requires A1 =/=K A2
       andBool #metachainShardId =/=K ShrId
       andBool notBool(A1 in Frozen)
       andBool A2 in Frozen
       andBool 0 <Int Val 
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2


endmodule

