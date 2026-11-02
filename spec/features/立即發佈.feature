# 來源：FR-15、FR-17、BR-02、BR-05、BR-06、BR-07、BR-08、BR-09、BR-12、BR-14、BR-15、BR-17、BR-18、BR-20、NFR-03、NFR-05、需求 4.4、需求 4.5、需求 4.7、情境二、例外情境
Feature: 立即發佈
  發佈者與管理員將貼文立即發佈到所有目標平台帳號。
  受理後立即回應，各平台在背景發佈並逐筆更新發佈紀錄，全部結束後依結果更新貼文最終狀態。
  除「受理後」相關 Rule 外，其餘 Example 的 Then 皆驗證背景發佈全部結束後的結果。

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
    And 平台帳號 "ntu_guitar_threads" 的發佈結果為成功，平台貼文連結為 "https://threads.test/p/1"
    And 平台帳號 "ntu_guitar_ig" 的發佈結果為成功，平台貼文連結為 "https://instagram.test/p/1"
    And 平台帳號 "公告" 的發佈結果為成功，平台貼文連結為 "https://discord.test/m/1"

  Rule: 前置：撰稿者不能立即發佈

    Example: 撰稿者立即發佈自己的貼文
      When "newbie@club.tw" 立即發佈貼文 "P1"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：管理員與發佈者可以立即發佈

    Example: 發佈者立即發佈
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功

    Example: 管理員立即發佈
      When "president@club.tw" 立即發佈貼文 "P1"
      Then 操作成功

  Rule: 前置：停用的帳號無法立即發佈

    Example: 停用的發佈者立即發佈
      When "retired@club.tw" 立即發佈貼文 "P1"
      Then 操作失敗
      And 貼文 "P1" 的狀態為 "DRAFT"

  Rule: 前置：只有草稿與已排程狀態的貼文可以立即發佈

    Example: 立即發佈已排程的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P2 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作成功

    Example: 立即發佈非草稿、非已排程的貼文
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 立即發佈貼文 "P4"
      Then 操作失敗
      When "pr@club.tw" 立即發佈貼文 "P5"
      Then 操作失敗
      When "pr@club.tw" 立即發佈貼文 "P6"
      Then 操作失敗
      When "pr@club.tw" 立即發佈貼文 "P7"
      Then 操作失敗

  Rule: 前置：貼文必須至少選擇 1 個目標平台帳號

    Example: 沒有選擇任何目標平台帳號
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      When "pr@club.tw" 立即發佈貼文 "P2"
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
      When "pr@club.tw" 立即發佈貼文 "P2"
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
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作失敗
      And 貼文 "P2" 的狀態為 "DRAFT"

    Example: 目標只有 Discord，文字恰為 2000 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 2000 字元
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作成功

    Example: 目標只有 Discord，文字為 2001 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 2001 字元
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作失敗

    Example: 目標只有 Instagram，文字恰為 2200 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 2200 字元
      And 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作成功

    Example: 目標只有 Instagram，文字為 2201 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 2201 字元
      And 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作失敗

    Example: 目標為 Instagram 與 Discord，文字為 2001 字元
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 的內容長度為 2001 字元
      And 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
        | 公告          |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作失敗

  Rule: 前置：換行、中文字、一般 emoji、組合 emoji 依各平台官方定義計算字數
    # 各平台的實際算法需查官方 API 文件並以實際 API 驗證後，補上 Threads、Instagram、Discord 各自的 Example
    #TODO

  Rule: 前置：圖片寬高必須符合所有目標平台各自的尺寸限制
    # 各平台官方尺寸限制待查證（待確認），不得自行假設數值；不符合時提示不符合的平台及原因
    #TODO

  Rule: 前置：目標平台帳號含 Instagram 時，貼文必須附加圖片

    Example: 目標含 Instagram 但沒有圖片
      Given 系統中有以下貼文：
        | id | creator    | content  | status | scheduled_at |
        | P2 | pr@club.tw | 社課公告 | DRAFT  |              |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name  |
        | ntu_guitar_ig |
      When "pr@club.tw" 立即發佈貼文 "P2"
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
      When "pr@club.tw" 立即發佈貼文 "P2"
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
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作失敗

  Rule: 後置：受理後貼文狀態立即改為發佈中

    Example: 背景發佈尚未完成時，貼文為發佈中
      Given 平台帳號 "ntu_guitar_threads" 的發佈尚未完成
      And 平台帳號 "ntu_guitar_ig" 的發佈尚未完成
      And 平台帳號 "公告" 的發佈尚未完成
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PUBLISHING"

  Rule: 後置：草稿受理後立即為每個目標平台帳號建立待發佈的發佈紀錄

    Example: 背景發佈尚未完成時，三筆發佈紀錄皆為待發佈
      Given 平台帳號 "ntu_guitar_threads" 的發佈尚未完成
      And 平台帳號 "ntu_guitar_ig" 的發佈尚未完成
      And 平台帳號 "公告" 的發佈尚未完成
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 待發佈 |              |          |                |
        | ntu_guitar_ig      | 待發佈 |              |          |                |
        | 公告               | 待發佈 |              |          |                |

  Rule: 後置：背景發佈逐筆更新發佈紀錄，已完成的平台帳號不等待其他平台帳號

    Example: Threads 與 Discord 已完成，Instagram 尚未完成
      Given 平台帳號 "ntu_guitar_ig" 的發佈尚未完成
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
        | ntu_guitar_ig      | 待發佈 |                          |
        | 公告               | 成功   | https://discord.test/m/1 |
      And 貼文 "P1" 的狀態為 "PUBLISHING"

  Rule: 後置：每個目標平台帳號各有一筆發佈紀錄；成功者記錄發佈時間與平台貼文連結

    Example: 三個平台皆發佈成功
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄為：
        | account_name       | status | published_at     | post_url                   | failure_reason |
        | ntu_guitar_threads | 成功   | 2026-10-05 10:00 | https://threads.test/p/1   |                |
        | ntu_guitar_ig      | 成功   | 2026-10-05 10:00 | https://instagram.test/p/1 |                |
        | 公告               | 成功   | 2026-10-05 10:00 | https://discord.test/m/1   |                |

  Rule: 後置：發佈失敗的平台帳號記錄使用者可理解的失敗原因

    Example: Instagram 因平台暫時無法連線而失敗
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name  | status | post_url | failure_reason   |
        | ntu_guitar_ig | 失敗   |          | 平台暫時無法連線 |

    Example: 平台回應 Token 被撤銷，失敗原因為帳號授權失效
    # 授權失效與過期都會使平台帳號授權狀態改為失效，並提示重新連結
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為授權失效
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name  | status | post_url | failure_reason |
        | ntu_guitar_ig | 失敗   |          | 帳號授權失效   |

  Rule: 後置：發佈失敗時保存平台原始錯誤訊息，且其中不包含存取憑證

    Example: 平台錯誤訊息夾帶存取 Token
      Given 平台帳號 "ntu_guitar_ig" 的存取憑證為 "ig-secret-token"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，平台原始錯誤訊息為 "500 upstream error, token=ig-secret-token"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 在平台帳號 "ntu_guitar_ig" 的平台原始錯誤訊息不包含 "ig-secret-token"

  Rule: 後置：任一平台帳號發佈失敗不影響其他平台帳號的發佈

    Example: Instagram 失敗，Threads 與 Discord 仍發佈成功
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：單一平台帳號發佈逾時（30 秒）不影響其他平台帳號的發佈

    Example: Instagram 逾時，Threads 與 Discord 仍發佈成功
      Given 平台帳號 "ntu_guitar_ig" 的發佈逾時
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 成功   | https://threads.test/p/1 |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：所有目標平台帳號皆成功時，貼文狀態為發佈完成

    Example: 三個平台皆成功
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PUBLISHED"

  Rule: 後置：部分目標平台帳號成功、部分失敗時，貼文狀態為部分失敗

    Example: Instagram 失敗，其餘成功
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "PARTIALLY_FAILED"

  Rule: 後置：所有目標平台帳號皆失敗時，貼文狀態為全部失敗

    Example: 三個平台皆失敗
      Given 平台帳號 "ntu_guitar_threads" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      And 平台帳號 "公告" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的狀態為 "FAILED"

  Rule: 後置：Instagram 使用 Instagram 版本的圖片，Threads 與 Discord 使用原圖

    Example: 9:16 海報發佈到三個平台
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 平台帳號 "ntu_guitar_ig" 收到的圖片尺寸為 1080 x 1350
      And 平台帳號 "ntu_guitar_threads" 收到的圖片網址為 "https://media.test/poster.jpg"
      And 平台帳號 "公告" 收到的圖片網址為 "https://media.test/poster.jpg"

  Rule: 後置：寫入一筆「發佈貼文」稽核紀錄

    Example: 立即發佈後新增稽核紀錄
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action   | target_type | target |
        | 使用者     | pr@club.tw | 發佈貼文 | 貼文        | P1     |

    Example: 稽核紀錄保存當次各目標平台帳號的執行結果
      Given 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor_type | actor      | action   | target_type | target | result           |
        | 使用者     | pr@club.tw | 發佈貼文 | 貼文        | P1     | PARTIALLY_FAILED |
      And 該筆稽核紀錄的各目標執行結果為：
        | account_name       | status | failure_reason   |
        | ntu_guitar_threads | 成功   |                  |
        | ntu_guitar_ig      | 失敗   | 平台暫時無法連線 |
        | 公告               | 成功   |                  |

  Rule: 後置：發佈時平台明確回應授權失效，該平台帳號的授權狀態改為失效

    Example: Instagram 存取 Token 已被平台撤銷
      Given 現在時間為 "2026-10-05 10:00"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為授權失效
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 失效        |

  Rule: 後置：一般發佈失敗（例如平台暫時無法連線）不改變平台帳號的授權狀態

    Example: Instagram 因平台暫時無法連線而失敗
      Given 現在時間為 "2026-10-05 10:00"
      And 平台帳號 "ntu_guitar_ig" 的發佈結果為失敗，失敗原因為 "平台暫時無法連線"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 平台帳號 "ntu_guitar_ig" 的資料為：
        | account_name  | auth_status |
        | ntu_guitar_ig | 有效        |

  Rule: 後置：發佈逾時的平台帳號，發佈紀錄為失敗，失敗原因為「發佈逾時」

    Example: Instagram 發佈逾時
      Given 現在時間為 "2026-10-05 10:00"
      And 平台帳號 "ntu_guitar_ig" 的發佈逾時
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 貼文 "P1" 的發佈紀錄包含：
        | account_name  | status | post_url | failure_reason |
        | ntu_guitar_ig | 失敗   |          | 發佈逾時       |

  Rule: 後置：立即發佈已排程的貼文後，排程時間為空

    Example: 已排程貼文改為立即發佈
      Given 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P2 | pr@club.tw | 社課公告 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P2" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      When "pr@club.tw" 立即發佈貼文 "P2"
      Then 操作成功
      And 貼文 "P2" 的排程時間為空

  Rule: 後置：已排程貼文立即發佈時，沿用既有的待發佈紀錄，不新增紀錄；已取消的紀錄維持已取消，不發佈
    # 只有待發佈紀錄會被執行；其他狀態的紀錄依各自規則處理

    Example: 已排程貼文改為立即發佈
      Given 系統中有以下貼文：
        | id | creator    | content  | status    | scheduled_at     |
        | P9 | pr@club.tw | 社遊報名 | SCHEDULED | 2026-10-06 12:00 |
      And 貼文 "P9" 已選擇以下目標平台帳號：
        | account_name |
        | 公告         |
      And 貼文 "P9" 已有以下發佈紀錄：
        | account_name       | status | published_at | post_url | failure_reason |
        | ntu_guitar_threads | 已取消 |              |          |                |
        | 公告               | 待發佈 |              |          |                |
      When "pr@club.tw" 立即發佈貼文 "P9"
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 收到 0 則貼文
      And 貼文 "P9" 的發佈紀錄為：
        | account_name       | status | post_url                 |
        | ntu_guitar_threads | 已取消 |                          |
        | 公告               | 成功   | https://discord.test/m/1 |

  Rule: 後置：實際發佈時，發佈紀錄保存當次發佈的完整文字內容

    Example: 社課公告發佈後，各發佈紀錄保存完整文字
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | status | content_summary                                                      |
        | ntu_guitar_threads | 成功   | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ |
        | 公告               | 成功   | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ |

  Rule: 後置：實際發佈時，發佈紀錄保存送出圖片的識別資訊（雜湊值、格式、尺寸、版本），不保存圖片檔案

    Example: 9:16 海報發佈到三個平台
      Given 貼文 "P1" 的圖片原圖雜湊值為 "sha256-orig"，Instagram 版本雜湊值為 "sha256-ig"
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 貼文 "P1" 的發佈紀錄包含：
        | account_name       | image_sha256 | image_format | image_width | image_height | image_variant  |
        | ntu_guitar_threads | sha256-orig  | JPEG         | 1080        | 1920         | 原圖           |
        | ntu_guitar_ig      | sha256-ig    | JPEG         | 1080        | 1350         | Instagram 版本 |
        | 公告               | sha256-orig  | JPEG         | 1080        | 1920         | 原圖           |

  Rule: 後置：草稿立即發佈建立發佈紀錄時，寫入變更前狀態為空的變更歷程

    Example: 社課公告立即發佈的建立歷程
      Given 平台帳號 "ntu_guitar_threads" 的發佈尚未完成
      And 平台帳號 "ntu_guitar_ig" 的發佈尚未完成
      And 平台帳號 "公告" 的發佈尚未完成
      When "pr@club.tw" 立即發佈貼文 "P1"
      Then 操作成功
      And 發佈紀錄變更歷程包含：
        | post | account_name       | from_status | to_status | actor_type | actor      | reason   |
        | P1   | ntu_guitar_threads |             | 待發佈    | 使用者     | pr@club.tw | 立即發佈 |
        | P1   | ntu_guitar_ig      |             | 待發佈    | 使用者     | pr@club.tw | 立即發佈 |
        | P1   | 公告               |             | 待發佈    | 使用者     | pr@club.tw | 立即發佈 |
