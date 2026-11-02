# 來源：FR-16、BR-12、BR-14、BR-15、BR-22、NFR-01、需求 4.4、情境二、BR-08、BR-09
Feature: 執行排程發佈
  排程時間到時，系統自動將已排程的貼文發佈到所有目標平台帳號。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
    And 系統中有以下平台帳號：
      | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
      | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord   | 公告               | 有效        |                  | president@club.tw |
    And 系統中有以下貼文：
      | id | creator    | content                                                              | status    | scheduled_at     |
      | P1 | pr@club.tw | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ | SCHEDULED | 2026-10-06 12:00 |
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                           |
      | JPEG   | 3       | 1080  | 1920   | https://media.test/poster.jpg |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | ntu_guitar_ig      |
      | 公告               |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name       | status | published_at | post_url | failure_reason |
      | ntu_guitar_threads | 待發佈 |              |          |                |
      | ntu_guitar_ig      | 待發佈 |              |          |                |
      | 公告               | 待發佈 |              |          |                |
    And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/1"
    And 平台帳號 "ntu_guitar_ig" 的發佈結果為成功，平台貼文連結為 "https://instagram.test/p/1"
    And 平台帳號 "公告" 的發佈結果為成功，平台貼文連結為 "https://discord.test/m/1"

  Rule: 前置：只發佈排程時間已到的已排程貼文

    Example: 排程時間恰好到達
      Given 現在時間為 "2026-10-06 12:00"
      When 系統執行排程發佈
      Then 貼文 "P1" 的狀態為 "PUBLISHED"

    Example: 排程時間尚未到達
      Given 現在時間為 "2026-10-06 11:59"
      When 系統執行排程發佈
      Then 貼文 "P1" 的狀態為 "SCHEDULED"
      And 平台帳號 "ntu_guitar_threads" 收到 0 則貼文

  Rule: 前置：草稿狀態的貼文不會被排程發佈

    Example: 草稿不被發佈
      Given 現在時間為 "2026-10-06 12:00"
      And 系統中有以下貼文：
        | id | creator    | content      | status | scheduled_at |
        | P2 | pr@club.tw | 期末成發宣傳 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When 系統執行排程發佈
      Then 貼文 "P2" 的狀態為 "DRAFT"

  Rule: 後置：排程貼文於排程時間後 10 分鐘內開始發佈
    #TODO

  Rule: 後置：待發佈的發佈紀錄更新為成功或失敗；成功者記錄發佈時間與平台貼文連結

    Example: 週二 12:00 後三個平台皆發佈成功
      Given 現在時間為 "2026-10-06 12:05"
      When 系統執行排程發佈
      Then 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | published_at     | post_url                   | failure_reason |
        | ntu_guitar_threads | 成功   | 2026-10-06 12:05 | https://threads.test/p/1   |                |
        | ntu_guitar_ig      | 成功   | 2026-10-06 12:05 | https://instagram.test/p/1 |                |
        | 公告               | 成功   | 2026-10-06 12:05 | https://discord.test/m/1   |                |

  Rule: 後置：任一平台帳號發佈失敗不影響其他平台帳號的發佈

    Example: Instagram 失敗，Threads 與 Discord 仍發佈成功
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | post_url                 | failure_reason   |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |                  |
        | ntu_guitar_ig      | 失敗   |                          | 平台暫時無法連線 |
        | 公告               | 成功   | https://discord.test/m/1 |                  |

  Rule: 後置：所有目標平台帳號皆成功時，貼文狀態為發佈完成

    Example: 三個平台皆成功
      Given 現在時間為 "2026-10-06 12:05"
      When 系統執行排程發佈
      Then 貼文 "P1" 的狀態為 "PUBLISHED"

  Rule: 後置：部分目標平台帳號成功、部分失敗時，貼文狀態為部分失敗

    Example: Instagram 失敗，其餘成功
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

    Example: Instagram 授權在排程後到期，其餘成功
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下平台帳號：
        | platform  | account_name | auth_status | auth_expires_at  | linked_by         |
        | Instagram | expired_ig   | 有效        | 2026-10-06 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P4 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p4.jpg |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name |
        | expired_ig   |
        | 公告         |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | expired_ig   | 待發佈 |              |          |                |
        | 公告         | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 貼文 "P4" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：所有目標平台帳號皆失敗時，貼文狀態為全部失敗

    Example: 三個平台皆失敗
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_threads" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      And 平台帳號 "公告" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 貼文 "P1" 的狀態為 "FAILED"

  Rule: 前置：跳過已取消的發佈紀錄，不發佈到該平台帳號

    Example: Threads 帳號已被移除，排程時只發佈到其餘平台帳號
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P3 | pr@club.tw | 迎新宿營 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P3" 的發佈紀錄為：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 已取消 |                          |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：授權失效的目標平台帳號發佈失敗，失敗原因為「帳號授權過期」，不發送到該平台

    Example: Instagram 授權於設定排程後到期
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下平台帳號：
        | platform  | account_name | auth_status | auth_expires_at  | linked_by         |
        | Instagram | expired_ig   | 有效        | 2026-10-06 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P4 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P4" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p4.jpg |
      And 貼文 "P4" 已選擇以下目標平台帳號：
        | account_name |
        | expired_ig   |
        | 公告         |
      And 貼文 "P4" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | expired_ig   | 待發佈 |              |          |                |
        | 公告         | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 平台帳號 "expired_ig" 收到 0 則貼文
      And 貼文 "P4" 的發佈紀錄為：
        | account_name | status | post_url                 | failure_reason |
        | expired_ig   | 失敗   |                          | 帳號授權過期   |
        | 公告         | 成功   | https://discord.test/m/1 |                |

  Rule: 後置：授權狀態為失效的目標平台帳號，同樣發佈失敗，失敗原因為「帳號授權過期」

    Example: Threads 授權狀態已標示為失效
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下平台帳號：
        | platform | account_name      | auth_status | auth_expires_at  | linked_by         |
        | Threads  | old_guitar_thread | 失效        | 2026-12-31 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P5 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P5" 已選擇以下目標平台帳號：
        | account_name      |
        | old_guitar_thread |
      And 貼文 "P5" 已有以下發佈紀錄：
        | account_name      | status | published_at | post_url | failure_reason |
        | old_guitar_thread | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 貼文 "P5" 的發佈紀錄為：
        | account_name      | status | post_url | failure_reason |
        | old_guitar_thread | 失敗   |          | 帳號授權過期   |
      And 貼文 "P5" 的狀態為 "FAILED"

  Rule: 後置：發佈時平台明確回應授權失效，該平台帳號的授權狀態改為失效

    Example: Instagram 存取 Token 已被平台撤銷
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為授權失效
      When 系統執行排程發佈
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 失效        |

  Rule: 後置：一般發佈失敗（例如平台暫時無法連線）不改變平台帳號的授權狀態

    Example: Instagram 因平台暫時無法連線而失敗
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 有效        |

  Rule: 後置：發佈逾時的平台帳號，發佈紀錄為失敗，失敗原因為「發佈逾時」

    Example: Instagram 發佈逾時
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈逾時
      When 系統執行排程發佈
      Then 貼文 "P1" 的發佈紀錄包含：
        | account_name  | status | post_url | failure_reason |
        | ntu_guitar_ig | 失敗   |          | 發佈逾時       |

  Rule: 前置：建立者帳號已停用的已排程貼文，仍依原排程發佈
    # 授權失效、已取消等其他發佈條件仍依各自 Rule 處理

    Example: 前任公關的已排程貼文照常發佈
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下使用者帳號：
        | email           | name     | role   | status |
        | retired@club.tw | 前任公關 | 發佈者 | 停用   |
      And 系統中有以下貼文：
        | id | creator         | content  | status    | scheduled_at     |
        | P6 | retired@club.tw | 迎新宿營 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P6" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 貼文 "P6" 的發佈紀錄為：
        | account_name | status | post_url                 |
        | 公告         | 成功   | https://discord.test/m/1 |
      And 貼文 "P6" 的狀態為 "PUBLISHED"

  Rule: 後置：寫入一筆「發佈貼文」稽核紀錄，操作者為系統，並記錄排程設定者與貼文建立者

    Example: 社課公告排程發佈後新增系統稽核紀錄
      Given 現在時間為 "2026-10-06 12:05"
      And 貼文 "P1" 由 "president@club.tw" 設定排程
      When 系統執行排程發佈
      Then 系統新增一筆稽核紀錄：
        | actor_type | actor | action   | target_type | target | scheduled_by      | post_creator | result    |
        | 系統       |       | 發佈貼文 | 貼文        | P1     | president@club.tw | pr@club.tw   | PUBLISHED |

  Rule: 後置：系統的「發佈貼文」稽核紀錄保存當次各目標平台帳號的執行結果

    Example: Instagram 失敗，其餘成功
      Given 現在時間為 "2026-10-06 12:05"
      And 貼文 "P1" 由 "pr@club.tw" 設定排程
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 系統新增一筆稽核紀錄：
        | actor_type | action   | target | result           |
        | 系統       | 發佈貼文 | P1     | PARTIALLY_FAILED |
      And 該筆稽核紀錄的各目標執行結果為：
        | account_name       | status | failure_reason   |
        | ntu_guitar_threads | 成功   |                  |
        | ntu_guitar_ig      | 失敗   | 平台暫時無法連線 |
        | 公告               | 成功   |                  |

  Rule: 後置：背景發佈完成時，發佈紀錄的狀態變更寫入變更歷程，操作者為系統

    Example: 排程發佈的變更歷程
      Given 現在時間為 "2026-10-06 12:05"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When 系統執行排程發佈
      Then 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | reason         |
        | P1   | ntu_guitar_threads | 待發佈      | 成功      | 系統       | 發佈貼文：成功 |
        | P1   | ntu_guitar_ig      | 待發佈      | 失敗      | 系統       | 發佈貼文：失敗 |
        | P1   | 公告               | 待發佈      | 成功      | 系統       | 發佈貼文：成功 |

  Rule: 後置：發佈內容以實際發佈當下的文字保存，排程後修改過的內容以修改後為準

    Example: 排程後修改內容，發佈時保存修改後的文字
      Given 現在時間為 "2026-10-06 12:05"
      And 系統中有以下貼文：
        | id | creator    | content          | status    | scheduled_at     |
        | P7 | pr@club.tw | 社課改到 202 教室 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P7" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 待發佈 |              |          |                |
      When 系統執行排程發佈
      Then 貼文 "P7" 的發佈紀錄為：
        | account_name | status | content_summary   |
        | 公告         | 成功   | 社課改到 202 教室 |
