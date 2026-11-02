# 來源：FR-04、情境一（換屆）、BR-17、BR-19、BR-20、BR-21、需求 4.5
Feature: 調整角色
  管理員調整幹部帳號的角色，包含將幹部設為管理員以完成換屆。

  Background:
    Given 系統中有以下使用者帳號：
      | email             | name     | role   | status |
      | president@club.tw | 社長     | 管理員 | 啟用   |
      | pr@club.tw        | 公關     | 發佈者 | 啟用   |
      | newbie@club.tw    | 新進幹部 | 撰稿者 | 啟用   |
      | retired@club.tw   | 前任社長 | 管理員 | 停用   |

  Rule: 前置：只有管理員可以調整角色

    Example: 發佈者調整他人角色
      When "pr@club.tw" 將 "newbie@club.tw" 的角色調整為 "發佈者"
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的角色為 "撰稿者"

    Example: 撰稿者調整自己的角色
      When "newbie@club.tw" 將 "newbie@club.tw" 的角色調整為 "管理員"
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的角色為 "撰稿者"

  Rule: 前置：停用的帳號無法調整角色

    Example: 停用的管理員調整他人角色
      When "retired@club.tw" 將 "newbie@club.tw" 的角色調整為 "發佈者"
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的角色為 "撰稿者"

  Rule: 前置：角色必須為管理員、發佈者、撰稿者三者之一

    Example: 調整為不存在的角色
      When "president@club.tw" 將 "newbie@club.tw" 的角色調整為 "社員"
      Then 操作失敗
      And 使用者帳號 "newbie@club.tw" 的角色為 "撰稿者"

  Rule: 前置：最後一位啟用中的管理員不可被調整為其他角色

    Example: 唯一啟用中的管理員將自己調整為發佈者
      When "president@club.tw" 將 "president@club.tw" 的角色調整為 "發佈者"
      Then 操作失敗
      And 使用者帳號 "president@club.tw" 的角色為 "管理員"

    Example: 尚有另一位啟用中的管理員時，可將自己調整為其他角色
      Given 使用者帳號 "pr@club.tw" 的角色已設為 "管理員"
      When "president@club.tw" 將 "president@club.tw" 的角色調整為 "發佈者"
      Then 操作成功
      And 使用者帳號 "president@club.tw" 的角色為 "發佈者"

  Rule: 後置：被調整帳號的角色更新為指定角色

    Example: 換屆：將新任幹部設為管理員
      When "president@club.tw" 將 "pr@club.tw" 的角色調整為 "管理員"
      Then 操作成功
      And 使用者帳號 "pr@club.tw" 的角色為 "管理員"

    Example: 將撰稿者調整為發佈者
      When "president@club.tw" 將 "newbie@club.tw" 的角色調整為 "發佈者"
      Then 操作成功
      And 使用者帳號 "newbie@club.tw" 的角色為 "發佈者"

  Rule: 後置：可以調整已停用帳號的角色，帳號維持停用

    Example: 將停用的前任社長角色調整為發佈者
      When "president@club.tw" 將 "retired@club.tw" 的角色調整為 "發佈者"
      Then 操作成功
      And 使用者帳號 "retired@club.tw" 的資料為：
        | email           | role   | status |
        | retired@club.tw | 發佈者 | 停用   |

  Rule: 後置：調整角色不影響已連結的平台帳號

    Example: 連結者被調整角色後，其連結的平台帳號不變
      Given 系統中有以下平台帳號：
        | platform  | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads   | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |
      And 使用者帳號 "pr@club.tw" 的角色已設為 "管理員"
      When "pr@club.tw" 將 "president@club.tw" 的角色調整為 "發佈者"
      Then 操作成功
      And 平台帳號 "ntu_guitar_threads" 的資料為：
        | platform | account_name       | auth_status | auth_expires_at  | linked_by         |
        | Threads  | ntu_guitar_threads | 有效        | 2026-12-31 00:00 | president@club.tw |

  Rule: 後置：寫入一筆「調整角色」稽核紀錄

    Example: 調整角色後新增稽核紀錄
      When "president@club.tw" 將 "pr@club.tw" 的角色調整為 "管理員"
      Then 操作成功
      And 系統新增一筆稽核紀錄：
        | actor             | action   | target_type | target     |
        | president@club.tw | 調整角色 | 使用者帳號  | pr@club.tw |
