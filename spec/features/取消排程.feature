# 來源：BR-11、BR-12、需求 4.3、BR-17、BR-18、BR-20
Feature: 取消排程
  使用者取消已排程但尚未發佈的貼文的排程，貼文改回草稿。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 系統中有以下平台帳號：
      | platform | account_name       | auth_status | auth_expires_at  | linked_by         |
      | Threads  | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord  | 公告               | 有效        |                  | president@club.tw |
    And 現在時間為 "2026-10-05 10:00"
    And 系統中有以下貼文：
      | id | creator        | content      | status    | scheduled_at     |
      | P1 | pr@club.tw     | 社課公告     | SCHEDULED | 2026-10-06 12:00 |
      | P2 | pr@club.tw     | 期末成發宣傳 | DRAFT     |                  |
      | P3 | newbie@club.tw | 新生茶會     | SCHEDULED | 2026-10-07 12:00 |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | 公告               |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name       | status | published_at | post_url | failure_reason |
      | ntu_guitar_threads | 待發佈 |              |          |                |
      | 公告               | 待發佈 |              |          |                |
    And 貼文 "P3" 已選擇以下目標平台帳號：
      | account_name |
      | 公告         |
    And 貼文 "P3" 已有以下發佈紀錄：
      | account_name | status | published_at | post_url | failure_reason |
      | 公告         | 待發佈 |              |          |                |

  Rule: 前置：撰稿者只能取消自己建立的貼文的排程

    Example: 撰稿者取消自己貼文的排程
      When "newbie@club.tw" 取消貼文 "P3" 的排程
      Then 操作成功
      And 貼文 "P3" 的狀態為 "DRAFT"

    Example: 撰稿者取消他人貼文的排程
      When "newbie@club.tw" 取消貼文 "P1" 的排程
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "SCHEDULED"

  Rule: 前置：管理員與發佈者可以取消任何貼文的排程

    Example: 發佈者取消撰稿者貼文的排程
      When "pr@club.tw" 取消貼文 "P3" 的排程
      Then 操作成功

    Example: 管理員取消發佈者貼文的排程
      When "president@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功

  Rule: 前置：停用的帳號無法取消排程

    Example: 停用的帳號取消排程
      When "retired@club.tw" 取消貼文 "P1" 的排程
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "SCHEDULED"

  Rule: 前置：只有已排程狀態的貼文可以取消排程

    Example: 取消草稿的排程
      When "pr@club.tw" 取消貼文 "P2" 的排程
      Then 操作失敗
      And 貼文 "P2" 的狀態為 "DRAFT"

    Example: 取消非已排程貼文的排程
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 取消貼文 "P4" 的排程
      Then 操作失敗
      When "pr@club.tw" 取消貼文 "P5" 的排程
      Then 操作失敗
      When "pr@club.tw" 取消貼文 "P6" 的排程
      Then 操作失敗
      When "pr@club.tw" 取消貼文 "P7" 的排程
      Then 操作失敗

  Rule: 後置：貼文狀態改回草稿

    Example: 取消社課公告的排程
      When "pr@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 後置：貼文的排程時間為空

    Example: 取消排程後排程時間清空
      When "pr@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功
      And 貼文 "P1" 的排程時間為空

  Rule: 後置：待發佈的發佈紀錄改為已取消，不刪除

    Example: 取消排程後發佈紀錄為已取消
      When "pr@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 已取消 |              |          |                |

  Rule: 後置：寫入一筆「取消排程」稽核紀錄

    Example: 取消排程後新增稽核紀錄
      When "pr@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor      | action   | target_type | target |
        | pr@club.tw | 取消排程 | 貼文        | P1     |

  Rule: 後置：發佈紀錄由待發佈改為已取消時寫入變更歷程

    Example: 取消排程的變更歷程
      When "pr@club.tw" 取消貼文 "P1" 的排程
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor      | reason   |
        | P1   | ntu_guitar_threads | 待發佈      | 已取消    | 使用者     | pr@club.tw | 取消排程 |
        | P1   | 公告               | 待發佈      | 已取消    | 使用者     | pr@club.tw | 取消排程 |
