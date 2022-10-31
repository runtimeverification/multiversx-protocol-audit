# ESDT Transfer

```k
requires "configuration.md"
requires "helpers.md"

module TRANSFER
    imports CONFIGURATION
    imports HELPERS

    imports K-EQUAL
       
     rule <shard>
            <steps> 
              . => #takeSnapshot
                ~> #createDefaultTokenSettings(TokId)
                ~> #basicChecks
                ~> #checkLimitedTransfer
                ~> #processSender
                ~> #processDest
                ~> #success
                ~> #finalizeTransaction
            </steps>
            <current-tx> transfer(_, _, TokId, _, _) </current-tx>
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
     syntax TxStep ::= #createDefaultTokenSettings(TokenId)
  // ------------------------------------------------------
     rule <shard>
            <steps> #createDefaultTokenSettings(TokId) => . ... </steps>
            <token-settings>
              (.Bag => #mkTokenSetting(TokId))
              REST
            </token-settings>
            ...
          </shard> 
          requires notBool(#tokenSettingExists(TokId, <token-settings> REST </token-settings>) )
          [label(create-default-token-settings)]
     
     rule <shard>
            <steps> #createDefaultTokenSettings(TokId) => . ... </steps>
            TokSettings:TokenSettingsCell
            ...
          </shard> 
          requires #tokenSettingExists(TokId, TokSettings)
          [label(skip-default-token-settings)]

     syntax Bool ::= #tokenSettingExists(TokenId, TokenSettingsCell)         [function, functional]
     rule #tokenSettingExists(_, <token-settings> .Bag </token-settings> ) => false
     rule #tokenSettingExists(TokId, <token-settings> 
                                        <token-setting>
                                          <token-setting-id> TokId </token-setting-id>
                                          _
                                        </token-setting> _ 
                                      </token-settings> ) => true
     rule #tokenSettingExists(TokId, <token-settings> 
                                        <token-setting>
                                          <token-setting-id> TokId2 </token-setting-id>
                                          _
                                        </token-setting> REST 
                                      </token-settings> ) 
          => #tokenSettingExists(TokId, <token-settings> 
                                          REST 
                                        </token-settings>) requires TokId =/=K TokId2

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
     syntax TxStep ::= #checkTokenSettings(TokenId, AccountName)
  // -----------------------------------------------------------  
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
          </shard>                [label(check-token-is-paused)]
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
        requires ActName in Frozen                [label(account-is-frozen)]

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
        requires notBool( ActName in Frozen )         [label(pass-check-token-settings)]
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
        requires Val <=Int #getBalance(BALS, TokId)     [label(pass-balance-check)]
    
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
        requires #getBalance(BALS, TokId) <Int Val      [label(insufficient-balance)]
```

### Payable check

```k
     syntax TxStep ::= "#checkPayable"
  // --------------------------------------------------
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
    // ---------------------------------------------------------------
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


```k
endmodule
```