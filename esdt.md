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
    imports LIST
    
    configuration
      <esdt>
        <meta>
          <meta-steps> .K </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
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
            <shard-id> 0:Int </shard-id>
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

            <logs> .Logs </logs>
          </shard>
        </shards>
      </esdt>

    syntax Transaction ::= "#nullTx"

    syntax AccountAddr ::= "#nullAct" [macro]
    rule #nullAct => accountAddr(#metachainShardId, "system")
    
    syntax Snapshot ::= "#emptySnapshot"
                      | AccountsCell

    syntax Logs ::= ".Logs"
                  | Logs ";" Log
    syntax Log ::= TxStep | Transaction

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
          </shard>  [label(take-user-action)]
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
          </shard> [label(take-incoming-tx)]

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
          </shard>  [label(esdt-transfer-steps)]
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
          </shard> [label(take-snapshot)]
```

### Common precondition checks

```k
     syntax TxStep ::= "#basicChecks"
  // ---------------------------------------------
     rule <shard> 
            <steps> #basicChecks => #failure(#ErrInvalidRcvAddr) ... </steps>
            <current-tx> transfer(_, accountAddr(#metachainShardId,_), _, _, _) </current-tx>
            ...
          </shard> [label(check-dest-is-metachain)] 
     
     rule <shard> 
            <steps> #basicChecks => . ... </steps>
            <current-tx> transfer(_, RCV, _, Val, _) </current-tx>
            ...
          </shard>  
          requires accountShard(RCV) =/=Shard #metachainShardId
           andBool 0 <Int Val                             // >
          [label(check-val-is-positive)]

    // TODO: Check Limited Transfer
     syntax TxStep ::= "#checkLimitedTransfer"
    // --------------------------------------------------
     rule <steps> #checkLimitedTransfer => . ... </steps> [label(check-limited-transfer)]
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
          [label(process-sender-at-dest-shard-skip)]
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
          [label(process-sender-at-sender-shard)]
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
          [label(process-dest-at-sender-shard-out-tx)]
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
          [label(process-dest-at-dest-shard)]
```



### Check token settings

If token settings does not exist on this shard, create default token settings
    
```k   
     syntax TxStep ::= #checkTokenSettings(TokenId, AccountName)
  // ---------------------------------------------
     rule <shard>
            <steps> #checkTokenSettings(TokId,_) ... </steps>
            <token-settings>
              (.Bag => #mkTokenSetting(TokId))
              REST
            </token-settings>
            ...
          </shard> 
          requires notBool(TokId in( #localTokenIds(<token-settings> REST </token-settings>) ))
          [label(create-local-token-settings)]

     syntax Set ::= #localTokenIds(TokenSettingsCell)         [function, functional]
     rule #localTokenIds(<token-settings> .Bag </token-settings> ) => .Set
     rule #localTokenIds(<token-settings> 
                          <token-setting>
                            <token-setting-id> TokId </token-setting-id>
                            _
                          </token-setting> REST 
                        </token-settings> ) => SetItem(TokId) #localTokenIds(<token-settings> REST </token-settings>)

     syntax TokenSettingCell ::= #mkTokenSetting(TokenId)      [function, functional]
  // -----------------------------------------------------------------------------------------  
     rule #mkTokenSetting(TokId) => 
          <token-setting>
            <token-setting-id> TokId </token-setting-id>
            <paused> false </paused>
            <limited> false </limited>
            <frozen> .Set </frozen>
          </token-setting>
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
    [label(check-token-is-paused)]
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
    [label(account-is-frozen)]

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
    [label(pass-check-token-settings)]
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
          [label(pass-balance-check)]
    
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
          [label(insufficient-balance)]
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
          [label(update-balance)]

```
## Finalize transaction

Log the successful transaction:

```k
     rule <shard> 
            <steps> (#success => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <logs> L => (L ; #success ; Tx ) </logs>
            ...
          </shard>
          [label(finalize-success-log)]
```

Send messages to destination shards:

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
          requires DestShrId ==Shard #txDestShard(Tx)
          [label(relay-cross-shard)]
```

Send messages to Metachain:

```k
     rule <meta-incoming> MQ => push(MQ, SndShrId, Tx) </meta-incoming>
          <shard>
            <steps> #finalizeTransaction </steps>
            <shard-id> SndShrId </shard-id>
            <out-txs> TxL(Tx) => .TxList ... </out-txs>
            ...
          </shard>
          requires #metachainShardId ==Shard #txDestShard(Tx)
          [label(relay-to-meta)]
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
          [label(finalize-cleanup)]
```



### Error handling

Restore to snapshot

```k
     rule <shard> 
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> L => (L ; #failure(Err) ; Tx ) </logs>
            ...
          </shard>
          requires notBool( #isCrossShard(Tx) )
          [label(finalize-failure-log-revert)]

     rule <shard> 
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> L => (L ; #failure(Err) ; Tx ) </logs>
            <out-txs> ... (.TxList => TxL(#mkReturnTx(Tx))) </out-txs>
            ...
          </shard>
          requires #isCrossShard(Tx)
          [label(finalize-failure-log-revert-cross)]
          
     rule <steps> #failure(_) ~> (_:TxStep => .) ... </steps>    [owise, label(failure-skip-rest)] 
    
```

```k
     syntax Transaction ::= #mkReturnTx(Transaction)       [function, functional]
  // ------------------------------------------------------------------------------------
     rule #mkReturnTx(transfer(Sender, Dest, TokId, Val, _)) => transfer(Dest, Sender, TokId, Val, true)
     rule #mkReturnTx(#nullTx) => #nullTx
     rule #mkReturnTx(issue(_,_,_) _ ) => #nullTx
     
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

    syntax Bool ::= ShardId "=/=Shard" ShardId        [function, functional]
    rule I:Int             =/=Shard J:Int                   => I =/=Int J
    rule _:Int             =/=Shard #metachainShardId       => true
    rule #metachainShardId =/=Shard _:Int                   => true
    rule #metachainShardId =/=Shard #metachainShardId       => false
    
    syntax Bool ::= ShardId "==Shard" ShardId        [function, functional]
    rule I:Int             ==Shard J:Int                   => I ==Int J
    rule _:Int             ==Shard #metachainShardId       => false
    rule #metachainShardId ==Shard _:Int                   => false
    rule #metachainShardId ==Shard #metachainShardId       => true     
```
## Issue fungible tokens


Send built-in call to Metachain
```k
     rule <shard>
            <steps> 
              . => #success
                ~> #finalizeTransaction
            </steps>
            <current-tx> Tx:BuiltinCall </current-tx>
            <out-txs> ... (.TxList => TxL(Tx)) </out-txs>
            ...
          </shard>
```

```k
     rule <meta-incoming> 
            ...
            _SndShr M|-> (TxL(Tx) Txs:TxList => Txs) 
            ... 
          </meta-incoming>
          <meta-steps> . => Tx </meta-steps>

     rule <meta-steps> issue(Owner, TokId, Supply) Props => #createToken(Owner, TokId, Props)
                                                         ~> #sendInitialSupply(Owner, TokId, Supply)
                                                         ...   
          </meta-steps> 
          GTS:GlobalTokenSettingsCell
          requires 0 <=Int Supply // >
           andBool notBool( TokId in( #tokenIds(GTS) ) )
           [label(start-issue-at-meta)]

     syntax Set ::= #tokenIds(GlobalTokenSettingsCell)         [function, functional]
     rule #tokenIds(<global-token-settings> .Bag </global-token-settings> ) => .Set
     rule #tokenIds(<global-token-settings> 
                      <global-token-setting>
                        <global-token-id> TokId </global-token-id>
                        _
                      </global-token-setting> REST 
                    </global-token-settings> ) => SetItem(TokId) #tokenIds(<global-token-settings> REST </global-token-settings>)
    
     syntax KItem ::= "#createToken" "(" AccountAddr "," TokenId "," Properties ")"
  // ----------------------------------------------------------------------
     rule <meta-steps> #createToken(Owner, TokId, Props) => . ... </meta-steps>
          <global-token-settings>
            (.Bag => #mkGlobalTokenSetting(Owner, TokId, Props))
            ...
          </global-token-settings>

     syntax GlobalTokenSettingCell ::= #mkGlobalTokenSetting(AccountAddr, TokenId, Properties)      [function, functional]
  // -----------------------------------------------------------------------------------------  
     rule #mkGlobalTokenSetting(Owner, TokId, Props) => 
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-paused> false </global-token-paused>
              <global-token-owner> Owner </global-token-owner>
              <global-token-props> #makeProperties(Props) </global-token-props>
            </global-token-setting>
```

Send the initial supply to the token owner using the `transfer` function.

```k
     syntax KItem ::= #sendInitialSupply(AccountAddr, TokenId, Int)
  // ----------------------------------------------------------------------
     rule <meta-steps> #sendInitialSupply(Owner, TokId, Supply) 
              => #let Tx = transfer(#nullAct, Owner, TokId, Supply, false)
                 #in #metaToShard(accountShard(Owner), Tx) 
                 ...
          </meta-steps>
    
```

### Metashard helpers

```k
     syntax KItem ::= #metaToShard(ShardId, Transaction)
  // -------------------------------------------------------------------------------
     rule <meta-steps> #metaToShard(ShrId, Tx) => . ... </meta-steps>
          <shard>
            <shard-id> ShrId </shard-id>
            <incoming-txs> MQ => push(MQ, #metachainShardId, Tx) </incoming-txs>
            ...
          </shard>
```

```k
endmodule
```
