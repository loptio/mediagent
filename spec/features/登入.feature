# 來源：FR-01、BR-17、BR-20、NFR-07、需求 4.5
Feature: 登入
  使用者以管理員建立的帳號（Email 與密碼）登入系統。
  所有登入失敗回傳相同的失敗結果，不透露帳號是否存在、是否停用或是否已被鎖定。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status | password  |
      | president@club.tw | 社長     | 管理員 | 啟用   | Pres#2026 |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   | Pub#2026  |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   | New#2026  |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   | Old#2025  |

  Rule: 前置：Email 與密碼皆正確時才可登入

    Example: 以正確的 Email 與密碼登入
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

    Example: 密碼錯誤
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗

    Example: Email 不存在
      When "nobody@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作失敗

  Rule: 前置：管理員、發佈者、撰稿者皆可登入

    Example: 三種角色皆可登入
      When "president@club.tw" 以密碼 "Pres#2026" 登入
      Then 操作成功
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功
      When "newbie@club.tw" 以密碼 "New#2026" 登入
      Then 操作成功

  Rule: 前置：停用的帳號無法登入

    Example: 停用的帳號以正確密碼登入
      When "retired@club.tw" 以密碼 "Old#2025" 登入
      Then 操作失敗

  Rule: 前置：帳號鎖定期間（早於鎖定到期時間）無法登入，即使密碼正確；到期那一刻即解除

    Example: 鎖定期間以正確密碼登入
      Given 現在時間為 "2026-10-05 10:00"
      And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作失敗

    Example: 恰好在鎖定到期時間以正確密碼登入
      Given 現在時間為 "2026-10-05 10:15"
      And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

    Example: 鎖定到期前 1 分鐘以正確密碼登入
      Given 現在時間為 "2026-10-05 10:14"
      And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作失敗

    Example: 鎖定到期後以正確密碼登入
      Given 現在時間為 "2026-10-05 10:16"
      And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 前置：同一個 IP 在任意連續 60 秒內最多 10 次登入嘗試；達到上限後拒絕該 IP 的後續嘗試，直到較早的嘗試超出 60 秒區間
    # 登入嘗試指每次實際送出的登入驗證請求，成功與失敗都計入

    Example: 60 秒內已有 10 次嘗試（含成功），第 11 次即使密碼正確也失敗
      Given 現在時間為 "2026-10-05 10:00:59"
      And IP "203.0.113.5" 已於以下時間嘗試登入：
        | occurred_at         | result |
        | 2026-10-05 10:00:00 | 成功   |
        | 2026-10-05 10:00:05 | 成功   |
        | 2026-10-05 10:00:10 | 失敗   |
        | 2026-10-05 10:00:15 | 成功   |
        | 2026-10-05 10:00:20 | 失敗   |
        | 2026-10-05 10:00:25 | 成功   |
        | 2026-10-05 10:00:30 | 成功   |
        | 2026-10-05 10:00:35 | 失敗   |
        | 2026-10-05 10:00:40 | 成功   |
        | 2026-10-05 10:00:45 | 成功   |
      When "pr@club.tw" 從 IP "203.0.113.5" 以密碼 "Pub#2026" 登入
      Then 操作失敗

    Example: 最早一次嘗試超出 60 秒區間後，可以再嘗試
      Given 現在時間為 "2026-10-05 10:01:01"
      And IP "203.0.113.5" 已於以下時間嘗試登入：
        | occurred_at         | result |
        | 2026-10-05 10:00:00 | 成功   |
        | 2026-10-05 10:00:05 | 成功   |
        | 2026-10-05 10:00:10 | 失敗   |
        | 2026-10-05 10:00:15 | 成功   |
        | 2026-10-05 10:00:20 | 失敗   |
        | 2026-10-05 10:00:25 | 成功   |
        | 2026-10-05 10:00:30 | 成功   |
        | 2026-10-05 10:00:35 | 失敗   |
        | 2026-10-05 10:00:40 | 成功   |
        | 2026-10-05 10:00:45 | 成功   |
      When "pr@club.tw" 從 IP "203.0.113.5" 以密碼 "Pub#2026" 登入
      Then 操作成功

    Example: 60 秒內只有 9 次嘗試，第 10 次可以登入
      Given 現在時間為 "2026-10-05 10:00:59"
      And IP "203.0.113.5" 在過去 1 分鐘內已嘗試登入 9 次
      When "pr@club.tw" 從 IP "203.0.113.5" 以密碼 "Pub#2026" 登入
      Then 操作成功

    Example: 不同 IP 不受影響
      Given IP "203.0.113.5" 在過去 1 分鐘內已嘗試登入 10 次
      When "pr@club.tw" 從 IP "198.51.100.7" 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 前置：IP 限流與帳號連續登入失敗鎖定為獨立的計數

    Example: 帳號從不同 IP 連續失敗 5 次，仍會被鎖定
      Given 現在時間為 "2026-10-05 10:00"
      And 使用者帳號 "pr@club.tw" 已連續登入失敗 4 次
      When "pr@club.tw" 從 IP "198.51.100.7" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為 "2026-10-05 10:15"

  Rule: 前置：登入時 Email 先標準化（移除前後空白、轉為小寫）再查詢帳號

    Example: 以大寫與前後空白的 Email 登入
      When " PR@Club.tw " 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 後置：登入成功時寫入一筆「登入」稽核紀錄

    Example: 登入成功後新增稽核紀錄
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor      | action | target_type | target     |
        | pr@club.tw | 登入   | 使用者帳號  | pr@club.tw |

  Rule: 後置：連續登入失敗達 5 次時，帳號鎖定 15 分鐘

    Example: 第 5 次連續失敗後鎖定
      Given 現在時間為 "2026-10-05 10:00"
      And 使用者帳號 "pr@club.tw" 已連續登入失敗 4 次
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為 "2026-10-05 10:15"

    Example: 第 4 次連續失敗不鎖定
      Given 現在時間為 "2026-10-05 10:00"
      And 使用者帳號 "pr@club.tw" 已連續登入失敗 3 次
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為空

  Rule: 後置：登入成功時，連續登入失敗次數歸零

    Example: 失敗 4 次後登入成功
      Given 使用者帳號 "pr@club.tw" 已連續登入失敗 4 次
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功
      And 使用者帳號 "pr@club.tw" 的連續登入失敗次數為 0

  Rule: 後置：登入失敗時新增一筆登入安全事件，記錄失敗原因與嘗試登入的 Email；Email 對應到既有帳號時關聯該帳號

    Example: 密碼錯誤
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 系統新增一筆登入安全事件：
        | event_type | failure_reason | attempted_email | user   |
        | 登入失敗   | 密碼錯誤 | pr@club.tw | pr@club.tw |

    Example: 帳號停用
      When "retired@club.tw" 以密碼 "Old#2025" 登入
      Then 操作失敗
      And 系統新增一筆登入安全事件：
        | event_type | failure_reason | attempted_email | user   |
        | 登入失敗   | 帳號停用 | retired@club.tw | retired@club.tw |

    Example: 帳號鎖定
      Given 現在時間為 "2026-10-05 10:00"
      And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"
      When "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作失敗
      And 系統新增一筆登入安全事件：
        | event_type | failure_reason | attempted_email | user   |
        | 登入失敗   | 帳號鎖定 | pr@club.tw | pr@club.tw |

    Example: 帳號不存在
      When "nobody@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作失敗
      And 系統新增一筆登入安全事件：
        | event_type | failure_reason | attempted_email | user   |
        | 登入失敗   | 帳號不存在 | nobody@club.tw |  |

  Rule: 後置：登入安全事件不保存密碼

    Example: 以錯誤密碼登入後，事件中不含該密碼
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 該筆登入安全事件不包含 "wrong-password"

  Rule: 後置：登入失敗不寫入一般稽核紀錄

    Example: 密碼錯誤時不新增稽核紀錄
      When "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 系統沒有新增稽核紀錄
