# mediagent API 設計

> 對象：mediagent 全體組員（前後端共同遵守的合約）
> 依據：`docs/requirements.md` 與 `spec/features/`
> 繳交時放在 `docs/api-design.md`；W06 依本文件產出 `docs/openapi.yaml`
> 相關文件：《mediagent 資料模型》（欄位與代碼）、《mediagent 系統架構設計》、《mediagent 團隊協作規範》

---

## 1. 共通規範

### 1.1 基本格式

| 項目 | 規定 |
|---|---|
| 前綴 | 所有端點為 `/api/v1/...`；`/health` 例外 |
| 格式 | Request 與 Response 皆為 JSON（`Content-Type: application/json`）；上傳圖片為 `multipart/form-data` |
| 命名 | 路徑用複數名詞與 kebab-case（`/platform-accounts`）；JSON 欄位用 snake_case |
| 時間 | 帶時區的 ISO 8601，一律 UTC（`2026-10-06T04:00:00Z`）；前端負責轉換台灣時間輸入與顯示（NFR-09） |
| 列舉值 | 英文代碼，對照表見《資料模型》§2；前端負責轉中文 |
| ID | 整數 |
| Request ID | 前端每個請求帶 `X-Request-Id`（UUID）；後端沒收到時自行產生，並在回應標頭回傳 |
| 文件 | `/docs`（Swagger UI）與 `/openapi.json` 在正式環境保持開放（課程規定） |

### 1.2 身分驗證（JWT + session）

| 項目 | 規定 |
|---|---|
| Access Token | JWT，有效 15 分鐘；放在 `Authorization: Bearer <token>`；內容含 `sub`（使用者 ID）、`sid`（session ID）、`exp` |
| Refresh Token | 隨機字串，有效 7 天；以 `HttpOnly`、`Secure`、`SameSite=None`、`Path=/api/v1/auth` 的 Cookie 傳送；資料庫只存雜湊 |
| 每次請求的檢查 | 驗證 JWT → 確認 `sid` 對應的 session 未撤銷、未過期 → 確認帳號為 `active` → **角色以資料庫為準**（角色調整立即生效） |
| 立即失效 | 登出撤銷目前 session；登出所有裝置與停用帳號撤銷該使用者全部 session（BR-43、NFR-07） |
| 開發模式 | `DEV_MODE=1` 時可用 `X-Dev-User: <user_id>` 標頭代替登入（正式環境無效） |

### 1.3 錯誤格式

所有錯誤回應皆為：

```json
{
  "code": "CONTENT_TOO_LONG",
  "message": "貼文超過 Threads 的字數上限",
  "detail": {"platform": "threads", "limit": 500, "length": 542},
  "request_id": "6f1c2a0e-6d0b-4b5e-9c55-2f0f6b1f8a11"
}
```

- `code`：錯誤碼，見 §4，前端依此判斷與顯示。
- `message`：中文說明，可直接顯示。
- `detail`：選填的補充資料。
- spec/features 中的 `Then 操作失敗` 對應「HTTP 狀態碼 ≥ 400」，並以 §4 的錯誤碼驗證是哪一種失敗。

### 1.4 分頁（BR-44、BR-45）

Request：`?page=1&page_size=20`，`page_size` 只能是 20、50、100（其他值回傳 `400 VALIDATION_ERROR`），預設 20。

Response：

```json
{
  "items": [],
  "page": 1,
  "page_size": 20,
  "total": 57,
  "total_pages": 3,
  "has_prev": false,
  "has_next": true
}
```

### 1.5 權限標示

本文件以 **A**（管理員）、**P**（發佈者）、**W**（撰稿者）標示可呼叫的角色。「W*」表示撰稿者只能操作自己建立的貼文（BR-18），對他人的貼文回傳 `403 FORBIDDEN`。停用帳號的請求一律 `401 UNAUTHENTICATED`。

---

## 2. 端點總覽

| # | 方法 | 路徑 | 角色 | 成功 | 功能（feature） | FR | 模組 |
|---|---|---|---|---|---|---|---|
| 1 | POST | `/auth/login` | 公開 | 200 | 登入 | FR-01 | M1 |
| 2 | POST | `/auth/refresh` | 已登入（Cookie） | 200 | — | FR-01 | M1 |
| 3 | POST | `/auth/logout` | A P W | 204 | 登出 | FR-23 | M1 |
| 4 | POST | `/auth/logout-all` | A P W | 204 | 登出所有裝置 | FR-24 | M1 |
| 5 | GET | `/auth/me` | A P W | 200 | — | — | M1 |
| 6 | GET | `/users` | A | 200 | 查看幹部帳號 | FR-03 | M1 |
| 7 | POST | `/users` | A | 201 | 建立幹部帳號 | FR-02 | M1 |
| 8 | PATCH | `/users/{id}` | A | 200 | 調整角色 | FR-04 | M1 |
| 9 | PUT | `/users/{id}/status` | A | 200 | 停用帳號、啟用帳號 | FR-05、FR-22 | M1 |
| 10 | DELETE | `/users/{id}/lock` | A | 204 | 解除鎖定 | FR-26 | M1 |
| 11 | GET | `/platform-accounts` | A P W | 200 | 查看平台帳號 | FR-07 | M2 |
| 12 | POST | `/platform-accounts/oauth-authorizations` | A | 200 | 連結、重新連結平台帳號（Threads、Instagram） | FR-06、FR-21 | M2 |
| 13 | GET | `/platform-accounts/oauth/callback` | 平台導回 | 302 | 同上 | FR-06、FR-21 | M2 |
| 14 | POST | `/platform-accounts` | A | 201 | 連結平台帳號（Discord） | FR-06 | M2 |
| 15 | PUT | `/platform-accounts/{id}/credential` | A | 200 | 重新連結平台帳號（Discord） | FR-21 | M2 |
| 16 | DELETE | `/platform-accounts/{id}` | A | 204 | 移除平台帳號 | FR-08 | M2 |
| 17 | GET | `/posts` | A P W | 200 | 查詢貼文列表 | FR-14 | M3 |
| 18 | POST | `/posts` | A P W | 201 | 建立貼文草稿 | FR-09 | M3 |
| 19 | GET | `/posts/{id}` | A P W | 200 | — | — | M3 |
| 20 | PATCH | `/posts/{id}` | A P W* | 200 | 修改貼文 | FR-12 | M3 |
| 21 | DELETE | `/posts/{id}` | A P W* | 204 | 刪除貼文 | FR-13 | M3 |
| 22 | POST | `/posts/{id}/image` | A P W* | 201 | 附加圖片 | FR-11 | M3 |
| 23 | DELETE | `/posts/{id}/image` | A P W* | 204 | 移除圖片 | FR-11 | M3 |
| 24 | POST | `/posts/{id}/copies` | A P W* | 201 | 複製為新草稿 | FR-27 | M3 |
| 25 | GET | `/posts/{id}/preview` | A P W | 200 | 預覽貼文 | FR-20 | M3 |
| 26 | PUT | `/posts/{id}/targets` | A P W* | 200 | 設定目標平台帳號 | FR-10 | M4 |
| 27 | PUT | `/posts/{id}/schedule` | A P（W* 只能改已排程的時間） | 200 | 設定排程 | FR-16 | M4 |
| 28 | DELETE | `/posts/{id}/schedule` | A P W* | 200 | 取消排程 | FR-25 | M4 |
| 29 | GET | `/posts/{id}/publish-records` | A P W | 200 | 查看發佈結果 | FR-17 | M4 |
| 30 | GET | `/posts/{id}/publish-records/history` | A P W | 200 | 查看發佈結果（變更歷程） | FR-17 | M4 |
| 31 | POST | `/posts/{id}/publish-jobs` | A P | 202 | 立即發佈、重試發佈 | FR-15、FR-18 | M5 |
| 32 | POST | `/internal/publish-due` | 定時任務 | 200 | 執行排程發佈 | FR-16 | M5 |
| 33 | POST | `/internal/publish-recovery` | 定時任務 | 200 | 發佈逾時恢復 | FR-28 | M5 |
| 34 | GET | `/audit-events` | A | 200 | 查詢稽核紀錄 | FR-19 | F |
| 35 | GET | `/health` | 公開 | 200 | — | 維運 | D |

- `/internal/*` 需帶 `X-Cron-Secret`，不列入公開文件（`include_in_schema=False`）。
- 本機開發另有 `GET /media/{storage_key}` 提供本機圖片（只在 `MEDIA_STORAGE_BACKEND=local` 時啟用）。

---

## 3. 端點規格

### 3.1 帳號與安全（M1）

#### 1. `POST /auth/login`

```json
// Request
{"email": " Alice@Club.org ", "password": "secret123"}
// Response 200（另以 Set-Cookie 回傳 Refresh Token）
{
  "access_token": "eyJhbGciOi...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {"id": 3, "email": "alice@club.org", "name": "Alice", "role": "publisher"}
}
```

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `401 LOGIN_FAILED` | 密碼錯誤、帳號不存在、停用、鎖定——**一律相同回應** | NFR-10、BR-41 |
| `429 TOO_MANY_LOGIN_ATTEMPTS` | 同 IP 60 秒內超過 10 次；回應帶 `Retry-After` | BR-42 |

#### 2. `POST /auth/refresh`
以 Cookie 中的 Refresh Token 換發新的 Access Token。Response 200 同登入的 `access_token`、`expires_in`。session 已撤銷、過期或帳號停用：`401 UNAUTHENTICATED`。

#### 3～5. `POST /auth/logout`、`POST /auth/logout-all`、`GET /auth/me`
- 登出：撤銷目前 session，清除 Cookie，204。
- 登出所有裝置：撤銷該使用者全部 session，204。
- `me`：回傳目前使用者 `{id, email, name, role}`。

#### 6. `GET /users`

```json
{"items": [{"id": 1, "email": "admin@club.org", "name": "社長", "role": "admin",
            "status": "active", "locked_until": null, "is_locked": false}]}
```
列出全部帳號（含停用），不分頁。

#### 7. `POST /users`

```json
// Request
{"email": "bob@club.org", "name": "Bob", "role": "writer", "initial_password": "abcd1234"}
```

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `400 VALIDATION_ERROR` | 角色不是三者之一、Email 格式錯誤 | |
| `422 PASSWORD_TOO_SHORT` | 初始密碼空白或少於 8 字元 | 4.1 |
| `409 EMAIL_TAKEN` | 標準化後 Email 已存在 | BR-40 |

#### 8. `PATCH /users/{id}`
Request `{"role": "admin"}`。可調整已停用帳號，帳號維持停用。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `409 LAST_ACTIVE_ADMIN` | 會讓系統沒有啟用中的管理員 | BR-19 |

#### 9. `PUT /users/{id}/status`
Request `{"status": "disabled"}` 或 `{"status": "active"}`。停用時同時撤銷該使用者所有 session。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `409 LAST_ACTIVE_ADMIN` | 停用最後一位啟用中的管理員 | BR-19 |
| `409 USER_ALREADY_DISABLED` | 帳號已是停用狀態（見 §5 #1） | BR-39 |
| `409 USER_NOT_DISABLED` | 啟用一個不是停用狀態的帳號 | BR-39 |

#### 10. `DELETE /users/{id}/lock`
清除鎖定到期時間並歸零失敗次數，不改變啟用或停用狀態。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `409 USER_NOT_LOCKED` | 目前未處於鎖定 | BR-39 |

### 3.2 平台帳號與串接（M2）

#### 11. `GET /platform-accounts`

```json
{"items": [{"id": 7, "platform": "instagram", "account_name": "guitar_club",
            "auth_status": "valid", "auth_expires_at": "2026-12-01T00:00:00Z"}]}
```
不含已移除者，也不含任何憑證；`auth_status` 為計算後的有效狀態（BR-09）。

#### 12～13. Threads、Instagram 的 OAuth 連結與重新連結

```json
// 12. Request：首次連結不帶 platform_account_id；重新連結帶入
{"platform": "instagram", "platform_account_id": 7}
// Response 200
{"authorization_url": "https://www.instagram.com/oauth/authorize?...&state=..."}
```

1. 前端將瀏覽器導向 `authorization_url`。
2. 平台導回 `13. /platform-accounts/oauth/callback?code=...&state=...`。`state` 為後端簽章的短效 Token，內含管理員 ID、平台、模式（連結或重新連結）與平台帳號 ID，用來防止偽造。
3. 後端完成換取 Token 後，以 302 導回前端 `/platform-accounts?result=<結果代碼>`：成功為 `linked`、`relinked`；失敗為下表的錯誤碼。

| 錯誤（回傳於 `result`） | 情境 | 規則 |
|---|---|---|
| `PLATFORM_AUTH_FAILED` | 使用者拒絕授權或平台授權失敗 | BR-37 |
| `PLATFORM_ID_MISMATCH` | 重新連結時平台識別碼不同 | BR-38 |
| `PLATFORM_ACCOUNT_NAME_TAKEN` | 同平台已有相同帳號名稱的未移除帳號（不記錄平台授權事件） | 4.2、BR-38 |

#### 14. `POST /platform-accounts`（Discord）

```json
{"platform": "discord", "account_name": "社團公告", "webhook_url": "https://discord.com/api/webhooks/..."}
```

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `400 PLATFORM_REQUIRES_OAUTH` | `platform` 為 Threads 或 Instagram（須改用端點 12） | — |
| `409 PLATFORM_ACCOUNT_NAME_TAKEN` | 名稱重複 | 4.2 |
| `422 WEBHOOK_INVALID` | 網址格式錯誤（須為 https 官方 Discord Webhook 網址，禁止內網位址與轉址）或 Discord 回應無效 | BR-37 |
| `503 VERIFICATION_UNAVAILABLE` | 網路或 Discord 暫時性錯誤 | BR-37 |

#### 15. `PUT /platform-accounts/{id}/credential`（Discord 重新連結）
Request `{"webhook_url": "..."}`；錯誤同端點 14（不含名稱重複，含 `422 WEBHOOK_INVALID` 網址格式與禁止內網位址／轉址檢查）。非 Discord 帳號：`400 PLATFORM_REQUIRES_OAUTH`。

#### 16. `DELETE /platform-accounts/{id}`
標記為已移除，並呼叫 M4 `lifecycle.on_platform_account_removed()` 處理所有受影響貼文（BR-23）。

### 3.3 貼文編輯（M3）

#### 17. `GET /posts?status=SCHEDULED&page=1&page_size=20`
依建立時間、ID 由新到舊；撰稿者也看得到他人貼文（BR-44）。

```json
{
  "items": [{
    "id": 42, "content": "本週三 19:00 社課…", "status": "SCHEDULED",
    "scheduled_at": "2026-10-06T04:00:00Z", "created_at": "2026-10-04T10:00:00Z",
    "creator": {"id": 3, "name": "Alice"}, "has_image": true,
    "targets": [{"id": 7, "platform": "instagram", "account_name": "guitar_club"}]
  }],
  "page": 1, "page_size": 20, "total": 1, "total_pages": 1, "has_prev": false, "has_next": false
}
```

#### 18～21. 建立、取得、修改、刪除貼文

```json
// 18. POST /posts → 201；20. PATCH /posts/{id} → 200
{"content": "本週三 19:00 社課在活動中心 201"}
// 19. GET /posts/{id} → 200
{
  "id": 42, "content": "…", "status": "DRAFT", "scheduled_at": null, "scheduled_by": null,
  "creator": {"id": 3, "name": "Alice"}, "created_at": "2026-10-04T10:00:00Z",
  "image": {"format": "jpeg", "size_bytes": 512000, "width": 1080, "height": 1920,
            "public_url": "https://…/orig.jpg",
            "ig_public_url": "https://…/ig.jpg", "ig_width": 1080, "ig_height": 1350,
            "ig_cropped": true},
  "targets": [{"id": 7, "platform": "instagram", "account_name": "guitar_club", "auth_status": "valid"}]
}
```

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `404 NOT_FOUND` | 貼文不存在或已刪除 | |
| `403 FORBIDDEN` | 撰稿者修改、刪除他人的貼文 | BR-18 |
| `409 POST_NOT_EDITABLE` | 貼文不是草稿或已排程 | BR-13 |
| `422 CONTENT_EMPTY` | 文字為空白 | BR-01 |
| `422 CONTENT_TOO_LONG` | 已排程貼文修改後超過目標平台上限 | BR-02、BR-24 |

刪除已排程貼文前，呼叫 M4 `lifecycle.on_post_deleting()` 將待發佈紀錄改為已取消。

#### 22. `POST /posts/{id}/image`
`multipart/form-data`，欄位 `file`。後端讀取實際格式與寬高，產生 Instagram 版本（BR-06）。Response 201 為上方 `image` 物件。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `409 IMAGE_ALREADY_ATTACHED` | 已有圖片 | BR-03 |
| `409 POST_NOT_EDITABLE` | 貼文不是草稿或已排程 | BR-13 |
| `422 IMAGE_FORMAT_INVALID` | 不是 JPEG | BR-04 |
| `422 IMAGE_TOO_LARGE` | 超過 8,000,000 位元組 | BR-04 |
| `422 IMAGE_DIMENSION_INVALID` | 寬高不符合目標平台限制（數值待 W08 查證） | 4.3.1 |

#### 23. `DELETE /posts/{id}/image`

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `404 NOT_FOUND` | 沒有圖片 | |
| `409 IMAGE_REQUIRED_BY_INSTAGRAM` | 目標含 Instagram | BR-05 |

#### 24. `POST /posts/{id}/copies`
任何狀態都可複製；Response 201 為新草稿（同端點 19 格式，無目標）。寫入 `POST_COPY` 稽核紀錄。

#### 25. `GET /posts/{id}/preview`

```json
{"items": [{
  "platform_account": {"id": 7, "platform": "instagram", "account_name": "guitar_club", "auth_status": "valid"},
  "text": "本週三 19:00 社課…", "char_count": 38, "char_limit": 2200,
  "image": {"url": "https://…/ig.jpg", "width": 1080, "height": 1350, "variant": "instagram"},
  "warnings": ["IMAGE_CROPPED"]
}]}
```
`warnings` 可能為 `CONTENT_TOO_LONG`、`IMAGE_CROPPED`、`AUTH_INVALID`（BR-46）。只讀取，不呼叫平台。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `422 NO_TARGET` | 尚未選擇目標平台帳號 | BR-46 |

### 3.4 目標與排程（M4）

#### 26. `PUT /posts/{id}/targets`
Request `{"platform_account_ids": [5, 7, 9]}`，以整組取代。已排程貼文同步發佈紀錄（BR-28）。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `400 TARGET_DUPLICATE` | 清單中有重複 | 4.3 |
| `409 POST_NOT_EDITABLE` | 貼文不是草稿或已排程 | BR-13 |
| `422 TARGET_NOT_AVAILABLE` | 平台帳號不存在或已移除 | BR-08 |
| `422 TARGET_AUTH_INVALID` | 授權失效或已過期 | BR-08、BR-09 |
| `422 IMAGE_REQUIRED_FOR_INSTAGRAM` | 沒有圖片卻選 Instagram | BR-05 |
| `422 CONTENT_TOO_LONG` | 已排程貼文的文字超過新目標上限 | BR-24 |
| `422 SCHEDULED_POST_REQUIRES_TARGET` | 已排程貼文清空目標 | BR-07 |

#### 27. `PUT /posts/{id}/schedule`
Request `{"scheduled_at": "2026-10-06T04:00:00Z"}`。草稿改為已排程並建立發佈紀錄；已排程則修改時間。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `403 FORBIDDEN` | 撰稿者為草稿設定排程，或修改他人貼文的排程 | BR-18 |
| `409 POST_NOT_SCHEDULABLE` | 貼文不是草稿或已排程 | BR-13 |
| `422 SCHEDULE_TIME_NOT_FUTURE` | 不晚於目前時間 | BR-10 |
| `422 SCHEDULE_TIME_NOT_ALIGNED` | 不是 5 分鐘整、秒數不為 0 | BR-10 |
| `422 NO_TARGET`、`CONTENT_TOO_LONG`、`IMAGE_REQUIRED_FOR_INSTAGRAM`、`TARGET_AUTH_INVALID`、`IMAGE_DIMENSION_INVALID` | 發佈限制不符合 | BR-02、05、07、08 |

#### 28. `DELETE /posts/{id}/schedule`
貼文改回草稿、清空排程時間、待發佈紀錄改已取消。Response 200 為貼文。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `409 POST_NOT_SCHEDULED` | 貼文不是已排程 | — |

#### 29. `GET /posts/{id}/publish-records`

```json
{
  "post_id": 42, "post_deleted": false, "post_status": "PARTIALLY_FAILED",
  "items": [{
    "id": 101,
    "platform_account": {"id": 7, "platform": "instagram", "account_name": "guitar_club", "removed": false},
    "status": "FAILED", "published_at": null, "platform_post_url": null,
    "failure_reason": "PLATFORM_UNAVAILABLE",
    "platform_error_message": "（只有管理員看得到此欄位）"
  }]
}
```
貼文已刪除時仍可查詢，`post_deleted` 為 `true`、`post_status` 為 `null`（BR-35）。非管理員的回應不含 `platform_error_message`。

#### 30. `GET /posts/{id}/publish-records/history`
回傳該貼文所有發佈紀錄的變更歷程，依時間由舊到新：`{publish_record_id, from_status, to_status, changed_at, actor_type, actor, reason}`。

### 3.5 發佈執行（M5）

#### 31. `POST /posts/{id}/publish-jobs`

```json
// 立即發佈
{"type": "immediate"}
// 重試
{"type": "retry"}
// Response 202
{"post_id": 42, "post_status": "PUBLISHING",
 "records": [{"id": 101, "platform_account_id": 7, "status": "PENDING"}]}
```
受理後立即回應，背景發佈（BR-30）。前端輪詢端點 29 直到沒有 `PENDING`。

| 錯誤 | 情境 | 規則 |
|---|---|---|
| `403 FORBIDDEN` | 撰稿者 | BR-18 |
| `409 POST_NOT_PUBLISHABLE` | 立即發佈：貼文不是草稿或已排程 | BR-12 |
| `409 POST_NOT_RETRYABLE` | 重試：貼文不是部分失敗或全部失敗 | BR-12 |
| `422 NOTHING_TO_RETRY` | 沒有可重試的紀錄；`detail.hints` 標示授權失效（請重新連結）或已移除（請複製為新草稿） | BR-34 |
| `422 NO_TARGET`、`CONTENT_TOO_LONG`、`IMAGE_REQUIRED_FOR_INSTAGRAM`、`TARGET_AUTH_INVALID`、`IMAGE_DIMENSION_INVALID` | 立即發佈的發佈限制不符合 | BR-02、05、07、08 |

#### 32～33. 定時任務端點
- `POST /internal/publish-due`：發佈排程時間已到的貼文。Response `{"started": 3}`。
- `POST /internal/publish-recovery`：處理進入發佈中超過 10 分鐘仍有待發佈紀錄的貼文（BR-33）。Response `{"checked": 1, "recovered": 1}`。
- 缺少或錯誤的 `X-Cron-Secret`：`401 UNAUTHENTICATED`。

### 3.6 稽核查詢（F）

#### 34. `GET /audit-events`

| 參數 | 說明 |
|---|---|
| `actor_type`、`actor_id` | 依操作者篩選；不含登入安全事件（BR-45） |
| `account_id` | 依對應帳號篩選：該帳號的登入安全事件 + 操作對象為該帳號的稽核紀錄 |
| `action` | 稽核操作類型（§2.5 代碼），或 `LOGIN_FAILED`、`LINK_FAILED`、`RELINK_FAILED` |
| `from`、`to` | 含開始、不含結束 |
| `page`、`page_size` | 同 §1.4 |

```json
{"items": [{
  "id": 501, "kind": "audit", "event_seq": 9821, "occurred_at": "2026-10-06T04:00:03Z",
  "actor_type": "system", "actor": null,
  "action": "POST_PUBLISH", "target": {"type": "post", "id": 42},
  "details": {"scheduled_by": 3, "post_creator_id": 3, "result": "PARTIALLY_FAILED"},
  "target_results": [{"platform_account_id": 7, "status": "FAILED", "failure_reason": "PLATFORM_UNAVAILABLE"}]
}], "page": 1, "page_size": 20, "total": 1, "total_pages": 1, "has_prev": false, "has_next": false}
```
`items` 為以 `kind` 區分的多型聯集（`audit`、`login_security`、`platform_auth`），共用 `id`（各表主鍵）、`kind`、`event_seq`、`occurred_at`；依時間、`event_seq` 由新到舊：

| `kind` | 專有欄位（對應《資料模型》§5.3、§5.5、§5.12～5.13） |
|---|---|
| `audit` | `actor_type`（`user`／`system`）、`actor`（`{id, email, name}` 或 `null`）、`action`、`target`（`{type, id}`）、`details`（選填欄位：`reason`、`related_post_id`、`scheduled_by`、`post_creator_id`、`result`）、`target_results`（發佈與重試時附帶：`{platform_account_id, status, failure_reason, skip_reason}`） |
| `login_security` | `event_type`（`LOGIN_FAILED`）、`failure_reason`、`attempted_email`、`account`（對應既有帳號時為 `{id, email, name}`，帳號不存在時為 `null`） |
| `platform_auth` | `actor_type`（恆為 `user`）、`actor`（`{id, email, name}`）、`event_type`（`LINK_FAILED`／`RELINK_FAILED`）、`platform`、`account_name`（未取得時為 `null`）、`platform_account_id`（首次連結失敗時為 `null`）、`failure_reason` |

### 3.7 健康檢查（D）

`GET /health` → 200 `{"status": "ok", "database": "ok"}`；資料庫無法連線時 503。

---

## 4. 錯誤碼總表

| HTTP | 錯誤碼 | 說明 | 規則 |
|---|---|---|---|
| 400 | `VALIDATION_ERROR` | 欄位缺漏、型別或格式錯誤、`page_size` 不是 20／50／100 | — |
| 400 | `TARGET_DUPLICATE` | 目標清單重複 | 4.3 |
| 400 | `PLATFORM_REQUIRES_OAUTH` | 對 Threads、Instagram 使用 Webhook 端點 | — |
| 401 | `UNAUTHENTICATED` | 未登入、Token 無效、session 已撤銷、帳號停用、`X-Cron-Secret` 錯誤 | NFR-07 |
| 401 | `LOGIN_FAILED` | 登入失敗（所有原因相同） | NFR-10 |
| 403 | `FORBIDDEN` | 角色不足，或撰稿者操作他人的貼文 | BR-17、BR-18 |
| 404 | `NOT_FOUND` | 資源不存在 | — |
| 409 | `EMAIL_TAKEN` | Email 已被使用 | BR-40 |
| 409 | `LAST_ACTIVE_ADMIN` | 會讓系統沒有啟用中的管理員 | BR-19 |
| 409 | `USER_ALREADY_DISABLED` | 停用已停用的帳號（暫定，見 §5） | BR-39 |
| 409 | `USER_NOT_DISABLED` | 啟用非停用帳號 | BR-39 |
| 409 | `USER_NOT_LOCKED` | 解除鎖定非鎖定帳號 | BR-39 |
| 409 | `PLATFORM_ACCOUNT_NAME_TAKEN` | 同平台帳號名稱重複 | 4.2 |
| 409 | `PLATFORM_ID_MISMATCH` | 重新連結的平台識別碼不同 | BR-38 |
| 409 | `POST_NOT_EDITABLE` | 貼文不是草稿或已排程 | BR-13 |
| 409 | `POST_NOT_SCHEDULABLE` | 不可設定排程的狀態 | BR-12 |
| 409 | `POST_NOT_SCHEDULED` | 取消非已排程貼文的排程 | — |
| 409 | `POST_NOT_PUBLISHABLE` | 不可立即發佈的狀態 | BR-12 |
| 409 | `POST_NOT_RETRYABLE` | 不可重試的狀態 | BR-12 |
| 409 | `IMAGE_ALREADY_ATTACHED` | 已有圖片 | BR-03 |
| 409 | `IMAGE_REQUIRED_BY_INSTAGRAM` | 目標含 Instagram 時移除圖片 | BR-05 |
| 422 | `PASSWORD_TOO_SHORT` | 初始密碼少於 8 字元 | 4.1 |
| 422 | `CONTENT_EMPTY` | 貼文文字空白 | BR-01 |
| 422 | `CONTENT_TOO_LONG` | 超過目標平台字數上限 | BR-02 |
| 422 | `IMAGE_FORMAT_INVALID` | 不是 JPEG | BR-04 |
| 422 | `IMAGE_TOO_LARGE` | 超過 8,000,000 位元組 | BR-04 |
| 422 | `IMAGE_DIMENSION_INVALID` | 寬高不符合目標平台限制 | 4.3.1 |
| 422 | `IMAGE_REQUIRED_FOR_INSTAGRAM` | 目標含 Instagram 但沒有圖片 | BR-05 |
| 422 | `NO_TARGET` | 沒有目標平台帳號 | BR-07、BR-46 |
| 422 | `SCHEDULED_POST_REQUIRES_TARGET` | 已排程貼文清空目標 | BR-07 |
| 422 | `TARGET_NOT_AVAILABLE` | 目標不存在或已移除 | BR-08 |
| 422 | `TARGET_AUTH_INVALID` | 目標授權失效或已過期 | BR-08、BR-09 |
| 422 | `SCHEDULE_TIME_NOT_FUTURE` | 排程時間不晚於目前 | BR-10 |
| 422 | `SCHEDULE_TIME_NOT_ALIGNED` | 排程時間不是 5 分鐘整 | BR-10 |
| 422 | `NOTHING_TO_RETRY` | 沒有可重試的紀錄 | BR-34 |
| 422 | `WEBHOOK_INVALID` | Discord Webhook 無效 | BR-37 |
| 422 | `PLATFORM_AUTH_FAILED` | 平台授權失敗 | BR-37 |
| 429 | `TOO_MANY_LOGIN_ATTEMPTS` | IP 登入次數超過限制 | BR-42 |
| 500 | `INTERNAL_ERROR` | 未預期錯誤；不洩漏內部細節 | — |
| 503 | `VERIFICATION_UNAVAILABLE` | 暫時無法向平台驗證 | BR-37 |

新增錯誤碼須在 PR 中同時更新本表與 `openapi.yaml`。

---

## 5. 待確認（規格未定義，實作前需決定）

| # | 事項 | 暫定 |
|---|---|---|
| 1 | 停用一個已經停用的帳號 | 回傳 `409 USER_ALREADY_DISABLED`，不寫稽核 |
| 2 | 發佈逾時恢復「檢查了但狀態沒有改變」要寫入稽核紀錄，但規格的稽核操作類型沒有對應項目 | 新增操作類型 `PUBLISH_RECOVERY`（發佈逾時恢復）；需同步更新 `docs/requirements.md` 4.5 |
| 3 | Discord 成功發佈後的貼文網址組成方式 | W08 實測 Webhook 回應後決定 |
