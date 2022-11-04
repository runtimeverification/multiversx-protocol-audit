
requires "../../esdt.md"



module TESTER 
     imports ESDT

    syntax EsdtCell 

    syntax K ::= "#emptyK" [macro]
    rule #emptyK => .

     configuration 
          <conf> 
            $PGM:EsdtCell //<esdt/>
          </conf>
     
     rule <logs> (_ ; _) => .Logs </logs>

endmodule