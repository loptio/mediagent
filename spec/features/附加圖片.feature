# 來源：FR-11、需求 4.3.1、BR-03、BR-04、BR-06、BR-11、BR-13、BR-17、BR-18、BR-20、情境二
Feature: 附加圖片
  使用者為貼文附加一張圖片。

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

  Rule: 前置：撰稿者只能為自己建立的貼文附加圖片

    Example: 撰稿者為自己的貼文附加圖片
      When "newbie@club.tw" 為貼文 "P1" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功

    Example: 撰稿者為他人的貼文附加圖片
      When "newbie@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗
      And 貼文 "P2" 沒有圖片

  Rule: 前置：管理員與發佈者可以為他人建立的貼文附加圖片

    Example: 發佈者為撰稿者的貼文附加圖片
      When "pr@club.tw" 為貼文 "P1" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功

    Example: 管理員為發佈者的貼文附加圖片
      When "president@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功

  Rule: 前置：停用的帳號無法附加圖片

    Example: 停用的帳號附加圖片
      When "retired@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗
      And 貼文 "P2" 沒有圖片

  Rule: 前置：只有草稿與已排程狀態的貼文可以附加圖片

    Example: 為已排程貼文附加圖片
      When "pr@club.tw" 為貼文 "P3" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功

    Example: 為非草稿、非已排程的貼文附加圖片
      Given 系統中有以下貼文：
        | id | creator    | content  | status           | scheduled_at |
        | P4 | pr@club.tw | 發佈中   | PUBLISHING       |              |
        | P5 | pr@club.tw | 已發佈   | PUBLISHED        |              |
        | P6 | pr@club.tw | 部分失敗 | PARTIALLY_FAILED |              |
        | P7 | pr@club.tw | 全部失敗 | FAILED           |              |
      When "pr@club.tw" 為貼文 "P4" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗
      When "pr@club.tw" 為貼文 "P5" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗
      When "pr@club.tw" 為貼文 "P6" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗
      When "pr@club.tw" 為貼文 "P7" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作失敗

  Rule: 前置：每則貼文最多附加一張圖片

    Example: 已有圖片的貼文再附加一張圖片
      Given 貼文 "P2" 已附加以下圖片：
        | format | size_mb | width | height | url                       |
        | JPEG   | 2       | 1080  | 1080   | https://media.test/p2.jpg |
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 1080  | 1350   |
      Then 操作失敗

  Rule: 前置：圖片格式必須為 JPEG

    Example: 附加 PNG 圖片
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | PNG    | 2       | 1080  | 1080   |
      Then 操作失敗
      And 貼文 "P2" 沒有圖片

  Rule: 前置：圖片檔案大小不可超過 8 MB（8,000,000 位元組）
    # 1 MB = 1,000,000 位元組；其他 Example 的 size_mb 亦依此換算

    Example: 檔案大小恰為 8,000,000 位元組
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_bytes | width | height |
        | JPEG   | 8000000    | 1080  | 1080   |
      Then 操作成功

    Example: 檔案大小為 8,000,001 位元組
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_bytes | width | height |
        | JPEG   | 8000001    | 1080  | 1080   |
      Then 操作失敗
      And 貼文 "P2" 沒有圖片

  Rule: 後置：0.8 ≤ 寬度 / 高度 ≤ 1.91（4:5 至 1.91:1，包含兩端）時，Instagram 版本與原圖相同

    Example: 1:1 的圖片
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1080  | 1080   | 1080     | 1080      |

    Example: 恰為 4:5 的圖片
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1350   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1080  | 1350   | 1080     | 1350      |

    Example: 恰為 1.91:1 的圖片
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1910  | 1000   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1910  | 1000   | 1910     | 1000      |

  Rule: 後置：寬度 / 高度 < 0.8 的圖片，系統從圖片中間裁切出 4:5 的 Instagram 版本

    Example: 9:16 的直式海報
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 1080  | 1920   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1080  | 1920   | 1080     | 1350      |

  Rule: 後置：寬度 / 高度 > 1.91 的圖片，系統從圖片中間裁切出 1.91:1 的 Instagram 版本

    Example: 2:1 的橫式圖片
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 2000  | 1000   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 2000  | 1000   | 1910     | 1000      |

  Rule: 後置：已排程貼文附加圖片成功後維持已排程，排程時間不變

    Example: 為已排程貼文附加圖片後狀態不變
      When "pr@club.tw" 為貼文 "P3" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 2       | 1080  | 1080   |
      Then 操作成功
      And 貼文 "P3" 的狀態為 "SCHEDULED"
      And 貼文 "P3" 的排程時間為 "2026-10-06 12:00"

  Rule: 後置：裁切只調整被裁的那一邊，另一邊維持原圖尺寸；被裁邊長先四捨五入，比例超出 0.8～1.91 時每次減 1 像素直到符合

    Example: 過高：1001×2000，高度 1251.25 四捨五入為 1251，比例符合
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 1001  | 2000   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1001  | 2000   | 1001     | 1251      |

    Example: 過高：1002×2000，高度 1252.5 四捨五入為 1253 超出範圍，減 1 為 1252
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 1002  | 2000   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 1002  | 2000   | 1002     | 1252      |

    Example: 過寬：3000×1001，寬度 1911.91 四捨五入為 1912 超出範圍，減 1 為 1911
      When "pr@club.tw" 為貼文 "P2" 附加以下圖片：
        | format | size_mb | width | height |
        | JPEG   | 3       | 3000  | 1001   |
      Then 操作成功
      And 貼文 "P2" 的圖片為：
        | format | width | height | ig_width | ig_height |
        | JPEG   | 3000  | 1001   | 1911     | 1001      |
