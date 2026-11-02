# 來源：FR-12、BR-01、BR-11、BR-13、BR-17、BR-18、BR-20、BR-02
Feature: 修改貼文
  使用者修改尚未發佈的貼文內容。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 現在時間為 "2026-10-05 10:00"
    And 系統中有以下貼文：
      | id | creator        | content      | status    | scheduled_at     |
      | P1 | newbie@club.tw | 新生茶會     | DRAFT     |                  |
      | P2 | pr@club.tw     | 期末成發宣傳 | DRAFT     |                  |
      | P3 | pr@club.tw     | 社課公告     | SCHEDULED | 2026-10-06 12:00 |

  Rule: 前置：撰稿者只能修改自己建立的貼文

    Example: 撰稿者修改自己的貼文
      When "newbie@club.tw" 將貼文 "P1" 的內容修改為 "新生茶會改到週五"
      Then 操作成功

    Example: 撰稿者修改他人的貼文
      When "newbie@club.tw" 將貼文 "P2" 的內容修改為 "期末成發延期"
      Then 操作失敗
      And 貼文 "P2" 的內容為 "期末成發宣傳"

  Rule: 前置：管理員與發佈者可以修改他人建立的貼文

    Example: 發佈者修改撰稿者的貼文
      When "pr@club.tw" 將貼文 "P1" 的內容修改為 "新生茶會改到週五"
      Then 操作成功

    Example: 管理員修改發佈者的貼文
      When "president@club.tw" 將貼文 "P2" 的內容修改為 "期末成發延期"
      Then 操作成功

  Rule: 前置：停用的帳號無法修改貼文

    Example: 停用的帳號修改貼文
      When "retired@club.tw" 將貼文 "P2" 的內容修改為 "期末成發延期"
      Then 操作失敗
      And 貼文 "P2" 的內容為 "期末成發宣傳"

  Rule: 前置：只有草稿與已排程狀態的貼文可以修改

    Example: 修改已排程的貼文
      When "pr@club.tw" 將貼文 "P3" 的內容修改為 "社課改到 202"
      Then 操作成功

    Example: 修改非草稿、非已排程的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 將貼文 "P4" 的內容修改為 "修改"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P5" 的內容修改為 "修改"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P6" 的內容修改為 "修改"
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P7" 的內容修改為 "修改"
      Then 操作失敗

  Rule: 前置：貼文文字不可為空白

    Example: 內容修改為空字串
      When "pr@club.tw" 將貼文 "P2" 的內容修改為 ""
      Then 操作失敗
      And 貼文 "P2" 的內容為 "期末成發宣傳"

    Example: 內容修改為只有空白字元
      When "pr@club.tw" 將貼文 "P2" 的內容修改為 "   "
      Then 操作失敗
      And 貼文 "P2" 的內容為 "期末成發宣傳"

  Rule: 前置：已排程貼文修改後的文字長度不可超過所選目標平台中最嚴格的字數上限

    Example: 已排程貼文目標含 Threads，修改為 500 字元
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "pr@club.tw" 將貼文 "P3" 的內容修改為長度 500 字元的文字
      Then 操作成功

    Example: 已排程貼文目標含 Threads，修改為 501 字元
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      When "pr@club.tw" 將貼文 "P3" 的內容修改為長度 501 字元的文字
      Then 操作失敗
      And 貼文 "P3" 的內容為 "社課公告"
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：貼文內容更新為修改後的文字

    Example: 修改草稿內容
      When "pr@club.tw" 將貼文 "P2" 的內容修改為 "期末成發 12/20 晚上七點"
      Then 操作成功
      And 貼文 "P2" 的內容為 "期末成發 12/20 晚上七點"

  Rule: 後置：已排程貼文修改成功後維持已排程，排程時間不變

    Example: 修改已排程貼文的內容
      When "pr@club.tw" 將貼文 "P3" 的內容修改為 "社課改到 202"
      Then 操作成功
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"
