# ESDT in K



```k
requires "esdt-syntax.md"
requires "containers.md"
requires "configuration.md"
requires "errors.md"
requires "helpers.md"
requires "transfer.md"
requires "builtin-functions.md"

module ESDT
    imports ESDT-SYNTAX
    imports CONFIGURATION
    imports HELPERS
    imports ERRORS
    imports TRANSFER
    imports BUILTIN-FUNCTIONS

    imports BOOL
    imports INT
    imports K-EQUAL

```

## Main Loop

Execute one of these steps:

* Execute a user action
* Execute an incoming transaction
* next block (?)

### Execute a user action

```k
     rule <is-running> #no => ShrId </is-running>
          <shard>
            <shard-id> ShrId </shard-id>
            <steps> . </steps>
            <user-txs> (TxL(Tx) => .TxList) ... </user-txs>
            <current-tx> #nullTx => Tx </current-tx>
            ...
          </shard>  [label(take-user-action)]
```

### Execute an incoming transaction

```k
     rule <is-running> #no => ShrId </is-running>
          <shard>
            <shard-id> ShrId </shard-id>
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
     rule <meta-steps> . </meta-steps>
          <meta-incoming> MQ => push(MQ, SndShrId, Tx) </meta-incoming>
          <shard>
            <steps> #finalizeTransaction </steps>
            <shard-id> SndShrId </shard-id>
            <out-txs> TxL(Tx) => .TxList ... </out-txs>
            ...
          </shard>
          requires #metachainShardId ==Shard #txDestShard(Tx)
          [label(relay-to-meta)]
```

Cleanup when there is no outgoing transaction.

```k
     rule <is-running> ShrId => #no </is-running>
          <shard> 
            <shard-id> ShrId </shard-id>
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
If `Tx` is a cross shard transaction and this shard is the destination, create a transaction using `#mkReturnTx` 
to revert the state in the sender's shard. For example, to return the tokens to the sender in cross shard transfers.

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> L => (L ; #failure(Err) ; Tx ) </logs>
            <out-txs> Txs => 
              #if (#isCrossShard(Tx) andBool #txDestShard(Tx) ==Shard ShrId)
              #then Txs TxL(#mkReturnTx(Tx))
              #else Txs #fi            
            </out-txs>
            ...
          </shard>
//          requires notBool( #isCrossShard(Tx) )
//            orBool #txDestShard(Tx) =/=Shard ShrId
          [label(finalize-failure-log-revert)]

     //rule <shard> 
     //       <shard-id> ShrId </shard-id>
     //       <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
     //       <current-tx> Tx </current-tx>
     //       <snapshot> ACTS </snapshot>
     //       (_:AccountsCell => ACTS)
     //       <logs> L => (L ; #failure(Err) ; Tx ) </logs>
     //       <out-txs> ... (.TxList => TxL(#mkReturnTx(Tx))) </out-txs>
     //       ...
     //     </shard>
     //     requires #isCrossShard(Tx)
     //      andBool #txDestShard(Tx) ==Shard ShrId
     //     [label(finalize-failure-log-revert-cross)]
          
     rule <steps> #failure(_) ~> (T:TxStep => .) ... </steps> requires T =/=K #finalizeTransaction    [label(failure-skip-rest)] 
    
```

```k
     syntax Transaction ::= #mkReturnTx(Transaction)       [function, functional]
  // ------------------------------------------------------------------------------------
     rule #mkReturnTx(transfer(Sender, Dest, TokId, Val, _)) => transfer(Dest, Sender, TokId, Val, true)
     rule #mkReturnTx(#nullTx) => #nullTx
     rule #mkReturnTx(_:ESDTManage)    => #nullTx
     rule #mkReturnTx(doFreeze(_,_,_)) => #nullTx
     rule #mkReturnTx(setGlobalSetting(_,_,_,_))  => #nullTx
     rule #mkReturnTx(setESDTRole(_,_,_, _))  => #nullTx
     
```

## ESDT Management Functions


Send ESDT management operations to the system SC on Metachain

```k
     rule <shard>
            <steps> 
              . => #success
                ~> #finalizeTransaction
            </steps>
            <current-tx> Tx:ESDTManage </current-tx>
            <out-txs> ... (.TxList => TxL(Tx)) </out-txs>
            ...
          </shard>
          [label(esdtmanage-to-output)]


     rule <meta-incoming> 
            ...
            _SndShr M|-> (TxL(Tx) Txs:TxList => Txs) 
            ... 
          </meta-incoming>
          <meta-steps> . => Tx </meta-steps>
          <is-running> #no => #metachainShardId </is-running>
          [label(meta-take-incoming-tx)]
```


### Issue fungible tokens

```k

     rule <meta-steps> issue(Owner, TokId, Supply) Props => #createToken(Owner, TokId, Props)
                                                         ~> #sendInitialSupply(Owner, TokId, Supply)
                                                         ~> #finalizeTransaction
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
              <global-token-limited> false </global-token-limited>
              <global-token-owner> Owner </global-token-owner>
              <global-token-props> #makeProperties(Props) </global-token-props>
              <global-esdt-roles> .SetMap </global-esdt-roles>
            </global-token-setting>
```

Send the initial supply to the token owner using the `transfer` function.

```k
     syntax KItem ::= #sendInitialSupply(AccountAddr, TokenId, Int)
  // ----------------------------------------------------------------------
     rule <meta-steps> #sendInitialSupply(Owner, TokId, Supply) => . ... </meta-steps>
          <meta-out-txs> ... (.TxList => TxL(transfer(#systemAct, Owner, TokId, Supply, false))) </meta-out-txs>
```

### Freeze/Unfreeze

At Metachain, check the ownership and token properties. Then, call the builtin function `doFreeze` at the destination account's shard.

```k

     rule <meta-steps> freeze(Caller, OtherAct, TokId, Val) => #finalizeTransaction
          </meta-steps> 
          <global-token-settings>
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> Caller </global-token-owner>
              <global-token-props> Props </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          <meta-out-txs> ... (.TxList => TxL( doFreeze(TokId, OtherAct, Val) ) ) </meta-out-txs>
          requires hasProp(Props, canFreeze)
          [label(freeze-at-meta)]
```

### Set special role

At Metachain, check the ownership and token properties. Then, call the builtin function `setESDTRole` at the destination account's shard.

```k
// TODO  update global esdt roles and toggle limited if needed

     rule <meta-steps> setSpecialRole(Caller, OtherAct, TokId, Role, Val) 
              => checkLimited(TokId, Role, Val, ROLES)
              ~> #finalizeTransaction
          </meta-steps> 
          <global-token-settings>
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> Caller </global-token-owner>
              <global-token-props> Props </global-token-props>
              <global-esdt-roles> 
                ROLES => setMapToggle(ROLES, Role, OtherAct, Val) 
              </global-esdt-roles> // ESDTRole |-> Set<AccountAddr>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          <meta-out-txs> ... (.TxList => TxL( setESDTRole(TokId, OtherAct, Role, Val) ) ) </meta-out-txs>
          requires hasProp(Props, canAddSpecialRoles)
          [label(set-special-role-meta)]
```

```k
    syntax KItem ::= checkLimited(TokenId, ESDTRole, Bool, SetMap)

```

First transfer role set, send limited global setting to all shards.
    
```k
    rule
      <meta-steps> checkLimited(TokId, ESDTRoleTransfer, true, OldRoles) 
                => sendGlobalSettingToAll(TokId, limited, true, .Set) ... 
      </meta-steps>
      <global-token-settings>
        <global-token-setting>
          <global-token-id> TokId </global-token-id>
          <global-token-limited> _ => true </global-token-limited>
          ...
        </global-token-setting>
        ...
      </global-token-settings>
      requires getSetItem(OldRoles, ESDTRoleTransfer) ==K .Set
```

Last transfer role removed

```k
    rule
      <meta-steps> checkLimited(TokId, ESDTRoleTransfer, false, OldRoles) 
                => sendGlobalSettingToAll(TokId, limited, false, .Set) ... 
      </meta-steps>
      <global-token-settings>
        <global-token-setting>
          <global-token-id> TokId </global-token-id>
          <global-esdt-roles> Roles </global-esdt-roles>
          <global-token-limited> _ => false </global-token-limited>
          ...
        </global-token-setting>
        ...
      </global-token-settings>
      requires getSetItem(OldRoles, ESDTRoleTransfer) =/=K .Set
       andBool getSetItem(Roles, ESDTRoleTransfer) ==K .Set

    rule
      <meta-steps> checkLimited(_, _, _, _) => . ... </meta-steps>
      [priority(160)]  // has lower priority than the above and higher than owise

```

### Pause/Unpause

At Metachain, check the ownership and token properties. Then, call the builtin function `freeze` at the destination account's shard.

```k

     rule <meta-steps> pause(Caller, TokId, Val) => sendGlobalSettingToAll(TokId, paused, Val, .Set)
                                                 ~> #finalizeTransaction
          </meta-steps> 
          <global-token-settings>
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> Caller </global-token-owner>
              <global-token-props> Props </global-token-props>
              <global-token-paused> _ => Val </global-token-paused>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          requires hasProp(Props, canPause)
          [label(pause-at-meta)]

     syntax KItem ::= sendGlobalSettingToAll(TokenId, MetadataKey, Bool, Set)
  // -----------------------------------------------------------
     rule <meta-steps>
            sendGlobalSettingToAll(TokId, Key, Val, Sent)
            => sendGlobalSettingToAll(TokId, Key, Val, Sent SetItem(ShrId) ) ... 
          </meta-steps>
          <meta-out-txs> 
            ... (.TxList => TxL( setGlobalSetting(ShrId, TokId, Key, Val)) )  
          </meta-out-txs>
          <shard>
            <shard-id> ShrId </shard-id>
            ...
          </shard>
          requires notBool (ShrId in(Sent))
          [label(sendGlobalSettingToAll-rec)]

     rule <meta-steps> sendGlobalSettingToAll(_, _, _, _) => . ... </meta-steps>
          [priority(160), label(sendGlobalSettingToAll-end)] // has lower priority than the above and higher than owise

```




### Upgrade properties

```k

     rule <meta-steps> controlChanges(Caller, TokId, Props) => #finalizeTransaction
          </meta-steps> 
          <global-token-settings>
            <global-token-setting>
              <global-token-id> TokId </global-token-id>
              <global-token-owner> Caller </global-token-owner>
              <global-token-props> TokProps => #updateProps(TokProps, Props) </global-token-props>
              ...
            </global-token-setting>
            ...
          </global-token-settings>
          requires hasProp(TokProps, canUpgrade)
          [label(controlChanges-at-meta)]
```

### Send messages from Metachain to shards:

```k
     rule <meta-steps> #finalizeTransaction </meta-steps>
          <meta-out-txs> TxL(Tx) => .TxList ... </meta-out-txs>
          <shard>
            <steps> . </steps>
            <shard-id> DestShrId </shard-id>
            <incoming-txs> MQ => push(MQ, #metachainShardId, Tx) </incoming-txs>
            ...
          </shard>
          requires DestShrId ==Shard #txDestShard(Tx)
          [label(relay-from-meta-to-shard)]

     rule <meta-steps> #finalizeTransaction => . </meta-steps>
          <meta-out-txs> .TxList </meta-out-txs>
          <is-running> #metachainShardId => #no </is-running>
```


```k
endmodule
```
