requires "../../esdt.md"
requires "verification.k"

requires "domains.md"

module CROSS-DEST-FAIL-SPEC
    imports VERIFICATION

    // simple cross shard successful  
    claim <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
     <shards>
      <shard>
        <shard-id> ShrId2 </shard-id>
      // ACCOUNTS
      // -------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId B|-> BAL2  ... </esdt-balances>
            ...
          </account>
          ...
        </accounts>
      
      // ACTIONS
      // --------------------------------------------------------------------------------
        <user-txs> .TxList </user-txs>
        <incoming-txs> 
          (ShrId1 M|-> TxL(transfer(accountAddr(ShrId1, _A1), accountAddr(ShrId2, A2), TokId, Val, false) #as Tx ) )
            => 
          (ShrId1 M|-> .TxList )
        </incoming-txs>
        <steps> . => #finalizeTransaction </steps>
        <out-txs> .TxList => TxL( #mkReturnTx(Tx) ) </out-txs>
        <current-tx> #nullTx => Tx </current-tx>

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
        <snapshot> #emptySnapshot => ?_ </snapshot>
        <logs> L => (L ; #failure(#ErrESDTIsFrozenForAccount) ; Tx ) </logs>
        ...
      </shard>
    </shards>
      requires ShrId1 =/=Shard ShrId2
       andBool ShrId2 =/=Shard #metachainShardId
       andBool ShrId1 =/=Shard #metachainShardId
       andBool A2 in Frozen2
       andBool 0 <Int Val
       andBool 0 <=Int BAL2 // >
      
endmodule

 