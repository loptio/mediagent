# 來源：FR-03、BR-17、BR-20
Feature: 查看幹部帳號
  管理員查看所有幹部帳號及其角色與狀態。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |

  Rule: 前置：只有管理員可以查看幹部帳號

    Example: 發佈者查看幹部帳號
      When "pr@club.tw" 查看幹部帳號列表
      Then 操作失敗

    Example: 撰稿者查看幹部帳號
      When "newbie@club.tw" 查看幹部帳號列表
      Then 操作失敗

  Rule: 前置：停用的帳號無法查看幹部帳號

    Example: 停用的管理員查看幹部帳號
      When "retired@club.tw" 查看幹部帳號列表
      Then 操作失敗

  Rule: 後置：列出所有幹部帳號及其角色與狀態（含停用的帳號）

    Example: 管理員查看幹部帳號列表
      When "president@club.tw" 查看幹部帳號列表
      Then 操作成功
      And 查詢結果為：
        | email             | name     | role   | status |
        | president@club.tw | 社長     | 管理員 | 啟用   |
        | pr@club.tw        | 公關     | 發佈者 | 啟用   |
        | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
        | retired@club.tw   | 前任社長 | 管理員 | 停用   |
