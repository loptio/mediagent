# 來源：FR-06、需求 4.2、情境一、BR-17、BR-20、NFR-02、需求 4.5
Feature: 連結平台帳號
  管理員連結社團在 Threads、Instagram、Discord 的平台帳號。
  Threads、Instagram 透過平台授權流程連結，帳號名稱、存取憑證與授權到期時間以平台回傳為準；
  Discord 由管理員貼上 Webhook 網址與頻道名稱。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |
    And 平台 "Threads" 授權完成後回傳以下資訊：
      | platform_user_id | account_name       | credential    | auth_expires_at  |
      | th-1001          | ntu_guitar_threads | threads-token | 2026-12-31 00:00 |
    And 平台 "Instagram" 授權完成後回傳以下資訊：
      | platform_user_id | account_name  | credential | auth_expires_at  |
      | ig-2001          | ntu_guitar_ig | ig-token   | 2026-12-31 00:00 |
    And Discord Webhook "https://discord.test/api/webhooks/1" 的驗證結果為有效

  Rule: 前置：只有管理員可以連結平台帳號

    Example: 發佈者連結平台帳號
      When "pr@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作失敗

    Example: 撰稿者連結平台帳號
      When "newbie@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作失敗

    Example: 發佈者連結 Discord 頻道
      When "pr@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作失敗

  Rule: 前置：停用的帳號無法連結平台帳號

    Example: 停用的管理員連結平台帳號
      When "retired@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作失敗

  Rule: 前置：平台必須為 Threads、Instagram、Discord 三者之一

    Example: 連結 Threads、Instagram、Discord
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作成功
      When "president@club.tw" 透過平台授權連結 "Instagram" 平台帳號
      Then 操作成功
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作成功

    Example: 連結 MVP 範圍外的平台
      When "president@club.tw" 透過平台授權連結 "X" 平台帳號
      Then 操作失敗

  Rule: 前置：未移除的平台帳號中，相同平台與帳號名稱不可重複連結

    Example: 重複連結已連結的 Instagram 帳號
      Given 系統中有以下平台帳號：
        | platform  | account_name  | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_ig | 有效        | 2026-12-31 00:00 | president@club.tw |
      When "president@club.tw" 透過平台授權連結 "Instagram" 平台帳號
      Then 操作失敗

    Example: 不同平台使用相同帳號名稱
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作成功

  Rule: 前置：Threads、Instagram 的平台授權必須成功

    Example: Threads 平台授權失敗
      Given 平台 "Threads" 授權失敗
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作失敗
      And 系統中沒有帳號名稱為 "ntu_guitar_threads" 的平台帳號

  Rule: 前置：Discord Webhook 網址須經 Discord 驗證存在且可使用

    Example: Webhook 網址驗證無效
      Given Discord Webhook "https://discord.test/api/webhooks/1" 的驗證結果為無效
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作失敗
      And 系統中沒有帳號名稱為 "公告" 的平台帳號

    Example: Webhook 網址驗證成功
      Given Discord Webhook "https://discord.test/api/webhooks/1" 的驗證結果為有效
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作成功

  Rule: 前置：因網路或 Discord 暫時性錯誤無法完成驗證時，操作失敗，不建立平台帳號
    # 回報「暫時無法驗證」，不判定 Webhook 無效

    Example: Discord 暫時無法回應驗證請求
      Given Discord Webhook "https://discord.test/api/webhooks/1" 的驗證結果為暫時無法驗證
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作失敗
      And 系統中沒有帳號名稱為 "公告" 的平台帳號

  Rule: 後置：Threads、Instagram 的帳號名稱與授權到期時間以平台授權回傳的資訊記錄，並記錄連結者

    Example: 連結 Instagram 帳號
      When "president@club.tw" 透過平台授權連結 "Instagram" 平台帳號
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | platform  | account_name  | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_ig | 有效        | 2026-12-31 00:00 | president@club.tw |

  Rule: 後置：平台授權未回傳明確的到期時間時，授權到期時間為空（未知），不由管理員填寫

    Example: Threads 授權未回傳到期時間
      Given 平台 "Threads" 授權完成後回傳以下資訊：
        | platform_user_id | account_name       | credential    | auth_expires_at |
        | th-1001          | ntu_guitar_threads | threads-token |                 |
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | platform | account_name       | auth_status | auth_expires_at |
        | Threads  | ntu_guitar_threads | 有效        |                 |

  Rule: 後置：Discord 平台帳號記錄管理員輸入的頻道名稱，授權到期時間為空（不適用）

    Example: 連結 Discord 頻道
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/1 |
      Then 操作成功
      And 平台帳號 "公告" 的資料為：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |

  Rule: 後置：已移除的平台帳號以相同平台與帳號名稱再連結時，新增一筆新的平台帳號，舊的一筆保留

    Example: 重新連結先前移除的 Instagram 帳號
      Given 系統中有以下平台帳號：
        | platform  | account_name  | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_ig | 有效        | 2026-10-31 00:00 | president@club.tw |
      And 平台帳號 "ntu_guitar_ig" 已被移除
      When "president@club.tw" 透過平台授權連結 "Instagram" 平台帳號
      Then 操作成功
      And 系統中帳號名稱為 "ntu_guitar_ig" 的平台帳號為：
        | platform  | account_name  | auth_expires_at  | removed |
        | Instagram | ntu_guitar_ig | 2026-10-31 00:00 | true    |
        | Instagram | ntu_guitar_ig | 2026-12-31 00:00 | false   |

  Rule: 後置：存取憑證加密保存
    #TODO

  Rule: 後置：寫入一筆「連結平台帳號」稽核紀錄

    Example: 連結平台帳號後新增稽核紀錄
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action       | target_type | target             |
        | president@club.tw | 連結平台帳號 | 平台帳號    | ntu_guitar_threads |

  Rule: 後置：連結失敗時新增一筆「連結平台帳號失敗」平台授權事件，記錄操作者、時間、平台、已取得的帳號名稱與失敗原因

    Example: Threads 平台授權失敗，尚未取得帳號名稱
      Given 現在時間為 "2026-10-05 10:00"
      And 平台 "Threads" 授權失敗
      When "president@club.tw" 透過平台授權連結 "Threads" 平台帳號
      Then 操作失敗
      And 系統新增一筆平台授權事件：
        | event_type       | platform | account_name | failure_reason | actor             | occurred_at      |
        | 連結平台帳號失敗 | Threads  |              | 平台授權失敗   | president@club.tw | 2026-10-05 10:00 |

    Example: Discord Webhook 驗證無效，記錄輸入的頻道名稱
      Given 現在時間為 "2026-10-05 10:00"
      And Discord Webhook "https://discord.test/api/webhooks/9" 的驗證結果為無效
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/9 |
      Then 操作失敗
      And 系統新增一筆平台授權事件：
        | event_type       | platform | account_name | failure_reason   | actor             | occurred_at      |
        | 連結平台帳號失敗 | Discord  | 公告         | Webhook 驗證無效 | president@club.tw | 2026-10-05 10:00 |

  Rule: 後置：連結失敗的平台授權事件不保存存取憑證或 Webhook 網址

    Example: Webhook 驗證無效時，事件中不含 Webhook 網址
      Given Discord Webhook "https://discord.test/api/webhooks/9" 的驗證結果為無效
      When "president@club.tw" 連結以下 Discord 頻道：
        | account_name | credential                          |
        | 公告         | https://discord.test/api/webhooks/9 |
      Then 操作失敗
      And 該筆平台授權事件不包含 "https://discord.test/api/webhooks/9"
