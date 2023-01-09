

```k
module ESDT-SYNTAX

    imports STRING
    imports INT-SYNTAX
    imports BOOL-SYNTAX
```

## Addresses and IDs

Accounts are identified by their addresses. An address is a pair of a shard ID and an account name.

```k
    syntax ShardId ::= Int
                     | "#metachainShardId"
    syntax AccountName ::= String
    syntax AccountAddr ::= addr(accountShard: ShardId, accountName: AccountName )

    syntax TokenId ::= Int
```

## Transactions 

A transaction is either a `BuiltinCall` or `ESDTManage`. 

```k
    syntax Transaction ::= BuiltinCall
                         | ESDTManage       // SC Calls to the ESDT system SC
```

### Management operations

The `ESDTManage` transactions are management operations invoked by calling the ESDT system smart contract.

[Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L179)

```k
    syntax ESDTManage ::= "issue" "(" AccountAddr "," TokenId "," Int ")" Properties   
                        | freeze( AccountAddr , AccountAddr , TokenId , Bool )
                        | controlChanges( AccountAddr , TokenId , Properties )
                        | pause( AccountAddr , TokenId , Bool )
                        | setSpecialRole( AccountAddr , AccountAddr , TokenId , ESDTRole , Bool )
```

### Builtin functions

[Go to implementation](https://github.com/multiversx/mx-chain-core-go/blob/3abc88468840f8147f614dc96f019baa0ef021c3/core/constants.go#L44)

```k
    syntax BuiltinCall ::= transfer( AccountAddr, AccountAddr, TokenId, Int, Bool )
                         | localMint( AccountAddr, TokenId, Int )
                         | localBurn( AccountAddr, TokenId, Int )
                         | doFreeze( TokenId , AccountAddr , Bool )
                         | setGlobalSetting( ShardId , TokenId , MetadataKey , Bool )
                         | setESDTRole( TokenId , AccountAddr , ESDTRole , Bool )
```

## Token properties

[Documentation](https://docs.elrond.com/tokens/esdt-tokens/#configuration-properties-of-an-esdt-token)

```k
    syntax Properties ::= ""
                        | "{" PropertyList "}"
                        
    syntax PropertyList ::= List{Property, ","}
    syntax Property     ::= PropertyName ":" Bool
    syntax PropertyName ::= "canFreeze" | "canWipe" | "canPause" | "canChangeOwner" 
                          | "canUpgrade" | "canAddSpecialRoles"
```


## ESDT Global Metadata

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtMetaData.go#L20)

```k
    syntax MetadataKey ::= "paused"
                         | "limited"
                         // | "burnRoleForAll"
```

## Roles

[Go to implementation](https://github.com/multiversx/mx-chain-core-go/blob/3abc88468840f8147f614dc96f019baa0ef021c3/core/constants.go#L118)

```k
    syntax ESDTRole ::= "ESDTRoleLocalMint"
                      | "ESDTRoleLocalBurn"
                      | "ESDTRoleNFTCreate"
                      | "ESDTRoleNFTCreateMultiShard"
                      | "ESDTRoleNFTAddQuantity"
                      | "ESDTRoleNFTBurn"
                      | "ESDTRoleNFTAddURI"
                      | "ESDTRoleNFTUpdateAttributes"
                      | "ESDTRoleTransfer"

endmodule
```