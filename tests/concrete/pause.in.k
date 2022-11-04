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
    <global-token-settings>
      <global-token-setting>
        <global-token-id>     1 </global-token-id>
        <global-token-paused> false </global-token-paused>
        <global-token-owner>  accountAddr(1 , "A1" ) </global-token-owner>
        <global-token-props>  canFreeze          P|-> false 
                              canWipe            P|-> false 
                              canPause           P|-> true 
                              canChangeOwner     P|-> false 
                              canUpgrade         P|-> true 
                              canAddSpecialRoles P|-> true </global-token-props>
      </global-token-setting>
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
        TxL(pause(accountAddr(1 , "A1" ), 1, true))
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
          <esdt-balances> .BalMap </esdt-balances>
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
    </shard> <shard>
      <shard-id>
        2
      </shard-id>
      <incoming-txs>
        .MQueue
      </incoming-txs>
      <user-txs>
        .TxList
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
      <accounts> .AccountCellMap </accounts>
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