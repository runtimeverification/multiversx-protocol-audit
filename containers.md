
```k
requires "esdt-syntax.md"

module TXLIST
    imports ESDT-SYNTAX

    syntax TxList [hook(LIST.List)]
    
    syntax TxList ::= ".TxList"                 [function, total, hook(LIST.unit), klabel(.TxList), symbol, smtlib(smt_seq_nil), latex(\dotCt{List})]

    syntax TxList ::= TxList TxList               [left, function, total, hook(LIST.concat), klabel(_TxList_), symbol, smtlib(smt_seq_concat), assoc, unit(.TxList), element(TxL), format(%1%n%2)]

    syntax TxList ::= TxL(Transaction)             [function, total, hook(LIST.element), klabel(TxL), symbol, smtlib(smt_seq_elem)]

    syntax Bool ::= isEmpty(TxList)              [function, total]
    rule isEmpty(.TxList)         => true
    rule isEmpty(TxL(_) _:TxList) => false
endmodule

module MULTIQUEUE

    imports TXLIST
    imports BOOL


    syntax MQueue [hook(MAP.Map)]
    syntax TList ::= TxList

    syntax MQueue ::= MQueue MQueue
        [ left, function, hook(MAP.concat), klabel(_MQueue_), symbol, assoc, comm
        , unit(.MQueue), element(_M|->_), index(0), format(%1%n%2)
        ]
        
    syntax MQueue ::= ".MQueue"
        [ function, total, hook(MAP.unit), klabel(.MQueue), symbol
        , latex(\dotCt{MQueue})
        ]
    syntax MQueue ::= ShardId "M|->" TList
        [ function, total, hook(MAP.element), klabel(_M|->_), symbol
        , latex({#1}\mapsto{#2})
        ]

    syntax priorities _M|->_ > _MQueue_ .MQueue
    syntax non-assoc _M|->_

    syntax TList ::= MQueue "[" ShardId "]"                              [function, hook(MAP.lookup), klabel(MQueue:lookup), symbol]
    
    syntax TList ::= MQueue "[" ShardId "]" "orDefault" TList           [function, total, hook(MAP.lookupOrDefault), klabel(MQueue:lookupOrDefault)]
    
    syntax MQueue ::= MQueue "[" key: ShardId "<-" value: TList "]"      [function, total, klabel(MQueue:update), symbol, hook(MAP.update), prefer]
    
    syntax Set ::= keys(MQueue)                                                 [function, total, hook(MAP.keys)]
    syntax List ::= "keys_list" "(" MQueue ")"                                  [function, hook(MAP.keys_list)]
    syntax Bool ::= ShardId "in_keys" "(" MQueue ")"                            [function, total, hook(MAP.in_keys)]


    syntax MQueue ::= push(MQueue, ShardId, Transaction)                        [function, total]
    rule push(MQ, Shr, Tx)    => MQ (Shr M|-> TxL(Tx) )            requires notBool( Shr in_keys(MQ))   // >
    rule push(MQ, Shr, Tx)    => MQ [Shr <- {MQ[Shr]}:>TxList TxL(Tx)  ]   requires Shr in_keys(MQ)             // >


    syntax Bool ::= isEmpty(MQueue)                           [function, total]
    rule isEmpty(.MQueue)                 => true
    rule isEmpty((_:ShardId M|-> Txs ) MQ) => isEmpty(MQ) requires isEmpty(Txs)
    rule isEmpty((_:ShardId M|-> Txs ) _)  => false       requires notBool( isEmpty(Txs) )

endmodule

module BALANCEMAP

    imports ESDT-SYNTAX
    imports BOOL
    imports INT

    syntax BalMap [hook(MAP.Map)]
    syntax Integer ::= Int

    syntax BalMap ::= BalMap BalMap
        [ left, function, hook(MAP.concat), klabel(_BalMap_), symbol, assoc, comm
        , unit(.BalMap), element(_B|->_), index(0), format(%1%n%2)
        ]
        
    syntax BalMap ::= ".BalMap"
        [ function, total, hook(MAP.unit), klabel(.BalMap), symbol
        , latex(\dotCt{BalMap})
        ]
    syntax BalMap ::= TokenId "B|->" Integer
        [ function, total, hook(MAP.element), klabel(_B|->_), symbol
        , latex({#1}\mapsto{#2})
        ]

    syntax priorities _B|->_ > _BalMap_ .BalMap
    syntax non-assoc _B|->_

    syntax Integer ::= BalMap "[" TokenId "]"                              [function, hook(MAP.lookup), klabel(BalMap:lookup), symbol]
    
    syntax Integer ::= BalMap "[" TokenId "]" "orDefault" Integer              [function, total, hook(MAP.lookupOrDefault), klabel(BalMap:lookupOrDefault)]
    
    syntax BalMap ::= BalMap "[" key: TokenId "<-" value: Integer "]"      [function, total, klabel(BalMap:update), symbol, hook(MAP.update), prefer]
    
    syntax Bool ::= TokenId "in_keys" "(" BalMap ")"                            [function, total, hook(MAP.in_keys)]

    syntax BalMap ::= #addToBalance( BalMap , TokenId , Int )                           [function, total]
    rule #addToBalance(Bs, TokId, Val) => Bs [TokId <- #getBalance(Bs, TokId) +Int Val] 
    
    syntax Int ::= #getBalance(BalMap, TokenId)    [function, total]
    rule #getBalance(M, A) => {M [ A ] orDefault 0}:>Int

endmodule

module TOKENPROPS
    imports ESDT-SYNTAX
    imports BOOL

    syntax Boolean ::= Bool

    syntax PropMap [hook(MAP.Map)]

    syntax PropMap ::= PropMap PropMap
        [ left, function, hook(MAP.concat), klabel(_PropMap_), symbol, assoc, comm
        , unit(.PropMap), element(_P|->_), index(0), format(%1%n%2)
        ]
        
    syntax PropMap ::= ".PropMap"
        [ function, total, hook(MAP.unit), klabel(.PropMap), symbol
        , latex(\dotCt{PropMap})
        ]
    syntax PropMap ::= PropertyName "P|->" Boolean
        [ function, total, hook(MAP.element), klabel(_P|->_), symbol
        , latex({#1}\mapsto{#2})
        ]

    syntax priorities _P|->_ > _PropMap_ .PropMap
    syntax non-assoc _P|->_

    syntax Boolean ::= PropMap "[" PropertyName "]"                              [function, hook(MAP.lookup), klabel(PropMap:lookup), symbol]
    
    syntax Boolean ::= PropMap "[" PropertyName "]" "orDefault" Boolean              [function, total, hook(MAP.lookupOrDefault), klabel(PropMap:lookupOrDefault)]
    
    syntax PropMap ::= PropMap "[" key: PropertyName "<-" value: Boolean "]"     [function, total, klabel(PropMap:update), symbol, hook(MAP.update), prefer]
    
    syntax Bool ::= PropertyName "in_keys" "(" PropMap ")"                                  [function, total, hook(MAP.in_keys)]

    syntax Bool ::= hasProp(PropMap, PropertyName)    [function, total]
    rule hasProp(M, A) => {M [ A ] orDefault false}:>Bool

    syntax PropMap ::= "#makeProperties" "(" Properties ")" [function, total]
    rule #makeProperties( )      => #defaultTokenProps
    rule #makeProperties({ Ps }) => #updatePropsH(#defaultTokenProps, Ps)
    
    syntax PropMap ::= "#defaultTokenProps" [macro]
    rule #defaultTokenProps => ( canFreeze          P|-> false 
                                 canWipe            P|-> false 
                                 canPause           P|-> false 
                                 canChangeOwner     P|-> false 
                                 canUpgrade         P|-> true 
                                 canAddSpecialRoles P|-> true)

    syntax PropMap ::= #updateProps(PropMap, Properties)        [function, total]
                     | #updatePropsH(PropMap, PropertyList)     [function, total]
    rule #updateProps(PMap, ) => PMap
    rule #updateProps(PMap, { Ps:PropertyList }) => #updatePropsH(PMap, Ps)
    rule #updatePropsH(PMap, .PropertyList) => PMap
    rule #updatePropsH(PMap, (P:V, Ps)) => #updatePropsH(PMap [P <- V], Ps)
     
    // >
endmodule

module SETMAP
    imports SET
    imports BOOL

    syntax MSet ::= Set

    syntax SetMap [hook(MAP.Map)]

    syntax SetMap ::= SetMap SetMap
        [ left, function, hook(MAP.concat), klabel(_SetMap_), symbol, assoc, comm
        , unit(.SetMap), element(_S|->_), index(0), format(%1%n%2)
        ]
        
    syntax SetMap ::= ".SetMap"
        [ function, total, hook(MAP.unit), klabel(.SetMap), symbol
        , latex(\dotCt{SetMap})
        ]
    syntax SetMap ::= KItem "S|->" MSet
        [ function, total, hook(MAP.element), klabel(_S|->_), symbol
        , latex({#1}\mapsto{#2})
        ]

    syntax priorities _S|->_ > _SetMap_ .SetMap
    syntax non-assoc _S|->_

    syntax MSet ::= SetMap "[" KItem "]"                              [function, hook(MAP.lookup), klabel(SetMap:lookup), symbol]
    
    syntax MSet ::= SetMap "[" KItem "]" "orDefault" MSet              [function, total, hook(MAP.lookupOrDefault), klabel(SetMap:lookupOrDefault)]
    
    syntax SetMap ::= SetMap "[" key: KItem "<-" value: MSet "]"     [function, total, klabel(SetMap:update), symbol, hook(MAP.update), prefer]
    
    syntax Bool ::= KItem "in_keys" "(" SetMap ")"                                  [function, total, hook(MAP.in_keys)]

    
    syntax Set ::= getSetItem(SetMap, KItem)     [function, total]
    rule getSetItem(M, X) => {M [X] orDefault .Set}:>Set

endmodule

module CONTAINERS
    imports TXLIST
    imports MULTIQUEUE
    imports BALANCEMAP
    imports TOKENPROPS
    imports SETMAP
endmodule
```








