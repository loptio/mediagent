# 來源：FR-05、情境一（換屆）、BR-17、BR-19、BR-20、BR-21、BR-22、NFR-07、需求 4.5
Feature: 停用帳號
  管理員停用幹部帳號；停用的帳號不刪除。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status | password  |
      | president@club.tw | 社長     | 管理員 | 啟用   | Pres#2026 |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   | Pub#2026  |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   | New#2026  |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   | Old#2025  |
    And 現在時間為 "2026-10-05 10:00"

  Rule: 前置：只有管理員可以停用帳號

    Example: 發佈者停用他人帳號
      When "pr@club.tw" 停用 "newbie@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的狀態為 "啟用"

    Example: 撰稿者停用他人帳號
      When "newbie@club.tw" 停用 "pr@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的狀態為 "啟用"

  Rule: 前置：停用的帳號無法停用其他帳號

    Example: 停用的管理員停用他人帳號
      When "retired@club.tw" 停用 "newbie@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的狀態為 "啟用"

  Rule: 前置：最後一位啟用中的管理員不可被停用

    Example: 唯一啟用中的管理員停用自己
      When "president@club.tw" 停用 "president@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "president@club.tw" 的狀態為 "啟用"

    Example: 換屆：已有新任管理員時，卸任管理員可停用自己
      Given 使用者帳號 "pr@club.tw" 的角色已設為 "管理員"
      When "president@club.tw" 停用 "president@club.tw" 的帳號
      Then 操作成功
      And 使用者帳號 "president@club.tw" 的狀態為 "停用"

  Rule: 後置：被停用帳號的狀態為停用，帳號不刪除

    Example: 停用撰稿者帳號
      When "president@club.tw" 停用 "newbie@club.tw" 的帳號
      Then 操作成功
      And 使用者帳號 "newbie@club.tw" 的資料為：
        | email          | name     | role   | status |
        | newbie@club.tw | 新進幹部 | 撰稿者 | 停用   |

  Rule: 後置：被停用的帳號立即無法登入

    Example: 停用後以正確密碼登入
      When "president@club.tw" 停用 "newbie@club.tw" 的帳號
      And "newbie@club.tw" 以密碼 "New#2026" 登入
      Then 操作失敗

  Rule: 後置：被停用帳號建立的貼文、發佈紀錄與稽核紀錄保留

    Example: 停用帳號後其資料仍存在
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content        | status    | scheduled_at |
        | P1 | pr@club.tw | 社課改到 201   | PUBLISHED |              |
      And 貼文 "P1" 已有以下發佈紀錄：
        | account_name | status | published_at     | post_url                   | failure_reason |
        | 公告         | 成功   | 2026-10-01 12:00 | https://discord.test/m/101 |                |
      And 系統中有以下稽核紀錄：
        | actor      | action   | target_type | target | occurred_at      |
        | pr@club.tw | 發佈貼文 | 貼文        | P1     | 2026-10-01 12:00 |
      When "president@club.tw" 停用 "pr@club.tw" 的帳號
      Then 操作成功
      And 貼文 "P1" 的資料為：
        | id | creator    | content      | status    |
        | P1 | pr@club.tw | 社課改到 201 | PUBLISHED |
      And 貼文 "P1" 的發佈紀錄為：
        | account_name | status | post_url                   |
        | 公告         | 成功   | https://discord.test/m/101 |
      And 稽核紀錄包含：
        | actor      | action   | target_type | target |
        | pr@club.tw | 發佈貼文 | 貼文        | P1     |

  Rule: 後置：被停用帳號建立且已排程的貼文維持已排程狀態

    Example: 停用發佈者後，其已排程貼文狀態不變
      Given 系統中有以下貼文：
        | id | creator    | content          | status    | scheduled_at     |
        | P2 | pr@club.tw | 期末成發宣傳     | SCHEDULED | 2026-10-06 12:00 |
      When "president@club.tw" 停用 "pr@club.tw" 的帳號
      Then 操作成功
      And 貼文 "P2" 的狀態為 "SCHEDULED"
      And 貼文 "P2" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：停用帳號不影響已連結的平台帳號

    Example: 連結者被停用後，其連結的平台帳號不變
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      And 使用者帳號 "pr@club.tw" 的角色已設為 "管理員"
      When "pr@club.tw" 停用 "president@club.tw" 的帳號
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | platform | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads  | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |

  Rule: 後置：寫入一筆「停用帳號」稽核紀錄

    Example: 停用帳號後新增稽核紀錄
      When "president@club.tw" 停用 "newbie@club.tw" 的帳號
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action   | target_type | target         |
        | president@club.tw | 停用帳號 | 使用者帳號  | newbie@club.tw |
