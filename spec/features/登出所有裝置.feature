# 來源：FR-01、NFR-07
Feature: 登出所有裝置
  使用者一次讓自己所有的登入憑證失效。
  須由伺服器端讓該使用者所有 Session 或 Refresh Token 失效。

  Background:
    Given 系統中有以下使用者帳號：
      | email          | name     | role   | status | password |
      | pr@club.tw     | 公關     | 發佈者 | 啟用   | Pub#2026 |
      | newbie@club.tw | 新進幹部 | 撰稿者 | 啟用   | New#2026 |
    And "pr@club.tw" 已登入，登入憑證為 "S1"
    And "pr@club.tw" 已登入，登入憑證為 "S2"
    And "newbie@club.tw" 已登入，登入憑證為 "N1"

  Rule: 後置：該使用者所有的登入憑證立即失效

    Example: 在 S1 執行登出所有裝置
      When "pr@club.tw" 以登入憑證 "S1" 登出所有裝置
      Then 操作成功
      When 以登入憑證 "S1" 查詢貼文列表
      Then 操作失敗
      When 以登入憑證 "S2" 查詢貼文列表
      Then 操作失敗

  Rule: 後置：其他使用者的登入憑證不受影響

    Example: 公關登出所有裝置後，新進幹部仍可使用
      When "pr@club.tw" 以登入憑證 "S1" 登出所有裝置
      Then 操作成功
      When 以登入憑證 "N1" 查詢貼文列表
      Then 操作成功

  Rule: 後置：登出所有裝置後，重新登入即可再次存取

    Example: 登出所有裝置後重新登入
      When "pr@club.tw" 以登入憑證 "S1" 登出所有裝置
      And "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 後置：寫入一筆「登出所有裝置」稽核紀錄

    Example: 登出所有裝置後新增稽核紀錄
      When "pr@club.tw" 以登入憑證 "S1" 登出所有裝置
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action       | target_type | target     |
        | 使用者     | pr@club.tw | 登出所有裝置 | 使用者帳號  | pr@club.tw |
