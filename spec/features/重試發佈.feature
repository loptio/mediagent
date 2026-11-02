# 來源：FR-18、BR-12、BR-15、BR-16、BR-17、BR-18、BR-20、需求 4.5、例外情境
Feature: 重試發佈
  發佈者與管理員重試某則貼文中發佈失敗的平台帳號。
  流程與立即發佈相同：受理後立即回應，在背景發佈並逐筆更新，全部結束後更新貼文最終狀態。
  除「受理後」相關 Rule 外，其餘 Example 的 Then 皆驗證背景發佈全部結束後的結果。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 系統中有以下平台帳號：
      | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
      | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord   | 公告               | 有效        |                  | president@club.tw |
    And 現在時間為 "2026-10-06 12:30"
    And 系統中有以下貼文：
      | id | creator        | content  | status           | scheduled_at |
      | P1 | newbie@club.tw | 社課公告 | PARTIALLY_FAILED |              |
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                           |
      | JPEG   | 3       | 1080  | 1920   | https://media.test/poster.jpg |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | ntu_guitar_ig      |
      | 公告               |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name       | status | published_at     | post_url                 | failure_reason   |
      | ntu_guitar_threads | 成功   | 2026-10-06 12:05 | https://threads.test/p/1 |                  |
      | ntu_guitar_ig      | 失敗   |                  |                          | 平台暫時無法連線 |
      | 公告               | 成功   | 2026-10-06 12:05 | https://discord.test/m/1 |                  |
    And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/9"
    And 平台帳號 "ntu_guitar_ig" 的發佈結果為成功，平台貼文連結為 "https://instagram.test/p/1"
    And 平台帳號 "公告" 的發佈結果為成功，平台貼文連結為 "https://discord.test/m/9"

  Rule: 前置：撰稿者不能重試發佈

    Example: 撰稿者重試自己的貼文
      When "newbie@club.tw" 重試發佈貼文 "P1"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 前置：管理員與發佈者可以重試發佈

    Example: 發佈者重試發佈
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功

    Example: 管理員重試發佈
      When "president@club.tw" 重試發佈貼文 "P1"
      Then 操作成功

  Rule: 前置：停用的帳號無法重試發佈

    Example: 停用的發佈者重試發佈
      When "retired@club.tw" 重試發佈貼文 "P1"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 前置：只有部分失敗與全部失敗狀態的貼文可以重試

    Example: 重試全部失敗的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 器材借用 | FAILED |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P2" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason   |
        | 公告         | 失敗   |              |          | 平台暫時無法連線 |
      When "pr@club.tw" 重試發佈貼文 "P2"
      Then 操作成功

    Example: 重試非部分失敗、非全部失敗的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status     | scheduled_at     |
        | P3 | pr@club.tw | 草稿     | DRAFT      |                  |
        | P4 | pr@club.tw | 已排程   | SCHEDULED  | 2026-10-07 12:00 |
        | P5 | pr@club.tw | 發佈中   | PUBLISHING |                  |
        | P6 | pr@club.tw | 已發佈   | PUBLISHED  |                  |
      When "pr@club.tw" 重試發佈貼文 "P3"
      Then 操作失敗
      When "pr@club.tw" 重試發佈貼文 "P4"
      Then 操作失敗
      When "pr@club.tw" 重試發佈貼文 "P5"
      Then 操作失敗
      When "pr@club.tw" 重試發佈貼文 "P6"
      Then 操作失敗

  Rule: 前置：失敗原因為「發佈逾時」的平台帳號可以重試
    # 重試前提醒使用者先到該平台確認貼文是否已發出，避免重複貼文

    Example: 重試發佈逾時的 Instagram
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P5 | pr@club.tw | 社課公告 | PARTIALLY_FAILED |              |
      And 貼文 "P5" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p5.jpg |
      And 貼文 "P5" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
        | 公告          |
      And 貼文 "P5" 已有以下發佈紀錄：
        | account_name  | status | published_at     | post_url                 | failure_reason |
        | ntu_guitar_ig | 失敗   |                  |                          | 發佈逾時       |
        | 公告          | 成功   | 2026-10-06 12:05 | https://discord.test/m/1 |                |
      When "pr@club.tw" 重試發佈貼文 "P5"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 收到 1 則貼文
      And 貼文 "P5" 的發佈紀錄包含：
        | account_name  | status | post_url                   |
        | ntu_guitar_ig | 成功   | https://instagram.test/p/1 |

  Rule: 前置：至少要有一筆發佈失敗、且平台帳號未被移除並授權有效的發佈紀錄，才受理重試
    # 拒絕時提示：授權失效的平台帳號請先重新連結；已移除的平台帳號可使用「複製為新草稿」重新選擇目標

    Example: 失敗的平台帳號一個授權到期、一個已被移除
      Given 系統中有以下平台帳號：
        | platform  | account_name | auth_status | auth_expires_at  | linked_by         |
        | Instagram | expired_ig   | 有效        | 2026-10-06 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P6 | pr@club.tw | 社課公告 | FAILED |              |
      And 貼文 "P6" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p6.jpg |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | expired_ig   |
        | 公告         |
      And 貼文 "P6" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason   |
        | expired_ig   | 失敗   |              |          | 帳號授權過期     |
        | 公告         | 失敗   |              |          | 平台暫時無法連線 |
      And 平台帳號 "公告" 已被移除
      When "pr@club.tw" 重試發佈貼文 "P6"
      Then 操作失敗
      And 貼文 "P6" 的狀態為 "FAILED"
      And 平台帳號 "expired_ig" 收到 0 則貼文
      And 平台帳號 "公告" 收到 0 則貼文
      And 系統沒有新增稽核紀錄

  Rule: 前置：授權失效的失敗平台帳號不重試，其發佈紀錄維持不變
    # 跳過時提示使用者先重新連結該平台帳號

    Example: Instagram 授權已到期被跳過，Threads 照常重試
      Given 系統中有以下平台帳號：
        | platform  | account_name | auth_status | auth_expires_at  | linked_by         |
        | Instagram | expired_ig   | 有效        | 2026-10-06 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P3 | pr@club.tw | 社課公告 | FAILED |              |
      And 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | expired_ig         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason   |
        | ntu_guitar_threads | 失敗   |              |          | 平台暫時無法連線 |
        | expired_ig         | 失敗   |              |          | 帳號授權過期     |
      When "pr@club.tw" 重試發佈貼文 "P3"
      Then 操作成功
      And 平台帳號 "expired_ig" 收到 0 則貼文
      And 貼文 "P3" 的發佈紀錄為：
        | account_name       | status | post_url                 | failure_reason |
        | ntu_guitar_threads | 成功   | https://threads.test/p/9 |                |
        | expired_ig         | 失敗   |                          | 帳號授權過期   |
      And 貼文 "P3" 的狀態為 "PARTIALLY_FAILED"

  Rule: 前置：已移除的失敗平台帳號不重試，其發佈紀錄維持不變

    Example: Discord 頻道已被移除而跳過，Threads 照常重試
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P4 | pr@club.tw | 社課公告 | FAILED |              |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason   |
        | ntu_guitar_threads | 失敗   |              |          | 平台暫時無法連線 |
        | 公告               | 失敗   |              |          | 平台暫時無法連線 |
      And 平台帳號 "公告" 已被移除
      When "pr@club.tw" 重試發佈貼文 "P4"
      Then 操作成功
      And 平台帳號 "公告" 收到 0 則貼文
      And 貼文 "P4" 的發佈紀錄為：
        | account_name       | status | post_url                 | failure_reason   |
        | ntu_guitar_threads | 成功   | https://threads.test/p/9 |                  |
        | 公告               | 失敗   |                          | 平台暫時無法連線 |

  Rule: 後置：受理後貼文狀態立即改為發佈中，重試的發佈紀錄改為待發佈

    Example: Instagram 重試尚未完成
      Given 平台帳號 "ntu_guitar_ig" 的發佈尚未完成
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PUBLISHING"
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
        | ntu_guitar_ig      | 待發佈 |                          |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：只重新發佈到發佈失敗的平台帳號

    Example: 只重新發佈到 Instagram
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 收到 1 則貼文

  Rule: 後置：已成功的平台帳號不得重複發佈

    Example: Threads 與 Discord 不會出現重複貼文
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 平台帳號 "公告" 收到 0 則貼文
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：重試成功的平台帳號發佈紀錄更新為成功，並記錄發佈時間與平台貼文連結

    Example: Instagram 重試成功
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name  | status | published_at     | post_url                   |
        | ntu_guitar_ig | 成功   | 2026-10-06 12:30 | https://instagram.test/p/1 |

  Rule: 後置：重試後所有目標平台帳號皆成功時，貼文狀態為發佈完成

    Example: Instagram 重試成功後全部成功
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PUBLISHED"

  Rule: 後置：重試後仍有平台帳號失敗、且有平台帳號成功時，貼文狀態為部分失敗

    Example: Instagram 重試仍失敗
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：寫入一筆「重試發佈」稽核紀錄

    Example: 重試發佈後新增稽核紀錄
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action   | target_type | target | result    |
        | 使用者     | pr@club.tw | 重試發佈 | 貼文        | P1     | PUBLISHED |
      And 該筆稽核紀錄的各目標執行結果為：
        | account_name       | status | failure_reason | skip_reason  |
        | ntu_guitar_threads | 未重試 |                | 先前已成功   |
        | ntu_guitar_ig      | 成功   |                |              |
        | 公告               | 未重試 |                | 先前已成功   |

    Example: 重試新增稽核紀錄，不覆蓋原本「發佈貼文」稽核紀錄的執行結果
      Given 系統中有以下稽核紀錄：
        | actor_type | actor      | action   | target_type | target | result           | occurred_at      |
        | 使用者     | pr@club.tw | 發佈貼文 | 貼文        | P1     | PARTIALLY_FAILED | 2026-10-06 12:05 |
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 稽核紀錄包含：
        | actor_type | actor      | action   | target_type | target | result           |
        | 使用者     | pr@club.tw | 發佈貼文 | 貼文        | P1     | PARTIALLY_FAILED |
        | 使用者     | pr@club.tw | 重試發佈 | 貼文        | P1     | PUBLISHED        |

  Rule: 後置：發佈時平台明確回應授權失效，該平台帳號的授權狀態改為失效

    Example: Instagram 存取 Token 已被平台撤銷
      Given 現在時間為 "2026-10-06 12:30"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為授權失效
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 失效        |

  Rule: 後置：一般發佈失敗（例如平台暫時無法連線）不改變平台帳號的授權狀態

    Example: Instagram 因平台暫時無法連線而失敗
      Given 現在時間為 "2026-10-06 12:30"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 有效        |

  Rule: 後置：「重試發佈」稽核紀錄列出全部目標平台帳號，未重試者標示未重試原因
    # 只代表本次重試，不覆蓋先前執行的歷史結果

    Example: Threads 重試失敗、Instagram 授權失效跳過、Discord 已移除跳過、另一平台先前已成功
      Given 系統中有以下平台帳號：
        | platform  | account_name | auth_status | auth_expires_at  | linked_by         |
        | Instagram | expired_ig   | 有效        | 2026-10-06 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P7 | pr@club.tw | 社課公告 | PARTIALLY_FAILED |              |
      And 貼文 "P7" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p7.jpg |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | ntu_guitar_ig      |
        | expired_ig         |
        | 公告               |
      And 貼文 "P7" 已有以下發佈紀錄：
        | account_name       | status | published_at     | post_url                   | failure_reason   |
        | ntu_guitar_threads | 失敗   |                  |                            | 平台暫時無法連線 |
        | ntu_guitar_ig      | 成功   | 2026-10-06 12:05 | https://instagram.test/p/7 |                  |
        | expired_ig         | 失敗   |                  |                            | 帳號授權過期     |
        | 公告               | 失敗   |                  |                            | 平台暫時無法連線 |
      And 平台帳號 "公告" 已被移除
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 重試發佈貼文 "P7"
      Then 操作成功
      And 該筆稽核紀錄的各目標執行結果為：
        | account_name       | status | failure_reason   | skip_reason    |
        | ntu_guitar_threads | 失敗   | 平台暫時無法連線 |                |
        | ntu_guitar_ig      | 未重試 |                  | 先前已成功     |
        | expired_ig         | 未重試 |                  | 授權失效而跳過 |
        | 公告               | 未重試 |                  | 已移除而跳過   |

  Rule: 後置：重試時發佈紀錄的狀態變更寫入變更歷程（開始時失敗→待發佈，完成時待發佈→成功或失敗）

    Example: Instagram 重試成功的變更歷程
      When "pr@club.tw" 重試發佈貼文 "P1"
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name  | from_status | to_status | actor_type | actor      | reason         |
        | P1   | ntu_guitar_ig | 失敗        | 待發佈    | 使用者     | pr@club.tw | 重試發佈：開始 |
        | P1   | ntu_guitar_ig | 待發佈      | 成功      | 系統       |            | 重試發佈：成功 |
