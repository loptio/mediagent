# 來源：FR-11、BR-11、BR-13、BR-17、BR-18、BR-20、BR-05
Feature: 移除圖片
  使用者移除貼文已附加的圖片。

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
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                       |
      | JPEG   | 2       | 1080  | 1080   | https://media.test/p1.jpg |
    And 貼文 "P2" 已附加以下圖片：
      | format | size_mb | width | height | url                       |
      | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
    And 貼文 "P3" 已附加以下圖片：
      | format | size_mb | width | height | url                       |
      | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |

  Rule: 前置：撰稿者只能移除自己建立的貼文的圖片

    Example: 撰稿者移除自己貼文的圖片
      When "newbie@club.tw" 移除貼文 "P1" 的圖片
      Then 操作成功

    Example: 撰稿者移除他人貼文的圖片
      When "newbie@club.tw" 移除貼文 "P2" 的圖片
      Then 操作失敗

  Rule: 前置：管理員與發佈者可以移除他人建立的貼文的圖片

    Example: 發佈者移除撰稿者貼文的圖片
      When "pr@club.tw" 移除貼文 "P1" 的圖片
      Then 操作成功

    Example: 管理員移除發佈者貼文的圖片
      When "president@club.tw" 移除貼文 "P2" 的圖片
      Then 操作成功

  Rule: 前置：停用的帳號無法移除圖片

    Example: 停用的帳號移除圖片
      When "retired@club.tw" 移除貼文 "P2" 的圖片
      Then 操作失敗

  Rule: 前置：只有草稿與已排程狀態的貼文可以移除圖片

    Example: 移除已排程貼文的圖片
      When "pr@club.tw" 移除貼文 "P3" 的圖片
      Then 操作成功

    Example: 移除已發佈貼文的圖片
      Given 系統中有以下貼文：
        | id | creator    | content | status    | scheduled_at |
        | P5 | pr@club.tw | 已發佈  | PUBLISHED |              |
      And 貼文 "P5" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p5.jpg |
      When "pr@club.tw" 移除貼文 "P5" 的圖片
      Then 操作失敗

  Rule: 前置：貼文的目標平台帳號含 Instagram 時，不能移除圖片
    # 操作失敗時提示使用者先取消選擇 Instagram

    Example: 草稿選擇了 Instagram，移除圖片
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
        | 公告          |
      When "pr@club.tw" 移除貼文 "P2" 的圖片
      Then 操作失敗
      And 貼文 "P2" 的圖片為：
        | format | width | height |
        | JPEG   | 1080  | 1080   |

    Example: 草稿取消選擇 Instagram 後，可以移除圖片
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
        | 公告          |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      And "pr@club.tw" 移除貼文 "P2" 的圖片
      Then 操作成功
      And 貼文 "P2" 沒有圖片

    Example: 已排程貼文選擇了 Instagram，移除圖片
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
        | 公告          |
      When "pr@club.tw" 移除貼文 "P3" 的圖片
      Then 操作失敗
      And 貼文 "P3" 的圖片為：
        | format | width | height |
        | JPEG   | 1080  | 1080   |
      And 貼文 "P3" 的狀態為 "SCHEDULED"

  Rule: 後置：貼文沒有圖片

    Example: 移除草稿的圖片
      When "pr@club.tw" 移除貼文 "P2" 的圖片
      Then 操作成功
      And 貼文 "P2" 沒有圖片

  Rule: 後置：已排程貼文移除圖片成功後維持已排程，排程時間不變

    Example: 已排程貼文只選擇 Discord，移除圖片
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Instagram | ntu_guitar_ig      | 有效        | 2026-12-31 00:00 | president@club.tw |
        | Discord   | 公告               | 有效        |                  | president@club.tw |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 移除貼文 "P3" 的圖片
      Then 操作成功
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"
