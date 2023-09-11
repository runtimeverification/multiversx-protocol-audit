requires "../../esdt.md"
requires "verification.k"

requires "domains.md"

module SIMPLE-SPEC
    imports VERIFICATION

// simple single shard successful
    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
    <shards>
      <shard>
        <shard-id> ShrId </shard-id>

      // ACCOUNTS
      // -------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId B|-> i(BAL1 => BAL1 -Int Val) ... </esdt-balances>
            ...
          </account>
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
        <user-txs> TxL(transfer(addr(ShrId, A1), addr(ShrId, A2), TokId, Val, false) #as Tx) => .TxList </user-txs>
        <incoming-txs> .MQueue </incoming-txs>
        <current-tx> #nullTx </current-tx>
        <steps> . </steps>
        <out-txs> .TxList </out-txs>
      
      // TOKEN CONFIGURATION
      // --------------------------------------------------------------------------------
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
      
      // OTHERS
      // --------------------------------------------------------------------------------
        <snapshot> #emptySnapshot </snapshot>
        <logs> L => (L ; #success ; Tx ) </logs>
        ...
      </shard>
    </shards>
      requires A1 =/=K A2
       andBool notBool(A1 in Frozen)
       andBool notBool(A2 in Frozen)
       andBool 0 <Int Val 
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2

// simple single shard destination is frozen
    claim <is-running> #no </is-running>
          <meta-steps> . </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
     <shards>
      <shard>
        <shard-id> ShrId </shard-id>

      // ACCOUNTS
      // --------------------------------------------------------------------------------
        <accounts>
          <account>
            <account-name> A1 </account-name>
            <esdt-balances> ... TokId B|-> i(BAL1) ... </esdt-balances>
            ...
          </account>
          <account>
            <account-name> A2 </account-name>
            <esdt-balances> ... TokId B|-> i(BAL2) ... </esdt-balances>
            <payable> true </payable>
            ...
          </account>
          ...    
        </accounts>

      // ACTIONS
      // --------------------------------------------------------------------------------
        <user-txs> TxL(transfer(addr(ShrId, A1), addr(ShrId, A2), TokId, Val, false) #as Tx) => .TxList </user-txs>
        <incoming-txs> .MQueue </incoming-txs>
        <current-tx> #nullTx </current-tx>
        <steps> . </steps>
        <out-txs> .TxList </out-txs>
      // TOKEN CONFIGURATION
      // --------------------------------------------------------------------------------
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
      
      // OTHERS
      // --------------------------------------------------------------------------------
        <snapshot> #emptySnapshot </snapshot>
        <logs> L => (L ; #failure(#ErrESDTIsFrozenForAccount) ; Tx) </logs>
        ...
      </shard>
    </shards>
      requires A1 =/=K A2
       andBool notBool(A1 in Frozen)
       andBool A2 in Frozen
       andBool 0 <Int Val 
       andBool Val <=Int BAL1
       andBool 0 <=Int BAL2


endmodule

