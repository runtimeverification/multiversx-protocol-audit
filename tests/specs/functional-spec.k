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
   

endmodule

