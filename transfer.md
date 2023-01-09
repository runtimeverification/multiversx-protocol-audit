
```k
requires "configuration.md"
requires "helpers.md"

module TRANSFER
    imports CONFIGURATION
    imports HELPERS

    imports K-EQUAL

    syntax TxStep ::= "#processBuiltinFunction"
```

# ESDT Transfer

Execute the ESDT Transfer builtin function: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L100)

```k
     rule <shard>
            <steps> #processBuiltinFunction 
                 => #createDefaultTokenSettings(TokId)
                 ~> #basicChecks
                 ~> #checkLimitedTransfer
                 ~> #processSender
                 ~> #processDest ...
            </steps>
            <current-tx> transfer(_, _, TokId, _, _) </current-tx>
            ...
          </shard>  [label(esdt-transfer-steps)]
```

# Common precondition checks

```k
     syntax TxStep ::= "#basicChecks"
  // ----------------------------------
     rule <shard> 
            <steps> #basicChecks => . ... </steps>
            <current-tx> transfer(_, RCV, _, Val, _) </current-tx>
            ...
          </shard>  
          requires accountShard(RCV) =/=Shard #metachainShardId
           andBool 0 <Int Val                             // >
          [label(basicChecks-pass)]
    
     rule <shard> 
            <steps> #basicChecks => #failure(
                                      #if (accountShard(RCV) ==Shard #metachainShardId)
                                      #then #ErrInvalidRcvAddr
                                      #else #ErrNegativeValue
                                      #fi
                                    ) ... </steps>
            <current-tx> transfer(_, RCV, _, _, _) </current-tx>
            ...
          </shard>  
          [label(basicChecks-fail), priority(160)]
```

# Limited transfer check

```k
     syntax TxStep ::= "#checkLimitedTransfer"
```

Skip if
  * not limited or
  * return transfer or
  * this shard is the destination

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L346)

```k
     rule <shard>
            <shard-id> ShrId </shard-id>
            <steps> #checkLimitedTransfer => #isSenderOrDestinationWithTransferRole ... </steps>
            <current-tx> transfer(addr(ShrId, _), _, TokId, _, false) </current-tx>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                <limited> true </limited>
                ...
              </token-setting>
              ...
            </token-settings>
            ...
          </shard>
          [label(check-limited-transfer)]

     rule <shard>
            <steps> #checkLimitedTransfer => . ... </steps>
            ...
          </shard> 
          [label(check-limited-transfer-pass), priority(160)]

    syntax TxStep ::= "#isSenderOrDestinationWithTransferRole"
  // ---------------------------------------------------------
    rule
      <shard>
        <shard-id> ShrId </shard-id>
        <steps> #isSenderOrDestinationWithTransferRole => . ... </steps>
        <current-tx> transfer(addr(ShrId, A1), _, TokId, _, false) </current-tx>
        <account> 
          <account-name> A1 </account-name>
          <esdt-roles> ROLES </esdt-roles>
          ...
        </account>
        ...
      </shard>
      requires ESDTRoleTransfer in(getSetItem(ROLES, TokId))
      [label(isSenderOrDestinationWithTransferRole-sender)]
    
    rule
      <shard>
        <shard-id> ShrId </shard-id>
        <steps> #isSenderOrDestinationWithTransferRole => . ... </steps>
        <current-tx> transfer(_, addr(ShrId, A2), TokId, _, false) </current-tx>
        <account> 
          <account-name> A2 </account-name>
          <esdt-roles> ROLES </esdt-roles>
          ...
        </account>
        ...
      </shard>
      requires ESDTRoleTransfer in(getSetItem(ROLES, TokId))
      [label(isSenderOrDestinationWithTransferRole-dest), priority(151)]
    
    rule
      <shard>
        <steps> #isSenderOrDestinationWithTransferRole => #failure(#ErrActionNotAllowed) ... </steps>
        ...
      </shard>
      [label(isSenderOrDestinationWithTransferRole-notAllowed), priority(160)]

```

# Process Sender

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L135)

## Process sender at destination shard
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
## Process sender at sender shard

Check token settings, then decrease the sender's balance.

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processSender => #checkTokenSettings(TokId, ActName)
                                   ~> #updateBalance(ActName, TokId, 0 -Int Val)
                                   ... 
            </steps>
            <current-tx> transfer(addr(ShrId, ActName), _, TokId, Val, _) </current-tx>
            ...
          </shard>
          [label(process-sender-at-sender-shard)]
```

# Process destination

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L149)

## Process destination at sender shard

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

## Process destination at destination shard

* Check payable: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L150) 
* Check token settings and increase the destination account's balance: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L155)

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> #processDest => #checkPayable
                                 ~> #checkTokenSettings(TokId, ActName)
                                 ~> #updateBalance(ActName, TokId, Val)
                                 ... 
            </steps>
            <current-tx> transfer(_, addr(ShrId, ActName), TokId, Val, _) </current-tx>
            ...
          </shard>
          [label(process-dest-at-dest-shard)]
```



# Check token settings

If token settings does not exist on this shard, create default token settings
    
```k   
     syntax TxStep ::= #createDefaultTokenSettings(TokenId)
  // ------------------------------------------------------   
     rule <shard>
            <steps> #createDefaultTokenSettings(TokId) => . ... </steps>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                ...
              </token-setting>
              ...
            </token-settings>
            ...
          </shard> 
          [label(skip-default-token-settings)]

     rule <shard>
            <steps> #createDefaultTokenSettings(TokId) => . ... </steps>
            <token-settings>
              (.Bag => #mkTokenSetting(TokId))
              ...
            </token-settings>
            ...
          </shard> 
          [label(create-default-token-settings), priority(160)]

     syntax TokenSettingCell ::= #mkTokenSetting(TokenId)      [function, total]
  // -----------------------------------------------------------------------------------------  
     rule #mkTokenSetting(TokId) => 
          <token-setting>
            <token-setting-id> TokId </token-setting-id>
            <paused> false </paused>
            <limited> false </limited>
            <frozen> .Set </frozen>
          </token-setting>
```

Check Paused: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L251)

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

# Check balance

Balance must be non-negative.

```k
     syntax TxStep ::= #checkBalance(AccountName, TokenId)
  // ----------------------------------------------------------
     rule <shard>
            <steps> #checkBalance(ActName, TokId) => . ... </steps>
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
        requires 0 <=Int #getBalance(BALS, TokId)     [label(pass-balance-check)]
    
     rule <shard>
            <steps> #checkBalance(ActName, TokId) => #failure(#ErrInsufficientFunds) ... </steps>
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
        requires #getBalance(BALS, TokId) <Int 0      [label(insufficient-balance)] // >

     rule <shard>
            <steps> #checkBalance(_, _) => #failure(#ErrUnknownAccount) ... </steps>
            ...
          </shard> [label(checkBalance-unknown-account), priority(160)]
```

# Payable check

```k
     syntax TxStep ::= "#checkPayable"
  // --------------------------------------------------
     rule <shard>
            <shard-id> ShrId </shard-id>
            <steps> #checkPayable => . ...  </steps>
            <current-tx> transfer(_, addr(ShrId, ActName), _, _, _) #as Tx </current-tx>
            <account>
              <account-name> ActName </account-name>
              <is-sc> IsSc </is-sc>
              <payable> Payable </payable>
              ...
            </account>
            ...
            </shard>
        requires (notBool(#mustVerifyPayable(Tx)))
          orBool (notBool(IsSc))
          orBool (Payable)
        [label(checkPayable-pass)]

     rule <shard>
            <steps> #checkPayable => #failure(#ErrAccountNotPayable) ...  </steps>
            ...
          </shard>
        [label(checkPayable-fail), priority(160)]

  // TODO return 'false' for transfer & execute
  syntax Bool ::= "#mustVerifyPayable" "(" Transaction ")"   [function, total]
  rule #mustVerifyPayable(transfer(Sender, _, _, _, IsReturn)) => false requires Sender ==K #systemAct orBool IsReturn
  rule #mustVerifyPayable(_) => true                             [owise]
  
```

# Update balance

Update a user's balance, and then check the result: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtTransfer.go#L256)

```k
     syntax TxStep ::= #updateBalance(AccountName, TokenId, Int)
    // ---------------------------------------------------------------
     rule <shard>
            <steps> #updateBalance(ActName, TokId, Val) 
                 => #checkBalance(ActName, TokId) ... </steps>
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

     rule <shard>
            <steps> #updateBalance(_, _, _) => #failure(#ErrUnknownAccount) ... </steps>
            ...
          </shard> [label(updateBalance-unknown-account), priority(160)]
endmodule
```