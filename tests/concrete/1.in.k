<esdt>
  <is-running> #no </is-running>
  <meta>
    <meta-steps>
      #emptyK
    </meta-steps>
    <meta-incoming>
      .MQueue
    </meta-incoming>
    <meta-out-txs>
      .TxList
    </meta-out-txs>
    <global-token-settings> .GlobalTokenSettingCellMap
    </global-token-settings>
  </meta>
  <shards>
    <shard>
      <shard-id>
        1
      </shard-id>
      <incoming-txs>
        .MQueue
      </incoming-txs>
      <user-txs>
        TxL(transfer(accountAddr(1 , "A1" ), accountAddr(1, "A2"), 1 , 10, false))
        TxL(transfer(accountAddr(1 , "A2" ), accountAddr(1, "A1"), 1 , 10, false))
        TxL(transfer(accountAddr(1 , "A1" ), accountAddr(1, "A2"), 2 , 20, false))
      </user-txs>
      <steps>
        #emptyK
      </steps>
      <current-tx>
        #nullTx
      </current-tx>
      <out-txs>
        .TxList
      </out-txs>
      <accounts>
        <account>
          <account-name>
            "A1"
          </account-name>
          <is-sc> false </is-sc>
          <esdt-balances>
            1 B|-> 100
            2 B|-> 120
          </esdt-balances>
        </account> <account>
          <account-name>
            "A2"
          </account-name>
          <is-sc> false </is-sc>
          <esdt-balances> 
            1 B|-> 10 
          </esdt-balances>
        </account>
      </accounts>
      <snapshot>
        #emptySnapshot
      </snapshot>
      <token-settings> .TokenSettingCellMap
      </token-settings>
      <logs>
        .Logs
      </logs>
    </shard>
  </shards>
</esdt>
