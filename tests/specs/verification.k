requires "../../esdt.md"
requires "domains.md"

module VERIFICATION-SYNTAX 


endmodule

module VERIFICATION
    imports VERIFICATION-SYNTAX 

    imports K-EQUAL
    imports ESDT
    imports MAP
    imports MAP-SYMBOLIC
    imports ML-SYNTAX
    
    rule (K  B|->  V M:BalMap) [ K ] orDefault _ => V                requires notBool (K in_keys(M))        [simplification]
    rule (K  B|->  V M:BalMap) [ K ]             => V                requires notBool (K in_keys(M))        [simplification]
    rule (X  B|->  _ M:BalMap) [ X <- Y ]        => (X B|-> Y) M     requires notBool(X in_keys(M))         [simplification]
    
    rule A +Int (0 -Int B) => A -Int B                                                                      [simplification]
    
    rule MQ:MQueue ==K (_:ShardId M|-> TxL(_)) => false              requires isEmpty(MQ)                   [simplification]

endmodule
