# ESDT in K



```k
requires "esdt-syntax.md"
requires "containers.md"
requires "errors.md"


module ESDT
    imports ESDT-SYNTAX
    imports MAP
    imports SET
    imports BOOL
    imports INT
    imports K-EQUAL
    imports CONTAINERS
    imports ERRORS

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
            <incoming-txs> .MQueue </incoming-txs>
            <user-txs> .TxList </user-txs>
            <steps> .K </steps>
            <current-tx> #nullTx </current-tx>
            <out-txs> .TxList </out-txs>

            <accounts>
              <account multiplicity="*" type="Map">
                <account-name> "":AccountName </account-name>
                <is-sc> false </is-sc>
                <esdt-balances> .BalMap </esdt-balances>
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

            <logs> .K </logs>
          </shard>
        </shards>
      </esdt>

    syntax Transaction ::= "#nullTx"

    syntax AccountAddr ::= "#nullAct"
    
    syntax Snapshot ::= "#emptySnapshot"
                      | AccountsCell


```

## Main Loop

Execute one of these steps:

* Execute a user action
* Execute an incoming transaction
* next block (?)

### Execute a user action

```k
     rule <shard>
            <steps> . </steps>
            <user-txs> (TxL(Tx) => .TxList) ... </user-txs>
            <current-tx> #nullTx => Tx </current-tx>
            ...
          </shard>
```

### Execute an incoming transaction

```k
     rule <shard>
            <steps> . </steps>
            <incoming-txs> 
                 ...
                 _SndShr M|-> (TxL(Tx) Txs:TxList => Txs) 
                 ... 
            </incoming-txs>
            <current-tx> #nullTx => Tx </current-tx>
            ...
          </shard>

     rule <steps> #nullTx => . ... </steps>

```

## ESDT Transfer

```k
    syntax TxStep ::= "#checkLimitedTransfer"
                    | "#checkPayable"    
                    | "#success"
                    | "#failure" "(" Error ")"
                    | "#finalizeTransaction"
                          
     rule <shard>
            <steps> 
              . => #takeSnapshot
                ~> #basicChecks
                ~> #checkLimitedTransfer
                ~> #processSender
                ~> #processDest
                ~> #success
                ~> #finalizeTransaction
            </steps>
            <current-tx> _:ESDTTransfer </current-tx>
            ...
          </shard>
```

### Take snapshot

```k
     syntax TxStep ::= "#takeSnapshot"
  // ---------------------------------------------
     rule <shard>
            <steps> #takeSnapshot => . ... </steps>
            (ACTS:AccountsCell)
            <snapshot> _ => ACTS </snapshot>
            ...
          </shard>
```

### Common precondition checks

```k
     syntax TxStep ::= "#basicChecks"
  // ---------------------------------------------
     rule <shard> 
            <steps> #basicChecks => #failure(#ErrInvalidRcvAddr) ... </steps>
            <current-tx> transfer(_, accountAddr(#metachainShardId,_), _, _, _) </current-tx>
            ...
          </shard>  
     
     rule <shard> 
            <steps> #basicChecks => . ... </steps>
            <current-tx> transfer(_, RCV, _, Val, _) </current-tx>
            ...
          </shard>  
          requires accountShard(RCV) =/=Shard #metachainShardId
           andBool 0 <Int Val                             // >
     
    // TODO: Check Limited Transfer
     syntax TxStep ::= "#checkLimitedTransfer"
    // --------------------------------------------------
     rule <steps> #checkLimitedTransfer => . ... </steps>
```

### Process Sender

Skip if sender is not at this shard

```k   
     syntax TxStep ::= "#processSender"
  // ---------------------------------------------
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processSender => . ... </steps>
            <current-tx> Tx </current-tx>
            ...
          </shard>  
          requires ShrId =/=Shard #txSenderShard(Tx)
```
Check gas and token settings, then decrease the sender's balance.

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processSender => #checkTokenSettings(TokId, ActName)
                                   ~> #checkBalance(ActName, TokId, Val)
                                   ~> #updateBalance(ActName, TokId, 0 -Int Val)
                                   ... 
            </steps>
            <current-tx> transfer(accountAddr(ShrId, ActName), _, TokId, Val, _) </current-tx>
            ...
          </shard>
```

### Process destination

If the destination is not at this shard, add the transaction to the output queue. 

```k   
     syntax TxStep ::= "#processDest"
  // ---------------------------------------------
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processDest => . ... </steps>
            <current-tx> Tx </current-tx>
            <out-txs> ... (.TxList => TxL(Tx)) </out-txs>
            ...
          </shard>
          requires ShrId =/=Shard #txDestShard(Tx)
```

Perform payable and token settings checks, then, increase the destination account's balance. 

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processDest => #checkPayable
                                 ~> #checkTokenSettings(TokId, ActName)
                                 ~> #updateBalance(ActName, TokId, Val)
                                 ... 
            </steps>
            <current-tx> transfer(_, accountAddr(ShrId, ActName), TokId, Val, _) </current-tx>
            ...
          </shard>
```



### Check token settings

If token settings does not exist on this shard, create default token settings
    
```k   
     syntax TxStep ::= #checkTokenSettings(TokenId, AccountName)
  // ---------------------------------------------
     rule <shard>
            <shard-id> ShrId </shard-id>
            <steps> #checkTokenSettings(TokId,_) ... </steps>
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
```

```k
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
      <steps> #checkTokenSettings(TokId,_) => #failure(#ErrTokenIsPaused) ... </steps>
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
      <steps> #checkTokenSettings(TokId, ActName) => #failure(#ErrESDTIsFrozenForAccount) ... </steps>
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
      <steps> #checkTokenSettings(TokId, ActName) => . ... </steps>
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

### Check sender's balance

```k
     syntax TxStep ::= #checkBalance(AccountName, TokenId, Int)
  // ----------------------------------------------------------
     rule <shard>
            <steps> #checkBalance(ActName, TokId, Val) => . ... </steps>
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
          requires Val <=Int #getBalance(BALS, TokId)
    
     rule <shard>
            <steps> #checkBalance(ActName, TokId, Val) => #failure(#ErrInsufficientFunds) ... </steps>
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
          requires #getBalance(BALS, TokId) <Int Val
```

### Payable check

```k
    rule <shard>
      <steps> #checkPayable => . ...  </steps>
      <current-tx> Tx:ESDTTransfer </current-tx>
      ...
    </shard>
    requires notBool #mustVerifyPayable(Tx)
      orBool #isPayable(Tx)

    rule <shard>
      <steps> #checkPayable => #failure(#ErrAccountNotPayable) ...  </steps>
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

### Update balance

```k
     syntax TxStep ::= #updateBalance(AccountName, TokenId, Int)
    // ---------------------------------------------------------------------------------------------- 
     rule <shard>
            <steps> #updateBalance(ActName, TokId, Val) => . ... </steps>
            <accounts>
              <account>
                <account-name> ActName </account-name>
                <esdt-balances> BALS => #addToBalance(BALS, TokId, Val) </esdt-balances>
                ...
              </account>
              ...
            </accounts>
            ...
          </shard>

```
## Finalize transaction

Log the successful transaction:

```k
     rule <shard> 
            <steps> (#success => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <logs> ... (. => #success ~> Tx) </logs>
            ...
          </shard>
```

Send messages to destination shards

```k
     rule <shard>
            <steps> #finalizeTransaction </steps>
            <shard-id> SndShrId </shard-id>
            <out-txs> TxL(Tx) => .TxList ... </out-txs>
            ...
          </shard>
          <shard>
            <shard-id> DestShrId </shard-id>
            <incoming-txs> MQ => push(MQ, SndShrId, Tx) </incoming-txs>
            ...
          </shard>
          requires DestShrId ==K #txDestShard(Tx)
```

Cleanup

```k
     rule <shard> 
            <steps> #finalizeTransaction => . </steps>
            <current-tx> _ => #nullTx </current-tx>
            <snapshot> _ => #emptySnapshot </snapshot>
            <out-txs> .TxList </out-txs>
            ...
          </shard>

```



### Error handling

Restore to snapshot

```k
     rule <shard> 
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> ... (. => #failure(Err) ~> Tx) </logs>
            ...
          </shard>

     rule <steps> #failure(_) ~> (_:TxStep => .) ... </steps>    [owise]
    
```



### Helper functions

```k
    
    syntax Bool ::= #isCrossShard(Transaction)          [function, functional]
    rule #isCrossShard(Tx) => #txSenderShard(Tx) =/=Shard #txDestShard(Tx)
    
    syntax Bool ::= #onDestShard(ShardId, Transaction)            [function, functional]
                  | #onSenderShard(ShardId, Transaction)          [function, functional]
    rule #onDestShard(Shr, Tx)   => Shr ==K #txDestShard(Tx)
    rule #onSenderShard(Shr, Tx) => Shr ==K #txSenderShard(Tx)
    
    syntax Bool ::= #checkSender(AccountName, Int, Int, Set, Bool) [function, functional]
                  | #checkDest(  AccountName,      Int, Set, Bool) [function, functional]
    rule #checkSender(SndName, Bal, Val, Frozen, Paused) => notBool Paused 
                                                    andBool notBool(SndName in Frozen) 
                                                    andBool 0 <Int Val                    // >
                                                    andBool Val <=Int Bal
    rule #checkDest(DestName, Val, Frozen, Paused) => notBool Paused 
                                              andBool notBool(DestName in Frozen) 
                                              andBool 0 <Int Val    // >

    
    syntax ShardId ::= #txDestShard(Transaction)        [function, functional]
                     | #txSenderShard(Transaction)      [function, functional]
    rule #txDestShard(transfer(_, ACT, _, _, _))   => accountShard(ACT)
    rule #txDestShard(issue(_, _, _) _)            => #metachainShardId    
    rule #txDestShard(#nullTx)                     => #metachainShardId

    rule #txSenderShard(transfer(ACT, _, _, _, _)) => accountShard(ACT)    
    rule #txSenderShard(issue(ACT, _, _) _)        => accountShard(ACT)
    rule #txSenderShard(#nullTx)                   => #metachainShardId

    syntax Bool ::= ShardId "=/=Shard" ShardId        [function, functional, smt-hook(distinct)]
    rule I:Int             =/=Shard J:Int                   => I =/=Int J
    rule _:Int             =/=Shard #metachainShardId       => true
    rule #metachainShardId =/=Shard _:Int                   => true
    rule #metachainShardId =/=Shard #metachainShardId       => false
    
    syntax Bool ::= ShardId "==Shard" ShardId        [function, functional, smt-hook(=)]
    rule I:Int             ==Shard J:Int                   => I ==Int J
    rule _:Int             ==Shard #metachainShardId       => false
    rule #metachainShardId ==Shard _:Int                   => false
    rule #metachainShardId ==Shard #metachainShardId       => true     
```
## Issue fungible tokens

```k
    rule 
        <meta-transactions> issue(Owner, TokId, Supply) Props:Properties 
            => #createToken(Owner, TokId, Props ) 
            ~> #sendInitialSupply(Owner, TokId, Supply)
            ... 
        </meta-transactions>
        requires 0 <=Int Supply  // >
         andBool #tokenDoesntExist(TokId)

    syntax Bool ::= #tokenDoesntExist(TokenId)      [function]
    rule [[ #tokenDoesntExist(TokId) => false ]]
      <global-token-id> TokId </global-token-id>
    rule #tokenDoesntExist(_) => true           [owise]


     syntax KItem ::= "#createToken" "(" AccountAddr "," TokenId "," Properties ")"
  // ----------------------------------------------------------------------
     rule <meta-transactions> #createToken(Owner, TokId, Props) => . ... </meta-transactions>
          <global-token-settings>
            (.Bag => <global-token-setting>
                      <global-token-id> TokId </global-token-id>
                      <global-token-paused> false </global-token-paused>
                      <global-token-owner> Owner </global-token-owner>
                      <global-token-props> #makeProperties(Props) </global-token-props>
                    </global-token-setting>)
            ...
          </global-token-settings>
    

    
    


```



Send the initial supply to the token owner using the `transfer` function.

```k
     syntax KItem ::= #sendInitialSupply(AccountAddr, TokenId, Int)
  // ----------------------------------------------------------------------
     rule <meta-transactions> #sendInitialSupply(Owner, TokId, Supply) 
              => #let Tx = transfer(#nullAct, Owner, TokId, Supply, false)
                 #in #metaToShard(accountShard(Owner), Tx) 
                 ...
          </meta-transactions>
    
```

### Metashard helpers

```k
     syntax KItem ::= #metaToShard(ShardId, Transaction)
  // -------------------------------------------------------------------------------
     rule <meta-transactions> #metaToShard(ShrId, Tx) => . ... </meta-transactions>
          <shard>
            <shard-id> ShrId </shard-id>
            <incoming-txs> MQ => push(MQ, #metachainShardId, Tx) </incoming-txs>
            ...
          </shard>
```

```k
endmodule
```
