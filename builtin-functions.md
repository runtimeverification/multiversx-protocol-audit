
```k
requires "configuration.md"
requires "helpers.md"
requires "transfer.md"

module BUILTIN-FUNCTIONS
    imports CONFIGURATION
    imports HELPERS
    imports TRANSFER
```

## Local Mint

```k
     rule <shard>
            <shard-id> ShrId </shard-id>
            <current-tx> localMint(addr(ShrId, Act), TokId, Val) </current-tx>
            <steps> . => #takeSnapshot
                      ~> #checkLocalMint
                      ~> #updateBalance(Act, TokId, Val) 
                      ~> #success
                      ~> #finalizeTransaction
            </steps>
            ...
          </shard>  [label(localMint-steps)]

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

```k
     rule <shard>
            <shard-id> ShrId </shard-id>
            <current-tx> localBurn(addr(ShrId, Act), TokId, Val) </current-tx>
            <steps> . => #takeSnapshot
                      ~> #checkLocalBurn
                      ~> #updateBalance(Act, TokId, 0 -Int Val) 
                      ~> #success
                      ~> #finalizeTransaction
            </steps>
            ...
          </shard>  [label(localBurn-steps)]

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

```k
     rule <shard>
            <current-tx> doFreeze(TokId, _, _) </current-tx>
            <steps> . => #takeSnapshot
                      ~> #createDefaultTokenSettings(TokId)
                      ~> #updateFrozen
                      ~> #success
                      ~> #finalizeTransaction
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


```k
     rule <shard>
            <current-tx> setGlobalSetting(_, TokId, _, _) </current-tx>
            <steps> . => #takeSnapshot
                      ~> #createDefaultTokenSettings(TokId)
                      ~> #updateMetadata
                      ~> #success
                      ~> #finalizeTransaction
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


```k
    rule 
      <shard>
        <current-tx> setESDTRole(_, _, _, _) </current-tx>
        <steps> . => #takeSnapshot
                  ~> #updateESDTRole
                  ~> #success
                  ~> #finalizeTransaction
        </steps>
        ...
      </shard>  [label(set-esdt-role)]


    syntax TxStep ::= "#updateESDTRole"
    rule 
      <shard>
        <steps> #updateESDTRole => . ... </steps>
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
      </shard>  [label(update-esdt-role)]

    rule 
      <shard>
        <steps> #updateESDTRole => #failure(#ErrUnknownAccount) ... </steps>
        <current-tx> setESDTRole(_, _, _, _) </current-tx>
        ...
      </shard>    [label(update-esdt-role-unknown-act), priority(160)]

endmodule
```