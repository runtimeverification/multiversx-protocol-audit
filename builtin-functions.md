
```k
requires "configuration.md"
requires "helpers.md"
requires "transfer.md"

module BUILTIN-FUNCTIONS
    imports CONFIGURATION
    imports HELPERS
    imports TRANSFER
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