

```k
module ESDT-SYNTAX


    imports STRING
    imports INT-SYNTAX
    imports BOOL-SYNTAX

    syntax ShardId ::= Int
                     | "#metachainShardId"
    syntax AccountName ::= String
    syntax AccountAddr ::= accountAddr(accountShard: ShardId, accountName: AccountName )

    syntax TokenId ::= Int

    syntax Transaction ::= BuiltinCall
                         | ESDTManage       // SC Calls to the ESDT system SC

    syntax ESDTManage ::= "issue" "(" AccountAddr "," TokenId "," Int ")" Properties   
                        | "freeze" "(" AccountAddr "," AccountAddr "," TokenId "," Bool ")"
                        | "controlChanges" "(" AccountAddr "," TokenId ")" Properties

    syntax Properties ::= ""
                        | "{" PropertyList "}"
                        
    syntax PropertyList ::= List{Property, ","}
    syntax Property     ::= PropertyName ":" Bool
    syntax PropertyName ::= "canFreeze" | "canWipe" | "canPause" | "canMint" | "canBurn" 
                          | "canChangeOwner" | "canUpgrade" | "canAddSpecialRoles"


    syntax BuiltinCall ::= ESDTTransfer
                         | "setFreeze" "(" TokenId "," AccountAddr "," Bool ")"

    syntax ESDTTransfer ::= transfer( AccountAddr, AccountAddr, TokenId, Int, Bool )
    


endmodule


```