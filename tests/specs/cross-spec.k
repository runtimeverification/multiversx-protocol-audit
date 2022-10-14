requires "../../esdt.md"
requires "verification.k"

requires "domains.md"

module CROSS-SPEC
    imports VERIFICATION

    // simple cross shard successful  
    claim <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
     <shards>
      <shard>
        <shard-id> ShrId1 </shard-id>
      // ACCOUNTS
      // -------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId B|-> (BAL1 => BAL1 -Int Val) ... </esdt-balances>
            ...
          </account>
          ...
        </accounts>
        
      // ACTIONS
      // --------------------------------------------------------------------------------
        <user-txs> TxL(transfer(accountAddr(ShrId1, A1), accountAddr(ShrId2, A2), TokId, Val, false) #as Tx) => .TxList </user-txs>
        <incoming-txs> .MQueue </incoming-txs>
        <steps> . </steps>
        <out-txs> .TxList </out-txs>
        <current-tx> #nullTx </current-tx>
      
      // TOKEN CONFIGURATION
      // --------------------------------------------------------------------------------
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen1 </frozen>
              ...
            </token-setting>
            //...
        </token-settings>

      // OTHERS
      // --------------------------------------------------------------------------------
        <snapshot> #emptySnapshot </snapshot>
        <logs> L1 => (L1 ; #success ; Tx ) </logs>
        ...
      </shard>
      <shard>
        <shard-id> ShrId2 </shard-id>
      // ACCOUNTS
      // -------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId B|-> (BAL2 => BAL2 +Int Val) ... </esdt-balances>
            ...
          </account>
          ...
        </accounts>
      
      // ACTIONS
      // --------------------------------------------------------------------------------
        <user-txs> .TxList </user-txs>
        <incoming-txs> .MQueue => (ShrId1 M|-> .TxList) </incoming-txs>
        <steps> . </steps>
        <out-txs> .TxList </out-txs>
        <current-tx> #nullTx </current-tx>

      // TOKEN CONFIGURATION
      // --------------------------------------------------------------------------------
        <token-settings>
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              <limited> false </limited>
              <paused> false </paused>
              <frozen> Frozen2 </frozen>
              ...
            </token-setting>
            //...
        </token-settings>

      // OTHERS
      // --------------------------------------------------------------------------------
        <snapshot> #emptySnapshot </snapshot>
        <logs> L2 => (L2 ; #success ; Tx ) </logs>
        ...
      </shard>
    </shards>
      requires ShrId1 =/=Shard ShrId2
       andBool ShrId1 =/=Shard #metachainShardId
       andBool ShrId2 =/=Shard #metachainShardId
       andBool notBool(A1 in Frozen1)
       andBool notBool(A2 in Frozen2)
       andBool 0 <Int Val
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2 // >

endmodule

