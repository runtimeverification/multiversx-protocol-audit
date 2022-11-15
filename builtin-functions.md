
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
            <steps> 
              . => #createDefaultTokenSettings(TokId)
                ~> #updateFrozen
                ~> #success
                ~> #finalizeTransaction
            </steps>
            ...
          </shard>  [label(freeze-at-shard)]

     syntax TxStep ::= "#updateFrozen"
     rule <shard>
            <steps> #updateFrozen => . ... </steps>
            <current-tx> doFreeze(TokId, addr(_, ActName), P) </current-tx>
            <token-settings>
              <token-setting>
                <token-setting-id> TokId </token-setting-id>
                <frozen> Frozen => setToggle(Frozen, ActName, P) </frozen>
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
            <steps> 
              . => #createDefaultTokenSettings(TokId)
                ~> #updateMetadata
                ~> #success
                ~> #finalizeTransaction
            </steps>
            ...
          </shard>  [label(pause-at-shard)]

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
        <current-tx> setESDTRole(TokId, addr(_, ActName), Role, P) </current-tx>
        <steps> . => #success
                  ~> #finalizeTransaction
        </steps>
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



```



```k
endmodule
```