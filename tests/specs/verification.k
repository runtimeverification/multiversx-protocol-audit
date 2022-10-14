requires "../../esdt.md"
requires "domains.md"

module VERIFICATION-SYNTAX 
    imports SET 

    syntax KItem ::= runLemma ( Step ) | doneLemma ( Step )

    syntax Step ::= Bool | Int | Set

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
    
    rule M:BalMap [ X ] orDefault Y => Y                             requires notBool(X in_keys(M))         [simplification]

    rule A +Int (0 -Int B) => A -Int B                                                                      [simplification]
    
    rule MQ:MQueue ==K (_:ShardId M|-> TxL(_)) => false              requires isEmpty(MQ)                   [simplification]

    rule A ==Shard B => A ==K B      [simplification]
    rule A =/=Shard B => A =/=K B    [simplification]
    
    rule <meta-steps> runLemma(S) => doneLemma(S) ... </meta-steps> [priority(1)]

    rule A <=Int B => true requires A <Int B                                                                [simplification]

    rule TokId in #localTokenIds( <token-settings>
                                    <token-setting>
                                      <token-setting-id> TokId </token-setting-id>
                                      _
                                    </token-setting> _
                                  </token-settings> ) => true                                               [simplification]

    rule TokId in #tokenIds(<global-token-settings>
                              <global-token-setting>
                                <global-token-id> TokId </global-token-id>
                                _
                              </global-token-setting> _
                            </global-token-settings> ) => true                                               [simplification]


endmodule
