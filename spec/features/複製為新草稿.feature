# 來源：BR-13、BR-17、BR-18、BR-20、需求 4.5
Feature: 複製為新草稿
  使用者將一則貼文複製為新的草稿，保留內容與圖片，重新選擇目標平台帳號。
  用於已移除的平台帳號無法重試時，改以新草稿重新發佈。
  步驟中的「新草稿」指本次複製所建立的貼文。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |
    And 系統中有以下平台帳號：
      | platform | account_name | auth_status | auth_expires_at | linked_by         |
      | Discord  | 公告         | 有效        |                 | president@club.tw |
    And 現在時間為 "2026-10-07 10:00"
    And 系統中有以下貼文：
      | id | creator        | content  | status    | scheduled_at     |
      | P1 | pr@club.tw     | 社課公告 | FAILED    |                  |
      | P2 | newbie@club.tw | 新生茶會 | DRAFT     |                  |
      | P3 | pr@club.tw     | 社員大會 | PUBLISHED |                  |
      | P4 | pr@club.tw     | 期末成發 | SCHEDULED | 2026-10-08 12:00 |
    And 貼文 "P1" 已附加以下圖片：
      | format | size_mb | width | height | url                       |
      | JPEG   | 3       | 1080  | 1920   | https://media.test/p1.jpg |
    And 貼文 "P1" 已選擇以下目標平台帳號：
      | account_name |
      | 公告         |
    And 貼文 "P1" 已有以下發佈紀錄：
      | account_name | status | published_at | post_url | failure_reason   |
      | 公告         | 失敗   |              |          | 平台暫時無法連線 |

  Rule: 前置：撰稿者只能複製自己建立的貼文

    Example: 撰稿者複製自己的草稿
      When "newbie@club.tw" 將貼文 "P2" 複製為新草稿
      Then 操作成功

    Example: 撰稿者複製他人的貼文
      When "newbie@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作失敗

  Rule: 前置：管理員與發佈者可以複製任何人建立的貼文

    Example: 發佈者複製撰稿者的草稿
      When "pr@club.tw" 將貼文 "P2" 複製為新草稿
      Then 操作成功

    Example: 管理員複製發佈者的貼文
      When "president@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功

  Rule: 前置：停用的帳號無法複製貼文

    Example: 停用的帳號複製貼文
      When "retired@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作失敗

  Rule: 前置：任何狀態的貼文都可以複製

    Example: 複製全部失敗、草稿、發佈完成、已排程的貼文
      When "pr@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      When "pr@club.tw" 將貼文 "P2" 複製為新草稿
      Then 操作成功
      When "pr@club.tw" 將貼文 "P3" 複製為新草稿
      Then 操作成功
      When "pr@club.tw" 將貼文 "P4" 複製為新草稿
      Then 操作成功

  Rule: 後置：新增一則草稿，內容與來源貼文相同，建立者為執行複製的使用者，排程時間為空

    Example: 管理員複製發佈者全部失敗的社課公告
      When "president@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      And 系統新增一則貼文：
        | creator           | content  | status | scheduled_at |
        | president@club.tw | 社課公告 | DRAFT  |              |

  Rule: 後置：新草稿保留來源貼文的圖片

    Example: 複製附有 9:16 海報的貼文
      When "pr@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      And 新草稿的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1080  | 1920   | 1080     | 1350      |

  Rule: 後置：新草稿沒有目標平台帳號，也沒有發佈紀錄

    Example: 複製後需重新選擇目標
      When "pr@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      And 新草稿沒有目標平台帳號
      And 新草稿沒有發佈紀錄

  Rule: 後置：來源貼文的狀態、目標平台帳號與發佈紀錄不變

    Example: 複製後原貼文維持全部失敗
      When "pr@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      And 貼文 "P1" 的狀態為 "FAILED"
      And 貼文 "P1" 的目標平台帳號為：
        | platform | account_name |
        | Discord  | 公告         |
      And 貼文 "P1" 的發佈紀錄為：
        | account_name | status | failure_reason   |
        | 公告         | 失敗   | 平台暫時無法連線 |

  Rule: 後置：寫入一筆「複製為新草稿」稽核紀錄，記錄來源貼文與新草稿

    Example: 複製後新增稽核紀錄
      When "pr@club.tw" 將貼文 "P1" 複製為新草稿
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action       | target_type | target | related_post |
        | 使用者     | pr@club.tw | 複製為新草稿 | 貼文        | P1     | 新草稿       |
