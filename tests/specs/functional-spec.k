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
        runLemma( #localTokenIds(<token-settings>
            .Bag
        </token-settings>))
            =>
        doneLemma(.Set)
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

endmodule

