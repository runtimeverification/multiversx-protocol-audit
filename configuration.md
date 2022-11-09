
```k
requires "esdt-syntax.md"
requires "errors.md"

module CONFIGURATION
    imports ESDT-SYNTAX
    imports COLLECTIONS
    imports CONTAINERS
    imports ERRORS

    configuration
      <esdt>
        <is-running> #no:Running </is-running>
        <meta>
          <meta-steps> .K </meta-steps>
          <meta-incoming> .MQueue </meta-incoming>
          <meta-out-txs> .TxList </meta-out-txs>
          <global-token-settings> 
            <global-token-setting multiplicity="*" type="Map">
              <global-token-id>     0:TokenId </global-token-id>
              <global-token-paused> false </global-token-paused>
              <global-token-owner>  #systemAct </global-token-owner>
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

    syntax Running ::= "#no"
                     | ShardId

    syntax Transaction ::= "#nullTx"

    syntax AccountAddr ::= "#systemAct" [macro]
    rule #systemAct => accountAddr(#metachainShardId, "system")
    
    syntax Snapshot ::= "#emptySnapshot"
                      | AccountsCell

    syntax Logs ::= ".Logs"
                  | Logs ";" Log
    syntax Log ::= TxStep | Transaction

    syntax TxStep ::= "#success"
                    | #failure( Error )
                    | "#finalizeTransaction"

endmodule
```