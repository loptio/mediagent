# 來源：FR-14、需求 4.6、BR-17、BR-20
Feature: 查詢貼文列表
  使用者查詢貼文列表，並依貼文狀態篩選。
  處理順序：先套用篩選條件，再排序，最後分頁。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 現在時間為 "2026-10-05 10:00"
    And 系統中有以下貼文：
      | id | creator        | content      | status           | scheduled_at     | created_at       |
      | P1 | newbie@club.tw | 新生茶會     | DRAFT            |                  | 2026-10-05 09:00 |
      | P2 | pr@club.tw     | 社課公告     | SCHEDULED        | 2026-10-06 12:00 | 2026-10-04 09:00 |
      | P3 | pr@club.tw     | 迎新宿營     | PUBLISHING       |                  | 2026-10-03 09:00 |
      | P4 | pr@club.tw     | 社員大會     | PUBLISHED        |                  | 2026-10-02 09:00 |
      | P5 | pr@club.tw     | 期中成發     | PARTIALLY_FAILED |                  | 2026-10-01 09:00 |
      | P6 | pr@club.tw     | 器材借用     | FAILED           |                  | 2026-09-30 09:00 |

  Rule: 前置：管理員、發佈者、撰稿者皆可查詢貼文列表

    Example: 三種角色查詢貼文列表
      When "president@club.tw" 查詢貼文列表
      Then 操作成功
      When "pr@club.tw" 查詢貼文列表
      Then 操作成功
      When "newbie@club.tw" 查詢貼文列表
      Then 操作成功

  Rule: 前置：停用的帳號無法查詢貼文列表

    Example: 停用的帳號查詢貼文列表
      When "retired@club.tw" 查詢貼文列表
      Then 操作失敗

  Rule: 後置：未篩選時列出所有使用者建立的貼文，撰稿者也可看到他人建立的貼文

    Example: 撰稿者查詢貼文列表，包含發佈者建立的貼文
      When "newbie@club.tw" 查詢貼文列表
      Then 操作成功
      And 查詢結果為：
        | id | creator        | status           |
        | P1 | newbie@club.tw | DRAFT            |
        | P2 | pr@club.tw     | SCHEDULED        |
        | P3 | pr@club.tw     | PUBLISHING       |
        | P4 | pr@club.tw     | PUBLISHED        |
        | P5 | pr@club.tw     | PARTIALLY_FAILED |
        | P6 | pr@club.tw     | FAILED           |

  Rule: 後置：依貼文狀態篩選時，只列出該狀態的貼文

    Example: 篩選已排程的貼文
      When "pr@club.tw" 查詢狀態為 "SCHEDULED" 的貼文列表
      Then 操作成功
      And 查詢結果為：
        | id | status    | scheduled_at     |
        | P2 | SCHEDULED | 2026-10-06 12:00 |

    Example: 篩選部分失敗的貼文
      When "pr@club.tw" 查詢狀態為 "PARTIALLY_FAILED" 的貼文列表
      Then 操作成功
      And 查詢結果為：
        | id | status           |
        | P5 | PARTIALLY_FAILED |

  Rule: 後置：查詢結果依建立時間由新到舊排序

    Example: 建立時間較新的貼文排在前面
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at | created_at       |
        | P7 | pr@club.tw | 社遊報名 | DRAFT  |              | 2026-10-05 09:30 |
      When "pr@club.tw" 查詢狀態為 "DRAFT" 的貼文列表
      Then 操作成功
      And 查詢結果依序為：
        | id | created_at       |
        | P7 | 2026-10-05 09:30 |
        | P1 | 2026-10-05 09:00 |

  Rule: 後置：建立時間相同時，依貼文 ID 由大到小排序
    # 範例中的 P 編號越大代表貼文 ID 越大

    Example: 兩則貼文建立時間相同
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at | created_at       |
        | P8 | pr@club.tw | 社遊報名 | DRAFT  |              | 2026-10-05 09:30 |
        | P9 | pr@club.tw | 器材盤點 | DRAFT  |              | 2026-10-05 09:30 |
      When "pr@club.tw" 查詢狀態為 "DRAFT" 的貼文列表
      Then 操作成功
      And 查詢結果依序為：
        | id | created_at       |
        | P9 | 2026-10-05 09:30 |
        | P8 | 2026-10-05 09:30 |
        | P1 | 2026-10-05 09:00 |

  Rule: 後置：未指定每頁筆數時，每頁 20 筆

    Example: 共 51 則貼文，查詢第 1 頁
      Given 系統中另有 45 則由 "pr@club.tw" 建立的草稿貼文
      When "pr@club.tw" 查詢貼文列表
      Then 操作成功
      And 查詢結果共 20 筆
      And 查詢結果的分頁資訊為：
        | page | page_size | total_count | total_pages | has_prev | has_next |
        | 1    | 20        | 51          | 3           | false    | true     |

  Rule: 前置：每頁筆數只能為 20、50 或 100

    Example: 每頁 50 筆
      Given 系統中另有 45 則由 "pr@club.tw" 建立的草稿貼文
      When "pr@club.tw" 查詢貼文列表，第 1 頁，每頁 50 筆
      Then 操作成功
      And 查詢結果共 50 筆
      And 查詢結果的分頁資訊為：
        | page | page_size | total_count | total_pages | has_prev | has_next |
        | 1    | 50        | 51          | 2           | false    | true     |

    Example: 每頁 100 筆
      Given 系統中另有 45 則由 "pr@club.tw" 建立的草稿貼文
      When "pr@club.tw" 查詢貼文列表，第 1 頁，每頁 100 筆
      Then 操作成功
      And 查詢結果共 51 筆

    Example: 每頁 30 筆
      When "pr@club.tw" 查詢貼文列表，第 1 頁，每頁 30 筆
      Then 操作失敗

  Rule: 後置：分頁資訊包含目前頁碼、每頁筆數、總筆數、總頁數、是否有上一頁與下一頁

    Example: 查詢最後一頁
      Given 系統中另有 45 則由 "pr@club.tw" 建立的草稿貼文
      When "pr@club.tw" 查詢貼文列表，第 3 頁，每頁 20 筆
      Then 操作成功
      And 查詢結果共 11 筆
      And 查詢結果的分頁資訊為：
        | page | page_size | total_count | total_pages | has_prev | has_next |
        | 3    | 20        | 51          | 3           | true     | false    |

  Rule: 後置：先篩選再分頁，總筆數為篩選後的筆數

    Example: 篩選草稿後分頁
      Given 系統中另有 45 則由 "pr@club.tw" 建立的草稿貼文
      When "pr@club.tw" 查詢狀態為 "DRAFT" 的貼文列表
      Then 操作成功
      And 查詢結果共 20 筆
      And 查詢結果的分頁資訊為：
        | page | page_size | total_count | total_pages | has_prev | has_next |
        | 1    | 20        | 46          | 3           | false    | true     |
