# 來源：FR-08、BR-17、BR-20、需求 4.5
Feature: 移除平台帳號
  管理員移除已連結的平台帳號。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |
    And 系統中有以下平台帳號：
      | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
      | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord   | 公告               | 有效        |                  | president@club.tw |

  Rule: 前置：只有管理員可以移除平台帳號

    Example: 發佈者移除平台帳號
      When "pr@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | account_name       | removed |
        | ntu_guitar_threads | false   |

    Example: 撰稿者移除平台帳號
      When "newbie@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | account_name       | removed |
        | ntu_guitar_threads | false   |

  Rule: 前置：停用的帳號無法移除平台帳號

    Example: 停用的管理員移除平台帳號
      When "retired@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作失敗
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | account_name       | removed |
        | ntu_guitar_threads | false   |

  Rule: 後置：被移除的平台帳號資料保留，標記為已移除

    Example: 移除 Threads 帳號後資料仍在
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | platform | account_name       | linked_by         | removed |
        | Threads  | ntu_guitar_threads | president@club.tw | true    |

  Rule: 後置：被移除的平台帳號不再出現在已連結的平台帳號中

    Example: 管理員移除 Threads 帳號
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      When "president@club.tw" 查看平台帳號列表
      Then 查詢結果為：
        | platform | account_name |
        | Discord  | 公告         |

  Rule: 後置：被移除平台帳號的發佈紀錄保留

    Example: 移除 Discord 頻道後，過去的發佈結果仍可查看
      Given 系統中有以下貼文：
        | id | creator    | content      | status    | scheduled_at |
        | P1 | pr@club.tw | 社課改到 201 | PUBLISHED |              |
      And 貼文 "P1" 已有以下發佈紀錄：
        | account_name | status | published_at     | post_url                   | failure_reason |
        | 公告         | 成功   | 2026-10-01 12:00 | https://discord.test/m/101 |                |
      When "president@club.tw" 移除平台帳號 "公告"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name | status | published_at     | post_url                   |
        | 公告         | 成功   | 2026-10-01 12:00 | https://discord.test/m/101 |

  Rule: 後置：被移除的平台帳號自動從草稿的目標平台帳號中移除

    Example: 草稿原本選擇 Threads 與 Discord
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 新生茶會 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P2" 的目標平台帳號為：
        | platform | account_name |
        | Discord  | 公告         |

  Rule: 後置：被移除的平台帳號自動從已排程貼文的目標平台帳號中移除

    Example: 已排程貼文原本選擇 Threads 與 Discord
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P3 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P3" 的目標平台帳號為：
        | platform | account_name |
        | Discord  | 公告         |

  Rule: 後置：已排程貼文對被移除平台帳號的待發佈紀錄改為已取消

    Example: 已排程貼文的 Threads 待發佈紀錄改為已取消
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P3 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄為：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 待發佈 |              |          |                |

  Rule: 後置：寫入一筆「移除平台帳號」稽核紀錄

    Example: 移除平台帳號後新增稽核紀錄
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action       | target_type | target             |
        | president@club.tw | 移除平台帳號 | 平台帳號    | ntu_guitar_threads |

  Rule: 後置：已排程貼文的待發佈紀錄因平台帳號被移除改為已取消時，寫入變更歷程

    Example: 移除 Threads 帳號的變更歷程
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P3 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor             | reason             |
        | P3   | ntu_guitar_threads | 待發佈      | 已取消    | 使用者     | president@club.tw | 目標平台帳號已移除 |

  Rule: 後置：已排程貼文仍有其他目標平台帳號時，維持已排程，排程時間不變

    Example: 社課公告還有 Discord 目標
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P3 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：被移除的是已排程貼文唯一的目標平台帳號時，貼文改回草稿

    Example: 新生茶會只選了 Threads
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P4 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P4" 的狀態為 "DRAFT"

  Rule: 後置：被移除的是已排程貼文唯一的目標平台帳號時，排程時間清空

    Example: 新生茶會只選了 Threads，排程時間清空
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P4 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P4" 的排程時間為空

  Rule: 後置：被移除的是已排程貼文唯一的目標平台帳號時，原有待發佈紀錄改為已取消並寫入變更歷程

    Example: 新生茶會的 Threads 紀錄改為已取消
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P4 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P4" 的發佈紀錄為：
        | account_name       | status |
        | ntu_guitar_threads | 已取消 |
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor             | reason             |
        | P4   | ntu_guitar_threads | 待發佈      | 已取消    | 使用者     | president@club.tw | 目標平台帳號已移除 |

  Rule: 後置：改回草稿的貼文保留建立者、內容與圖片

    Example: 新生茶會改回草稿後資料仍在
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P4 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
      And 貼文 "P4" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p4.jpg |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      And 貼文 "P4" 的資料為：
        | id | creator        | content  | status |
        | P4 | newbie@club.tw | 新生茶會 | DRAFT  |
      And 貼文 "P4" 的圖片為：
        | format | width | height |
        | JPEG   | 1080  | 1080   |

  Rule: 後置：改回草稿的貼文，原排程時間到時不會被發佈
    # 須以交易或併發控制確保改回草稿後，舊的排程任務不會再發佈

    Example: 移除後到了原排程時間
      Given 現在時間為 "2026-10-05 10:00"
      And 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P4 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
      When "president@club.tw" 移除平台帳號 "ntu_guitar_threads"
      Then 操作成功
      Given 現在時間為 "2026-10-06 12:05"
      When 系統執行排程發佈
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P4" 的狀態為 "DRAFT"
