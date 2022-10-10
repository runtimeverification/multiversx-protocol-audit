requires "../../esdt.md"
requires "verification.k"

requires "domains.md"

// module VERIFICATION
//     imports K-EQUAL
//     imports ESDT
//     imports MAP
//     imports MAP-SYMBOLIC
//     imports ML-SYNTAX
    
//     rule (K  B|->  V M:BalMap) [ K ] orDefault 0 => V ensures notBool (K in_keys(M)) [simplification]
//     rule (K  B|->  V M:BalMap) [ K ]             => V ensures notBool (K in_keys(M)) [simplification]

//     // rule ((TokId B|-> Val) Rest:BalMap) [ TokId ] orDefault _:Int => Val 
//     //   requires notBool( TokId in_keys(Rest))                                [simplification]

//     rule (X B|-> _) M:BalMap [ X <- Y ] => (X B|-> Y) M     requires notBool(X in_keys(M))              [simplification]
    
//     rule A +Int (0 -Int B) => A -Int B                                                                  [simplification, smt-lemma]
//     rule A ==Int A +Int B  => false requires 0 <Int B                                                   [simplification, smt-lemma]

//     // rule #Ceil ( L ~> #success ~> transfer(S, D, T, V, R) ) => #Ceil( L ) 
//     //                                                       #And #Ceil( S ) 
//     //                                                       #And #Ceil( D ) 
//     //                                                       #And #Ceil( T ) 
//     //                                                       #And #Ceil( V ) 
//     //                                                       #And #Ceil( R )                    [simplification]

//     // // rule MQ2 #Equals ShrId1 M|-> TxL(_) => #false                           [simplification]

//     // //rule { X #Equals (X ~> #success ~> transfer(_, _, _, _, _))} => #False      
//     // //  requires #Ceil(X) [simplification]
  
//     rule MQ:MQueue ==K ShrId1 M|-> TxL(_) => false requires isEmpty(MQ)    [simplification]

//     // rule X ==Int X +Int Y => false requires 0 <Int Y                       [simplification]
    
//     // rule X ==Int X +Int Y => 0 ==Int Y                                     [simplification]

//     // rule 0 ==Int X => false requires 0 <Int X                              [simplification]
    
// endmodule

module CROSS-SPEC
    imports VERIFICATION

    // simple cross shard successful  
    claim <meta-transactions> . </meta-transactions>
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
        <logs> LOGS1 => LOGS1 ~> #success ~> Tx </logs>
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
        <incoming-txs> .MQueue => MQ2:MQueue </incoming-txs>
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
        <logs> LOGS2 => LOGS2 ~> #success ~> Tx </logs>
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
       andBool isEmpty(MQ2)

endmodule

