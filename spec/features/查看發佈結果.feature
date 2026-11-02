# 來源：FR-17、需求 4.4、BR-17、BR-20、情境二、例外情境
Feature: 查看發佈結果
  使用者查看貼文在每個目標平台帳號的發佈結果。

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
    And 系統中有以下貼文：
      | id | creator    | content  | status           | scheduled_at |
      | P1 | pr@club.tw | 社課公告 | PUBLISHED        |              |
      | P2 | pr@club.tw | 期中成發 | PARTIALLY_FAILED |              |
      | P3 | pr@club.tw | 迎新宿營 | SCHEDULED        | 2026-10-08 12:00 |
      | P4 | pr@club.tw | 新生茶會 | DRAFT            |                  |
      | P5 | pr@club.tw | 器材借用 | DRAFT            |                  |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name       | status | published_at     | post_url                   | failure_reason |
      | ntu_guitar_threads | 成功   | 2026-10-06 12:05 | https://threads.test/p/1   |                |
      | ntu_guitar_ig      | 成功   | 2026-10-06 12:05 | https://instagram.test/p/1 |                |
      | 公告               | 成功   | 2026-10-06 12:05 | https://discord.test/m/1   |                |
    And 貼文 "P2" 已有以下發佈紀錄：
      | account_name       | status | published_at     | post_url                 | failure_reason   |
      | ntu_guitar_threads | 成功   | 2026-10-06 12:05 | https://threads.test/p/2 |                  |
      | ntu_guitar_ig      | 失敗   |                  |                          | 平台暫時無法連線 |
      | 公告               | 成功   | 2026-10-06 12:05 | https://discord.test/m/2 |                  |
    And 貼文 "P2" 在平台帳號 "ntu_guitar_ig" 的平台原始錯誤訊息為 "503 Service Unavailable"
    And 貼文 "P3" 已有以下發佈紀錄：
      | account_name | status | published_at | post_url | failure_reason |
      | 公告         | 待發佈 |              |          |                |
    And 貼文 "P5" 已有以下發佈紀錄：
      | account_name | status | published_at | post_url | failure_reason |
      | 公告         | 已取消 |              |          |                |

  Rule: 前置：管理員、發佈者、撰稿者皆可查看發佈結果

    Example: 三種角色查看發佈結果
      When "president@club.tw" 查看貼文 "P1" 的發佈結果
      Then 操作成功
      When "pr@club.tw" 查看貼文 "P1" 的發佈結果
      Then 操作成功
      When "newbie@club.tw" 查看貼文 "P1" 的發佈結果
      Then 操作成功

  Rule: 前置：停用的帳號無法查看發佈結果

    Example: 停用的帳號查看發佈結果
      When "retired@club.tw" 查看貼文 "P1" 的發佈結果
      Then 操作失敗

  Rule: 後置：列出每個目標平台帳號的狀態、發佈時間與平台貼文連結

    Example: 三個平台皆發佈成功，顯示三則平台貼文連結
      When "pr@club.tw" 查看貼文 "P1" 的發佈結果
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | status | published_at     | post_url                   |
        | Threads   | ntu_guitar_threads | 成功   | 2026-10-06 12:05 | https://threads.test/p/1   |
        | Instagram | ntu_guitar_ig      | 成功   | 2026-10-06 12:05 | https://instagram.test/p/1 |
        | Discord   | 公告               | 成功   | 2026-10-06 12:05 | https://discord.test/m/1   |

  Rule: 後置：發佈失敗的平台帳號顯示失敗原因

    Example: Instagram 因平台暫時無法連線而失敗
      When "pr@club.tw" 查看貼文 "P2" 的發佈結果
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | status | post_url                 | failure_reason   |
        | Threads   | ntu_guitar_threads | 成功   | https://threads.test/p/2 |                  |
        | Instagram | ntu_guitar_ig      | 失敗   |                          | 平台暫時無法連線 |
        | Discord   | 公告               | 成功   | https://discord.test/m/2 |                  |

  Rule: 後置：已排程貼文的發佈紀錄狀態為待發佈

    Example: 查看已排程貼文的發佈結果
      When "pr@club.tw" 查看貼文 "P3" 的發佈結果
      Then 操作成功
      And 查詢結果為：
        | platform | account_name | status | published_at | post_url |
        | Discord  | 公告         | 待發佈 |              |          |

  Rule: 後置：從未設定排程或立即發佈的草稿沒有發佈紀錄

    Example: 查看從未排程的草稿的發佈結果
      When "pr@club.tw" 查看貼文 "P4" 的發佈結果
      Then 操作成功
      And 查詢結果為空

  Rule: 後置：已取消排程的草稿，發佈紀錄狀態為已取消

    Example: 查看已取消排程的草稿的發佈結果
      When "pr@club.tw" 查看貼文 "P5" 的發佈結果
      Then 操作成功
      And 查詢結果為：
        | platform | account_name | status |
        | Discord  | 公告         | 已取消 |

  Rule: 後置：失敗原因為「帳號授權過期」「帳號授權失效」「平台暫時無法連線」「內容不符合平台限制」「發佈逾時」「其他」之一
    # 固定類別的完整驗證由各發佈功能的 Example 涵蓋；此處驗證查詢結果直接顯示類別文字

    Example: 查詢結果顯示固定類別的失敗原因
      When "newbie@club.tw" 查看貼文 "P2" 的發佈結果
      Then 操作成功
      And 查詢結果包含：
        | platform  | account_name  | status | failure_reason   |
        | Instagram | ntu_guitar_ig | 失敗   | 平台暫時無法連線 |

  Rule: 後置：管理員可查看平台原始錯誤訊息

    Example: 管理員查看部分失敗貼文的發佈結果
      When "president@club.tw" 查看貼文 "P2" 的發佈結果
      Then 操作成功
      And 查詢結果包含：
        | platform  | account_name  | status | failure_reason   | platform_error_message  |
        | Instagram | ntu_guitar_ig | 失敗   | 平台暫時無法連線 | 503 Service Unavailable |

  Rule: 後置：發佈者與撰稿者查看發佈結果時不包含平台原始錯誤訊息

    Example: 發佈者查看部分失敗貼文的發佈結果
      When "pr@club.tw" 查看貼文 "P2" 的發佈結果
      Then 操作成功
      And 查詢結果不包含欄位 "platform_error_message"

    Example: 撰稿者查看部分失敗貼文的發佈結果
      When "newbie@club.tw" 查看貼文 "P2" 的發佈結果
      Then 操作成功
      And 查詢結果不包含欄位 "platform_error_message"

  Rule: 後置：已刪除貼文仍可透過貼文 ID 查看發佈結果，並標示貼文已刪除

    Example: 查看已刪除貼文的發佈結果
      Given 貼文 "P5" 已被刪除
      When "pr@club.tw" 查看貼文 "P5" 的發佈結果
      Then 操作成功
      And 查詢結果的貼文已刪除標示為 true
      And 查詢結果為：
        | platform | account_name | status |
        | Discord  | 公告         | 已取消 |
