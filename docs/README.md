# KESDT: the ESDT token standard in K

This repository presents a formal model of the Elrond Network's token standard [ESDT](https://docs.elrond.com/tokens/esdt-tokens/) in [K](https://kframework.org/). 

_Note: Currently, the scope is limited to issuance, transfer, and management of fungible tokens._

# Configuration

[Code](../configuration.md)

* `<shard>`
    * `<user-txs>`: a queue of transactions that represent user inputs. 
    * `<incoming-txs>`: a multi-queue of transactions implemented as a map from shard IDs to transaction queues. Stores the internal transactions created in other shards and sent to this shard.
    * `<out-txs>`: list of system-generated transactions created during the execution of a transaction. 
        * Example: when a cross-shard transfer fails in the receiver's shard, a transaction is created to return the tokens. 
    * `<accounts>`: account database. Stores ESDT balances, roles, and user meta-data.
    * `<token-settings>`: local token settings, frozen accounts, and token metadata.
    * execution-related cells: `<steps>`, `<current-tx>`, `<snapshot>`, `<logs>`...
* `<meta>`: metachain
    * `<global-token-settings>`: stores the token properties, token owner, and other metadata.
    * `<meta-incoming>`: stores the internal transactions sent from shards. (like `<incoming-txs>`)
    * execution-related cells: `<meta-out-txs>`, `<meta-steps>`


# Constructors

## Addresses and IDs

Accounts are identified by their addresses. An address is a pair of a shard ID and a user name. ([Code](../esdt-syntax.md#addresses-and-ids))

```k
syntax AccountAddr ::= addr(accountShard: ShardId, accountName: AccountName )
```

Tokens have integer IDs:

```k
syntax TokenId ::= Int
```

## Transactions

A transaction is either a `BuiltinCall` or `ESDTManage`. ([syntax module](../esdt-syntax.md#transactions)) The `ESDTManage` transactions are management operations invoked by calling the ESDT system smart contract. 

```k
syntax Transaction ::= BuiltinCall
                     | ESDTManage

syntax ESDTManage ::= "issue" "(" AccountAddr "," TokenId "," Int ")" Properties   
                    | freeze( AccountAddr , AccountAddr , TokenId , Bool )
                    | ...

syntax BuiltinCall ::= transfer( AccountAddr, AccountAddr, TokenId, Int, Bool )
                     | localMint( AccountAddr, TokenId, Int )
                     | localBurn( AccountAddr, TokenId, Int )
                     | ...
```

Following is an example transfer. _Alice_ from shard 1 sends tokens to _Bob_ from shard 2. Token ID is 2, amount is 20.

```k
transfer( addr(1, "Alice"), addr(2, "Bob"), 2, 20, false )
```

## Other definitions

* [Token properties](../esdt-syntax.md#token-properties)
* [Roles](../esdt-syntax.md#roles)


# Shards and communication

Every shard has its own input and output transaction queues, data stores, and execution-related cells. Every shard runs a main loop to consume the transactions from input queues and send messages to other shards. Shards communicate by sending system-generated transactions via the `<output-txs>` and `<incoming-txs>` cells. 

## Main Loop


[Go to semantics](../esdt.md#main-loop)

At each iteration, one of the following actions is chosen nondeterministically:

* execute a user-created transaction from `<user-txs>` queue, ([rules](../esdt.md#execute-a-user-action)) 
* execute an internal (system-generated) transaction from `<incoming-txs>`. Since `<incoming-txs>` is a multi-queue, one of the internal queues is chosen nondeterministically. ([rules](../esdt.md#execute-an-incoming-transaction)) When executing internal transactions, the order between the transactions sent from the same shard is preserved.

Every transaction is executed following basically these steps:

1. Execute the transaction locally.
    * `ESDTManage`: forward to Metachain. ([rules](../esdt.md#esdt-management-functions))
    * `BuiltinCall`: 
        1. take a snapshot and execute the function. ([rules](../builtin-functions.md#execute-builtin-functions))
        1. If there is an error, revert the state using the snapshot ([rules](../esdt.md#error-handling))
1. Log the result: ([rules](../esdt.md#finalize-transaction))
1. Send internal transactions if there are any ([rules](../esdt.md#sending-output-transactions))
1. Finalize the transaction ([rules](../esdt.md#cleanup))



## Cross-shards communication

The following cases require sending out internal transactions from a shard:

1. Cross shard transfer successfully executed in the sender's shard: [rules](../transfer.md#process-destination)
1. Cross shard transaction failed in the receiver's shard: [rules](../esdt.md#error-handling)
1. Forwarding `ESDTManage` to Metachain: [rules](../esdt.md#esdt-management-functions)

If a transaction requires sending messages to another shard or to Metachain, the `<out-txs>` cell is populated during the execution. When finalizing the transaction, the content of `<out-txs>` is sent to destination shards. They will eventually be executed in main loop of destination shards.

# Transfer function

```
transfer( Sender, Recv, TokId, Amount, IsReturn )
```
ESDT transfers carry the information of sender's address (`Sender`), receiver's address (`Recv`), ID of the token sent (`TokId`), amount (`Amount`, and a boolean flag (`IsReturn`). A user-created transfer is input to the system from the `<user-txs>` cell of the sender's shard. 

Transfer is a builtin function, so it is executed following the steps described in the [Main Loop](#main-loop) section. Execution of the transfer builtin function occurs in 3 main steps ([semantics](../transfer.md#esdt-transfer)):

1. check preconditions
1. process sender
1. process destination

In the case of in-shard transfers, all these steps are executed consecutively. 

If the receiver is on another shard, the _process destination_ step is skipped. Instead, an internal transaction is sent to the destination shard. ([semantics](../transfer.md#process-destination-at-sender-shard)) When the destination shard executing the transaction, it skips the _process sender_ step after checking the preconditions. ([semantics](../transfer.md#process-sender-at-destination-shard))

# Error handling

TODO 

# Metachain

Metachain is responsible from storing token metadata such as token owners and properties, and executiong token management operations. It models the [ESDT system smart contract](https://github.com/multiversx/mx-chain-go/blob/bcca886ce2ee9eb5fec9e1dddef1143fc6f6593e/vm/systemSmartContracts/esdt.go) that lives in the Metachain.

Metachain has a similar main loop similar to shards. It consumes incoming transactions from `<meta-incoming>` and sends system-generated transactions to shards.

TODO 


# Notes on concurrency

Since there is no shared data among shards and the only communication is through message passing, we chose to execute transactions sequentially. In other words, there cannot be more than one shard executing a transaction at the same time. This mutual exclusion mechanism is implemented using the `<is-running>` cell. Its value is either `#no` or a shard ID.
