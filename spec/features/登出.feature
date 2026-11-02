# 來源：FR-01、NFR-07
Feature: 登出
  使用者主動登出，使目前的登入狀態立即失效。
  登出須由伺服器端讓目前的 Session 或 Refresh Token 失效；若採用 JWT，須搭配伺服器端撤銷機制，不能只清除用戶端的 Token。
  帳號停用後立即無法存取系統（NFR-07）由各功能的「停用的帳號無法…」Rule 驗證，不依賴登出功能。

  Background:
    Given 系統中有以下使用者帳號：
      | email      | name | role   | status | password |
      | pr@club.tw | 公關 | 發佈者 | 啟用   | Pub#2026 |
    And "pr@club.tw" 已登入，登入憑證為 "S1"
    And "pr@club.tw" 已登入，登入憑證為 "S2"

  Rule: 後置：登出後，原本的登入憑證立即失效

    Example: 以登出前的登入憑證查詢貼文列表
      When "pr@club.tw" 以登入憑證 "S1" 登出
      Then 操作成功
      When 以登入憑證 "S1" 查詢貼文列表
      Then 操作失敗

  Rule: 後置：登出後，重新登入即可再次存取

    Example: 登出後重新登入
      When "pr@club.tw" 以登入憑證 "S1" 登出
      And "pr@club.tw" 以密碼 "Pub#2026" 登入
      Then 操作成功

  Rule: 後置：一般登出只讓目前的登入憑證失效，其他裝置的登入憑證仍有效
    # 要讓所有裝置失效請使用「登出所有裝置」

    Example: 在 S1 登出後，S2 仍可使用
      When "pr@club.tw" 以登入憑證 "S1" 登出
      Then 操作成功
      When 以登入憑證 "S2" 查詢貼文列表
      Then 操作成功

  Rule: 後置：寫入一筆「登出」稽核紀錄

    Example: 登出後新增稽核紀錄
      When "pr@club.tw" 以登入憑證 "S1" 登出
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action | target_type | target     |
        | 使用者     | pr@club.tw | 登出   | 使用者帳號  | pr@club.tw |
