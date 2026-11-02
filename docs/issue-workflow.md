# mediagent Issue 撰寫規範與模板

> 對象：mediagent 七位組員（M1～M5、F、D）
> 用途：把模組功能拆解為 issue，交由組員或 Claude 依 issue 開發
> 原則：issue 品質直接決定開發品質。資訊不全，產出必然偏差。
> 相關文件：`docs/requirements.md`、`spec/features/`、《mediagent 資料模型》、《mediagent API 設計》、《mediagent 系統架構設計》、《mediagent 團隊協作規範》

---

## 1. 為什麼 issue 要寫得詳細

開發者（組員或 Claude）看不到你腦中的設計，也看不到組員之間口頭達成的共識。每張 issue 必須**自足**：讀完就能獨立開發出符合規格、能與其他模組銜接的功能。

本專案的規格已經非常具體（`spec/features/` 有 452 個例子），因此 issue 的重點是：**指出這張 issue 負責哪些 Rule、用到哪些端點與資料表、依賴誰**，而不是重新描述需求。

**資訊不全會發生什麼**：
- 沒寫負責哪些 Rule → 兩個人做同一條規則，或某條規則沒人做
- 沒有 In／Out scope → 做過頭（寫到別人的表）或做不夠
- 沒寫整合點 → 自己重寫一份共用核心已經有的功能
- 沒寫依賴 → 卡住時不知道在等誰

---

## 2. Issue 大小的拿捏

### 2.1 理想尺寸
- **1～3 天**單人工作量、**一個 PR**
- **一個可獨立驗收的單元**：一組 Rule 的例子全部通過
- **垂直切片優先**：API + 資料庫 + 前端畫面 + 驗收測試一起完成

### 2.2 太大的訊號（要拆）
- 一個 feature 超過約 15 條 Rule（例如「立即發佈」32 條、「設定排程」22 條、「設定目標平台帳號」21 條）
- 要改 3 個以上模組
- PR 預計超過 500 行

**拆法：依 Rule 分組，不依技術層拆。** 例如「立即發佈」拆成「受理端點」（前置條件與受理後的狀態，#M5-1）與「發佈引擎」（背景執行與結果，#M5-2）兩張；不要拆成「寫 router」「寫 service」。

**同一 `.feature` 拆成多張 issue 時的 CI 與合入規則**：
- 首張 PR（如 #M5-1）建立 `tests/bdd/test_<功能>.py`，透過 `tests/bdd/conftest.py` 的 `load_feature_scenarios(...)`（以 `"{rule} — {example}"` 區分不同 `Rule` 下的同名例子，確保全專案 452 個例子完整收集）載入整個 `.feature` 時，必須在該測試檔內以 `PENDING_RULES`／`PENDING_EXAMPLES` 把屬於後續 issue（如 #M5-2）的 Out-of-scope 規則與例子一併登記為 `pending #M5-2`（見團隊規範 §8.1），由 `conftest.py` 自動標記 skip，確保全套 CI 不會因 #M5-2 尚未實作的步驟而拋出 `StepDefinitionNotFoundError`。
- 共用同一個 `tests/bdd/test_<功能>.py` 的拆分 issue 應**依序合入**（#M5-2 接續在 #M5-1 之後開發／merge），避免同時修改同一支測試檔產生衝突。

### 2.3 太小的訊號（要合併）
- 只有一兩條 Rule、沒有獨立價值
- 只是改一個欄位名稱或一個按鈕

### 2.4 各模組概估

| 模組 | 功能數 | Rule 數 | 建議 issue 數 |
|---|---|---|---|
| M1 帳號與安全 | 9 | 67 | 7～9 |
| M2 平台帳號與串接 | 4 + 3 個真實 Adapter | 55 | 8～10 |
| M3 貼文編輯 | 8 | 68 | 7～9 |
| M4 目標與排程 | 4 + lifecycle | 63 | 6～8 |
| M5 發佈執行 | 4 + 發佈引擎 | 80 | 7～9 |
| F 前端骨架與稽核查詢 | 1 + 前端基礎 | 13 | 5～7 |
| D DevOps 與共用核心 | 共用核心、CI、部署 | — | 8～10 |

---

## 3. Issue 必備內容

| 區塊 | 必要度 | 說明 |
|---|---|---|
| 標題（含模組前綴） | 必要 | `[M5] 立即發佈：受理端點 POST /posts/{id}/publish-jobs` |
| 對應規格 | 必要 | FR 編號、**feature 檔與負責的 Rule 清單**、相關 BR、NFR |
| 背景 | 必要 | 兩三句說明這張 issue 在整個流程中的位置 |
| Scope（In／Out） | 必要 | In 列出負責的 Rule；Out 列出同一個 feature 中由其他 issue 負責的 Rule |
| 端點 | 視情況 | 引用《API 設計》的端點編號；有偏離時寫明並同步更新文件 |
| 資料表 | 視情況 | 引用《資料模型》的表；確認只寫入自己有權限的表或欄位 |
| 畫面 | 前端必要 | 頁面、元件、載入／空資料／錯誤狀態、角色差異 |
| 整合點 | 必要 | 使用的共用核心函式、呼叫的跨模組函式 |
| 依賴 | 必要 | 等待的 issue 或交付物；可用 `@pending` 隔離的例子 |
| 驗收條件 | 必要 | **以 feature 例子通過為主**，加上規格未涵蓋的技術條件 |
| 測試方式 | 必要 | 驗收測試檔、單元測試、手動測試 |

---

## 4. Issue 模板

> 複製以下內容到 GitHub Issue，刪除不適用的區塊。

````markdown
# [<模組>] <功能>：<這張負責的部分>

## 對應規格
- FR：FR-XX
- Feature：`spec/features/<功能>.feature`
- 負責的 Rule：
  - 前置：……
  - 後置：……
- 相關規則：BR-XX、NFR-XX

## 背景
<2～3 句：在整個流程中的位置、為什麼現在做>

## Scope

### In scope
- [ ] 上列 Rule 的實作與驗收測試
- [ ] ……

### Out of scope（由其他 issue 負責）
- ❌ ……（#NN）

## 端點
《API 設計》端點 #N：`METHOD /api/v1/...`（偏離文件時寫明原因）

## 資料表
- 寫入：……（確認屬於本模組，見《資料模型》§4）
- 讀取：……

## 畫面（前端）
- 頁面與元件：
- 載入／空資料／錯誤：
- 角色差異：

## 整合點
- 共用核心：……
- 跨模組函式：……（若有，必須是團隊規範 §1.2 允許的兩條之一）

## 依賴
- [ ] #NN ……（若與前一張拆分 issue 共用 `test_<功能>.py`，須等前一張先合入）
- 依賴完成前標 `@pending` 的例子：……（於 `tests/bdd/test_<功能>.py` 以 `PENDING_RULES`／`PENDING_EXAMPLES` 宣告 `pending #NN`，由 `tests/bdd/conftest.py` 依 `Rule` + `Example` 識別並自動 skip，不改 `.feature`；拆分首張 PR 須一併登記 Out of scope 的後續 issue 規則與例子）

## 驗收條件
- [ ] `tests/bdd/test_<功能>.py` 經 `load_feature_scenarios(...)` 完整收集例子（不覆蓋同名 `Example`），上列本 issue 可直接驗收之 Rule 例子全部通過；已於 `PENDING_RULES`／`PENDING_EXAMPLES` 登記 `pending #NN` 的例子於 CI 正常 skip，無 `StepDefinitionNotFoundError`
- [ ] 符合團隊規範 §8.2 完成的定義
- [ ] ……（規格未涵蓋的技術條件）

## 測試方式
1. 驗收測試：
2. 單元測試：
3. 手動測試：

## 備註
````

---

## 5. 完整範例：M5 立即發佈（受理端點）

### `[M5] 立即發佈：受理端點 POST /posts/{id}/publish-jobs`

#### 對應規格
- FR：FR-15
- Feature：`spec/features/立即發佈.feature`
- 負責的 Rule（16 條）：
  - 前置：撰稿者不能立即發佈
  - 前置：管理員與發佈者可以立即發佈
  - 前置：停用的帳號無法立即發佈
  - 前置：只有草稿與已排程狀態的貼文可以立即發佈
  - 前置：貼文必須至少選擇 1 個目標平台帳號
  - 前置：貼文文字長度不可超過所選目標平台中最嚴格的字數上限
  - 前置：換行、中文字、一般 emoji、組合 emoji 依各平台官方定義計算字數（`#TODO`，W08 補）
  - 前置：圖片寬高必須符合所有目標平台各自的尺寸限制（`#TODO`，W08 補）
  - 前置：目標平台帳號含 Instagram 時，貼文必須附加圖片
  - 前置：目標平台帳號的授權狀態必須為有效
  - 前置：授權到期時間已過的目標平台帳號視為失效
  - 後置：受理後貼文狀態立即改為發佈中
  - 後置：草稿受理後立即為每個目標平台帳號建立待發佈的發佈紀錄
  - 後置：立即發佈已排程的貼文後，排程時間為空
  - 後置：已排程貼文立即發佈時，沿用既有的待發佈紀錄，不新增紀錄；已取消的紀錄維持已取消，不發佈（本 issue 實作受理期沿用紀錄邏輯並以單元測試驗證；其 BDD 例子因斷言背景發佈完成後的「成功」狀態與連結，暫標 `pending #M5-2`）
  - 後置：草稿立即發佈建立發佈紀錄時，寫入變更前狀態為空的變更歷程
- 相關規則：BR-02、BR-05、BR-07、BR-08、BR-09、BR-12、BR-18、BR-26、BR-29、BR-30

#### 背景
立即發佈分成「受理」與「執行」兩段（《系統架構設計》§6.1）。本 issue 只做受理：檢查能不能發佈、建立或沿用待發佈紀錄、把貼文改成發佈中，然後回應 202 並把貼文交給發佈引擎。實際呼叫平台與寫回結果由 #M5-2 發佈引擎負責。

#### Scope

**In scope**
- [ ] 端點 #31 `POST /api/v1/posts/{id}/publish-jobs`，`type = "immediate"`
- [ ] 上列 16 條 Rule（2 條 `#TODO` 先以目前已知限制實作）
- [ ] 回應 202 後以 `BackgroundTasks` 呼叫 `run_post(post_id)`（#M5-2 完成前為空實作）
- [ ] 前端 `PublishActions` 元件的「立即發佈」按鈕（含確認、送出中、錯誤提示）

**Out of scope**
- ❌ 背景發佈、寫回結果、判定最終狀態、「發佈貼文」稽核紀錄、授權失效處理（#M5-2 發佈引擎）
- ❌ `type = "retry"`（#M5-4 重試發佈）
- ❌ 字數算法與圖片寬高的平台實際數值（W08 查證後由 M2、M3 更新 `Capabilities` 與 `publish_rules`）

#### 端點
《API 設計》端點 #31。Request `{"type": "immediate"}`；Response 202：

```json
{"post_id": 42, "post_status": "PUBLISHING",
 "records": [{"id": 101, "platform_account_id": 7, "status": "PENDING"},
             {"id": 102, "platform_account_id": 9, "status": "PENDING"}]}
```

| 錯誤 | 情境 |
|---|---|
| `403 FORBIDDEN` | 撰稿者 |
| `401 UNAUTHENTICATED` | 停用帳號 |
| `409 POST_NOT_PUBLISHABLE` | 貼文不是草稿或已排程 |
| `422 NO_TARGET` | 沒有目標 |
| `422 CONTENT_TOO_LONG` | 超過最嚴格字數上限 |
| `422 IMAGE_REQUIRED_FOR_INSTAGRAM` | 目標含 Instagram 但沒有圖片 |
| `422 TARGET_AUTH_INVALID` | 目標授權失效或已過期 |
| `422 IMAGE_DIMENSION_INVALID` | 圖片寬高不符合（W08 補數值） |

#### 資料表
- 寫入：`post.status`（→ PUBLISHING）、`post.publishing_started_at`、`post.scheduled_at`（清空）；`publish_record` 經 `publish_records.ensure_pending()`；`publish_record_history` 由該函式一併寫入。皆屬 M5 權限（《資料模型》§4.1）。
- 讀取：`post_target`、`post_image`、`media_file`、`platform_account`。

#### 畫面
- 元件 `frontend/src/modules/m5-publishing/components/PublishActions.vue`，放在 F 的貼文編輯頁骨架中。
- 撰稿者不顯示按鈕；送出時按鈕顯示載入並停用；成功後切到發佈結果並開始每 3 秒輪詢；錯誤以 `ElMessage` 顯示後端 `message`。

#### 整合點
- 共用核心：`require_role("publisher")`、`clock.now()`、`publish_rules.check()`、`effective_auth_status()`、`transition_post()`、`publish_records.ensure_pending()`。
- 跨模組函式：無。

#### 依賴
- [ ] Sprint 0：全部 models 與 migration、`require_role`、`publish_rules.check()`、`transition_post()`、`publish_records.*`、`tests/bdd/conftest.py`、共用測試步驟
- [ ] #M5-2 發佈引擎：本 issue 不需等待；受理後的背景呼叫先為空實作
- 依賴完成前標 `@pending` 的例子：於 `tests/bdd/test_立即發佈.py` 以 `PENDING_RULES` 登記 Out of scope 的 16 條背景引擎 Rule，以及「後置：已排程貼文立即發佈時，沿用既有的待發佈紀錄，不新增紀錄；已取消的紀錄維持已取消，不發佈」（其 BDD 例子驗證引擎完成後的「成功」結果）為 `pending #M5-2`，不改 `.feature`

#### 驗收條件
- [ ] `tests/bdd/test_立即發佈.py` 中上列 13 條可直接於受理期驗收之 Rule 的 BDD 例子全部通過（另 2 條 `#TODO` 無例子；1 條斷言引擎完成狀態之沿用紀錄 Rule 與 Out of scope 的 16 條背景引擎 Rule 已於 `PENDING_RULES` 登記為 `pending #M5-2`，於 CI 正常 skip 且無 `StepDefinitionNotFoundError`）；BR-29 沿用待發佈紀錄且維持 `CANCELLED` 不變之受理邏輯由單元測試 `tests/unit/m5_publishing/test_accept.py` 驗證通過
- [ ] 同一貼文連續送出兩次，第二次回 `409 POST_NOT_PUBLISHABLE`，不產生重複的發佈紀錄
- [ ] 受理與狀態變更在同一交易內完成，並先鎖定貼文（《資料模型》§6）
- [ ] 符合團隊規範 §8.2 完成的定義

#### 測試方式
1. **驗收測試**：`pytest tests/bdd/test_立即發佈.py`（不加 `-k` 過濾；`load_feature_scenarios(...)` 完整載入全檔例子，受理期可驗收例子全部 passed，登記於 `PENDING_RULES` 的 `pending #M5-2` 例子自動 skipped）。
2. **單元測試**：`tests/unit/m5_publishing/test_accept.py`：已排程貼文沿用紀錄、已取消紀錄不被改回待發佈、併發送出兩次。
3. **手動測試**：`docker compose up`、載入種子資料，以發佈者在前端按「立即發佈」，確認貼文變成發佈中、Swagger 端點 #29 看到待發佈紀錄。

#### 備註
- 已排程貼文立即發佈時，只執行 `PENDING` 紀錄，`CANCELLED` 維持不變（BR-29）。
- 字數以目標平台 Adapter 的 `count_chars()` 計算，W08 前為 Unicode 字元數。

---

## 6. 送出 issue 前的自我檢查

- [ ] 標題有模組前綴（`[M1]`～`[M5]`、`[F]`、`[D]`）
- [ ] 列出負責的 feature 與 **Rule 清單**；同一 feature 的其他 Rule 標明由哪張 issue 負責
- [ ] In scope 和 Out of scope 都明確
- [ ] 端點與錯誤碼引用《API 設計》，沒有自創
- [ ] 只寫入自己模組有權限的表或欄位（《資料模型》§4）
- [ ] 沒有重寫共用核心已有的功能；跨模組呼叫只有允許的兩條
- [ ] 依賴清楚，並列出可用 `@pending` 隔離的例子
- [ ] 驗收條件以 feature 例子通過為主
- [ ] 沒有要求在 Log、回應或畫面輸出任何憑證
- [ ] 能在 1～3 天內完成（否則依 Rule 拆開）
- [ ] 自己讀一次：第一次接觸專案的人能不能照著做？
