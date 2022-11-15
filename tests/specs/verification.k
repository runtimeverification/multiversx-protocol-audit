requires "../../esdt.md"

module VERIFICATION-SYNTAX 
    imports SET 
    imports ESDT 

    syntax KItem ::= runLemma ( KItem ) | doneLemma ( KItem )

    // syntax Step ::= Bool | Int | Set | 

endmodule

module VERIFICATION
    imports VERIFICATION-SYNTAX 

    imports K-EQUAL
    imports ESDT
    imports MAP
    imports MAP-SYMBOLIC
    imports SET-SYMBOLIC
    imports ML-SYNTAX
    
    rule (K  B|->  V M:BalMap) [ K ] orDefault _ => V                requires notBool (K in_keys(M))        [simplification]
    rule (K  B|->  V M:BalMap) [ K ]             => V                requires notBool (K in_keys(M))        [simplification]
    rule (X  B|->  _ M:BalMap) [ X <- Y ]        => (X B|-> Y) M     requires notBool(X in_keys(M))         [simplification]
    
    rule M:BalMap [ X ] orDefault Y => Y                             requires notBool(X in_keys(M))         [simplification]


    rule (P1:PropMap P2:PropMap) P2[A] => true requires notBool(A in_keys(P1)) [simplification]

    rule (P1:PropMap (A P|-> B)) [A] => B requires notBool(A in_keys(P1))  [simplification]

    rule P1:PropMap (X P|-> B:Bool) [X] orDefault false => B requires notBool(X in_keys(P1))                [simplification]
    
    rule (_MAP:PropMap [ K  <-  V1 ]) [ K ] orDefault _ => V1                                               [simplification]

    rule A +Int (0 -Int B) => A -Int B                                                                      [simplification]
    
    rule MQ:MQueue ==K (_:ShardId M|-> TxL(_)) => false              requires isEmpty(MQ)                   [simplification]

    rule A ==Shard B => A ==K B      [simplification]
    rule A =/=Shard B => A =/=K B    [simplification]
    
    rule <meta-steps> runLemma(S) => doneLemma(S) ... </meta-steps> [priority(1)]

    rule A <=Int B => true requires A <Int B         [simplification] // >

    rule A -Int B +Int B => A [simplification]

    rule ((A M|-> B) Rest:MQueue) [ A ] => B requires notBool(A in_keys(Rest)) [simplification] // >
    rule ((A M|-> _) Rest:MQueue) [ A <- B ] => ((A M|-> B) Rest:MQueue) requires notBool(A in_keys(Rest)) [simplification]

    rule (_MAP:PropMap [ K  <-  V1 ]) [ K ]  => V1        [simplification]

    rule X in( SetItem(Y) ) => false requires X =/=K Y                   [simplification]
    
    rule A in (_S1 -Set S2) => false requires A in S2    [simplification]

    rule .SetMap [ _ ] orDefault .Set => .Set    [simplification]

    rule .SetMap [ X <- Y ] => X S|-> Y     [simplification]

    rule notBool (A ==Int B) => true requires notBool( A ==K B)    [simplification]
  
endmodule
