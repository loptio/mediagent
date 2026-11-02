# 來源：FR-02、需求 4.1、BR-17、BR-20、情境一、需求 4.5
Feature: 建立幹部帳號
  管理員建立幹部帳號，設定 Email、名稱、角色與初始密碼。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |

  Rule: 前置：只有管理員可以建立幹部帳號

    Example: 發佈者建立幹部帳號
      When "pr@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作失敗

    Example: 撰稿者建立幹部帳號
      When "newbie@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作失敗

  Rule: 前置：停用的帳號無法建立幹部帳號

    Example: 停用的管理員建立幹部帳號
      When "retired@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作失敗

  Rule: 前置：Email 不可與其他帳號重複

    Example: 以已存在的 Email 建立帳號
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | pr@club.tw     | 文書 | 發佈者 | Doc#2026  |
      Then 操作失敗

  Rule: 前置：角色必須為管理員、發佈者、撰稿者三者之一

    Example: 以三種角色建立帳號
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | vp@club.tw     | 副社 | 管理員 | Vice#2026 |
      Then 操作成功
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作成功
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | art@club.tw    | 美宣 | 撰稿者 | Art#2026  |
      Then 操作成功

    Example: 以不存在的角色建立帳號
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role | password  |
        | member@club.tw | 社員 | 社員 | Mem#2026  |
      Then 操作失敗

  Rule: 前置：初始密碼不可為空，且至少 8 個字元
    # 允許英文字母、數字及常見特殊符號，不強制特定組合；建議每位幹部使用不同的初始密碼

    Example: 初始密碼恰為 8 個字元
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作成功

    Example: 初始密碼為 7 個字元
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#202   |
      Then 操作失敗

    Example: 初始密碼為空
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 |           |
      Then 操作失敗

    Example: 只有英文字母的 8 個字元密碼
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | abcdefgh  |
      Then 操作成功

  Rule: 前置：Email 標準化（移除前後空白、轉為小寫）後不可與其他帳號重複

    Example: 以大寫的已存在 Email 建立帳號
      When "president@club.tw" 建立以下幹部帳號：
        | email      | name | role   | password |
        | PR@club.tw | 文書 | 發佈者 | Doc#2026 |
      Then 操作失敗

  Rule: 後置：系統新增一筆具有指定 Email、名稱與角色的使用者帳號

    Example: 管理員建立發佈者帳號
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作成功
      And 使用者帳號 "doc@club.tw" 的資料為：
        | email       | name | role   |
        | doc@club.tw | 文書 | 發佈者 |

  Rule: 後置：建立的帳號可使用初始密碼登入

    Example: 新建立的幹部以初始密碼登入
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      And "doc@club.tw" 以密碼 "Doc#2026" 登入
      Then 操作成功

  Rule: 後置：密碼只保存雜湊值

    Example: 保存的密碼不為明文
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作成功
      And 使用者帳號 "doc@club.tw" 保存的密碼值不為 "Doc#2026"

  Rule: 後置：寫入一筆「建立幹部帳號」稽核紀錄

    Example: 建立帳號後新增稽核紀錄
      When "president@club.tw" 建立以下幹部帳號：
        | email          | name | role   | password  |
        | doc@club.tw    | 文書 | 發佈者 | Doc#2026  |
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action       | target_type | target      |
        | president@club.tw | 建立幹部帳號 | 使用者帳號  | doc@club.tw |

  Rule: 後置：Email 以標準化後的值（移除前後空白、轉為小寫）儲存

    Example: 輸入含大寫與前後空白的 Email
      # DataTable 儲存格會自動去除前後空白，故以雙引號包住原始輸入值
      When "president@club.tw" 建立以下幹部帳號：
        | email            | name | role   | password |
        | " Doc@Club.TW "  | 文書 | 發佈者 | Doc#2026 |
      Then 操作成功
      And 使用者帳號 "doc@club.tw" 的資料為：
        | email       | name | role   |
        | doc@club.tw | 文書 | 發佈者 |
