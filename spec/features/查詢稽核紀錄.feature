# 來源：FR-19、需求 4.5、BR-17、BR-20
Feature: 查詢稽核紀錄
  管理員查詢重要操作的稽核紀錄，可依操作者、對應帳號、操作類型與時間區間篩選。
  查詢範圍包含三種紀錄：一般稽核紀錄、登入安全事件、平台授權事件，以 record_kind 區分；未指定操作類型時三種都列出。
  操作類型「登入失敗」對應登入安全事件，「連結平台帳號失敗」「重新連結平台帳號失敗」對應平台授權事件。
  處理順序：先套用篩選條件，再排序，最後分頁。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |
    And 系統中有以下稽核紀錄：
      | actor_type | actor             | action       | target_type | target         | occurred_at      |
      | 使用者     | president@club.tw | 建立幹部帳號 | 使用者帳號  | newbie@club.tw | 2026-09-01 09:00 |
      | 使用者     | pr@club.tw        | 登入         | 使用者帳號  | pr@club.tw     | 2026-10-05 09:55 |
      | 使用者     | pr@club.tw        | 設定排程     | 貼文        | P1             | 2026-10-05 10:00 |
      | 系統       |                   | 發佈貼文     | 貼文        | P1             | 2026-10-06 12:05 |
    And 系統中有以下登入安全事件：
      | event_type | failure_reason | attempted_email | user       | occurred_at      |
      | 登入失敗   | 帳號不存在     | nobody@club.tw  |            | 2026-10-05 08:00 |
      | 登入失敗   | 密碼錯誤       | pr@club.tw      | pr@club.tw | 2026-10-05 09:50 |
    And 系統中有以下平台帳號：
      | platform  | account_name  | auth_status | auth_expires_at  | linked_by         |
      | Instagram | ntu_guitar_ig | 失效        | 2026-10-01 00:00 | president@club.tw |
    And 系統中有以下平台授權事件：
      | event_type           | failure_reason | account_name  | actor             | occurred_at      |
      | 重新連結平台帳號失敗 | 平台授權失敗   | ntu_guitar_ig | president@club.tw | 2026-10-05 11:00 |

  Rule: 前置：只有管理員可以查詢稽核紀錄

    Example: 發佈者查詢稽核紀錄
      When "pr@club.tw" 查詢稽核紀錄
      Then 操作失敗

    Example: 撰稿者查詢稽核紀錄
      When "newbie@club.tw" 查詢稽核紀錄
      Then 操作失敗

  Rule: 前置：停用的帳號無法查詢稽核紀錄

    Example: 停用的管理員查詢稽核紀錄
      When "retired@club.tw" 查詢稽核紀錄
      Then 操作失敗

  Rule: 後置：未指定操作類型時，一般稽核紀錄、登入安全事件與平台授權事件合併列出，以紀錄種類區分，依時間由新到舊排序

    Example: 管理員查詢稽核紀錄
      When "president@club.tw" 查詢稽核紀錄
      Then 操作成功
      And 查詢結果依序為：
        | record_kind  | actor_type | actor             | action               | occurred_at      |
        | 稽核紀錄     | 系統       |                   | 發佈貼文             | 2026-10-06 12:05 |
        | 平台授權事件 | 使用者     | president@club.tw | 重新連結平台帳號失敗 | 2026-10-05 11:00 |
        | 稽核紀錄     | 使用者     | pr@club.tw        | 設定排程             | 2026-10-05 10:00 |
        | 稽核紀錄     | 使用者     | pr@club.tw        | 登入                 | 2026-10-05 09:55 |
        | 登入安全事件 |            |                   | 登入失敗             | 2026-10-05 09:50 |
        | 登入安全事件 |            |                   | 登入失敗             | 2026-10-05 08:00 |
        | 稽核紀錄     | 使用者     | president@club.tw | 建立幹部帳號         | 2026-09-01 09:00 |

  Rule: 後置：事件時間相同時，依三種紀錄共用的全域事件序號由大到小排序
    # 各類紀錄原有的 ID 只用於識別各自資料表中的紀錄

    Example: 兩筆稽核紀錄時間相同
      Given 系統中有以下稽核紀錄：
        | actor_type | actor             | action   | target_type | target     | occurred_at      | event_seq |
        | 使用者     | president@club.tw | 調整角色 | 使用者帳號  | pr@club.tw | 2026-10-07 09:00 | 101       |
        | 使用者     | president@club.tw | 停用帳號 | 使用者帳號  | pr@club.tw | 2026-10-07 09:00 | 102       |
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | from             |
        | 2026-10-07 00:00 |
      Then 操作成功
      And 查詢結果依序為：
        | action   | occurred_at      |
        | 停用帳號 | 2026-10-07 09:00 |
        | 調整角色 | 2026-10-07 09:00 |

    Example: 稽核紀錄與登入安全事件時間相同
      Given 系統中有以下稽核紀錄：
        | actor_type | actor      | action | target_type | target     | occurred_at      | event_seq |
        | 使用者     | pr@club.tw | 登入   | 使用者帳號  | pr@club.tw | 2026-10-07 09:00 | 201       |
      And 系統中有以下登入安全事件：
        | event_type | failure_reason | attempted_email | user       | occurred_at      | event_seq |
        | 登入失敗   | 密碼錯誤       | pr@club.tw      | pr@club.tw | 2026-10-07 09:00 | 202       |
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | from             |
        | 2026-10-07 00:00 |
      Then 操作成功
      And 查詢結果依序為：
        | record_kind  | action   | occurred_at      |
        | 登入安全事件 | 登入失敗 | 2026-10-07 09:00 |
        | 稽核紀錄     | 登入     | 2026-10-07 09:00 |

  Rule: 後置：依操作者篩選時，只列出該使用者執行的稽核紀錄與平台授權事件；登入安全事件沒有操作者，不列出

    Example: 篩選公關的操作，不含公關帳號的登入失敗事件
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | actor      |
        | pr@club.tw |
      Then 操作成功
      And 查詢結果依序為：
        | record_kind | actor      | action   |
        | 稽核紀錄    | pr@club.tw | 設定排程 |
        | 稽核紀錄    | pr@club.tw | 登入     |

    Example: 篩選社長的操作，包含平台授權事件
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | actor             |
        | president@club.tw |
      Then 操作成功
      And 查詢結果依序為：
        | record_kind  | actor             | action               |
        | 平台授權事件 | president@club.tw | 重新連結平台帳號失敗 |
        | 稽核紀錄     | president@club.tw | 建立幹部帳號         |

  Rule: 後置：依對應帳號篩選時，列出對應該帳號的登入安全事件，以及操作對象為該使用者帳號的一般稽核紀錄；各紀錄的操作者不變
    # 以穩定的使用者 ID 比對，不使用 Email 或顯示名稱；Example 以 Email 表示該帳號

    Example: 篩選對應公關帳號的紀錄
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | related_account |
        | pr@club.tw      |
      Then 操作成功
      And 查詢結果依序為：
        | record_kind  | actor      | action   | target_type | target     | user       |
        | 稽核紀錄     | pr@club.tw | 登入     | 使用者帳號  | pr@club.tw |            |
        | 登入安全事件 |            | 登入失敗 |             |            | pr@club.tw |

    Example: 篩選對應新進幹部帳號的紀錄，操作者仍為社長
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | related_account |
        | newbie@club.tw  |
      Then 操作成功
      And 查詢結果為：
        | record_kind | actor             | action       | target_type | target         |
        | 稽核紀錄    | president@club.tw | 建立幹部帳號 | 使用者帳號  | newbie@club.tw |

  Rule: 後置：操作者篩選為「系統」時，只列出系統執行的稽核紀錄

    Example: 篩選系統的操作
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | actor |
        | 系統  |
      Then 操作成功
      And 查詢結果為：
        | actor_type | action   | target |
        | 系統       | 發佈貼文 | P1     |

  Rule: 後置：依操作類型篩選時，只列出該類型的稽核紀錄

    Example: 篩選設定排程
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | action   |
        | 設定排程 |
      Then 操作成功
      And 查詢結果為：
        | actor      | action   | target |
        | pr@club.tw | 設定排程 | P1     |

  Rule: 後置：依時間區間篩選時，列出操作時間大於等於開始時間、且小於結束時間的紀錄

    Example: 恰好等於開始時間者列出，恰好等於結束時間者不列出
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | from             | to               |
        | 2026-10-05 09:55 | 2026-10-05 10:00 |
      Then 操作成功
      And 查詢結果為：
        | record_kind | action | occurred_at      |
        | 稽核紀錄    | 登入   | 2026-10-05 09:55 |

    Example: 篩選 2026-10-05 當天
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | from             | to               |
        | 2026-10-05 00:00 | 2026-10-05 23:59 |
      Then 操作成功
      And 查詢結果依序為：
        | record_kind  | action               | occurred_at      |
        | 平台授權事件 | 重新連結平台帳號失敗 | 2026-10-05 11:00 |
        | 稽核紀錄     | 設定排程             | 2026-10-05 10:00 |
        | 稽核紀錄     | 登入                 | 2026-10-05 09:55 |
        | 登入安全事件 | 登入失敗             | 2026-10-05 09:50 |
        | 登入安全事件 | 登入失敗             | 2026-10-05 08:00 |

  Rule: 後置：操作類型為「登入失敗」時，列出登入安全事件；帳號不存在的事件也可查得

    Example: 篩選 2026-10-05 的登入失敗
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | action   | from             | to               |
        | 登入失敗 | 2026-10-05 00:00 | 2026-10-05 23:59 |
      Then 操作成功
      And 查詢結果依序為：
        | event_type | failure_reason | attempted_email | user       | occurred_at      |
        | 登入失敗   | 密碼錯誤       | pr@club.tw      | pr@club.tw | 2026-10-05 09:50 |
        | 登入失敗   | 帳號不存在     | nobody@club.tw  |            | 2026-10-05 08:00 |

  Rule: 後置：未指定每頁筆數時，每頁 20 筆

    Example: 共 52 筆紀錄（含 2 筆登入安全事件、1 筆平台授權事件），查詢第 1 頁
      Given 系統中另有 45 筆由 "pr@club.tw" 執行的「登入」稽核紀錄
      When "president@club.tw" 查詢稽核紀錄
      Then 操作成功
      And 查詢結果共 20 筆
      And 查詢結果的分頁資訊為：
        | page | page_size | total_count | total_pages | has_prev | has_next |
        | 1    | 20        | 52          | 3           | false    | true     |

  Rule: 前置：每頁筆數只能為 20、50 或 100

    Example: 每頁 50 筆
      Given 系統中另有 45 筆由 "pr@club.tw" 執行的「登入」稽核紀錄
      When "president@club.tw" 查詢稽核紀錄，第 1 頁，每頁 50 筆
      Then 操作成功
      And 查詢結果共 50 筆

    Example: 每頁 30 筆
      When "president@club.tw" 查詢稽核紀錄，第 1 頁，每頁 30 筆
      Then 操作失敗

  Rule: 後置：操作類型為「連結平台帳號失敗」或「重新連結平台帳號失敗」時，只列出符合該事件類型的平台授權事件
    # 查詢功能整合，底層紀錄分開管理

    Example: 查詢重新連結失敗事件
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | action               |
        | 重新連結平台帳號失敗 |
      Then 操作成功
      And 查詢結果為：
        | event_type           | failure_reason | account_name  | actor             | occurred_at      |
        | 重新連結平台帳號失敗 | 平台授權失敗   | ntu_guitar_ig | president@club.tw | 2026-10-05 11:00 |

    Example: 發佈者查詢重新連結失敗事件
      When "pr@club.tw" 以下列條件查詢稽核紀錄：
        | action               |
        | 重新連結平台帳號失敗 |
      Then 操作失敗

    Example: 查詢首次連結失敗事件，不含重新連結失敗事件
      Given 系統中有以下平台授權事件：
        | event_type       | platform | account_name | failure_reason   | actor             | occurred_at      |
        | 連結平台帳號失敗 | Discord  | 公告         | Webhook 驗證無效 | president@club.tw | 2026-10-05 12:00 |
      When "president@club.tw" 以下列條件查詢稽核紀錄：
        | action           |
        | 連結平台帳號失敗 |
      Then 操作成功
      And 查詢結果為：
        | record_kind  | event_type       | platform | account_name | failure_reason   |
        | 平台授權事件 | 連結平台帳號失敗 | Discord  | 公告         | Webhook 驗證無效 |
