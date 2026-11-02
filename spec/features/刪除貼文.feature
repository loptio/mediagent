# 來源：FR-13、BR-11、BR-13、BR-17、BR-18、BR-20
Feature: 刪除貼文
  使用者刪除尚未發佈的貼文。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 現在時間為 "2026-10-05 10:00"
    And 系統中有以下平台帳號：
      | platform | account_name | auth_status | auth_expires_at | linked_by         |
      | Discord  | 公告         | 有效        |                 | president@club.tw |
    And 系統中有以下貼文：
      | id | creator        | content      | status    | scheduled_at     |
      | P1 | newbie@club.tw | 新生茶會     | DRAFT     |                  |
      | P2 | pr@club.tw     | 期末成發宣傳 | DRAFT     |                  |
      | P3 | pr@club.tw     | 社課公告     | SCHEDULED | 2026-10-06 12:00 |

  Rule: 前置：撰稿者只能刪除自己建立的貼文

    Example: 撰稿者刪除自己的貼文
      When "newbie@club.tw" 刪除貼文 "P1"
      Then 操作成功

    Example: 撰稿者刪除他人的貼文
      When "newbie@club.tw" 刪除貼文 "P2"
      Then 操作失敗
      And 貼文 "P2" 存在

  Rule: 前置：管理員與發佈者可以刪除他人建立的貼文

    Example: 發佈者刪除撰稿者的貼文
      When "pr@club.tw" 刪除貼文 "P1"
      Then 操作成功

    Example: 管理員刪除發佈者的貼文
      When "president@club.tw" 刪除貼文 "P2"
      Then 操作成功

  Rule: 前置：停用的帳號無法刪除貼文

    Example: 停用的帳號刪除貼文
      When "retired@club.tw" 刪除貼文 "P2"
      Then 操作失敗
      And 貼文 "P2" 存在

  Rule: 前置：只有草稿與已排程狀態的貼文可以刪除

    Example: 刪除已排程的貼文
      When "pr@club.tw" 刪除貼文 "P3"
      Then 操作成功

    Example: 刪除非草稿、非已排程的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 刪除貼文 "P4"
      Then 操作失敗
      When "pr@club.tw" 刪除貼文 "P5"
      Then 操作失敗
      When "pr@club.tw" 刪除貼文 "P6"
      Then 操作失敗
      When "pr@club.tw" 刪除貼文 "P7"
      Then 操作失敗

  Rule: 後置：被刪除的貼文不存在

    Example: 刪除草稿
      When "pr@club.tw" 刪除貼文 "P2"
      Then 操作成功
      And 貼文 "P2" 不存在

  Rule: 後置：被刪除的貼文不出現在貼文列表

    Example: 刪除草稿後查詢貼文列表
      When "pr@club.tw" 刪除貼文 "P2"
      Then 操作成功
      When "pr@club.tw" 查詢貼文列表
      Then 查詢結果為：
        | id |
        | P1 |
        | P3 |

  Rule: 後置：被刪除貼文的發佈紀錄保留，並保留原貼文 ID

    Example: 刪除已取消排程的貼文後，發佈紀錄仍在
      Given 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 已取消 |              |          |                |
      When "pr@club.tw" 刪除貼文 "P3"
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄為：
        | account_name | status |
        | 公告         | 已取消 |

  Rule: 後置：刪除已排程貼文時，待發佈紀錄改為已取消並寫入變更歷程

    Example: 刪除已排程的社課公告
      Given 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 待發佈 |              |          |                |
      When "pr@club.tw" 刪除貼文 "P3"
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄為：
        | account_name | status |
        | 公告         | 已取消 |
      And 發佈紀錄變更歷程包含：
        | post | account_name | from_status | to_status | actor_type | actor      | reason   |
        | P3   | 公告         | 待發佈      | 已取消    | 使用者     | pr@club.tw | 刪除貼文 |

  Rule: 後置：被刪除貼文的發佈紀錄變更歷程與稽核紀錄保留

    Example: 刪除貼文後，取消排程的歷程與稽核紀錄仍在
      Given 發佈紀錄變更歷程中有以下紀錄：
        | post | account_name | from_status | to_status | actor_type | actor      | reason   |
        | P3   | 公告         | 待發佈      | 已取消    | 使用者     | pr@club.tw | 取消排程 |
      And 系統中有以下稽核紀錄：
        | actor_type | actor      | action   | target_type | target | occurred_at      |
        | 使用者     | pr@club.tw | 取消排程 | 貼文        | P3     | 2026-10-05 09:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 已取消 |              |          |                |
      When "pr@club.tw" 刪除貼文 "P3"
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name | from_status | to_status | reason   |
        | P3   | 公告         | 待發佈      | 已取消    | 取消排程 |
      And 稽核紀錄包含：
        | actor      | action   | target |
        | pr@club.tw | 取消排程 | P3     |

  Rule: 後置：圖片檔案不再被其他資料引用時，刪除實體檔案

    Example: 刪除附有圖片的草稿
      Given 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
      When "pr@club.tw" 刪除貼文 "P2"
      Then 操作成功
      And 圖片檔案 "https://media.test/p2.jpg" 不存在
