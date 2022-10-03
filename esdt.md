# ESDT in K



```k
requires "esdt-syntax.md"

module ESDT
    imports ESDT-SYNTAX
    imports MAP
    imports SET
    imports BOOL
    imports INT
    imports K-EQUAL

    configuration
      <esdt>
        <meta>
          <meta-transactions> .K </meta-transactions>
          <global-token-settings> 
            <global-token-setting multiplicity="*" type="Map">
              <global-token-id>     0:TokenId </global-token-id>
              <global-token-paused> false </global-token-paused>
              <global-token-owner>  #nullAct </global-token-owner>
              <global-token-props>  #defaultTokenProps </global-token-props>
            </global-token-setting>
          </global-token-settings>
        </meta>
        
        <shards>
          <shard multiplicity="*" type="Map">
            <shard-id> 0:ShardId </shard-id>
            <transactions> .K </transactions>
            <current-tx> #nullTx </current-tx>
            <accounts>
              <account multiplicity="*" type="Map">
                <account-name> "":AccountName </account-name>
                <is-sc> false </is-sc>
                <esdt-balances> .Map </esdt-balances>
              </account>
            </accounts>

            <snapshot> #emptySnapshot </snapshot>

            <token-settings>
              <token-setting multiplicity="*" type="Map">
                <token-setting-id> 0:TokenId </token-setting-id>
                <limited> false </limited>
                <paused> false </paused>
                <frozen> .Set </frozen>
                // TODO
              </token-setting>
            </token-settings>

            <out-transfers> .K </out-transfers>

            <logs> .K </logs>
          </shard>
        </shards>
      </esdt>

    syntax Transaction ::= "#nullTx" [macro]
    rule #nullTx => transfer(#nullAct, #nullAct, 0, 0, false)
    
    syntax AccountAddr ::= "#nullAct" [macro]
    rule #nullAct => accountAddr(#metachainShardId, "")
    
    syntax Snapshot ::= "#emptySnapshot"
                      | AccountsCell

    syntax Map ::= "#defaultTokenProps" [macro]
    rule #defaultTokenProps => ( canFreeze          |-> false 
                                 canWipe            |-> false 
                                 canPause           |-> false 
                                 canMint            |-> false 
                                 canBurn            |-> false 
                                 canChangeOwner     |-> false 
                                 canUpgrade         |-> true 
                                 canAddSpecialRoles |-> true)
```

## ESDT Transfer

```k
    syntax TransferStep ::= "#takeSnapshot"
                          | "#basicChecks"
                          | "#checkLimitedTransfer"
                          | "#checkTokenSettings" "(" TokenId "," AccountName ")"
                          | "#checkPayable"    
                          | "#processSender"
                          | "#checkGas"
                          | "#processDest"  
                          | "#addToBalance" "(" AccountName "," TokenId "," Int ")"             
                          | "#success"
                          | "#failure" "(" Error ")"
                          | "#finalizeTransaction"
                          
    syntax Error ::= "#ErrInvalidRcvAddr"
                   | "#ErrTokenIsPaused"
                   | "#ErrESDTIsFrozenForAccount"
                   | "#ErrInsufficientFunds"
                   | "#ErrAccountNotPayable"

    rule <transactions> #nullTx => . ... </transactions>

    rule 
      <shard>
        <transactions> 
          Tx:ESDTTransfer 
            => #takeSnapshot
            ~> #basicChecks
            ~> #checkLimitedTransfer
            ~> #processSender
            ~> #processDest
            ~> #finalizeTransaction ... 
        </transactions>
        <current-tx> _ => Tx </current-tx>
      ...
      </shard>
```

### Take snapshot

```k
    rule 
      <shard>
        <transactions> #takeSnapshot => . ... </transactions>
        (ACTS:AccountsCell)
        <snapshot> _ => ACTS </snapshot>
      ...
      </shard>


```

### Common precondition checks
```k


    rule <shard> 
      <transactions> #basicChecks => #failure(#ErrInvalidRcvAddr) ... </transactions>
      <current-tx> transfer(_, accountAddr(#metachainShardId,_), _, _, _) </current-tx>
    ...
    </shard>  
      
    rule <shard> 
      <transactions> #basicChecks => . ... </transactions>
      <current-tx> transfer(_, ACT, _, Val, _) </current-tx>
    ...
    </shard>  
      requires accountShard(ACT) =/=K #metachainShardId
       andBool 0 <Int Val

    // Check Limited Transfer TODO
    rule <shard>
      <transactions> #checkLimitedTransfer => . ... </transactions>
      //<current-tx> transfer(_, accountAddr(#metachainShardId,_), _, Val, IsReturn) </current-tx>
      //<token-settings>
      //  <token-setting>
      //    <token-setting-id> TokId </token-setting-id>
      //    <limited> true </paused>
      //    ...
      //  </token-setting>
      //</token-settings>
    ...
    </shard>
    //requires notBool IsReturn
```

### Process Sender

Skip if sender is not at this shard

```k
    rule <shard> 
      <shard-id> ShrId </shard-id>
      <transactions> #processSender => . ... </transactions>
      <current-tx> transfer(ACT, _, _, _, _) </current-tx>
    ...
    </shard>  
    requires ShrId =/=K accountShard(ACT)
```
Check gas and token settings, then decrease the sender's balance.

```k
    rule <shard> 
      <shard-id> ShrId </shard-id>
      <transactions> #processSender => #checkGas
                                    ~> #checkTokenSettings(TokId, ActName)
                                    ~> #addToBalance(ActName, TokId, 0 -Int Val)
                                    ... 
      </transactions>
      <current-tx> transfer(accountAddr(ShrId, ActName), _, TokId, Val, _) </current-tx>
      ...
    </shard>

    rule <transactions> #checkGas => . ... </transactions> // TODO
```

### Process destination

If the destination is not at this shard, add the transaction to the output queue. 

```k
    rule <shard> 
      <shard-id> ShrId </shard-id>
      <transactions> #processDest => . ... </transactions>
      <current-tx> transfer(_, ACT, _, _, _) #as Tx </current-tx>
      <out-transfers> Txs => Txs ~> Tx </out-transfers>
      ...
    </shard>  
    requires ShrId =/=K accountShard(ACT)
```

Perform payable and token settings checks, then, increase the destination account's balance. 

```k
    rule <shard> 
      <shard-id> ShrId </shard-id>
      <transactions> #processDest => #checkPayable
                                  ~> #checkTokenSettings(TokId, ActName)
                                  ~> #addToBalance(ActName, TokId, Val)
                                  ... 
      </transactions>
      <current-tx> transfer(_, accountAddr(ShrId, ActName), TokId, Val, _) </current-tx>
    ...
    </shard>
```



### Check token settings

```k
    // If token settings does not exist on this shard, create default token settings
    rule <shard>
      <shard-id> ShrId </shard-id>
      <transactions> #checkTokenSettings(TokId,_) ... </transactions>
      <token-settings>
        (.Bag => <token-setting>
          <token-setting-id> TokId </token-setting-id>
          <paused> false </paused>
          <limited> false </limited>
          <frozen> .Set </frozen>
        </token-setting>)
        ...
      </token-settings>
      ...
    </shard> 
    requires #settingDoesntExist(ShrId, TokId)

    syntax Bool ::= #settingDoesntExist(ShardId, TokenId) [function]
    rule [[ #settingDoesntExist(ShrId, TokId) => false ]]
        <shard> 
          <shard-id> ShrId </shard-id>
          <token-settings> 
            <token-setting>
              <token-setting-id> TokId </token-setting-id>
              ...
            </token-setting>
            ...
          </token-settings>
          ...
        </shard>
    
    rule #settingDoesntExist(_,_) => true [owise]
```

Check Paused

```k
    rule <shard>
      <transactions> #checkTokenSettings(TokId,_) => #failure(#ErrTokenIsPaused) ... </transactions>
      <token-settings>
        <token-setting>
          <token-setting-id> TokId </token-setting-id>
          <paused> true </paused>
          ...
        </token-setting>
        ...
      </token-settings>
      ...
    </shard>  
```

Check Frozen

```k
    rule <shard>
      <transactions> #checkTokenSettings(TokId, ActName) => #failure(#ErrESDTIsFrozenForAccount) ... </transactions>
      <token-settings>
        <token-setting>
          <token-setting-id> TokId </token-setting-id>
          <paused> false </paused>
          <frozen> Frozen </frozen>
          ...
        </token-setting>
        ...
      </token-settings>
      ...
    </shard> 
    requires ActName in Frozen

    // TODO add check fungible
    rule <shard>
      <transactions> #checkTokenSettings(TokId, ActName) => . ... </transactions>
      <token-settings>
        <token-setting>
          <token-setting-id> TokId </token-setting-id>
          <paused> false </paused>
          <frozen> Frozen </frozen>
          ...
        </token-setting>
        ...
      </token-settings>
      ...
    </shard>  
    requires notBool( ActName in Frozen )
```
### Payable check

```k
    rule <shard>
      <transactions> #checkPayable => . ...  </transactions>
      <current-tx> Tx:ESDTTransfer </current-tx>
      ...
    </shard>
    requires notBool #mustVerifyPayable(Tx)
      orBool #isPayable(Tx)

    rule <shard>
      <transactions> #checkPayable => #failure(#ErrAccountNotPayable) ...  </transactions>
      <current-tx> Tx:ESDTTransfer </current-tx>
      ...
    </shard>
    requires #mustVerifyPayable(Tx)
     andBool notBool (#isPayable(Tx))

  // TODO complete #mustVerifyPayable definition
  syntax Bool ::= "#mustVerifyPayable" "(" ESDTTransfer ")"   [function, functional]
  rule #mustVerifyPayable(transfer(_, _, _, _, true)) => false
  rule #mustVerifyPayable(_)                          => true    [owise]
  
  // TODO complete #isPayable definition
  syntax Bool ::= "#isPayable"  "(" ESDTTransfer ")"          [function, functional]
  rule #isPayable(_) => true

```

### Add to balance

```k
    rule <shard>
      <transactions> #addToBalance(ActName, TokId, Val) => . ... </transactions>
      <accounts>
        <account>
          <account-name> ActName </account-name>
          <esdt-balances> BALS => BALS [ TokId <- #getInt(BALS, TokId) +Int Val ] </esdt-balances>
          ...
        </account>
        ...
      </accounts>
      ...
    </shard>
    requires 0 <=Int #getInt(BALS, TokId) +Int Val

    rule <shard> 
      <transactions> #addToBalance(ActName, TokId, Val) => . ... </transactions>
      <accounts>
        <account>
          <account-name> ActName </account-name>
          <esdt-balances> BALS </esdt-balances>
          ...
        </account>
        ...
      </accounts>
      ...
    </shard>
    requires #getInt(BALS, TokId) +Int Val <Int 0

```
## Finalize transaction

```k
    rule <shard> 
      <transactions> #finalizeTransaction => . </transactions>
      <current-tx> Tx => #nullTx </current-tx>
      <snapshot> _ => #emptySnapshot </snapshot>
      <logs> LOGS => LOGS ~> #success ~> Tx </logs>
      ...
    </shard>
```

### Error handling

Restore to snapshot

```k
    rule <shard> 
      <transactions> #failure(Err) ~> #finalizeTransaction => . </transactions>
      <current-tx> Tx => #nullTx </current-tx>
      <snapshot> ACTS:AccountsCell => #emptySnapshot </snapshot>

      (_:AccountsCell => ACTS)
      <logs> LOGS => LOGS ~> #failure(Err) ~> Tx </logs>
      ...
    </shard>

    rule <transactions> #failure(_) ~> (_:TransferStep => .) ... </transactions>    [owise]
    
```



### Helper functions

```k
    
    syntax Bool ::= #isCrossShard(Transaction)          [function, functional]
    rule #isCrossShard(Tx) => #txSenderShard(Tx) =/=K #txDestShard(Tx)
    
    syntax Bool ::= #onDestShard(ShardId, Transaction)            [function, functional]
                  | #onSenderShard(ShardId, Transaction)          [function, functional]
    rule #onDestShard(Shr, Tx)   => Shr ==K #txDestShard(Tx)
    rule #onSenderShard(Shr, Tx) => Shr ==K #txSenderShard(Tx)
    
    syntax Bool ::= #checkSender(AccountName, Int, Int, Set, Bool) [function, functional]
                  | #checkDest(  AccountName,      Int, Set, Bool) [function, functional]
    rule #checkSender(SndName, Bal, Val, Frozen, Paused) => notBool Paused 
                                                    andBool notBool(SndName in Frozen) 
                                                    andBool 0 <Int Val
                                                    andBool Val <=Int Bal
    rule #checkDest(DestName, Val, Frozen, Paused) => notBool Paused 
                                              andBool notBool(DestName in Frozen) 
                                              andBool 0 <Int Val

    syntax Map ::= #addToBalance( Map , TokenId , Int )  [function, functional]
    rule #addToBalance(Bs, TokId, Val) => Bs [TokId <- #getInt(Bs, TokId) +Int Val] 
    
    syntax Int ::= #getInt(Map, KItem)    [function, functional]
    rule #getInt(M,                       A) => 0 requires notBool( A in_keys(M) )
    rule #getInt(_:Map A |-> X:Int _:Map, A) => X
    rule #getInt(_,                       _) => 0        [owise]
    
    syntax ShardId ::= #txDestShard(Transaction)        [function, functional]
                     | #txSenderShard(Transaction)      [function, functional]
    rule #txDestShard(transfer(_, ACT, _, _, _))   => accountShard(ACT)    
    rule #txSenderShard(transfer(ACT, _, _, _, _)) => accountShard(ACT)    
    

```
## Issue fungible tokens

```k
    rule 
        <meta-transactions> issue(Owner, TokId, Supply) Props:Properties 
            => #createToken(Owner, TokId, Props ) 
            ~> #sendInitialSupply(Owner, TokId, Supply)
            ... 
        </meta-transactions>
          
//          <global-token-settings> GTokens </global-token-settings>
        requires 0 <=Int Supply  // invalid supply .. >
         andBool #tokenDoesntExist(TokId)

    syntax Bool ::= #tokenDoesntExist(TokenId)      [function]
    rule [[ #tokenDoesntExist(TokId) => false ]]
      <global-token-id> TokId </global-token-id>
    rule #tokenDoesntExist(_) => true           [owise]


    syntax KItem ::= "#createToken" "(" AccountAddr "," TokenId "," Properties ")"
    rule 
      <meta-transactions> #createToken(Owner, TokId, Props) => . ... </meta-transactions>
      <global-token-settings>
        (.Bag => <global-token-setting>
                  <global-token-id> TokId </global-token-id>
                  <global-token-paused> false </global-token-paused>
                  <global-token-owner> Owner </global-token-owner>
                  <global-token-props> #makeProperties(Props) </global-token-props>
                </global-token-setting>)
        ...
      </global-token-settings>
    
    syntax Map ::= "#makeProperties" "(" Properties ")" [function, functional]
                 | "#makePropertiesH" "(" Map "," PropertyList ")" [function, functional]
    rule #makeProperties( )      => #defaultTokenProps
    rule #makeProperties({ Ps }) => #makePropertiesH(#defaultTokenProps, Ps)
    rule #makePropertiesH(Acc, .PropertyList) => Acc
    rule #makePropertiesH(Acc, (canFreeze : V, Ps:PropertyList)) => #makePropertiesH(Acc [canFreeze <- V], Ps )
    
    


```



Send the initial supply to the token owner using the `transfer` function.

```k
    syntax KItem ::= #sendInitialSupply(AccountAddr, TokenId, Int)
    rule <meta-transactions>
      #sendInitialSupply(Owner, TokId, Supply) 
        => #let Tx = transfer(#nullAct, Owner, TokId, Supply, false)
           #in #metaToShard(accountShard(Owner), Tx) 
           ...
    </meta-transactions>
    
```

### Metashard helpers

```k

    syntax KItem ::= #metaToShard(ShardId, Transaction)
    rule <meta-transactions>
      #metaToShard(ShrId, Tx) => . ...
    </meta-transactions>
    <shard>
      <shard-id> ShrId </shard-id>
      <transactions> Txs => Txs ~> Tx </transactions>
      ...
    </shard>

```

## Relay transactions

```k

    rule <shards>
          <shard>
            <shard-id> Shr1 </shard-id>
            <out-transfers> Tx => . ... </out-transfers>
            ...
          </shard>
          <shard>
            <shard-id> Shr2 </shard-id>
            <transactions> Txs => Txs ~> Tx </transactions>
            ...
          </shard>
          ...
         </shards>
         requires Shr1 =/=K Shr2
          andBool Shr2 ==K #txDestShard(Tx)


endmodule
```
