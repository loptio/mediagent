# MediAgent：社團多平台貼文同步發佈服務

> Multi-platform Post Sync & Scheduling Service for Student Clubs

## Project Info

| 項目 | 內容 |
|---|---|
| Project Title | MediAgent |
| Group Number | G01 |
| Course | 網際服務軟體工程（Web Service Software Engineering） |

## Members

| 姓名 | 主要負責 |
|---|---|
| 趙徊智 | 平台串接（Threads／Bluesky Adapter）、發佈與重試流程 |
| 傅資涵 | 需求與提案文件、RESTful API Design、OpenAPI Contract |
| 蘇文伶 | 軟體架構、Data Model／ERD、資料庫設計 |
| 詹皓宇 | 貼文管理與排程核心邏輯 |
| 陳亭妤 | 帳號與權限（Authentication／Authorization） |
| 陳冠斌 | 自動化測試、GitHub Actions CI |
| 陳薏安 | Docker、部署、Logging 與 Health Check |

## Problem Statement

學生社團通常同時經營多個社群平台帳號，例如 Threads、Facebook 粉專、Bluesky，用來發佈活動公告、招生資訊與成果分享。同一則公告必須由幹部逐一登入各平台、重複貼上相同內容，不但耗時，也容易漏發某個平台、各平台內容版本不一致，或錯過預定的發佈時間。

MediAgent 讓社團幹部在同一個地方撰寫一次貼文，選擇要發佈的平台，系統即可立即或依排程時間同步發佈到各平台，並記錄每個平台的發佈結果。

## Target Users

- **社團幹部（主要使用者）**：負責撰寫並發佈社團公告的公關、宣傳幹部
- **社團管理者**：負責連結社團的各平台官方帳號、管理哪些幹部可以使用系統

## MVP Scope

1. 帳號與權限管理：支援註冊、登入，以及 Admin／Editor 角色權限
2. 社群帳號管理：支援社群平台帳號的連結、查看與移除
3. 多平台串接：首階段支援 Threads、Bluesky，並採 Adapter 架構保留擴充性
4. 貼文草稿管理：支援貼文的新增、查詢、修改與刪除
5. 貼文同步發佈：支援立即發佈與排程發佈至已連結平台
6. 發佈結果與重試：記錄各平台發佈狀態，並支援失敗平台重新發佈
7. 貼文內容範圍：MVP 階段僅支援純文字貼文，圖片、影片等多媒體內容暫不納入範圍，對應 FR-01～FR-13

## Extension Features（延伸功能，視進度實作）

1. AI 貼文改寫：依不同平台的字數限制與內容風格自動調整貼文，經使用者確認後發佈
2. AI 留言自動回覆：定期取得新留言，依預設語氣與回覆規則產生回覆，並支援自動／手動模式切換
3. 更多社群平台：擴充支援 Facebook 粉專、Discord、Telegram 等平台
4. 多媒體貼文與 Instagram：支援圖片上傳與圖片貼文，進一步整合 Instagram 發佈功能
5. 發佈成效統計：彙整各平台貼文的按讚、留言等互動數據，提供成效追蹤與比較

## Documents

- [需求與提案規格](docs/requirements.md)
