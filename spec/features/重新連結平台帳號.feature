# 來源：spec 第 8 節（平台授權到期後由管理員手動重新連結）、需求 4.2、BR-09、BR-17、BR-20
Feature: 重新連結平台帳號
  管理員更新既有平台帳號的存取憑證與授權到期時間，使授權狀態恢復為有效。
  Threads、Instagram 透過平台授權流程取得新的存取憑證與授權到期時間。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |
    And 系統中有以下平台帳號：
      | platform  | account_name       | platform_user_id | auth_status | auth_expires_at  | linked_by         |
      | Threads   | ntu_guitar_threads | th-1001          | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Instagram | ntu_guitar_ig      | ig-2001          | 有效        | 2026-10-01 00:00 | president@club.tw |
    And 現在時間為 "2026-10-05 10:00"
    And 平台 "Instagram" 授權完成後回傳以下資訊：
      | platform_user_id | account_name  | credential   | auth_expires_at  |
      | ig-2001          | ntu_guitar_ig | ig-token-new | 2026-12-31 00:00 |

  Rule: 前置：只有管理員可以重新連結平台帳號

    Example: 發佈者重新連結平台帳號
      When "pr@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗

    Example: 撰稿者重新連結平台帳號
      When "newbie@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗

  Rule: 前置：停用的帳號無法重新連結平台帳號

    Example: 停用的管理員重新連結平台帳號
      When "retired@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗

  Rule: 前置：Threads、Instagram 的平台授權必須成功；失敗時保留原有資料

    Example: Instagram 重新授權失敗
      Given 平台 "Instagram" 授權失敗
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status | auth_expires_at  |
        | ntu_guitar_ig | 有效        | 2026-10-01 00:00 |

  Rule: 前置：Discord 新的 Webhook 網址須經 Discord 驗證存在且可使用；失敗時保留原有資料

    Example: 新 Webhook 網址驗證無效
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And Discord Webhook "https://discord.test/api/webhooks/2" 的驗證結果為無效
      When "president@club.tw" 以 Webhook 網址 "https://discord.test/api/webhooks/2" 重新連結 Discord 頻道 "公告"
      Then 操作失敗
      And 平台帳號 "公告" 的資料為：
        | account_name | auth_status | linked_by         |
        | 公告         | 有效        | president@club.tw |

    Example: 新 Webhook 網址驗證成功
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And Discord Webhook "https://discord.test/api/webhooks/2" 的驗證結果為有效
      When "president@club.tw" 以 Webhook 網址 "https://discord.test/api/webhooks/2" 重新連結 Discord 頻道 "公告"
      Then 操作成功

  Rule: 前置：因網路或 Discord 暫時性錯誤無法完成驗證時，操作失敗，保留原有資料
    # 回報「暫時無法驗證」，不判定 Webhook 無效

    Example: Discord 暫時無法回應驗證請求
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And Discord Webhook "https://discord.test/api/webhooks/2" 的驗證結果為暫時無法驗證
      When "president@club.tw" 以 Webhook 網址 "https://discord.test/api/webhooks/2" 重新連結 Discord 頻道 "公告"
      Then 操作失敗
      And 平台帳號 "公告" 的資料為：
        | account_name | auth_status | linked_by         |
        | 公告         | 有效        | president@club.tw |

  Rule: 前置：平台回傳的平台帳號識別碼必須與原平台帳號相同；不同時操作失敗，原有資料不變
    # 以平台提供的穩定唯一識別碼比對，不只比較帳號名稱；提示「授權的帳號與原平台帳號不一致，請切換至正確的帳號後重新操作。」
    # 要新增另一個帳號應使用「連結平台帳號」

    Example: 管理員登入成另一個 Instagram 帳號
      Given 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name | credential     | auth_expires_at  |
        | ig-9999          | other_ig     | other-ig-token | 2026-12-31 00:00 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | platform  | account_name  | platform_user_id | auth_status | auth_expires_at  |
        | Instagram | ntu_guitar_ig | ig-2001          | 失效        | 2026-10-01 00:00 |

  Rule: 前置：識別碼相同但平台回傳的新帳號名稱與同平台其他未移除的平台帳號重複時，操作失敗，原有資料不變
    # 提示使用者帳號名稱與其他已連結的平台帳號重複

    Example: 新名稱與另一個已連結的 Instagram 帳號相同
      Given 系統中有以下平台帳號：
        | platform  | account_name | platform_user_id | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar   | ig-3001          | 有效        | 2026-12-31 00:00 | president@club.tw |
      And 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name | credential   | auth_expires_at  |
        | ig-2001          | ntu_guitar   | ig-token-new | 2026-12-31 00:00 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | platform  | account_name  | platform_user_id | auth_status | auth_expires_at  |
        | Instagram | ntu_guitar_ig | ig-2001          | 失效        | 2026-10-01 00:00 |

  Rule: 後置：平台帳號的授權到期時間更新為新的到期時間

    Example: 重新連結已到期的 Instagram 帳號
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | platform  | account_name  | auth_expires_at  |
        | Instagram | ntu_guitar_ig | 2026-12-31 00:00 |

  Rule: 後置：平台帳號的授權狀態改回有效

    Example: 已到期的 Instagram 帳號重新連結後為有效
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 有效        |

  Rule: 後置：平台授權未回傳明確的到期時間時，授權到期時間為空（未知）

    Example: Instagram 重新授權未回傳到期時間
      Given 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name  | credential   | auth_expires_at |
        | ig-2001          | ntu_guitar_ig | ig-token-new |                 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status | auth_expires_at |
        | ntu_guitar_ig | 有效        |                 |

  Rule: 後置：存取憑證更新為新的存取憑證，並加密保存
    #TODO

  Rule: 後置：原本選擇此平台帳號為目標的貼文，目標平台帳號維持不變

    Example: 草稿仍以重新連結後的 Instagram 帳號為目標
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P1 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P1" 已附加以下圖片：
        | format | size_mb | width | height | url                           |
        | JPEG   | 3       | 1080  | 1350   | https://media.test/poster.jpg |
      And 貼文 "P1" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | ntu_guitar_ig      |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 貼文 "P1" 的目標平台帳號為：
        | platform  | account_name       |
        | Threads   | ntu_guitar_threads |
        | Instagram | ntu_guitar_ig      |

  Rule: 後置：此平台帳號既有的發佈紀錄維持不變

    Example: 重新連結不改變先前的發佈紀錄
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P2 | pr@club.tw | 期中成發 | PARTIALLY_FAILED |              |
      And 貼文 "P2" 已有以下發佈紀錄：
        | account_name       | status | published_at     | post_url                 | failure_reason |
        | ntu_guitar_threads | 成功   | 2026-10-02 12:00 | https://threads.test/p/2 |                |
        | ntu_guitar_ig      | 失敗   |                  |                          | 帳號授權過期   |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 貼文 "P2" 的發佈紀錄為：
        | account_name       | status | post_url                 | failure_reason |
        | ntu_guitar_threads | 成功   | https://threads.test/p/2 |                |
        | ntu_guitar_ig      | 失敗   |                          | 帳號授權過期   |

  Rule: 後置：連結者維持原本的連結者，重新連結的管理員記錄於稽核紀錄

    Example: 副社長重新連結社長連結的 Instagram 帳號
      Given 系統中有以下使用者帳號：
        | email      | name   | role   | status |
        | vp@club.tw | 副社長 | 管理員 | 啟用   |
      When "vp@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | linked_by         |
        | ntu_guitar_ig | president@club.tw |
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action           | target_type | target        |
        | 使用者     | vp@club.tw | 重新連結平台帳號 | 平台帳號    | ntu_guitar_ig |

  Rule: 後置：重新連結成功時寫入一筆「重新連結平台帳號」稽核紀錄

    Example: 重新連結後新增稽核紀錄
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action           | target_type | target        |
        | president@club.tw | 重新連結平台帳號 | 平台帳號    | ntu_guitar_ig |

  Rule: 後置：重新連結失敗時，新增一筆平台授權事件，記錄失敗原因、平台帳號與執行者

    Example: Instagram 平台授權失敗
      Given 平台 "Instagram" 授權失敗
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 系統新增一筆平台授權事件：
        | event_type           | failure_reason | account_name  | actor             |
        | 重新連結平台帳號失敗 | 平台授權失敗   | ntu_guitar_ig | president@club.tw |

    Example: 授權的帳號識別碼不一致
      Given 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name | credential     | auth_expires_at  |
        | ig-9999          | other_ig     | other-ig-token | 2026-12-31 00:00 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 系統新增一筆平台授權事件：
        | event_type           | failure_reason         | account_name  | actor             |
        | 重新連結平台帳號失敗 | 平台帳號識別碼不一致   | ntu_guitar_ig | president@club.tw |

    Example: Discord Webhook 驗證無效
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And Discord Webhook "https://discord.test/api/webhooks/2" 的驗證結果為無效
      When "president@club.tw" 以 Webhook 網址 "https://discord.test/api/webhooks/2" 重新連結 Discord 頻道 "公告"
      Then 操作失敗
      And 系統新增一筆平台授權事件：
        | event_type           | failure_reason   | account_name | actor             |
        | 重新連結平台帳號失敗 | Webhook 驗證無效 | 公告         | president@club.tw |

  Rule: 後置：平台授權事件不保存存取憑證或 Webhook 網址

    Example: Webhook 驗證無效時，事件中不含 Webhook 網址
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And Discord Webhook "https://discord.test/api/webhooks/2" 的驗證結果為無效
      When "president@club.tw" 以 Webhook 網址 "https://discord.test/api/webhooks/2" 重新連結 Discord 頻道 "公告"
      Then 操作失敗
      And 該筆平台授權事件不包含 "https://discord.test/api/webhooks/2"

  Rule: 後置：識別碼相同時，帳號名稱更新為平台回傳的名稱

    Example: 平台上的帳號名稱已由 ntu_guitar_ig 改為 ntu_guitar_ig_v2
      Given 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name     | credential   | auth_expires_at  |
        | ig-2001          | ntu_guitar_ig_v2 | ig-token-new | 2026-12-31 00:00 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig_v2" 的資料為：
        | platform  | account_name     | platform_user_id | auth_status | auth_expires_at  |
        | Instagram | ntu_guitar_ig_v2 | ig-2001          | 有效        | 2026-12-31 00:00 |

  Rule: 後置：因新帳號名稱與其他已連結帳號重複而失敗時，不記錄平台授權事件
    # 屬資料衝突而非授權問題；未來若需追蹤，可記錄於一般稽核紀錄

    Example: 新名稱與另一個已連結的 Instagram 帳號相同
      Given 系統中有以下平台帳號：
        | platform  | account_name | platform_user_id | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar   | ig-3001          | 有效        | 2026-12-31 00:00 | president@club.tw |
      And 平台 "Instagram" 授權完成後回傳以下資訊：
        | platform_user_id | account_name | credential   | auth_expires_at  |
        | ig-2001          | ntu_guitar   | ig-token-new | 2026-12-31 00:00 |
      When "president@club.tw" 透過平台授權重新連結平台帳號 "ntu_guitar_ig"
      Then 操作失敗
      And 系統沒有新增平台授權事件
