# 來源：BR-12、BR-14、BR-15、BR-16、NFR-03
Feature: 發佈逾時恢復
  系統定期檢查發佈中的貼文；進入「發佈中」的時間距今大於或等於 10 分鐘、仍有待發佈紀錄時，啟動逾時恢復流程，確認實際結果後更新發佈紀錄與貼文狀態，使其能進入既有的重試流程。
  10 分鐘為整則貼文發佈任務的恢復門檻；單一平台帳號的發佈逾時門檻為 30 秒（NFR-03），兩者分開定義。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name | role   | status |
      | president@club.tw | 社長 | 管理員 | 啟用   |
      | pr@club.tw        | 公關 | 發佈者 | 啟用   |
    And 系統中有以下平台帳號：
      | platform | account_name       | auth_status | auth_expires_at  | linked_by         |
      | Threads  | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord  | 公告               | 有效        |                  | president@club.tw |
    And 系統中有以下貼文：
      | id | creator    | content  | status     | scheduled_at |
      | P1 | pr@club.tw | 社課公告 | PUBLISHING |              |
    And 貼文 "P1" 於 "2026-10-06 12:00" 進入發佈中
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | 公告               |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name       | status | published_at     | post_url                 | failure_reason |
      | ntu_guitar_threads | 待發佈 |                  |                          |                |
      | 公告               | 成功   | 2026-10-06 12:00 | https://discord.test/m/1 |                |

  Rule: 前置：只處理進入發佈中的時間距今大於或等於 10 分鐘、仍有待發佈紀錄的貼文

    Example: 進入發佈中 9 分 59 秒，不處理
      Given 現在時間為 "2026-10-06 12:09:59"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的狀態為 "PUBLISHING"
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status |
        | ntu_guitar_threads | 待發佈 |

    Example: 進入發佈中恰好 10 分鐘，處理
      Given 現在時間為 "2026-10-06 12:10:00"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

    Example: 進入發佈中 10 分 1 秒，處理
      Given 現在時間為 "2026-10-06 12:10:01"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：可透過平台查詢確認已發佈時，發佈紀錄記為成功，不重新發佈

    Example: Threads 查詢到貼文其實已發佈
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為已發佈，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |

  Rule: 後置：無法確認是否已發佈時，發佈紀錄記為失敗，失敗原因為「發佈逾時」，不重新發佈
    # 提示使用者先到平台確認是否已有貼文，再決定是否重試

    Example: Threads 無法查詢發佈結果
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | failure_reason |
        | ntu_guitar_threads | 失敗   | 發佈逾時       |

  Rule: 後置：依所有目標平台帳號的發佈紀錄重新計算貼文狀態

    Example: Threads 確認已發佈，貼文為發佈完成
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為已發佈，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的狀態為 "PUBLISHED"

    Example: Threads 無法確認，貼文為部分失敗，可進入重試
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：系統重新啟動時掃描未完成的發佈任務並執行恢復檢查，不直接重新發佈

    Example: 系統重新啟動，發佈中的貼文已超過 10 分鐘
      Given 現在時間為 "2026-10-06 12:30"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統重新啟動
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | failure_reason |
        | ntu_guitar_threads | 失敗   | 發佈逾時       |
      And 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：平台明確確認未發佈時，系統自動重新發佈到該平台帳號，結果出來前發佈紀錄維持待發佈

    Example: Threads 確認未發佈，自動重新發佈成功
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 平台帳號 "ntu_guitar_threads" 收到 1 則貼文
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
      And 貼文 "P1" 的狀態為 "PUBLISHED"

    Example: 自動重新發佈尚未完成時，紀錄維持待發佈
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      And 平台帳號 "ntu_guitar_threads" 的發佈尚未完成
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status |
        | ntu_guitar_threads | 待發佈 |

  Rule: 後置：自動重新發佈的結果依實際情況記錄

    Example: 自動重新發佈時平台暫時無法連線
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | failure_reason   |
        | ntu_guitar_threads | 失敗   | 平台暫時無法連線 |

  Rule: 前置：每筆發佈紀錄最多自動重新發佈 1 次
    # 已達上限且平台仍確認未發佈時，記為失敗、原因「發佈逾時」，不再自動重新發佈；使用者可手動重試

    Example: 已自動重新發佈過 1 次，不再自動重新發佈
      Given 現在時間為 "2026-10-06 12:30"
      And 貼文 "P1" 在平台帳號 "ntu_guitar_threads" 已自動重新發佈 1 次
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      When 系統執行發佈逾時恢復檢查
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文

  Rule: 後置：每次自動重新發佈寫入一筆「自動重試發佈」稽核紀錄，記錄原因、時間與結果

    Example: 自動重新發佈成功的稽核紀錄
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 系統新增一筆稽核紀錄：
        | actor_type | action       | target_type | target | reason         | result    | occurred_at      |
        | 系統       | 自動重試發佈 | 貼文        | P1     | 平台確認未發佈 | PUBLISHED | 2026-10-06 12:11 |
      And 該筆稽核紀錄的各目標執行結果為：
        | account_name       | status | failure_reason |
        | ntu_guitar_threads | 成功   |                |

  Rule: 後置：只有發佈紀錄狀態實際改變時才寫入變更歷程

    Example: 確認已發佈，寫入「發佈逾時恢復：已確認發佈」
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為已發佈，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | reason                     |
        | P1   | ntu_guitar_threads | 待發佈      | 成功      | 系統       | 發佈逾時恢復：已確認發佈 |

    Example: 無法確認，寫入「發佈逾時恢復：無法確認」
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 無法查詢發佈結果
      When 系統執行發佈逾時恢復檢查
      Then 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | reason                   |
        | P1   | ntu_guitar_threads | 待發佈      | 失敗      | 系統       | 發佈逾時恢復：無法確認 |

    Example: 確認未發佈並自動重新發佈成功，狀態只由待發佈變為成功一次
      Given 現在時間為 "2026-10-06 12:11"
      And 平台帳號 "ntu_guitar_threads" 查詢發佈結果為未發佈
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/1"
      When 系統執行發佈逾時恢復檢查
      Then 貼文 "P1" 在平台帳號 "ntu_guitar_threads" 的變更歷程為：
        | from_status | to_status | actor_type | reason               |
        | 待發佈      | 成功      | 系統       | 自動重試發佈：成功 |
