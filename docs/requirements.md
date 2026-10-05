# Mediagent Requirements & Proposals

社團多平台貼文同步發佈服務：需求與提案規格

| 項目 | 內容 |
|---|---|
| Project Title | mediagent |
| Group | 1 |
| Members | 趙徊智、傅資涵、蘇文伶、詹皓宇、陳亭妤、陳冠斌、陳薏安 |
| Version | v0.1 |

---

## 1. 問題陳述（Problem Statement）

學生社團通常同時經營多個社群平台帳號（例如 Threads、Facebook 粉專、Bluesky），用來發佈活動公告、招生資訊與活動紀錄。同一則公告，幹部必須逐一登入每個平台、重複貼上相同內容。過程中常發生：

- **耗時又重複**：平台越多，發一則公告要做的重複操作越多。
- **漏發與不一致**：某個平台忘了發，或各平台貼的是不同版本的內容。
- **錯過時間**：活動前一天晚上要發的提醒，負責的幹部剛好在忙就忘了。
- **無法掌握結果**：不容易確認每個平台是否都已成功發出。

mediagent 希望讓社團幹部只需撰寫一次貼文、選擇目標平台，系統就能立即或依排程時間同步發佈到各平台，並清楚記錄每個平台的發佈結果。

## 2. 為什麼這個問題值得解決？

- **真實且常見**：多數社團都有 2 個以上的社群帳號，而社團幹部是課業之外的志工，時間有限。
- **重複性高**：社團一學期會發佈數十則公告，每則都要在每個平台重做一次，省下的時間會持續累積。
- **錯誤代價明顯**：活動公告漏發或晚發，會直接影響活動人數與招生成效。
- **適合用 Web Service 解決**：各社群平台皆提供 API，正好可以由一個服務統一串接、排程與記錄。

## 3. 目標使用者（Target Users）

### Stakeholders

| 角色 | 是否直接使用 | 主要需求 |
|---|---|---|
| 社團幹部（Editor） | 是 | 撰寫貼文、選擇平台、立即或排程發佈、確認發佈結果 |
| 社團管理者（Admin） | 是 | 連結社團各平台的官方帳號、管理可使用系統的幹部 |
| 社團粉絲／社員 | 否 | 在各平台準時收到一致的公告內容 |
| 社群平台（Threads、Bluesky 等） | 否 | 透過官方 API 存取，需遵守其使用條款與流量限制 |

### Primary Users

- **社團幹部（Editor）**：負責宣傳、公關的幹部，是最主要的使用者。
- **社團管理者（Admin）**：通常是社長或公關長，負責帳號連結與權限設定。

## 4. 主要使用情境（User Scenario）

### Scenario 1：排程同步發佈活動公告

小美是吉他社的公關幹部。週日晚上，她要預先準備週三社課的公告。社團有 Threads 和 Bluesky 兩個帳號。

她登入 mediagent，撰寫一則公告：「本週三 19:00 社課在活動中心 201，主題是指彈入門，歡迎新生帶吉他來！」，勾選 Threads 和 Bluesky，並把發佈時間設在週二 12:00。系統檢查內容長度符合兩個平台的字數限制、時間在未來，接著把貼文排入排程。

週二 12:00 一到，系統自動把貼文發到兩個平台。小美下課後打開 mediagent，看到兩個平台都顯示「發佈成功」，並附上各平台的貼文連結。

### Scenario 2：部分平台發佈失敗

某次發佈時，Threads 成功了，但 Bluesky 因為平台暫時無法連線而失敗。mediagent 把這則貼文標示為「部分失敗」，並顯示 Bluesky 的失敗原因。小美按下重試，系統只重新發佈到 Bluesky，不會讓 Threads 再出現一則重複的貼文。

### 從 Scenario 抽出的要素

| 要素 | 內容 |
|---|---|
| Actor | 社團幹部 |
| Trigger | 需要在多個平台發佈同一則公告 |
| Input | 貼文內容、目標平台、發佈時間（可選） |
| Processing | 檢查內容與時間、排程、呼叫各平台 API、記錄結果 |
| Outcome | 各平台準時發出一致的內容，幹部可確認每個平台的結果 |

## 5. 核心功能（Core Functions）

| 功能 | 說明 |
|---|---|
| 帳號與登入 | 社團成員以自己的帳號登入系統 |
| 平台帳號連結 | 管理者把社團各平台的官方帳號連結到系統 |
| 貼文管理 | 撰寫、修改、刪除貼文草稿 |
| 同步發佈 | 一則貼文同時發佈到多個選定的平台 |
| 排程發佈 | 指定時間，到時自動發佈 |
| 發佈紀錄 | 顯示每個平台的成功或失敗結果，失敗可重試 |

## 6. 功能需求初稿（Functional Requirements）

| ID | 功能需求 | 來源 |
|---|---|---|
| FR-01 | 系統應允許社團成員註冊並登入系統。 | Stakeholders |
| FR-02 | 系統應允許管理者連結社團在社群平台的官方帳號。 | Scenario 1 |
| FR-03 | 系統應允許使用者查看已連結的平台帳號及其連線狀態。 | Scenario 1 |
| FR-04 | 系統應允許管理者移除已連結的平台帳號。 | Stakeholders |
| FR-05 | 系統應允許使用者建立貼文草稿。 | Scenario 1 |
| FR-06 | 系統應允許使用者為貼文選擇一個或多個目標平台帳號。 | Scenario 1 |
| FR-07 | 系統應允許使用者修改尚未發佈的貼文。 | Scenario 1 |
| FR-08 | 系統應允許使用者刪除尚未發佈的貼文。 | Scenario 1 |
| FR-09 | 系統應允許使用者將貼文立即發佈到所選的所有平台。 | Scenario 1 |
| FR-10 | 系統應允許使用者為貼文設定排程時間，並於該時間自動發佈到所選平台。 | Scenario 1 |
| FR-11 | 系統應記錄每則貼文在每個平台的發佈結果，包含成功／失敗、發佈時間、平台貼文連結或失敗原因。 | Scenario 1、2 |
| FR-12 | 系統應允許使用者重新發佈某則貼文中發佈失敗的平台。 | Scenario 2 |
| FR-13 | 系統應允許使用者查詢貼文列表，並可依貼文狀態篩選。 | Scenario 1 |

> 本階段只描述系統「要做什麼」，HTTP Method、Path 與資料結構留待 W06 之後設計。

## 7. 非功能需求初稿（Non-functional Requirements）

| ID | 非功能需求 | 類型 |
|---|---|---|
| NFR-01 | 排程貼文應於預定時間後 10 分鐘內開始發佈。 | 時效（Timeliness） |
| NFR-02 | 平台存取憑證（Access Token）應加密保存，且不得出現在任何 API 回應或 Log 中。 | 安全（Security） |
| NFR-03 | 單一平台發佈失敗或逾時（30 秒）時，不應影響其他平台的發佈，也不應造成服務中斷。 | 可靠性（Reliability） |
| NFR-04 | 系統應能在不連線真實社群平台的情況下，以模擬平台完成自動化測試。 | 可測試性（Testability） |
| NFR-05 | 發佈失敗時，系統應記錄可讓使用者理解的失敗原因（例如字數超過上限、帳號授權過期）。 | 可理解性（Clarity） |

## 8. 重要商業規則（Business Rules）

### 貼文內容

| ID | 規則 |
|---|---|
| BR-01 | 貼文內容不可為空白。 |
| BR-02 | 貼文內容長度不可超過所選平台中最嚴格的字數上限。MVP 平台上限：Threads 500 字元、Bluesky 300 字元。 |

### 目標平台

| ID | 規則 |
|---|---|
| BR-03 | 發佈或排程前，貼文必須至少選擇 1 個目標平台帳號。 |
| BR-04 | 目標平台帳號必須是已連結且授權有效的帳號；授權失效的帳號不可被選為目標。 |

### 排程

| ID | 規則 |
|---|---|
| BR-05 | 排程時間必須晚於目前時間。 |
| BR-06 | 已排程但尚未發佈的貼文，可以修改內容、目標平台與排程時間，或取消排程改回草稿。 |

### 貼文狀態

| ID | 規則 |
|---|---|
| BR-07 | 貼文狀態依序為：草稿（DRAFT）→ 已排程（SCHEDULED）→ 發佈中（PUBLISHING）→ 發佈完成（PUBLISHED）／部分失敗（PARTIALLY_FAILED）／全部失敗（FAILED）。立即發佈時可由 DRAFT 直接進入 PUBLISHING。 |
| BR-08 | 只有 DRAFT 與 SCHEDULED 狀態的貼文可以修改或刪除；已開始發佈的貼文不可修改。 |

### 發佈與重試

| ID | 規則 |
|---|---|
| BR-09 | 各平台獨立發佈：任一平台失敗，不影響其他平台的發佈。 |
| BR-10 | 所有目標平台皆成功時，貼文為 PUBLISHED；部分成功為 PARTIALLY_FAILED；全部失敗為 FAILED。 |
| BR-11 | 重試只針對發佈失敗的平台；已成功的平台不得重複發佈，以避免產生重複貼文。 |

### 權限

| ID | 規則 |
|---|---|
| BR-12 | 只有管理者（Admin）可以連結或移除平台帳號；一般幹部（Editor）可以撰寫、排程與發佈貼文。 |

## 9. MVP 範圍（Minimum Viable Product Scope）

**如果只能完成最重要的功能，mediagent 最少要做到：**

社團幹部撰寫一則貼文，就能立即或依排程時間，把它同步發佈到**至少 2 個**社群平台，並確認每個平台的發佈結果。

MVP 包含：

1. 使用者註冊、登入，有 Admin／Editor 兩種角色
2. 連結、查看、移除平台帳號功能
3. **支援至少 2 個社群平台**：預計串接 Threads 與 Bluesky；平台串接採轉接器（Adapter）設計，可視進度增加社群平台數量
4. 貼文草稿的建立、查詢、修改、刪除
5. 立即或依排程時間同步發佈
6. 每個平台的發佈結果紀錄，以及失敗平台的重試

MVP 只發佈**純文字貼文**，對應 FR-01～FR-13。

## 10. 不包含範圍（Out of Scope）

### 延伸功能（Extension Features）：MVP 完成後視進度實作

| 延伸功能 | 說明 |
|---|---|
| AI 內容改寫 | 依各平台的字數與風格，由 AI 改寫貼文內容，使用者確認後才發佈（對應 W15 Service Integration & AI） |
| 自動模式（留言自動回覆） | 定期讀取社團貼文底下的新留言，由 AI 依社團設定的語氣與規則自動回覆；可隨時切回手動模式 |
| 更多平台 | Facebook 粉專、Discord、Telegram 頻道 |
| 圖片貼文與 Instagram | Instagram 的 API 不支援純文字貼文，須先支援圖片上傳與公開圖片網址 |
| 發佈成效統計 | 彙整各平台的按讚、留言數 |

### 本專題明確不做

| 項目 | 原因 |
|---|---|
| X（Twitter） | 2026 年起 X API 取消免費方案，改為按次計費，不適合課程專題 |
| 以瀏覽器自動化操作平台 | 違反平台使用條款，可能導致社團帳號被封鎖，且須保存帳號密碼，有安全疑慮 |
| 開放給其他社團或組織使用 | Meta 系列平台開放第三方帳號連結須通過 App Review 與商家驗證；本專題僅服務本社團自己的帳號 |
| 私訊（DM）功能 | 非本專題核心問題 |
| 主動對他人貼文按讚、留言或追蹤 | 屬於垃圾訊息行為，違反平台規範 |

## 11. 初步 Web Service 功能構想

> 這裡只列出主要資源與大方向。正式的 RESTful API Design 與 OpenAPI Contract 會在 W06 之後完成。

### 主要資源（Resources）

| Resource | 說明 |
|---|---|
| User | 系統使用者（社團成員），具 Admin 或 Editor 角色 |
| Platform Account | 社團連結的社群平台帳號（平台類型、帳號名稱、授權狀態） |
| Post | 一則貼文（內容、目標平台、排程時間、狀態） |
| Publication | 一則貼文在某一個平台的發佈結果（成功／失敗、平台貼文連結、失敗原因） |

### 初步 API 構想

| Method | Path | 用途 | 對應 FR |
|---|---|---|---|
| POST | `/auth/register`、`/auth/login` | 註冊、登入 | FR-01 |
| POST | `/platform-accounts` | 連結平台帳號 | FR-02 |
| GET | `/platform-accounts` | 查看已連結帳號 | FR-03 |
| DELETE | `/platform-accounts/{id}` | 移除平台帳號 | FR-04 |
| POST | `/posts` | 建立貼文草稿 | FR-05、FR-06 |
| GET | `/posts` | 查詢貼文列表（可依狀態篩選） | FR-13 |
| GET | `/posts/{id}` | 取得單則貼文 | FR-13 |
| PATCH | `/posts/{id}` | 修改貼文、目標平台或排程時間 | FR-06、FR-07、FR-10 |
| DELETE | `/posts/{id}` | 刪除貼文 | FR-08 |
| POST | `/posts/{id}/publications` | 立即發佈 | FR-09 |
| GET | `/posts/{id}/publications` | 查看各平台發佈結果 | FR-11 |
| POST | `/posts/{id}/publications/retry` | 重試失敗的平台 | FR-12 |
| GET | `/health` | 服務健康檢查 | 維運 |

> 最後一條 `/retry` 帶有動作名稱，W06 設計 API Contract 時會再檢討是否改為更符合 REST Style 的設計。

### 系統架構構想

```
Client（Swagger UI／前端）
        │ HTTP / JSON
        ▼
mediagent Web Service（FastAPI）
  ├─ Router：接收 Request
  ├─ Service：貼文狀態、排程、發佈流程
  ├─ Platform Adapter：ThreadsAdapter、BlueskyAdapter、MockAdapter（測試用）
  └─ Repository ──▶ PostgreSQL（Neon）

排程觸發：GitHub Actions 定時任務 ──▶ 呼叫「發佈到期貼文」端點
```

- **Platform Adapter**：每個平台實作同一個介面（發佈貼文、檢查授權）。新增平台時只要新增一個 Adapter，不必修改核心流程；測試時可換成 MockAdapter，滿足 NFR-04。
- **排程觸發**：Render 免費方案閒置時會休眠，無法在服務內常駐排程，因此改由外部定時任務觸發（見第 14 節風險）。

## 12. 工作分配

> 依組員專長調整，以下為初步規劃。

| 組員 | 主要負責 | 對應週次 |
|---|---|---|
| 趙徊智 | 平台串接（Threads／Bluesky Adapter）、發佈與重試流程 | W08～W13 |
| 傅資涵 | 需求與提案文件、RESTful API Design、OpenAPI Contract | W05～W06 |
| 蘇文伶 | 軟體架構、Data Model／ERD、資料庫設計 | W07～W08 |
| 詹皓宇 | 貼文管理與排程核心邏輯（貼文狀態、排程觸發） | W08～W13 |
| 陳亭妤 | 帳號與權限（Authentication／Authorization）、Access Token 加密保存 | W09 |
| 陳冠斌 | 自動化測試（pytest、MockAdapter）、GitHub Actions CI | W10～W11 |
| 陳薏安 | Docker、部署（Render＋Neon）、Logging 與 Health Check | W12～W14 |
| 全體 | Code Review、延伸功能（AI 內容改寫、自動模式）、期末報告與 Live Demo | W15～W18 |

## 13. 學期開發計畫

依課程進度逐週累積工程成果：

| 週次 | 課程主題 | 專題進度 |
|---|---|---|
| W05 | Group Project Proposal | 完成提案、需求初稿、建立 Repository |
| W06 | API Contract & OpenAPI | 完成 RESTful API Design 與 `openapi.yaml` |
| W07 | Software Architecture & Data Modeling | 確定分層架構與 Adapter 介面、完成 Data Model／ERD |
| W08 | Database Design & Core Implementation | 完成資料庫與貼文 CRUD；**申請 Threads、Bluesky 開發者權限並完成第一次真實發文** |
| W09 | API Security | 註冊、登入、Admin／Editor 權限；Token 加密保存 |
| W10 | Testing & Git Collaboration | pytest 測試（以 MockAdapter 模擬平台）、Pull Request 協作流程 |
| W11 | Continuous Integration | GitHub Actions 自動測試 |
| W12 | Docker & Containerization | Dockerfile、本機容器執行 |
| W13 | Production Configuration & Deployment | 部署至 Render＋Neon；排程觸發上線 |
| W14 | Operation & Observability | `/health`、Logging、發佈失敗追蹤 |
| W15 | Service Integration & AI | 延伸功能：AI 內容改寫、自動模式 |
| W16 | Final Project Presentation | 期末成果報告與 Live Demo |
| W17～W18 | Extension／Portfolio | 依回饋修正、完成 Final Report 與最終繳交 |

**里程碑**：W08 前完成「發一則貼文到 2 個真實平台」的技術驗證，確認最大的技術風險可以解決。

## 14. 風險與待確認問題（Risks）

### 風險

| 風險 | 影響 | 因應方式 |
|---|---|---|
| 平台 API 權限申請卡關（例如 Meta 開發者帳號驗證） | MVP 平台無法串接 | MVP 承諾的是「至少 2 個平台」而非特定平台；Threads 不順時改用 Facebook 粉專或 Discord 替代；W08 前完成技術驗證 |
| 平台 API 規格或限制變動 | 發佈失敗 | 透過 Adapter 隔離平台差異，影響範圍限於單一 Adapter |
| 排程在免費雲端方案無法常駐執行 | 排程貼文沒有準時發出 | 改由 GitHub Actions 定時任務觸發發佈端點；NFR-01 允許 10 分鐘內誤差 |
| Access Token 外洩 | 社團帳號被盜用 | Token 加密保存、不回傳、不寫入 Log；以環境變數管理密鑰（NFR-02） |
| 平台 Token 過期（例如長效 Token 約 60 天） | 發佈失敗 | 發佈前檢查授權狀態，過期時標示並提示重新連結（BR-04、NFR-05） |
| 測試時誤發到真實帳號 | 社團帳號出現測試貼文 | 測試一律使用 MockAdapter；開發時使用專用的測試帳號 |
| 平台流量限制（Rate Limit） | 短時間大量發佈失敗 | 社團使用量低，風險小；失敗時記錄原因並可重試 |
