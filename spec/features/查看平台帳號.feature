# 來源：FR-07、BR-09、BR-17、BR-20、BR-21、NFR-02
Feature: 查看平台帳號
  使用者查看已連結的平台帳號及其授權狀態與授權到期時間。

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
      | Instagram | ntu_guitar_ig      | 有效        | 2026-10-01 00:00 | president@club.tw |
      | Discord   | 公告               | 有效        |                  | president@club.tw |
    And 現在時間為 "2026-10-05 10:00"

  Rule: 前置：管理員、發佈者、撰稿者皆可查看平台帳號

    Example: 三種角色查看平台帳號
      When "president@club.tw" 查看平台帳號列表
      Then 操作成功
      When "pr@club.tw" 查看平台帳號列表
      Then 操作成功
      When "newbie@club.tw" 查看平台帳號列表
      Then 操作成功

  Rule: 前置：停用的帳號無法查看平台帳號

    Example: 停用的帳號查看平台帳號
      When "retired@club.tw" 查看平台帳號列表
      Then 操作失敗

  Rule: 後置：列出已連結平台帳號的平台、帳號名稱、授權狀態與授權到期時間

    Example: 撰稿者查看平台帳號列表
      When "newbie@club.tw" 查看平台帳號列表
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | auth_expires_at  |
        | Threads   | ntu_guitar_threads | 2026-12-31 00:00 |
        | Instagram | ntu_guitar_ig      | 2026-10-01 00:00 |
        | Discord   | 公告               |                  |

  Rule: 後置：授權到期時間已過的平台帳號，授權狀態為失效

    Example: Instagram 授權已於 2026-10-01 到期
      When "pr@club.tw" 查看平台帳號列表
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | auth_status |
        | Threads   | ntu_guitar_threads | 有效        |
        | Instagram | ntu_guitar_ig      | 失效        |
        | Discord   | 公告               | 有效        |

  Rule: 後置：查詢結果不包含存取憑證

    Example: 管理員查看平台帳號列表時不回傳存取憑證
      When "president@club.tw" 查看平台帳號列表
      Then 操作成功
      And 查詢結果不包含欄位 "credential"
