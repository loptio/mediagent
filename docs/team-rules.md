# mediagent 團隊協作規範

> 對象：mediagent 七位組員
> 依據：課程 W01 統一開發環境、《分組期末專題最終繳交規範》、《第16週分組期末專題成果報告規範》。標示 **[課程規定]** 的項目不可更改。
> 相關文件：`docs/requirements.md`（需求，編號以此為準）、`spec/`（資料模型與驗收規格）、《mediagent 系統架構設計》、《mediagent 資料模型》、《mediagent API 設計》、《mediagent Issue 撰寫規範》

---

## 目錄

1. 模組與分工
2. Sprint 計畫與共用核心交付時程
3. 技術棧
4. Git 協作流程
5. 程式結構與分層
6. 命名與代碼
7. API 與資料庫規則
8. 測試與完成的定義
9. 前端介面慣例
10. 文件、Demo 與繳交
11. 環境變數與密鑰
12. 平台開發者帳號與測試帳號
13. Issue 標籤與看板
14. 容易忽略的規則
15. Kickoff 會議議程

---

## 1. 模組與分工

### 1.1 七個角色

| 代號 | 模組 | 負責的功能（`spec/features/`） | 負責的表（寫入） | 負責人 |
|---|---|---|---|---|
| M1 | 帳號與安全 | 登入、登出、登出所有裝置、建立幹部帳號、查看幹部帳號、調整角色、停用帳號、啟用帳號、解除鎖定 | `user_account`、`user_session`、`login_security_event` | 待分配 |
| M2 | 平台帳號與串接 | 連結平台帳號、重新連結平台帳號、查看平台帳號、移除平台帳號；**Threads、Instagram、Discord 真實 Adapter** | `platform_account`、`platform_auth_event` | 待分配 |
| M3 | 貼文編輯 | 建立貼文草稿、修改貼文、刪除貼文、附加圖片、移除圖片、複製為新草稿、查詢貼文列表、預覽貼文 | `post`（內容）、`post_image`、`media_file` | 待分配 |
| M4 | 目標與排程 | 設定目標平台帳號、設定排程、取消排程、查看發佈結果；發佈紀錄生命週期服務 | `post_target`、`post.status`（草稿↔已排程）、`publish_record`（排程與修改目標時建立、取消） | 待分配 |
| M5 | 發佈執行 | 立即發佈、執行排程發佈、重試發佈、發佈逾時恢復；發佈引擎與定時任務端點 | `publish_record`（立即發佈時建立、發佈結果、重試、逾時恢復）、`post.status`（發佈中與結果）、`audit_target_result` | 待分配 |
| F | 前端骨架與稽核查詢 | 查詢稽核紀錄；前端版面、路由、共用元件、API client、代碼中文對照 | 無（只讀） | 待分配 |
| D | DevOps 與共用核心 | 共用核心、共用測試步驟、Docker、CI、部署、定時任務、監控 | 共用核心 | 待分配 |

- M1～M5、F 採**垂直切片**：負責自己功能的後端、前端頁面與驗收測試。
- 完整的寫入權限矩陣與跨模組函式見《資料模型》§4；依賴關係見《系統架構設計》§4.2。

### 1.2 平行開發的三條規則

1. **讀取任何表都可以；只能寫入分配給自己的表或欄位。** 要改別人的表，呼叫對方提供的函式。
2. **跨模組呼叫只有兩條**：M2 → M4 `lifecycle.on_platform_account_removed()`、M3 → M4 `lifecycle.on_post_deleting()`。新增任何跨模組呼叫前，須在團隊會議提出並更新本文件。
3. **共用的東西一律放共用核心**（狀態轉換、發佈紀錄寫入、稽核、發佈限制檢查、Adapter 介面、圖片儲存），不在各模組重複實作。

### 1.3 組員貢獻紀錄

課程規定 Final Report 要有 Team Contribution 表，寫出具體工程成果 **[課程規定]**。本專案**依 §1.1 的模組分配撰寫**，例如「M1 帳號與安全：登入、JWT + session、IP 限流、帳號管理功能與 67 條驗收規則」；Git 的 commit 與 PR 作為佐證，不另外維護紀錄文件。

---

## 2. Sprint 計畫與共用核心交付時程

Sprint 長度 2 週，每個 sprint 結束時 Demo 與檢討。

### 2.1 Sprint 0（W06～W07）：合約與共用核心

**目標：W07 結束時，每個模組都能在不等待別人的情況下開始寫功能。**

| 交付物 | 主筆 | 完成時間 |
|---|---|---|
| Repository 骨架、Docker Compose、基本 CI（lint + pytest） | D | W06 |
| `docs/openapi.yaml` v1（依《API 設計》） | 全體，各自寫自己模組的端點，F 整合 | W06 **[課程規定 W06]** |
| 全部 ORM models、第一版 migration、觸發器、`global_event_seq` | D | W06 |
| 代碼列舉、錯誤處理與錯誤碼、時鐘 | D | W06 |
| `get_current_user`、`require_role`、`ensure_owner_or_role`、開發模式、`audit.write()` | M1 | W07 |
| `Capabilities`、`PlatformAdapter`、`MockAdapter`、`effective_auth_status()`、`mark_auth_invalid()` | M2 | W07 |
| `MediaStorage`、`LocalMediaStorage`、`publish_rules.check()` | M3 | W07 |
| `transition_post()`、`publish_records.*` | M4 | W07 |
| 共用測試步驟（39 個句型）、測試資料工廠 | D 主筆，M5 協助發佈相關步驟 | W07 |
| 前端骨架：版面、路由與角色守衛、API client、型別產生、代碼中文對照、貼文編輯頁骨架 | F | W07 |
| 種子資料 `seeds/seed_dev.py` | D | W07 |

### 2.2 Sprint 1～4

| Sprint | 週次 | M1 | M2 | M3 | M4 | M5 | F | D |
|---|---|---|---|---|---|---|---|---|
| 1 | W08～W09 | 登入、登出、登出所有裝置、建立與查看帳號 | **W08 真實平台技術驗證**（Discord → Threads → Instagram）；Discord 連結、查看平台帳號 | 建立、修改、列表、附加與移除圖片（含裁切） | 設定目標、設定排程、取消排程；**`lifecycle` 兩個函式於 W08 結束前交付** | 發佈引擎 `run_post`、立即發佈 | 貼文列表與編輯頁整合 | CI 完整化（型別檢查、前端） |
| 2 | W10～W11 | 調整角色、停用、啟用、解除鎖定；IP 限流 | Threads、Instagram OAuth 連結與重新連結；移除平台帳號 | 刪除、複製、預覽 | 查看發佈結果與變更歷程 | 執行排程發佈、重試 | 稽核查詢 | 定時任務設定 |
| 3 | W12～W13 | 安全檢查與修正 | 真實 Adapter 的 `check_published` | 平台寬高限制（`#TODO` 補完） | 移除 `@pending`、整合修正 | 逾時恢復 | 前端整合 | **Render + Neon + 物件儲存部署**；README |
| 4 | W14～W15 | 整合、修正 bug | 整合、修正 bug | 整合、修正 bug | 整合、修正 bug | 整合、修正 bug | Playwright E2E | 監控、備份演練、`runbook.md` |

- **W13 里程碑**：正式環境走完「建立帳號 → 登入 → 撰寫並附圖 → 排程 → 自動發佈到三個平台 → 查看紀錄」。
- **W15 里程碑**：Demo 腳本彩排（§10.3）、`docs/` 必要檔案齊全。
- **W16**：期末報告與 Live Demo **[課程規定]**；**W18**：最終繳交 **[課程規定]**。

### 2.3 依賴到位前怎麼開發

| 情況 | 做法 |
|---|---|
| M2、M3 需要 M4 的 `lifecycle` | W08 結束前交付；之前相關例子標 `@pending` |
| M5 需要真實平台 | 一律用 MockAdapter；真實 Adapter 由 M2 獨立完成後註冊 |
| 前端需要尚未完成的 API | 依 `openapi.yaml` 產生的型別先寫畫面，以假資料呈現；API 完成後接上 |
| 任何模組需要登入 | 開發模式 `X-Dev-User` 標頭 |

---

## 3. 技術棧

### 3.1 後端

| 項目 | 選擇 | 備註 |
|---|---|---|
| 語言 | **Python 3.12** **[課程規定：Python]** | 版本來源為 `.python-version` |
| Web 框架 | **FastAPI** **[課程規定]** | |
| ORM、Migration | **SQLAlchemy 2.x**、**Alembic** | 禁止手動改 DB schema |
| 資料驗證 | **Pydantic v2** | |
| 套件管理 | **pip + `requirements.txt`** **[課程規定]** | 執行套件鎖定版本；測試與開發工具放 `requirements-dev.txt` |
| 呼叫平台 API | **httpx**（async） | 逾時 30 秒（NFR-03） |
| 身分驗證 | **PyJWT** + session 表 | 《API 設計》§1.2 |
| 密碼雜湊 | **Argon2**（`pwdlib`） | |
| 憑證加密 | **`cryptography` MultiFernet** | 支援金鑰輪替 |
| 圖片處理 | **Pillow** | 實際格式、寬高、Instagram 裁切 |

### 3.2 前端

| 項目 | 選擇 | 備註 |
|---|---|---|
| 語言、框架 | **TypeScript**、**Vue 3** | 一律 `<script setup lang="ts">` |
| 建置 | **Vite** | |
| UI 元件庫 | **Element Plus** | 不混用其他元件庫 |
| 伺服器資料 | **TanStack Query（Vue）** | |
| 本地狀態 | **Pinia** | 只放登入狀態 |
| 路由、表單 | **Vue Router**、**VeeValidate + Zod** | |
| API 型別 | **openapi-typescript** | 由 `openapi.yaml` 產生，禁止手寫 |
| HTTP、套件管理 | **Axios**、**pnpm** | |
| Node | **24 LTS** | 版本來源為 `frontend/.nvmrc` |

### 3.3 基礎設施與工具

| 項目 | 選擇 |
|---|---|
| 資料庫 | PostgreSQL 17；正式環境 Neon **[課程規定]** |
| 部署 | Render（後端以 `Dockerfile`、前端 Static Site）**[課程規定]** |
| 本機環境 | Docker Compose **[課程規定：Docker]** |
| CI、排程 | GitHub Actions **[課程規定]** |
| 測試 | pytest、**pytest-bdd**、CI 的 PostgreSQL service、vitest、Playwright **[課程規定：pytest]** |
| 程式品質 | ruff、mypy、eslint（含 eslint-plugin-vue）、prettier、pre-commit |
| 監控 | UptimeRobot |

---

## 4. Git 協作流程

### 4.1 分支

- `main`：正式環境，merge 後自動部署；受保護。
- `dev`：整合分支；受保護。
- `feature/<模組>-<簡述>`，例：`feature/M4-set-schedule`；`fix/...`；緊急修正 `hotfix/...`（從 `main` 開，修完合回 `main` 與 `dev`）。
- **禁止直接 push 到 `main` 與 `dev`。**
- 每個 sprint 結束時，D 開 `dev` → `main` 的 release PR，完成 §10.4 Engineering Check 後 merge。

### 4.2 Commit 訊息（Conventional Commits）

```
<type>(<模組>): <description>

[body：說明為何]

[footer：Closes #12；多人合作加 Co-authored-by]
```

`type`：`feat`、`fix`、`docs`、`refactor`、`test`、`chore`。模組：`M1`～`M5`、`F`、`D`、`core`。

### 4.3 Pull Request

- 一個 PR 對應一張 issue，由一位負責人開立。
- 描述必含：`Closes #N`、影響的模組、測試方式、API 變更時附 `openapi.yaml` 差異。
- 至少**一位其他模組的組員** review；**共用核心、`openapi.yaml`、migration、共用測試步驟**需要 **2 位** review，其中一位是 D（變更 `docs/openapi.yaml` 時，另一位建議找負責整合與前端型別的 F，避免前端型別脫節）。
- CI 通過才能 merge；一律 squash merge。

### 4.4 版本標記

- 每次 `dev` → `main` 的 release 打 tag：`v0.<sprint>.<修正次數>`，例：`v0.2.0`。
- W16 報告版本打 `v1.0.0-presentation`；W18 最終繳交打 `v1.0.0`，並以該 tag 的 Commit SHA 繳交 **[課程規定：以 Commit SHA 為準]**。

---

## 5. 程式結構與分層

### 5.1 目錄

完整目錄見《系統架構設計》§3.4。後端模組目錄：`app/core`、`app/m1_accounts`、`app/m2_platforms`、`app/m3_posts`、`app/m4_scheduling`、`app/m5_publishing`、`app/audit_query`。

### 5.2 模組內分層（必遵守）**[課程規定：Router／Service／Repository]**

```
app/m4_scheduling/
├── router.py        HTTP：endpoint、參數、權限依賴、回傳 response
├── service.py       商業規則、交易、呼叫共用核心、拋出 domain exception
├── repository.py    SQLAlchemy 查詢
├── schemas.py       Pydantic request／response
├── exceptions.py    本模組的 domain exception
└── lifecycle.py     對外公開的函式（只有提供跨模組函式的模組才有）
```

| 層 | 可以做 | 禁止 |
|---|---|---|
| `router` | 接收 request、呼叫 service、`Depends(require_role(...))` | 呼叫 repository、寫 SQL、商業規則、try/except domain exception |
| `service` | 商業規則、交易、鎖定、呼叫共用核心與其他模組的公開函式 | `import fastapi`、寫入不屬於自己的表 |
| `repository` | 查詢與寫入自己的表 | 商業規則、拋 domain exception |

- 依賴方向 `router → service → repository`，不可反向或跳層。
- 跨模組只能呼叫對方的公開函式（`lifecycle.py`），不可 import 對方的 `service` 或 `repository`。

---

## 6. 命名與代碼

### 6.1 程式碼

- Python：函式 `snake_case`、類別 `PascalCase`、常數 `UPPER_CASE`。
- TypeScript：函式與變數 `camelCase`、型別 `PascalCase`；Vue 元件 `PascalCase.vue`；composable 以 `use` 開頭。
- **資料表名稱與 `spec/erm.dbml` 相同**（單數，例：`post`、`publish_record`），方便與規格及驗收測試對照。

### 6.2 代碼與術語

- 列舉值一律使用英文代碼，**完整對照表在《資料模型》§2**，不在其他地方另訂。
- 前端顯示文字由 F 維護的 `frontend/src/shared/labels.ts` 統一對照。
- 常用術語：

| 中文 | 程式用詞 |
|---|---|
| 貼文 | `post` |
| 發佈（動詞） | `publish`（不用 post 當動詞） |
| 發佈紀錄 | `publish_record` |
| 變更歷程 | `publish_record_history` |
| 目標平台帳號 | `post_target` |
| 平台帳號 | `platform_account` |
| 存取憑證 | `credential` |
| 授權狀態 | `auth_status`（API 回傳的是計算後的有效狀態） |
| 發佈工作 | `publish_job`（API 資源，立即發佈與重試） |
| 逾時恢復 | `recovery` |
| 稽核紀錄 | `audit_log`；查詢結果統稱 `audit_event` |
| 系統身分 | `actor_type = system` |

---

## 7. API 與資料庫規則

### 7.1 API

- 一律依《API 設計》：前綴、錯誤格式、分頁、時間、身分驗證。
- **`openapi.yaml` 是合約**：API 變更必須同一個 PR 更新 `openapi.yaml`（PR 建議含 F review，見 §4.3）；前端重新產生型別。
- 新錯誤碼須同時登記到《API 設計》§4 與 `openapi.yaml`。
- 正式環境不可關閉 `/docs`、`/openapi.json` **[課程規定]**。

### 7.2 資料庫

- 一律依《資料模型》：型別、限制、索引、寫入權限。
- 所有 schema 變更走 Alembic migration，檔名 `{timestamp}_{模組}_{簡述}.py`；migration 由該表的擁有者開立，2 位 review。
- **維持單一 Alembic head**：migration PR 合入 `dev` 前必須確認 `alembic heads` 只有 **1 個 head**（CI 亦會檢查）；若 `dev` 已先合入其他 migration，須先 rebase 並更新 `down_revision`，避免 `scripts/entrypoint.sh` 的 `alembic upgrade head` 因多 head 失敗。
- 只能新增的表（稽核、事件、變更歷程）不得提供修改或刪除的程式。
- 改變貼文狀態或發佈紀錄前，必須先鎖定貼文（《資料模型》§6）。

---

## 8. 測試與完成的定義

### 8.1 測試規則

| 類型 | 工具 | 要求 |
|---|---|---|
| 驗收測試 | **pytest-bdd** 執行 `spec/features/` | 該功能的例子全部通過（`@pending` 除外） |
| 單元測試 | pytest | 演算法與邊界；後端各模組覆蓋率 ≥ 70% |
| 前端 | vitest | 表單驗證與角色差異；覆蓋率 ≥ 50% |
| E2E | Playwright | 情境一、情境二、例外情境（Sprint 4） |

- **CI 與自動化測試一律使用 MockAdapter，禁止呼叫真實平台**（NFR-04）。
- **共用步驟（39 個句型）只能在 `tests/bdd/steps/` 實作，BDD 載入與跳過機制統一放在 `tests/bdd/conftest.py`**（皆由 D 於 Sprint 0 交付，修改須含 D 在內 2 位 review），各模組不得重寫。`tests/bdd/conftest.py` 提供 `load_feature_scenarios(...)`，在載入 `.feature` 時將 `Rule` 名稱前綴至 `Example` 名稱（`"{rule} — {example}"`），避免 `pytest-bdd` 原生 `scenarios(...)` 因不同 `Rule` 下出現同名 `Example` 而互相覆蓋，確保 `spec/features/` 全部 **452** 個例子皆完整收集。其餘 97 個單一模組句型若在同一模組的多個 feature 間共用，可放在該模組自己的輔助檔（例：`tests/bdd/m3_steps.py`），不觸發 `tests/bdd/steps/` 審核門檻。
- 依賴其他模組（或同一 feature 拆分後尚未實作的 issue）才能通過的例子標 `@pending`，並在 issue 註明等待的對象；依賴完成後立刻移除。**`@pending` 一律在各測試檔 `tests/bdd/test_<功能>.py` 內以模組區域常數 `PENDING_RULES`（依 `Rule` 名稱）／`PENDING_EXAMPLES`（依 `(Rule, Example)` 配對，區分同名例子）宣告**，由 `tests/bdd/conftest.py` 的 `pytest_collection_modifyitems` 自動套用 `pytest.mark.skip(reason="pending #issue")`——既不改動 `.feature` 檔（保持 `git diff spec/features/` 為空），也不集中在單一共用檔登記而造成跨模組 merge 衝突。
- **不得修改 `spec/features/` 的內容**來讓測試通過；規格有誤，或 W08 平台查證後補上 `#TODO` 例子（§2.2）時，開 `spec-question` issue 討論，決定後再以 PR（含 D review）改規格。

### 8.2 完成的定義（Definition of Done）

一張 issue 要符合以下全部條件才能關閉：

- [ ] 對應 feature 的例子在 CI 全部通過（`@pending` 有對應 issue）
- [ ] 單元測試涵蓋演算法與邊界；覆蓋率符合 §8.1
- [ ] API 與 `openapi.yaml` 一致；新錯誤碼已登記
- [ ] 前端頁面有載入、空資料、錯誤三種狀態，並依角色顯示（§9）
- [ ] 稽核紀錄、Log、錯誤訊息不含密碼、Token、Webhook 網址
- [ ] ruff、mypy、eslint 通過，CI 綠燈
- [ ] 在 Docker Compose 環境手動操作過一次
- [ ] 另一模組組員 review 通過；影響文件時已更新文件

### 8.3 準備好的定義（Definition of Ready）

一張 issue 可以開始做的條件：符合《Issue 撰寫規範》的必備內容、依賴已交付或可用 `@pending` 隔離、預估 1～3 天。

---

## 9. 前端介面慣例

| 項目 | 規定 |
|---|---|
| 語言 | 介面一律繁體中文；代碼經 `labels.ts` 轉換，不在畫面顯示英文代碼 |
| 時間 | 顯示格式 `2026-10-06 12:00`（台灣時間）；排程時間選擇器只能選 5 分鐘整 |
| 載入 | 列表與頁面使用骨架畫面（`el-skeleton`）；按鈕送出時顯示載入並停用，避免重複送出 |
| 空資料 | 使用 `el-empty`，並提示下一步（例：「尚未連結平台帳號，請管理員連結」） |
| 錯誤 | API 錯誤以 `ElMessage` 顯示 `message`；表單錯誤顯示在欄位下方；`401` 自動導回登入 |
| 確認 | 刪除、停用、移除平台帳號、取消排程、重試「發佈逾時」前，跳出確認對話框（BR-32 要提醒先到平台確認） |
| 權限 | 依角色隱藏或停用按鈕，但**真正的檢查在後端** |
| 狀態顏色 | 草稿灰、已排程藍、發佈中橘、發佈完成綠、部分失敗黃、全部失敗紅；發佈紀錄同色系 |
| 輪詢 | 發佈中時每 3 秒更新發佈結果，全部結束後停止 |
| 憑證 | 任何畫面不顯示 Token 或 Webhook 網址；Webhook 輸入框使用密碼型欄位 |

---

## 10. 文件、Demo 與繳交

### 10.1 `docs/` **[課程規定]**

| 檔案 | 來源 | 負責 |
|---|---|---|
| `requirements.md` | 《mediagent MVP 規格》 | 全體 |
| `api-design.md` | 《API 設計》 | F |
| `openapi.yaml` | W06 產出，持續維護 | F 整合 |
| `architecture.md` | 《系統架構設計》 | D |
| `data-model.md` | 《資料模型》 | D |
| `final-report.pdf` | W18 | 全體 |

團隊自訂：`team-rules.md`、`issue-workflow.md`、`platform-notes.md`（M2，平台實測紀錄）、`runbook.md`（D、M2）。

### 10.2 README **[課程規定]**

由 D 負責，W13 完成，必須包含：專題名稱、問題、組員、功能、架構、主要 API、執行環境、啟動方式、測試方式、Docker 建置與執行、正式網址、Swagger 網址、CI 說明。

### 10.3 W16 Live Demo 腳本 **[課程規定：必須現場 Demo]**

| 步驟 | 內容 | 對應規定 |
|---|---|---|
| 1 | 開啟正式網址與 Swagger UI | Production URL、API Docs |
| 2 | 管理員登入，展示平台帳號（含授權到期時間）與幹部帳號 | 身分驗證 |
| 3 | 撰稿者嘗試立即發佈 → `403 FORBIDDEN` | 錯誤情況 |
| 4 | 發佈者撰寫貼文、附加直式海報、勾選三平台、預覽 Instagram 裁切、立即發佈，展示三則平台貼文連結 | 核心使用情境 |
| 5 | 展示發佈結果、變更歷程與稽核紀錄，證明資料已保存 | Database |
| 6 | 展示 GitHub Actions（含 452 個驗收例子）與 `/health` | CI、Health |

錄影只能當備案 **[課程規定]**。**Demo 前一週由管理員重新連結 Threads、Instagram**，避免授權到期。

### 10.4 Release 與繳交前檢查（Engineering Check）**[課程規定]**

- [ ] 正式網址可以開啟
- [ ] Swagger UI 可以開啟
- [ ] 核心使用情境可以完整操作
- [ ] 資料庫正常
- [ ] 身分驗證與權限檢查正常
- [ ] 自動化測試可以執行
- [ ] GitHub Actions 通過
- [ ] Docker 可以 Build
- [ ] `/health` 正常
- [ ] Log 可以追查錯誤
- [ ] README 資訊完整

---

## 11. 環境變數與密鑰

- `.env.example` 進 git，`.env` 不進 git；**密鑰絕不寫在程式碼中**。

| 變數 | 用途 |
|---|---|
| `DATABASE_URL` | 資料庫連線 |
| `JWT_SECRET` | 簽發 Access Token |
| `OAUTH_STATE_SECRET` | 簽章 OAuth `state` |
| `CREDENTIAL_ENCRYPTION_KEYS` | 平台憑證加密金鑰，可多把以輪替 |
| `CRON_SECRET` | 保護 `/internal/*` |
| `THREADS_APP_ID`、`THREADS_APP_SECRET` | Threads OAuth |
| `INSTAGRAM_APP_ID`、`INSTAGRAM_APP_SECRET` | Instagram OAuth |
| `OAUTH_REDIRECT_BASE_URL` | OAuth 回呼的後端網址 |
| `FRONTEND_ORIGIN` | CORS 與 OAuth 完成後導回的前端網址 |
| `MEDIA_STORAGE_BACKEND` | `local` 或正式環境的物件儲存 |
| 物件儲存的金鑰與公開網址前綴 | 選定服務後補上 |
| `DEV_MODE` | 開發模式（正式環境必須為 0） |
| `LOG_LEVEL`、`PORT` | Log 等級；服務埠號 |

- 正式環境的值只放在 Render；`CRON_SECRET` 另存 GitHub Secrets。只有 D 與組長能查看正式環境密鑰。

---

## 12. 平台開發者帳號與測試帳號

| 項目 | 規定 |
|---|---|
| Meta 開發者 App（Threads、Instagram） | 由 M2 建立；**另加一位組員為 App 管理員作為備援**，避免單一人員離開後無法管理 |
| 正式使用的社團帳號 | 社團的 Threads 與 Instagram（Instagram 須為專業帳號）加入 App 的測試者；Demo 使用 |
| 開發測試帳號 | 另建一組測試用 Threads、Instagram 帳號供開發驗證，**不在社團帳號上測試** |
| Discord | 建立團隊專用測試伺服器，每位需要的組員一個測試頻道與 Webhook |
| 帳密與金鑰保管 | 使用團隊共用的密碼管理工具（例如 Bitwarden 免費組織），**不得貼在 issue、PR、聊天群組或程式碼** |
| 紀錄 | 平台設定步驟、限制實測結果、遇到的錯誤記錄在 `docs/platform-notes.md` |
| 授權到期 | M2 在 `platform-notes.md` 記錄各帳號的到期日；到期前一週提醒管理員重新連結 |

---

## 13. Issue 標籤與看板

### 13.1 標籤

| 類別 | 標籤 |
|---|---|
| 模組 | `M1`、`M2`、`M3`、`M4`、`M5`、`F`、`D`、`core` |
| 類型 | `feature`、`bug`、`test`、`docs`、`chore`、`spec-question`（規格疑問） |
| 優先度 | `P0`（阻擋他人）、`P1`（本 sprint 必做）、`P2`（有時間再做） |
| 其他 | `blocked`（等待依賴）、`pending-example`（含 `@pending` 例子） |

### 13.2 看板（GitHub Projects）

| 欄位 | 進入條件 |
|---|---|
| Backlog | 已建立 |
| Ready | 符合 §8.3 準備好的定義 |
| In Progress | 已指派且開始實作；**每人同時最多 2 張** |
| In Review | PR 已開立 |
| Done | 符合 §8.2 完成的定義並已 merge |

- 每個 sprint 建立一個 Milestone（例：`Sprint 1 (W08-W09)`）。
- 共用核心與被依賴的函式一律標 `P0`，優先處理。

---

## 14. 容易忽略的規則

| 主題 | 規則 |
|---|---|
| 時區 | 全系統 UTC 儲存；前端才轉台灣時間；禁止使用不帶時區的 `datetime.now()`，一律用核心的 `clock.now()` |
| 排程延遲 | GitHub Actions 尖峰時可能延遲；Render 休眠喚醒約 1 分鐘；NFR-01 允許 10 分鐘 |
| 定時任務停用 | **公開 Repository 連續 60 天沒有活動時，GitHub 會停用定時任務**；寒暑假由 D 確認 |
| 重複發佈 | 寫回結果前確認仍為待發佈；排程掃描用 `SKIP LOCKED` |
| 平台 | Instagram 必須有圖、JPEG、專業帳號；Threads、Instagram 發文為兩步驟；Discord Webhook 網址等同密碼 |
| 授權 | 不自動刷新；平台帳號頁顯示到期日；Demo 前重新連結 |
| 錯誤處理 | service 拋 domain exception，由全域 handler 轉換；router 不 try/except |
| 限流 | IP 限流存在記憶體，重啟歸零（已知限制） |
| 整合時間 | 最後 2～3 週保留給整合與 Demo 準備 |

---

## 15. Kickoff 會議議程（約 2 小時）

1. 確認模組分工與負責人（§1）（20 分）
2. 走過《系統架構設計》§4～§6：依賴、共用核心、發佈引擎（20 分）
3. 走過《資料模型》§2、§4：代碼與寫入權限（15 分）
4. 走過《API 設計》§2：各模組認領自己的端點，分工寫 `openapi.yaml`（20 分）
5. Sprint 0 交付物與負責人（§2.1）（15 分）
6. Git 流程、PR、完成的定義（§4、§8）（15 分）
7. 平台開發者帳號與密碼管理（§12）（10 分）
8. 建立 GitHub Projects 看板與標籤（§13）（5 分）
