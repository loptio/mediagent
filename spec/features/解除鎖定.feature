# 來源：BR-17、BR-20、需求 4.5
Feature: 解除鎖定
  管理員手動解除因連續登入失敗而被鎖定的帳號。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status | password  |
      | president@club.tw | 社長     | 管理員 | 啟用   | Pres#2026 |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   | Pub#2026  |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   | New#2026  |
      | oldpres@club.tw   | 前任社長 | 管理員 | 停用   | OldP#2025 |
    And 現在時間為 "2026-10-05 10:00"
    And 使用者帳號 "pr@club.tw" 已連續登入失敗 5 次
    And 使用者帳號 "pr@club.tw" 鎖定至 "2026-10-05 10:15"

  Rule: 前置：只有管理員可以解除鎖定

    Example: 撰稿者解除他人鎖定
      When "newbie@club.tw" 解除 "pr@club.tw" 的鎖定
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為 "2026-10-05 10:15"

  Rule: 前置：停用的帳號無法解除鎖定

    Example: 停用的管理員解除鎖定
      When "oldpres@club.tw" 解除 "pr@club.tw" 的鎖定
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為 "2026-10-05 10:15"

  Rule: 前置：目標帳號必須處於鎖定狀態；未被鎖定時操作失敗，不修改任何資料
    # 提示「此帳號目前未被鎖定」

    Example: 對未被鎖定的撰稿者執行解除鎖定
      Given 使用者帳號 "newbie@club.tw" 已連續登入失敗 2 次
      When "president@club.tw" 解除 "newbie@club.tw" 的鎖定
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的連續登入失敗次數為 2
      And 系統沒有新增稽核紀錄

  Rule: 後置：被解除鎖定的帳號鎖定到期時間為空

    Example: 管理員解除公關的鎖定
      When "president@club.tw" 解除 "pr@club.tw" 的鎖定
      Then 操作成功
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為空

  Rule: 後置：解除鎖定時，連續登入失敗次數歸零

    Example: 解除鎖定後失敗次數為 0
      When "president@club.tw" 解除 "pr@club.tw" 的鎖定
      Then 操作成功
      And 使用者帳號 "pr@club.tw" 的連續登入失敗次數為 0

    Example: 解除鎖定後輸錯一次不會立刻再被鎖定
      When "president@club.tw" 解除 "pr@club.tw" 的鎖定
      And "pr@club.tw" 以密碼 "wrong-password" 登入
      Then 操作失敗
      And 使用者帳號 "pr@club.tw" 的鎖定到期時間為空

  Rule: 後置：解除鎖定後可立即以正確密碼登入

    Example: 解除鎖定後在原鎖定期間內登入
      When "president@club.tw" 解除 "pr@club.tw" 的鎖定
      And "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 後置：寫入一筆「解除鎖定」稽核紀錄

    Example: 解除鎖定後新增稽核紀錄
      When "president@club.tw" 解除 "pr@club.tw" 的鎖定
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor             | action   | target_type | target     |
        | 使用者     | president@club.tw | 解除鎖定 | 使用者帳號  | pr@club.tw |

  Rule: 後置：解除鎖定不改變帳號的啟用或停用狀態；停用的帳號解除鎖定後仍無法登入

    Example: 解除停用帳號的鎖定
      Given 使用者帳號 "oldpres@club.tw" 鎖定至 "2026-10-05 10:15"
      When "president@club.tw" 解除 "oldpres@club.tw" 的鎖定
      Then 操作成功
      And 使用者帳號 "oldpres@club.tw" 的狀態為 "停用"
      When "oldpres@club.tw" 以密碼 "OldP#2025" 登入
      Then 操作失敗
