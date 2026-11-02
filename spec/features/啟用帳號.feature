# 來源：需求 4.1、BR-17、BR-20、需求 4.5
Feature: 啟用帳號
  管理員將停用的幹部帳號重新啟用。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status | password  |
      | president@club.tw | 社長     | 管理員 | 啟用   | Pres#2026 |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   | Pub#2026  |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   | New#2026  |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   | Old#2025  |
      | oldpres@club.tw   | 前任社長 | 管理員 | 停用   | OldP#2025 |

  Rule: 前置：只有管理員可以啟用帳號

    Example: 發佈者啟用帳號
      When "pr@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "retired@club.tw" 的狀態為 "停用"

    Example: 撰稿者啟用帳號
      When "newbie@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "retired@club.tw" 的狀態為 "停用"

  Rule: 前置：停用的帳號無法啟用其他帳號

    Example: 停用的管理員啟用他人帳號
      When "oldpres@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "retired@club.tw" 的狀態為 "停用"

  Rule: 前置：只有狀態為停用的帳號可以啟用

    Example: 啟用已是啟用狀態的帳號
      When "president@club.tw" 啟用 "pr@club.tw" 的帳號
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的狀態為 "啟用"

  Rule: 後置：被啟用帳號的狀態為啟用，Email、名稱與角色維持原本的值

    Example: 重新啟用前任公關
      When "president@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作成功
      And 使用者帳號 "retired@club.tw" 的資料為：
        | email           | name     | role   | status |
        | retired@club.tw | 前任公關 | 發佈者 | 啟用   |

  Rule: 後置：被啟用的帳號可以用原本的密碼登入

    Example: 重新啟用後登入
      When "president@club.tw" 啟用 "retired@club.tw" 的帳號
      And "retired@club.tw" 以密碼 "Old#2025" 登入
      Then 操作成功

  Rule: 後置：被啟用帳號建立的貼文與發佈紀錄維持不變

    Example: 重新啟用後，先前建立的貼文仍在
      Given 系統中有以下平台帳號：
        | platform | account_name | auth_status | auth_expires_at | linked_by         |
        | Discord  | 公告         | 有效        |                 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator         | content      | status    | scheduled_at |
        | P1 | retired@club.tw | 社課改到 201 | PUBLISHED |              |
      And 貼文 "P1" 已有以下發佈紀錄：
        | account_name | status | published_at     | post_url                   | failure_reason |
        | 公告         | 成功   | 2026-10-01 12:00 | https://discord.test/m/101 |                |
      When "president@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作成功
      And 貼文 "P1" 的資料為：
        | id | creator         | content      | status    |
        | P1 | retired@club.tw | 社課改到 201 | PUBLISHED |
      And 貼文 "P1" 的發佈紀錄為：
        | account_name | status | post_url                   |
        | 公告         | 成功   | https://discord.test/m/101 |

  Rule: 後置：寫入一筆「啟用帳號」稽核紀錄

    Example: 啟用帳號後新增稽核紀錄
      When "president@club.tw" 啟用 "retired@club.tw" 的帳號
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action   | target_type | target          |
        | president@club.tw | 啟用帳號 | 使用者帳號  | retired@club.tw |
