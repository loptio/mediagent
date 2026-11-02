# 來源：FR-09、BR-01、需求 4.3、需求 4.6、BR-17、BR-20
Feature: 建立貼文草稿
  使用者建立貼文草稿。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任公關 | 發佈者 | 停用   |

  Rule: 前置：管理員、發佈者、撰稿者皆可建立貼文草稿

    Example: 三種角色建立貼文草稿
      When "president@club.tw" 建立貼文草稿，內容為 "社員大會延期"
      Then 操作成功
      When "pr@club.tw" 建立貼文草稿，內容為 "期末成發宣傳"
      Then 操作成功
      When "newbie@club.tw" 建立貼文草稿，內容為 "新生茶會"
      Then 操作成功

  Rule: 前置：停用的帳號無法建立貼文草稿

    Example: 停用的帳號建立貼文草稿
      When "retired@club.tw" 建立貼文草稿，內容為 "社課公告"
      Then 操作失敗

  Rule: 前置：貼文文字不可為空白

    Example: 內容為空字串
      When "pr@club.tw" 建立貼文草稿，內容為 ""
      Then 操作失敗

    Example: 內容只有空白字元
      When "pr@club.tw" 建立貼文草稿，內容為 "   "
      Then 操作失敗

  Rule: 後置：新貼文的狀態為草稿、排程時間為空，建立者為執行建立的使用者

    Example: 發佈者建立社課公告草稿
      When "pr@club.tw" 建立貼文草稿，內容為 "本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！"
      Then 操作成功
      And 系統新增一則貼文：
        | creator    | content                                                              | status | scheduled_at |
        | pr@club.tw | 本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！ | DRAFT  |              |
