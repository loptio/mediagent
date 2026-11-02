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

---

## 系統規格文件導讀

本專案之詳細需求規格、系統架構、資料庫模型、API 合約與驗收測試規格已完整定義於 `docs/` 與 `spec/` 目錄中：

| 檔案 | 內容 |
|---|---|
| `docs/requirements.md` | 需求規格：角色權限、資料、功能需求（FR）、商業規則（BR）、非功能需求（NFR）、MVP 範圍、待確認事項 |
| `docs/architecture.md` | 系統架構：部署與開發環境、模組分工（M1～M5、F、D）、發佈引擎、平台串接、安全、測試架構、架構決策紀錄 |
| `docs/data-model.md` | 資料模型：13 張資料表的完整欄位、英文代碼對照、各表由哪個模組寫入、交易與併發 |
| `docs/api-design.md` | API 設計：35 個端點、錯誤碼、前後端共同遵守的合約 |
| `docs/team-rules.md` | 團隊協作規範：模組分工、Sprint 時程、技術棧、Git 流程、命名與分層、測試與完成的定義、繳交、密鑰管理 |
| `docs/issue-workflow.md` | Issue 撰寫規範與模板：如何把功能拆成可開發的 issue |
| `spec/erm.dbml` | 業務資料模型（DBML），可貼到 [dbdiagram.io](https://dbdiagram.io) 檢視 ER 圖 |
| `spec/features/*.feature` | 30 個功能的驗收規格（Gherkin），共 452 個例子，以 pytest-bdd 執行 |

### 建議閱讀順序

1. **所有人**：`docs/requirements.md` 第 1～3 節（問題、角色、情境）→ `docs/team-rules.md`
2. **後端**：`docs/architecture.md` → `docs/data-model.md` → `docs/api-design.md` → 自己模組負責的 `spec/features/`
3. **前端**：`docs/api-design.md` → `docs/requirements.md` 第 2.1 節（角色權限）、第 4.7 節（平台限制）
4. **開 issue 前**：`docs/issue-workflow.md`

### 閱讀慣例

- **編號**：FR-xx、BR-xx、NFR-xx 以 `docs/requirements.md` 為準，其他文件與 issue 一律引用這些編號。
- **「需求 4.3」**：指 `docs/requirements.md` 第 4.3 節。
- **文件間引用**：《mediagent 資料模型》＝`docs/data-model.md`、《mediagent API 設計》＝`docs/api-design.md`、《mediagent 系統架構設計》＝`docs/architecture.md`、《mediagent 團隊協作規範》＝`docs/team-rules.md`、《mediagent Issue 撰寫規範》＝`docs/issue-workflow.md`。
- **`#TODO`**：feature 中尚待外部資料查證的規則（如各平台字數算法、圖片尺寸限制）。
- **圖表**：架構文件使用 Mermaid，在 GitHub 或安裝 Mermaid 擴充套件的 VS Code 中可直接顯示。

### 尚待決定

- `docs/requirements.md` 第 10 節：異常通知、幹部自行改密碼、PNG 轉檔等 6 項。
- `docs/api-design.md` 第 5 節：API 層面暫定的處理方式。

規格有疑問或需修改時，請開 `spec-question` issue 討論，決定後再更新文件（見 `docs/team-rules.md`）。
