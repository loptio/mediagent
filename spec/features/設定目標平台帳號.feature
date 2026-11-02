# 來源：FR-10、需求 4.3、BR-05、BR-08、BR-09、BR-11、BR-13、BR-17、BR-18、BR-20、情境二、BR-02、BR-07
Feature: 設定目標平台帳號
  使用者為貼文選擇一個或多個目標平台帳號。

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
      | id | creator        | content      | status    | scheduled_at     |
      | P1 | newbie@club.tw | 新生茶會     | DRAFT     |                  |
      | P2 | pr@club.tw     | 期末成發宣傳 | DRAFT     |                  |
      | P3 | pr@club.tw     | 社課公告     | SCHEDULED | 2026-10-06 12:00 |

  Rule: 前置：撰稿者只能為自己建立的貼文設定目標平台帳號

    Example: 撰稿者為自己的貼文設定目標平台帳號
      When "newbie@club.tw" 將貼文 "P1" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
      Then 操作成功

    Example: 撰稿者為他人的貼文設定目標平台帳號
      When "newbie@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
      Then 操作失敗

  Rule: 前置：管理員與發佈者可以為他人建立的貼文設定目標平台帳號

    Example: 發佈者為撰稿者的貼文設定目標平台帳號
      When "pr@club.tw" 將貼文 "P1" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作成功

    Example: 管理員為發佈者的貼文設定目標平台帳號
      When "president@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作成功

  Rule: 前置：停用的帳號無法設定目標平台帳號

    Example: 停用的帳號設定目標平台帳號
      When "retired@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作失敗

  Rule: 前置：只有草稿與已排程狀態的貼文可以設定目標平台帳號

    Example: 為已排程貼文修改目標平台帳號
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作成功

    Example: 為非草稿、非已排程的貼文設定目標平台帳號
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 將貼文 "P4" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P5" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P6" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作失敗
      When "pr@club.tw" 將貼文 "P7" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作失敗

  Rule: 前置：同一則貼文不可重複選擇同一個平台帳號

    Example: 重複選擇同一個 Discord 頻道
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
        | 公告         |
      Then 操作失敗

  Rule: 前置：目標平台帳號必須是已連結的平台帳號

    Example: 選擇未連結的平台帳號
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name    |
        | not_linked_acct |
      Then 操作失敗

    Example: 選擇已移除的平台帳號
      Given 平台帳號 "ntu_guitar_threads" 已被移除
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
      Then 操作失敗

  Rule: 前置：目標平台帳號的授權狀態必須為有效

    Example: 選擇授權狀態為失效的平台帳號
      Given 系統中有以下平台帳號：
        | platform | account_name      | auth_status | auth_expires_at  | linked_by         |
        | Threads  | old_guitar_thread | 失效        | 2026-12-31 00:00 | president@club.tw |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name      |
        | old_guitar_thread |
      Then 操作失敗

  Rule: 前置：授權到期時間已過的平台帳號視為失效，不可選擇

    Example: 授權到期時間早於目前時間
      Given 系統中有以下平台帳號：
        | platform | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads  | expired_threads    | 有效        | 2026-10-05 09:59 | president@club.tw |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name    |
        | expired_threads |
      Then 操作失敗

  Rule: 前置：貼文沒有附加圖片時，Instagram 平台帳號不能被選為目標平台帳號

    Example: 沒有圖片的貼文選擇 Instagram
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name  |
        | ntu_guitar_ig |
      Then 操作失敗

    Example: 已附加圖片的貼文選擇 Instagram
      Given 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                          |
        | JPEG   | 2       | 1080  | 1350   | https://media.test/p2.jpg    |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name  |
        | ntu_guitar_ig |
      Then 操作成功

  Rule: 前置：已排程貼文的文字長度不可超過新目標平台中最嚴格的字數上限

    Example: 已排程貼文內容 501 字元，目標由 Discord 改為含 Threads
      Given 貼文 "P3" 的內容長度為 501 字元
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      Then 操作失敗
      And 貼文 "P3" 的目標平台帳號為：
        | platform | account_name |
        | Discord  | 公告         |
      And 貼文 "P3" 的狀態為 "SCHEDULED"

  Rule: 前置：草稿可以清空目標平台帳號
    # 立即發佈或設定排程時才要求至少 1 個目標平台帳號（BR-07）

    Example: 將草稿的目標平台帳號清空
      Given 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name |
      Then 操作成功
      And 貼文 "P2" 的目標平台帳號為：
        | platform | account_name |

  Rule: 前置：已排程貼文至少要保留 1 個目標平台帳號

    Example: 將已排程貼文的目標平台帳號清空
      Given 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name |
      Then 操作失敗
      And 貼文 "P3" 的目標平台帳號為：
        | platform | account_name |
        | Discord  | 公告         |

  Rule: 後置：貼文的目標平台帳號為所選的平台帳號

    Example: 選擇三個平台帳號
      Given 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                          |
        | JPEG   | 2       | 1080  | 1350   | https://media.test/p2.jpg    |
      When "pr@club.tw" 將貼文 "P2" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
        | ntu_guitar_ig      |
        | 公告               |
      Then 操作成功
      And 貼文 "P2" 的目標平台帳號為：
        | platform  | account_name       |
        | Threads   | ntu_guitar_threads |
        | Instagram | ntu_guitar_ig      |
        | Discord   | 公告               |

  Rule: 後置：已排程貼文設定目標平台帳號成功後維持已排程，排程時間不變

    Example: 已排程貼文改為只發佈到 Discord
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name |
        | 公告         |
      Then 操作成功
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：已排程貼文新增的目標平台帳號，建立一筆待發佈紀錄

    Example: 目標由 Threads＋Discord 改為 Discord＋Instagram，Instagram 新增待發佈紀錄
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄包含：
        | account_name       | status |
        | ntu_guitar_ig      | 待發佈 |

  Rule: 後置：已排程貼文被拿掉的目標平台帳號，其待發佈紀錄改為已取消

    Example: 目標由 Threads＋Discord 改為 Discord＋Instagram，Threads 改為已取消
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄包含：
        | account_name       | status |
        | ntu_guitar_threads | 已取消 |

  Rule: 後置：已排程貼文保留的目標平台帳號，發佈紀錄不變

    Example: 目標由 Threads＋Discord 改為 Discord＋Instagram，Discord 維持待發佈
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄包含：
        | account_name       | status |
        | 公告               | 待發佈 |

  Rule: 後置：已排程貼文修改目標平台帳號後，發佈紀錄只更新受影響的平台帳號（整合）

    Example: 目標由 Threads＋Discord 改為 Discord＋Instagram
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄為：
        | account_name       | status |
        | ntu_guitar_threads | 已取消 |
        | 公告               | 待發佈 |
        | ntu_guitar_ig      | 待發佈 |

  Rule: 後置：被拿掉的目標平台帳號的發佈紀錄狀態變更寫入變更歷程

    Example: Threads 由待發佈改為已取消的變更歷程
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor      | reason           |
        | P3   | ntu_guitar_threads | 待發佈      | 已取消    | 使用者     | pr@club.tw | 修改目標平台帳號 |

  Rule: 後置：已排程貼文把先前拿掉的目標平台帳號加回時，同一筆已取消紀錄改回待發佈，不新增紀錄

    Example: 社課公告先拿掉 Threads，再加回 Threads
      Given 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name       |
        | ntu_guitar_threads |
        | 公告               |
      Then 操作成功
      And 貼文 "P3" 的發佈紀錄為：
        | account_name       | status |
        | ntu_guitar_threads | 待發佈 |
        | 公告               | 待發佈 |
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor      | reason           |
        | P3   | ntu_guitar_threads | 已取消      | 待發佈    | 使用者     | pr@club.tw | 修改目標平台帳號 |

  Rule: 後置：已排程貼文新增目標平台帳號建立發佈紀錄時，寫入變更前狀態為空的變更歷程

    Example: 新增 Instagram 的建立歷程
      Given 貼文 "P3" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p3.jpg |
      And 貼文 "P3" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P3" 已有以下發佈紀錄：
        | account_name | status | published_at | post_url | failure_reason |
        | 公告         | 待發佈 |              |          |                |
      When "pr@club.tw" 將貼文 "P3" 的目標平台帳號設定為：
        | account_name  |
        | 公告          |
        | ntu_guitar_ig |
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name  | from_status | to_status | actor_type | actor      | reason           |
        | P3   | ntu_guitar_ig |             | 待發佈    | 使用者     | pr@club.tw | 新增目標平台帳號 |
