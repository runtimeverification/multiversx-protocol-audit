requires "../../esdt.md"
requires "verification.k"

requires "domains.md"

module CROSS-DEST-SPEC
    imports VERIFICATION

    // simple cross shard successful  
    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
     <shards>
      <shard>
        <shard-id> ShrId2 </shard-id>
      // ACCOUNTS
      // -------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId B|-> i(BAL2 => BAL2 +Int Val) ... </esdt-balances>
            <payable> true </payable>
            ...
          </account>
          ...
        </accounts>
      
      // ACTIONS
      // --------------------------------------------------------------------------------
        <user-txs> .TxList </user-txs>
        <incoming-txs> 
          (ShrId1 M|-> TxL(transfer(addr(ShrId1, _A1), addr(ShrId2, A2), TokId, Val, false) #as Tx ) )
            => 
          (ShrId1 M|-> .TxList )
        </incoming-txs>
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
        <logs> L =>( L ; #success ; Tx ) </logs>
        ...
      </shard>
    </shards>
      requires ShrId1 =/=Shard ShrId2
       andBool notBool(A2 in Frozen2)
       andBool 0 <Int Val
       andBool 0 <=Int BAL2 // >

endmodule

 