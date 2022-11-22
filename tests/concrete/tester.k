
requires "../../esdt.md"

module TESTER-SYNTAX 
    imports ESDT

    syntax Stmts ::= List{Stmt, ""}
    
    syntax Stmt ::= "#wait"
                  | addShard(ShardId)
                  | addAccount(ShardId, AccountName, Bool)
                  | addUserTx(Transaction)
                  | setBalance(AccountAddr, TokenId, Int)
                  | assert(String, Exp)                             [strict(2)]

    syntax Exp ::= Int | Bool | Set
                 | getBalance(AccountAddr, TokenId)
                 | getRoles(AccountAddr, TokenId)
                 | getFrozen(ShardId, TokenId)
                 | isPaused(ShardId, TokenId)
                 | isLimited(ShardId, TokenId)
                 | Exp "==" Exp   [seqstrict]

    syntax Value ::= Int | Bool | Set
    syntax Exp ::= Value 

    syntax KResult ::= Value
endmodule

module TESTER 
    imports ESDT
    imports TESTER-SYNTAX

    configuration 
      <k> $PGM:Stmts </k>
      <esdt/>
      <status-code exit=""> 1 </status-code>
      
    syntax AccountCell

    
    rule <k> S:Stmt SS:Stmts => S ~> SS ... </k>     [structural]
    rule <k> .Stmts => . </k>
         <status-code> _ => 0 </status-code>
    
    rule <k> #wait => . ... </k> requires #executionFinished

    syntax KItem ::= "#executionGotStuck"
    rule <k> #wait => #executionGotStuck ... </k>
         requires notBool(#executionFinished)         [owise]

    syntax Bool ::= "#executionFinished" [function]
  // ------------------------------------------  
  // is-running is false
  // no incoming txs
  // no user txs
    rule 
      [[ #executionFinished => false ]]
      <is-running> _:ShardId </is-running>

    rule 
      [[ #executionFinished => false ]]
      <user-txs> Txs </user-txs> requires notBool( isEmpty(Txs) )

    rule 
      [[ #executionFinished => false ]]
      <incoming-txs> MQ </incoming-txs> requires  notBool( isEmpty(MQ) )

    rule 
      [[ #executionFinished => false ]]
      <meta-incoming> MQ </meta-incoming> requires notBool( isEmpty(MQ) )

    rule #executionFinished => true      [owise]
    
    rule
      <k> addShard(ShrId) => . ... </k>
      <shards>
        (.Bag => <shard>
          <shard-id> ShrId </shard-id>
          <incoming-txs> .MQueue </incoming-txs>
          <user-txs> .TxList </user-txs>
          <steps> .K </steps>
          <current-tx> #nullTx </current-tx>
          <out-txs> .TxList </out-txs>
          <accounts> .Bag </accounts>
          <snapshot> #emptySnapshot </snapshot>
          <token-settings> .Bag </token-settings>
          <logs> .Logs </logs>
        </shard>)
        ...
      </shards>
      [priority(30)]


    rule 
      <k> addAccount(ShrId, ActName, IsSc) => . ... </k>
      <shard> 
        <shard-id> ShrId </shard-id>
        <accounts> (.Bag => <account>
            <account-name> ActName </account-name>
            <is-sc> IsSc </is-sc>
            <esdt-balances> .BalMap </esdt-balances>
            <esdt-roles> .SetMap </esdt-roles>
          </account>) 
          ... 
        </accounts>
        ...
      </shard>
      [priority(30)]   


    rule 
      <k> addUserTx(Tx) => . ... </k>
      <shard>
        <shard-id> ShrdId </shard-id>
        <user-txs> Txs => Txs TxL(Tx) </user-txs>
        ...
      </shard>
      requires ShrdId ==Shard #txSenderShard(Tx)
      [priority(30)]

    
    rule 
      <k> setBalance(addr(ShrId, ActName), TokId, Val) => . ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
        <accounts> 
          <account>
            <account-name> ActName </account-name>
            <esdt-balances> BALS => BALS [TokId <- Val] </esdt-balances>
            ...
          </account>
          ...
        </accounts>
        ...
      </shard>
      [priority(30)]

    
    rule 
      <k> getBalance(addr(ShrId, ActName), TokId) => #getBalance(BALS, TokId) ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
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
      [priority(30)]

    rule 
      <k> getRoles(addr(ShrId, ActName), TokId) => getSetItem(ROLES, TokId) ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
        <accounts>
          <account> 
            <account-name> ActName </account-name>
            <esdt-roles> ROLES </esdt-roles>
            ...
          </account>
          ...
        </accounts>
        ...
      </shard>
      [priority(30)]

    rule 
      <k> getFrozen(ShrId, TokId) => FROZEN ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
        <token-settings>
          <token-setting>
            <token-setting-id> TokId </token-setting-id>
            <frozen> FROZEN </frozen>
            ...
          </token-setting>
          ...
        </token-settings>
        ...
      </shard>
      [priority(30)]

    rule 
      <k> isPaused(ShrId, TokId) => P ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
        <token-settings>
          <token-setting>
            <token-setting-id> TokId </token-setting-id>
            <paused> P </paused>
            ...
          </token-setting>
          ...
        </token-settings>
        ...
      </shard>
      [priority(30)]

    rule 
      <k> isLimited(ShrId, TokId) => P ... </k>
      <shard>
        <shard-id> ShrId </shard-id>
        <token-settings>
          <token-setting>
            <token-setting-id> TokId </token-setting-id>
            <limited> P </limited>
            ...
          </token-setting>
          ...
        </token-settings>
        ...
      </shard>
      [priority(30)]

    rule <k> A:Value  == B:Value  => A ==K B ... </k>

    rule <k> assert(_, true) => . ... </k>

    syntax KItem ::= "#assertionFailed" "(" String ")"
    rule <k> assert(Msg, false) => #assertionFailed(Msg) ... </k>

endmodule