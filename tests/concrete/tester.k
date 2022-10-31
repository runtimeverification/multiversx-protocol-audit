/*
  K module for concrete testing.
  Loads the input ESDT configuration and executes transactions.
  Finally, collects all the account balances in the `<out-bals/>` cell and removes the `<esdt/>` cell
*/
requires "../../esdt.md"


module TESTER-SYNTAX 
    imports ESDT 

    syntax EsdtCell 

    syntax Conf ::= EsdtCell

    syntax K ::= "#emptyK" [macro]
    rule #emptyK => .

endmodule 


module TESTER 
     imports ESDT 
     imports TESTER-SYNTAX
     imports STRING 

     configuration 
          <k> $PGM:Conf </k>
          <conf multiplicity="?"> 
            <esdt/>
          </conf>
          <out-bals > .Map </out-bals>
     
     syntax KItem ::= "#loaded"

     rule <k> S:EsdtCell => #loaded </k>
          (.Bag => <conf> S </conf>)

     rule <shard>
            <shard-id> ShardId </shard-id>
            <accounts>
              (<account>
                <account-name> ActName </account-name>
                <esdt-balances> Bals </esdt-balances>
                ...
              </account> => .Bag)
              ...
            </accounts>
            ...
          </shard>
          <out-bals> AllBals => AllBals (accountAddr(ShardId, ActName) |-> Bals) </out-bals>  [owise]

     rule (<shard>
            <accounts> .Bag </accounts>
            ...
          </shard> => .Bag) [owise]

       rule (<conf> <esdt><shards>
              .Bag
            </shards> ... </esdt> </conf>) => .Bag  [owise]

endmodule