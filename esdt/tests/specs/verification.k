requires "../../esdt.md"

module VERIFICATION-SYNTAX 
    imports SET 
    imports ESDT 

    syntax KItem ::= runLemma ( KItem ) | doneLemma ( KItem )

    // syntax Step ::= Bool | Int | Set | 

endmodule

module VERIFICATION
    imports VERIFICATION-SYNTAX 
    imports INT-SIMPLIFICATION
    imports K-EQUAL
    imports ESDT
    imports MAP
    imports MAP-SYMBOLIC
    imports SET-SYMBOLIC
    imports ML-SYNTAX
    
    rule (K  B|->  V M:BalMap) [ K ] orDefault _ => V                requires notBool (K in_keys(M))        [simplification]
    rule (K  B|->  V M:BalMap) [ K ]             => V                requires notBool (K in_keys(M))        [simplification]
    rule (X  B|->  _ M:BalMap) [ X <- Y ]        => (X B|-> Y) M     requires notBool(X in_keys(M))         [simplification]
    rule M:BalMap [ Tok1 <- _ ] [ Tok2 ] orDefault D => M [ Tok2 ] orDefault D requires Tok1 =/=K Tok2       [simplification]
    rule _:BalMap [ Tok1 <- V ] [ Tok2 ] orDefault _ => V requires Tok1 ==K Tok2       [simplification]
    
    rule M:BalMap [ X ] orDefault Y => Y                             requires notBool(X in_keys(M))         [simplification]


    rule (P1:PropMap P2:PropMap) P2[A] => true requires notBool(A in_keys(P1)) [simplification]

    rule (P1:PropMap (A P|-> B)) [A] => B requires notBool(A in_keys(P1))  [simplification]

    rule P1:PropMap (X P|-> B:Bool) [X] orDefault false => B requires notBool(X in_keys(P1))                [simplification]
    
    rule (_MAP:PropMap [ K  <-  V1 ]) [ K ] orDefault _ => V1                                               [simplification]
    
    rule MQ:MQueue ==K (_:ShardId M|-> TxL(_)) => false              requires isEmpty(MQ)                   [simplification]

    rule A ==Shard B => A ==K B      [simplification]
    rule A =/=Shard B => A =/=K B    [simplification]
    
    rule <meta-steps> runLemma(S) => doneLemma(S) ... </meta-steps> [priority(1)]

    rule ((A M|-> B) Rest:MQueue) [ A ] => B requires notBool(A in_keys(Rest)) [simplification] // >
    rule ((A M|-> _) Rest:MQueue) [ A <- B ] => ((A M|-> B) Rest:MQueue) requires notBool(A in_keys(Rest)) [simplification]

    rule (_MAP:PropMap [ K  <-  V1 ]) [ K ]  => V1        [simplification]

    rule X in( SetItem(Y) ) => false requires X =/=K Y                   [simplification]
    
    rule A in (_S1 -Set S2) => false requires A in S2    [simplification]

    rule .SetMap [ _ ] orDefault .Set => .Set    [simplification]

    rule .SetMap [ X <- Y ] => X S|-> Y     [simplification]
  
    syntax Bool ::= #tokenSettingExists(TokenId, TokenSettingsCell)         [function, total]
    rule #tokenSettingExists(TokId, 
                            <token-settings> 
                                <token-setting> 
                                    <token-setting-id> TokId </token-setting-id>
                                    _
                                </token-setting>
                                _
                            </token-settings>) => true 
    rule #tokenSettingExists(_,_) => false                      [owise]

    rule #Not ( #Exists ActName . {
            _Gen9:AccountAddr
        #Equals
            addr ( _:Int , ActName )
        } ) => #Bottom                  [simplification]

    syntax BalMap ::= #totalBalance(AccountsCell)      [function, total]
                    | #totalBalanceH(AccountsCell, BalMap) [function, total]
    rule #totalBalance(Acts) => #totalBalanceH(Acts, .BalMap)
    rule #totalBalanceH(<accounts> .Bag </accounts>, Acc) => Acc
    rule #totalBalanceH(<accounts> 
                          (<account>
                            <esdt-balances> BALS </esdt-balances>
                            _
                          </account> => .Bag)
                          _ 
                        </accounts>, Acc => #addBalMap(BALS, Acc))        [simplification] 
    rule #totalBalanceH(Acts, #addBalMap(_,_) #as Acc) => #addBalMap( #totalBalanceH(Acts, .BalMap)
                                                                    , Acc)    [simplification]

    syntax BalMap ::= #addBalMap(BalMap, BalMap) [function, total, no-evaluators]

    // rule #getBalance(#addBalMap(A,B), TokId) => ...
    rule asInt( #addBalMap(A,B) [ TokId ] orDefault i(0)) 
        => #getBalance(A, TokId) +Int #getBalance(B, TokId)             [simplification]

    rule A +Int V +Int (B -Int V +Int C) => B +Int (A +Int C)             [simplification]
    rule A -Int V +Int (B +Int V +Int C) => B +Int (A +Int C)             [simplification]

    syntax Int ::= #balanceOut(ShardId, TokenId, TxList)  [function, total]
    rule #balanceOut(_, _, .TxList) => 0
    
    rule #balanceOut( ShrId, TokId, TxL(Tx) Rest) 
        => #balanceOut(ShrId, TokId, Rest) +Int #balanceOutTx(ShrId, TokId, Tx)   [simplification]

    // calculate the total balance being sent to a shard via cross-shard transfers
    syntax Int ::= #balanceIn(ShardId, TokenId, MQueue)  [function, total, no-evaluators]
    rule #balanceIn ( ShrTo, TokId, push(MQ, _, Tx) ) 
        => #balanceIn(ShrTo, TokId, MQ) +Int #balanceInTx(ShrTo, TokId, Tx)     [simplification]

    syntax Int ::= #balanceInTx(ShardId, TokenId, Transaction)    [function, total]
    rule #balanceInTx(ShrId, TokId, transfer(From, To, TokId, Val, _)) => Val 
      requires ShrId =/=Shard accountShard(From)
       andBool ShrId ==Shard accountShard(To)
    rule #balanceInTx(_, _, _) => 0             [owise]
    
    syntax Int ::= #balanceOutTx(ShardId, TokenId, Transaction)    [function, total]
    rule #balanceOutTx(ShrId, TokId, transfer(From, To, TokId, Val, _)) => Val 
      requires ShrId =/=Shard accountShard(To)
       andBool ShrId ==Shard accountShard(From)
    rule #balanceOutTx(_, _, _) => 0             [owise]

endmodule


// Retrieved from EVM Semantics: https://github.com/runtimeverification/evm-semantics/blob/master/include/kframework/lemmas/int-simplification.k

module INT-SIMPLIFICATION
    imports INT
    imports BOOL
  // ###########################################################################
  // add, sub
  // ###########################################################################

    // associativity normalization

    rule C1 +Int S2 => S2 +Int C1 [concrete(C1), symbolic(S2), simplification]
    
    rule S1 +Int (S2 +Int I3) => (S1 +Int S2) +Int I3 [symbolic(S1, S2), simplification]
    rule S1 +Int (S2 -Int I3) => (S1 +Int S2) -Int I3 [symbolic(S1, S2), simplification]
    rule S1 -Int (S2 +Int I3) => (S1 -Int S2) -Int I3 [symbolic(S1, S2), simplification]
    rule S1 -Int (S2 -Int I3) => (S1 -Int S2) +Int I3 [symbolic(S1, S2), simplification]

    rule S1 +Int (C2 -Int S3) => (S1 -Int S3) +Int C2 [symbolic(S1, S3), concrete(C2), simplification]
    rule S1 -Int (C2 -Int S3) => (S1 +Int S3) -Int C2 [symbolic(S1, S3), concrete(C2), simplification]

    rule (I1 +Int C2) +Int S3 => (I1 +Int S3) +Int C2 [concrete(C2), symbolic(S3), simplification]
    rule (I1 +Int C2) -Int S3 => (I1 -Int S3) +Int C2 [concrete(C2), symbolic(S3), simplification]
    rule (I1 -Int C2) +Int S3 => (I1 +Int S3) -Int C2 [concrete(C2), symbolic(S3), simplification]
    rule (I1 -Int C2) -Int S3 => (I1 -Int S3) -Int C2 [concrete(C2), symbolic(S3), simplification]

    rule (S1 +Int C2) +Int C3 => S1 +Int (C2 +Int C3) [concrete(C2, C3), symbolic(S1), simplification]
    rule (S1 +Int C2) -Int C3 => S1 +Int (C2 -Int C3) [concrete(C2, C3), symbolic(S1), simplification]
    rule (S1 -Int C2) +Int C3 => S1 +Int (C3 -Int C2) [concrete(C2, C3), symbolic(S1), simplification]
    rule (S1 -Int C2) -Int C3 => S1 -Int (C2 +Int C3) [concrete(C2, C3), symbolic(S1), simplification]

  // ###########################################################################
  // inequality
  // ###########################################################################

    rule I1 +Int C   <Int I2         => I1          <Int I2 -Int C  [concrete(C), simplification]
    rule C1          <Int I2 +Int C3 => C1 -Int C3  <Int I2         [concrete(C1, C3), simplification]
    rule C1         <=Int I2 +Int C3 => C1 -Int C3 <=Int I2         [concrete(C1, C3), simplification]



  // ###########################################################################
  // add, sub
  // ###########################################################################

  // 2 terms
    rule A -Int A => 0 [simplification]
    rule A -Int 0 => A [simplification]
    rule 0 +Int A => A [simplification]
    rule A +Int 0 => A [simplification]

  // 3 terms
    rule  (A -Int  B) +Int B  => A [simplification]
    rule   A -Int (A  -Int B) => B [simplification]
    rule   A +Int (B  -Int A) => B [simplification]
    rule  (A +Int  B) -Int A  => B [simplification]

  // ###########################################################################    
  // inequality
  // ###########################################################################    

    rule A +Int B <Int A => false requires 0 <=Int B [simplification]

    rule A <Int A -Int B => false requires 0 <=Int B [simplification]

    rule 0 <Int 1 <<Int A => true requires 0 <=Int A [simplification]

    // inequality sign normalization
    rule          A  >Int B  => B  <Int A [simplification]
    rule          A >=Int B  => B <=Int A [simplification]
    rule notBool (A  <Int B) => B <=Int A [simplification]
    rule notBool (A <=Int B) => B  <Int A [simplification]

    rule 0 <=Int A *Int B => true requires 0 <=Int A andBool 0 <=Int B [simplification]

    rule A -Int B +Int C <=Int D => false requires D <Int A -Int B andBool 0 <=Int C [simplification]

    rule minInt(A, B) <Int C  => true requires A  <Int C  orBool B  <Int C [simplification]
    rule A  <Int minInt(B, C) => true requires A  <Int B andBool A  <Int C [simplification]
    rule A <=Int minInt(B, C) => true requires A <=Int B andBool A <=Int C [simplification]


    rule A <=Int maxInt(B, C) => true requires A <=Int B orBool A <=Int C [simplification]

endmodule