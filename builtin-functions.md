
```k
requires "configuration.md"
requires "helpers.md"
requires "transfer.md"

module BUILTIN-FUNCTIONS
    imports CONFIGURATION
    imports HELPERS
    imports TRANSFER
```

# Execute builtin functions

[Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/process/smartContract/process.go#L931)

First, take a snapshot to use in error handling, and then call the builtin function.

```k

     rule <shard>
            <current-tx> _:BuiltinCall </current-tx>
            <steps> . => #takeSnapshot
                      ~> #processBuiltinFunction
                      ~> #success
                      ~> #finalizeTransaction
            </steps>
            ...
          </shard>  [label(execute=builtin-function)]
```

## Take snapshot

[Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/process/smartContract/process.go#L940)

The snapshot contains the initial data in the accounts cell. If the execution fails, the state will be reverted to this snapshot.

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

# Local Mint

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalMint.go#L64)

```k
     rule <shard>
            <shard-id> ShrId </shard-id>
            <current-tx> localMint(addr(ShrId, Act), TokId, Val) </current-tx>
            <steps> #processBuiltinFunction 
                 => #checkLocalMint
                 ~> #updateBalance(Act, TokId, Val) ...
            </steps>
            ...
          </shard>  [label(localMint-steps)]
```

Check the preconditions:
* the value must be positive: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalMint.go#L71)
* the account must have the `ESDTRoleLocalMint` role: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalMint.go#L77)

```k
    syntax TxStep ::= "#checkLocalMint"
    rule
      <shard>
        <steps> #checkLocalMint => . ... </steps>
        <current-tx> localMint(addr(_, Act), TokId, Val) </current-tx>
        <account>
          <account-name> Act </account-name>
          <esdt-roles> ROLES </esdt-roles>
          ... 
        </account>
        ...
      </shard>  
      requires ESDTRoleLocalMint in(getSetItem(ROLES, TokId))
       andBool 0 <Int Val
      [label(checkLocalMint-pass)]

    rule
      <shard>
        <current-tx> localMint(_, _, Val) </current-tx>
        <steps> 
          #checkLocalMint => #failure(
                              #if Val <=Int 0
                              #then #ErrNegativeValue
                              #else #ErrActionNotAllowed
                              #fi
                             ) 
                            ... 
        </steps>
        ...
      </shard>
      [label(checkLocalMint-fail), priority(160)]

```

## Local Burn

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalBurn.go#L64)

```k
     rule <shard>
            <shard-id> ShrId </shard-id>
            <current-tx> localBurn(addr(ShrId, Act), TokId, Val) </current-tx>
            <steps> #processBuiltinFunction 
                 => #checkLocalBurn
                 ~> #updateBalance(Act, TokId, 0 -Int Val) ...
            </steps>
            ...
          </shard>  [label(localBurn-steps)]
```

* the value must be positive: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalBurn.go#L71)
* The account must be allowed to burn: [Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtLocalBurn.go#L77)

The `#updateBalance` step checks if the account has enough balance to burn.

```k
    syntax TxStep ::= "#checkLocalBurn"
    rule
      <shard>
        <steps> #checkLocalBurn => . ... </steps>
        <current-tx> localBurn(addr(_, Act), TokId, Val) </current-tx>
        <account>
          <account-name> Act </account-name>
          <esdt-roles> ROLES </esdt-roles>
          ... 
        </account>
        ...
      </shard>  
      requires ESDTRoleLocalBurn in(getSetItem(ROLES, TokId))
       andBool 0 <Int Val
      [label(checkLocalBurn-pass)]

    rule
      <shard>
        <current-tx> localBurn(_, _, Val) </current-tx>
        <steps> 
          #checkLocalBurn => #failure(
                              #if Val <=Int 0
                              #then #ErrNegativeValue
                              #else #ErrActionNotAllowed
                              #fi
                             ) 
                            ... 
        </steps>
        ...
      </shard>
      [label(checkLocalBurn-fail), priority(160)]

```

## Freeze/Unfreeze

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtFreezeWipe.go#L77)

The `doFreeze` function toggles the freeze status of an account. It is always called from the system SC, so there is no precondition check.

```k
     rule <shard>
            <current-tx> doFreeze(TokId, _, _) </current-tx>
            <steps> #processBuiltinFunction 
                 => #createDefaultTokenSettings(TokId)
                 ~> #updateFrozen ...
            </steps>
            ...
          </shard>  [label(freeze-at-shard)]

     syntax TxStep ::= "#updateFrozen"
     rule <shard>
            <steps> #updateFrozen => . ... </steps>
            <current-tx> doFreeze(TokId, Addr, P) </current-tx>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                <frozen> Frozen => setToggle(Frozen, accountName(Addr), P) </frozen>
                ...
              </token-setting>
              ...
            </token-settings>
            ...
          </shard>
          [label(frozen-toggle)]

```

## Set global setting

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtGlobalSettings.go#L74)

Toggles the `paused` and `limited` settings. Always called from Metachain.

```k
     rule <shard>
            <current-tx> setGlobalSetting(_, TokId, _, _) </current-tx>
            <steps> #processBuiltinFunction 
                 => #createDefaultTokenSettings(TokId)
                 ~> #updateMetadata ...
            </steps>
            ...
          </shard>  [label(setGlobalSetting-steps)]

     syntax TxStep ::= "#updateMetadata"
     rule <shard>
            <steps> #updateMetadata => . ... </steps>
            <current-tx> setGlobalSetting(_, TokId, paused, Val) </current-tx>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                <paused> _ => Val </paused>
                ...
              </token-setting>
              ...
            </token-settings>
            ...
          </shard>  [label(update-pause)]

     rule <shard>
            <current-tx> setGlobalSetting(_, TokId, limited, Val) </current-tx>
            <steps> #updateMetadata => . ... </steps>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                <limited> _ => Val </limited>
                ...
              </token-setting>
              ...
            </token-settings>
            ...
          </shard>  [label(update-limited)]
```

## Set ESDT Role

[Go to implementation](https://github.com/multiversx/mx-chain-vm-common-go/blob/755643b6f3982d2deb61782fffc492037f1aeb24/builtInFunctions/esdtRoles.go#L44)

Sets or unsets an ESDT role for given account. Always called from Metachain.

```k
    rule 
      <shard>
        <steps> #processBuiltinFunction => . ... </steps>
        <current-tx> setESDTRole(TokId, addr(_, ActName), Role, P) </current-tx>
        <accounts>
          <account>
              <account-name> ActName </account-name>
              <esdt-roles> ROLES => setMapToggle(ROLES, TokId, Role, P) </esdt-roles>
              ...
          </account>
          ...
        </accounts>
        ...
      </shard>  [label(set-esdt-role)]

    rule 
      <shard>
        <steps> #processBuiltinFunction => #failure(#ErrUnknownAccount) ... </steps>
        <current-tx> setESDTRole(_, _, _, _) </current-tx>
        ...
      </shard>  [label(set-esdt-role-unknown-acct), priority(160)]

endmodule
```