# 來源：FR-20、BR-06、情境二、BR-17、BR-20
Feature: 預覽貼文
  使用者在發佈前預覽貼文在各目標平台帳號呈現的文字與圖片。

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
      | id | creator    | content                                                              | status | scheduled_at |
      | P1 | pr@club.tw | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ | DRAFT  |              |
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                           |
      | JPEG   | 3       | 1080  | 1920   | https://media.test/poster.jpg |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name       |
      | ntu_guitar_threads |
      | ntu_guitar_ig      |
      | 公告               |

  Rule: 前置：管理員、發佈者、撰稿者皆可預覽貼文

    Example: 三種角色預覽貼文
      When "president@club.tw" 預覽貼文 "P1"
      Then 操作成功
      When "pr@club.tw" 預覽貼文 "P1"
      Then 操作成功
      When "newbie@club.tw" 預覽貼文 "P1"
      Then 操作成功

  Rule: 前置：停用的帳號無法預覽貼文

    Example: 停用的帳號預覽貼文
      When "retired@club.tw" 預覽貼文 "P1"
      Then 操作失敗

  Rule: 前置：貼文必須至少選擇 1 個目標平台帳號才能預覽
    # 提示「請先選擇至少一個目標平台帳號，再預覽貼文。」

    Example: 預覽沒有目標平台帳號的草稿
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 新生茶會 | DRAFT  |              |
      When "pr@club.tw" 預覽貼文 "P2"
      Then 操作失敗

  Rule: 後置：每個目標平台帳號各有一筆預覽，呈現貼文文字

    Example: 預覽社課公告在三個平台的文字
      When "pr@club.tw" 預覽貼文 "P1"
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | content                                                              |
        | Threads   | ntu_guitar_threads | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ |
        | Instagram | ntu_guitar_ig      | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ |
        | Discord   | 公告               | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ |

  Rule: 後置：Instagram 預覽顯示 Instagram 版本（裁切後）的圖片

    Example: 9:16 海報在 Instagram 預覽為 4:5
      When "pr@club.tw" 預覽貼文 "P1"
      Then 操作成功
      And 查詢結果包含：
        | platform  | account_name  | image_width | image_height |
        | Instagram | ntu_guitar_ig | 1080        | 1350         |

  Rule: 後置：Threads 與 Discord 預覽顯示原圖

    Example: 9:16 海報在 Threads 與 Discord 預覽為原圖
      When "pr@club.tw" 預覽貼文 "P1"
      Then 操作成功
      And 查詢結果包含：
        | platform | account_name       | image_url                     | image_width | image_height |
        | Threads  | ntu_guitar_threads | https://media.test/poster.jpg | 1080        | 1920         |
        | Discord  | 公告               | https://media.test/poster.jpg | 1080        | 1920         |

  Rule: 後置：只顯示已選擇的目標平台帳號的預覽

    Example: 只選擇 Discord 的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P3 | pr@club.tw | 新生茶會 | DRAFT  |              |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 預覽貼文 "P3"
      Then 操作成功
      And 查詢結果為：
        | platform | account_name | content  |
        | Discord  | 公告         | 新生茶會 |

  Rule: 後置：已選目標平台帳號在選擇後授權失效時，照常顯示該平台帳號的預覽，並標示授權已失效

    Example: Threads 與 Instagram 授權在選擇後到期，Discord 不受影響
      Given 現在時間為 "2027-01-01 10:00"
      When "pr@club.tw" 預覽貼文 "P1"
      Then 操作成功
      And 查詢結果為：
        | platform  | account_name       | auth_status |
        | Threads   | ntu_guitar_threads | 失效        |
        | Instagram | ntu_guitar_ig      | 失效        |
        | Discord   | 公告               | 有效        |
