requires "../../esdt.md"
requires "verification.k"

requires "domains.md"




module FUNCTIONAL-SPEC
    imports VERIFICATION

    claim <meta-steps>
        runLemma( #tokenIds(<global-token-settings>
            .Bag
        </global-token-settings>))
            =>
        doneLemma(.Set)
        ...
    </meta-steps>
    
    claim <meta-steps>
        runLemma( #tokenSettingExists(_, <token-settings>
            .Bag
        </token-settings>))
            =>
        doneLemma(false)
        ...
    </meta-steps>

    claim <meta-steps>
        runLemma( #tokenSettingExists(TokId, <token-settings>
            <token-setting>
              <token-setting-id>
                TokId
              </token-setting-id>
              <limited>
                false
              </limited>
              <paused>
                false
              </paused>
              <frozen>
                .Set
              </frozen>
            </token-setting>
          </token-settings>))
            =>
        doneLemma(true)
        ...
    </meta-steps>


    claim <meta-steps> runLemma( isEmpty(.TxList) ) => doneLemma(true) ... </meta-steps>
    claim <meta-steps> runLemma( isEmpty(TxL(#nullTx)) ) => doneLemma(false) ... </meta-steps>
    claim <meta-steps> runLemma( isEmpty(TxL(#nullTx) TxL(_) )  ) => doneLemma(false) ... </meta-steps>

    claim <meta-steps> runLemma( isEmpty(.MQueue) ) => doneLemma(true) ... </meta-steps>
    claim <meta-steps> 
        runLemma( isEmpty( 
            1 M|-> .TxList
            2 M|-> .TxList
            3 M|-> .TxList  ) ) 
        => 
        doneLemma(true) ... 
    </meta-steps>

    claim <meta-steps> 
        runLemma( isEmpty( 
            1 M|-> .TxList
            2 M|-> .TxList
            3 M|-> TxL(_)
            4 M|-> .TxList  ) ) 
        => 
        doneLemma(false) ... 
    </meta-steps>


    // Token Properties
    claim <meta-steps> 
        runLemma( #makeProperties( ) ) => doneLemma(#defaultTokenProps) ... 
    </meta-steps>

    claim <meta-steps> 
        runLemma( #makeProperties({ .PropertyList }) ) => doneLemma(#defaultTokenProps) ... 
    </meta-steps>

    claim <meta-steps> 
        runLemma( #makeProperties({ canFreeze : true }) ) => doneLemma( #defaultTokenProps [ canFreeze <- true ] ) ... 
    </meta-steps>

    claim <meta-steps> 
        runLemma( #makeProperties({ A : B }) ) => doneLemma( #defaultTokenProps [ A <- B ] ) ... 
    </meta-steps>


    claim <meta-steps> 
        runLemma( 
            #getBalance( #addBalMap(.BalMap, Bs )
                       , TokId) 
        ) 
            => 
        doneLemma( #getBalance(Bs, TokId) ) ...
    </meta-steps>

    claim <meta-steps> 
        runLemma( 
            #getBalance(#addBalMap( 
                1 B|-> _XA1
                2 B|-> _XA2
                3 B|-> XA3
                5 B|-> _XA5 ,

                1 B|-> _XB1
                3 B|-> XB3
                4 B|-> _XB4
                5 B|-> _XB5
            ), 3) 
        ) 
        
        => 
        doneLemma( XA3 +Int XB3 ) ... 
    </meta-steps>

endmodule

