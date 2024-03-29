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

# Main Loop

Choose one of these steps nondeterministically:

* Execute a user action from `<user-txs>`
* Execute an incoming transaction from `<incoming-txs>`

## Execute a user action

The `<user-txs>` cell contains the transactions created by users in this shard. Pop the first transaction in the queue and set as `<current-tx>`.

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

## Execute an incoming transaction

The `<incoming-txs>` cell contains the transactions sent from other shards (or Metachain). Since there are multiple queues in this cell, one of these queues are chosen nondeterministically.

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
```

For example, suppose this is the initial content of the `<incoming-txs>` cell:

```
<incoming-txs>
  ShardA M|-> TxL( TxA1 ) TxL( TxA2 )
  ShardB M|-> TxL( TxB1 ) TxL( TxB2 ) TxL( TxB3 ) 
<incoming-txs>
```

There are 5 transactions in total: 2 from Shard A and 3 from Shard B. One of `TxA1` or `TxB2` is chosen randomly.

See [ESDT Management Functions](#esdt-management-functions) section or [Builtin Functions](./builtin-functions.md) module for execution of transactions.

# Finalize transaction

After successfully executing the transaction add a log entry:

```k
     rule <shard> 
            <steps> (#success => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <logs> L => (L ; #success ; Tx ) </logs>
            ...
          </shard>
          [label(finalize-success-log)]
```

## Sending output transactions

If there are transactions created during the execution, send those transactions. Sending a transaction means `push`ing the transaction to the `<incoming-txs>` of the destination shard with the current shard ID. The `MQueue` data structure maintains multiple queues to separate transactions coming from different shards.

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

The following cases require sending internal transactions:

1. Cross shard transfer successfully executed in the sender's shard: [rules](./transfer.md#process-destination)
1. Cross shard transaction failed in the receiver's shard: [rules](#error-handling)
1. Forwarding `ESDTManage` to Metachain: [rules](#esdt-management-functions)
1. Metachain sends `BuiltinCall`s to shards as a result of executing `ESDTManage` on Metachain.


## Cleanup

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

# Error handling

If a transaction fails at some step, the remaining steps are not executed and the state is reverted. When a transaction fails, It leaves a `#failure(_)` on top of the `<steps>` cell. The following rule skips the rest of the execution steps if there is a failure:

```k
    rule <steps> #failure(_) ~> (T:TxStep => .) ... </steps> 
      requires T =/=K #finalizeTransaction    [label(failure-skip-rest)] 
```

After skipping the remaining execution steps, the `<accounts>` cell is restored to the snapshot. If `Tx` is a cross shard transaction and this shard is the destination, the sender's shard needs to be informed about the failure. Hence, a transaction is created using `#mkReturnTx` to revert the state in the sender's shard. For example, to return tokens to the sender in cross shard transfers.

```k
     rule <shard> 
            <shard-id> ShrId </shard-id>
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> L => (L ; #failure(Err) ; Tx ) </logs>
            <out-txs> Txs => Txs TxL(#mkReturnTx(Tx)) </out-txs>
            ...
          </shard>
          requires #isCrossShard(Tx) andBool (#txDestShard(Tx) ==Shard ShrId)
          [label(finalize-failure-log-revert-cross)]

     rule <shard>
            <steps> (#failure(Err) => .) ~> #finalizeTransaction </steps>
            <current-tx> Tx </current-tx>
            <snapshot> ACTS </snapshot>
            (_:AccountsCell => ACTS)
            <logs> L => (L ; #failure(Err) ; Tx ) </logs>
            ...
          </shard>
          [label(finalize-failure-log-revert), priority(160)]
    
     syntax Transaction ::= #mkReturnTx(Transaction)       [function, total]
  // ------------------------------------------------------------------------------------
     rule #mkReturnTx(transfer(Sender, Dest, TokId, Val, _)) => transfer(Dest, Sender, TokId, Val, true)
     rule #mkReturnTx(#nullTx) => #nullTx
     rule #mkReturnTx(_:ESDTManage)    => #nullTx
     rule #mkReturnTx(doFreeze(_,_,_)) => #nullTx
     rule #mkReturnTx(setGlobalSetting(_,_,_,_))  => #nullTx
     rule #mkReturnTx(setESDTRole(_,_,_, _))  => #nullTx
     rule #mkReturnTx(localMint(_,_,_))       => #nullTx
     rule #mkReturnTx(localBurn(_,_,_))       => #nullTx
     
```

# ESDT Management Functions

ESDT Management functions are SC calls to the ESDT system smart contract. When a shard receives an `ESDTManage` transaction, it forwards the transaction to the Metachain. 

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
## Issue fungible tokens

[Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L293)

Create new token and send initial supply to the token owner. Check if `Supply` is non-negative and `TokId` is unique.

```k
     rule <meta-steps> issue(Owner, TokId, Supply) Props => #createToken(Owner, TokId, Props)
                                                         ~> #sendInitialSupply(Owner, TokId, Supply)
                                                         ~> #finalizeTransaction
          </meta-steps> 
          GTS:GlobalTokenSettingsCell
          requires 0 <=Int Supply // >
           andBool notBool( TokId in( #tokenIds(GTS) ) )
           [label(start-issue-at-meta)]

     syntax Set ::= #tokenIds(GlobalTokenSettingsCell)         [function, total]
     rule #tokenIds(<global-token-settings> .Bag </global-token-settings> ) => .Set
     rule #tokenIds(<global-token-settings> 
                      <global-token-setting>
                        <global-token-id> TokId </global-token-id>
                        _
                      </global-token-setting> REST 
                    </global-token-settings> ) => SetItem(TokId) #tokenIds(<global-token-settings> REST </global-token-settings>)
```

Create new token save token settings. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L636))

```k
     syntax KItem ::= "#createToken" "(" AccountAddr "," TokenId "," Properties ")"
  // ----------------------------------------------------------------------
     rule <meta-steps> #createToken(Owner, TokId, Props) => . ... </meta-steps>
          <global-token-settings>
            (.Bag => #mkGlobalTokenSetting(Owner, TokId, Props))
            ...
          </global-token-settings>

     syntax GlobalTokenSettingCell ::= #mkGlobalTokenSetting(AccountAddr, TokenId, Properties)      [function, total]
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

Create a `transfer` to send the initial supply to the token owner. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L342))

```k
     syntax KItem ::= #sendInitialSupply(AccountAddr, TokenId, Int)
  // ----------------------------------------------------------------------
     rule <meta-steps> #sendInitialSupply(Owner, TokId, Supply) => . ... </meta-steps>
          <meta-out-txs> ... (.TxList => TxL(transfer(#systemAct, Owner, TokId, Supply, false))) </meta-out-txs>
```

## Freeze/Unfreeze

At Metachain, check the ownership and token properties. Then, call the builtin function `doFreeze` at the destination account's shard. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L934))

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

## Set/Unset special role

At Metachain, check the ownership and token properties. Then, make a call to the builtin function `setESDTRole` at the destination account's shard. `Caller` must be the owner of the token, and the token must have the `canAddSpecialRoles` property. ([Go to `setSpecialRole` implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L1735), [Go to `unSetSpecialRole` implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L1793))

```k

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

If this is the first transfer role set, make the token `limited`. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L1723)) Send the global setting to all shards using `setGlobalSetting` builtin call.
    
```k
    syntax KItem ::= checkLimited(TokenId, ESDTRole, Bool, SetMap)

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

When the last transfer role removed, make the token un`limited`. Send the global setting to all shards using `setGlobalSetting` builtin call. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L1849))

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

## Pause/Unpause

At Metachain, check the ownership and token properties. Then, call the builtin function `freeze` at the destination account's shard. ([Go to implementation](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go#L1073))

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

## Upgrade properties

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

## Send messages from Metachain to shards:

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

endmodule
```
