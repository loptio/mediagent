# 來源：FR-16、BR-02、BR-05、BR-07、BR-08、BR-09、BR-10、BR-11、BR-12、BR-17、BR-18、BR-20、需求 4.5、情境二
Feature: 設定排程
  發佈者與管理員為貼文設定排程時間，系統於該時間自動發佈到所有目標平台帳號。

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
      | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
      | Discord   | 公告               | 有效        |                  | president@club.tw |
    And 現在時間為 "2026-10-05 10:00"
    And 系統中有以下貼文：
      | id | creator        | content                                                              | status | scheduled_at |
      | P1 | newbie@club.tw | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ | DRAFT  |              |
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                           |
      | JPEG   | 3       | 1080  | 1920   | https://media.test/poster.jpg |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | ntu_guitar_ig      |
      | 公告               |

  Rule: 前置：撰稿者不能為草稿設定排程

    Example: 撰稿者為自己的草稿設定排程
      When "newbie@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：撰稿者可以修改自己建立的已排程貼文的排程時間

    Example: 撰稿者修改自己已排程貼文的排程時間
      Given 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P6 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
        | P7 | pr@club.tw     | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "newbie@club.tw" 將貼文 "P6" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P6" 的狀態為 "SCHEDULED"
      And 貼文 "P6" 的排程時間為 "2026-10-07 12:00"

  Rule: 前置：撰稿者不能修改他人建立的已排程貼文的排程時間

    Example: 撰稿者修改發佈者已排程貼文的排程時間
      Given 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P6 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
        | P7 | pr@club.tw     | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "newbie@club.tw" 將貼文 "P7" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作失敗
      And 貼文 "P7" 的排程時間為 "2026-10-06 12:00"

  Rule: 前置：管理員與發佈者可以設定新排程，也可以修改任何已排程貼文的排程時間

    Example: 發佈者修改撰稿者已排程貼文的排程時間
      Given 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P6 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
        | P7 | pr@club.tw     | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 將貼文 "P6" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P6" 的排程時間為 "2026-10-07 12:00"

    Example: 發佈者設定排程
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功

    Example: 管理員設定排程
      When "president@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功

  Rule: 前置：停用的帳號無法設定排程

    Example: 停用的發佈者設定排程
      When "retired@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：只有草稿與已排程狀態的貼文可以設定排程時間

    Example: 修改已排程貼文的排程時間
      Given 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P2 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P2" 的排程時間為 "2026-10-07 12:00"

    Example: 為非草稿、非已排程的貼文設定排程
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 將貼文 "P4" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P5" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P6" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P7" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗

  Rule: 前置：排程時間必須晚於目前時間
    # 時間以台灣時間輸入，比較時統一轉為 UTC

    Example: 排程時間為目前時間後的下一個 5 分鐘刻度
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-05 10:05"
      Then 操作成功

    Example: 排程時間等於目前時間
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-05 10:00"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

    Example: 排程時間早於目前時間
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-04 12:00"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：排程時間必須以 5 分鐘為單位（分鐘數為 5 的倍數，秒數為 0）

    Example: 排程時間為 12:05
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:05"
      Then 操作成功

    Example: 排程時間為 12:03
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:03"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：貼文必須至少選擇 1 個目標平台帳號

    Example: 沒有選擇任何目標平台帳號
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      And 貼文 "P2" 的狀態為 "DRAFT"

  Rule: 前置：貼文文字長度不可超過所選目標平台中最嚴格的字數上限
    # 字數依各平台官方定義分別計算；本 Rule 的邊界 Example 以英文字母產生文字，三個平台皆算 1 字元

    Example: 目標含 Threads，文字恰為 500 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 500 字元
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功

    Example: 目標含 Threads，文字為 501 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 501 字元
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      And 貼文 "P2" 的狀態為 "DRAFT"

  Rule: 前置：圖片寬高必須符合所有目標平台各自的尺寸限制
    # 各平台官方尺寸限制待查證（待確認），不得自行假設數值；不符合時提示不符合的平台及原因
    #TODO

  Rule: 前置：目標平台帳號含 Instagram 時，貼文必須附加圖片

    Example: 選擇 Instagram 但沒有圖片
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗
      And 貼文 "P2" 的狀態為 "DRAFT"

  Rule: 前置：目標平台帳號的授權狀態必須為有效

    Example: 目標平台帳號的授權狀態為失效
      Given 系統中有以下平台帳號：
        | platform | account_name      | auth_status | auth_expires_at  | linked_by         |
        | Threads  | old_guitar_thread | 失效        | 2026-12-31 00:00 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name      |
        | old_guitar_thread |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗

  Rule: 前置：授權到期時間已過的目標平台帳號視為失效

    Example: 目標平台帳號的授權到期時間早於目前時間
      Given 系統中有以下平台帳號：
        | platform | account_name    | auth_status | auth_expires_at  | linked_by         |
        | Threads  | expired_threads | 有效        | 2026-10-05 09:59 | president@club.tw |
      And 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name    |
        | expired_threads |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作失敗

  Rule: 後置：貼文狀態為已排程，排程時間為設定的時間

    Example: 社課公告排程於週二 12:00
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "SCHEDULED"
      And 貼文 "P1" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：為每個目標平台帳號建立一筆狀態為待發佈的發佈紀錄

    Example: 社課公告排程後，三個目標平台帳號各有一筆待發佈紀錄
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | ntu_guitar_ig      | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |

  Rule: 後置：已取消排程的貼文重新設定排程時，已取消的發佈紀錄改回待發佈，不新增紀錄

    Example: 取消排程後重新排程
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P2" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 已取消 |              |          |                |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P2" 的發佈紀錄為：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 待發佈 |              |          |                |

  Rule: 後置：寫入一筆「設定排程」稽核紀錄

    Example: 設定排程後新增稽核紀錄
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor      | action   | target_type | target |
        | pr@club.tw | 設定排程 | 貼文        | P1     |

    Example: 取消排程後重新排程，同樣寫入「設定排程」稽核紀錄
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P2" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 已取消 |              |          |                |
      When "pr@club.tw" 將貼文 "P2" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor      | action   | target_type | target |
        | pr@club.tw | 設定排程 | 貼文        | P2     |

    Example: 撰稿者修改自己已排程貼文的排程時間，寫入「設定排程」稽核紀錄
      Given 系統中有以下貼文：
        | id | creator        | content  | status    | scheduled_at     |
        | P6 | newbie@club.tw | 新生茶會 | SCHEDULED | 2026-10-06 12:00 |
        | P7 | pr@club.tw     | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P6" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P7" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "newbie@club.tw" 將貼文 "P6" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor          | action   | target_type | target |
        | newbie@club.tw | 設定排程 | 貼文        | P6     |

  Rule: 後置：排程時間以台灣時間輸入，以 UTC 儲存

    Example: 台灣時間 2026-10-06 12:00 儲存為 UTC 2026-10-06T04:00:00Z
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 貼文 "P1" 排程時間的儲存值為 "2026-10-06T04:00:00Z"

  Rule: 後置：貼文的排程設定者為最後一次成功設定排程的使用者

    Example: 發佈者設定排程後成為排程設定者
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 貼文 "P1" 的排程設定者為 "pr@club.tw"

    Example: 管理員修改排程時間後，排程設定者改為管理員
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      And "president@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P1" 的排程設定者為 "president@club.tw"

    Example: 設定排程失敗時，排程設定者不變
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      And "president@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-04 12:00"
      Then 操作失敗
      And 貼文 "P1" 的排程設定者為 "pr@club.tw"

  Rule: 後置：取消排程後修改目標再重新排程時，仍是目標的已取消紀錄改回待發佈、新目標建立待發佈紀錄、已不是目標的維持已取消

    Example: 取消排程後目標由 Threads＋Discord 改為 Discord＋Instagram，再重新排程
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P8 | pr@club.tw | 社遊報名 | DRAFT  |              |
      And 貼文 "P8" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p8.jpg |
      And 貼文 "P8" 已選擇以下目標平台帳號：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      And 貼文 "P8" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 已取消 |              |          |                |
      When "pr@club.tw" 將貼文 "P8" 的排程時間設定為 "2026-10-07 12:00"
      Then 操作成功
      And 貼文 "P8" 的發佈紀錄為：
        | account_name       | status |
        | ntu_guitar_threads | 已取消 |
        | 公告               | 待發佈 |
        | ntu_guitar_ig      | 待發佈 |
      And 發佈紀錄變更歷程包含：
        | post | account_name | from_status | to_status | actor_type | actor      | reason   |
        | P8   | 公告         | 已取消      | 待發佈    | 使用者     | pr@club.tw | 重新排程 |

  Rule: 後置：設定排程建立發佈紀錄時，寫入變更前狀態為空的變更歷程

    Example: 社課公告排程後的建立歷程
      When "pr@club.tw" 將貼文 "P1" 的排程時間設定為 "2026-10-06 12:00"
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor      | reason   |
        | P1   | ntu_guitar_threads |             | 待發佈    | 使用者     | pr@club.tw | 設定排程 |
        | P1   | ntu_guitar_ig      |             | 待發佈    | 使用者     | pr@club.tw | 設定排程 |
        | P1   | 公告               |             | 待發佈    | 使用者     | pr@club.tw | 設定排程 |
