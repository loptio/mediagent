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

1. 使用者帳號與登入
2. 連結社團在至少 2 個社群平台的官方帳號（預計 Threads 與 Bluesky）
3. 撰寫、修改、刪除貼文草稿
4. 選擇目標平台，立即同步發佈
5. 設定排程時間，到時自動同步發佈
6. 查詢各平台的發佈結果（成功／失敗與原因），並可重試失敗的平台

## Extension Features（延伸功能，視進度實作）

- AI 依各平台特性改寫貼文內容
- 自動模式：定期讀取社團貼文底下的新留言，由 AI 依社團設定自動回覆
- 支援更多平台（Facebook 粉專、Discord、Telegram、Instagram）

## Documents

- [需求與提案規格](docs/requirements.md)
