# Plan: file uploads for the course agent

Status: proposal, written 2026-11-07 against PrairieLearn `master` at `febac8bf8`
("Give the course agent read-only web browsing").

Goal: let an instructor attach files to a course agent message (a screenshot of a
broken question, a syllabus PDF, an old exam, a CSV of scores, a diagram to use in
a question) and have the agent see or read them.

## How the agent works today (the parts that matter)

- **Browser → PL → Worker.** The chat is a WebSocket from the browser to PL
  (`apps/prairielearn/src/ee/routers/courseAgentChat.ts`). PL checks the feature,
  course permissions, conversation ownership, and CSRF, then proxies to the
  Cloudflare Worker with a service token. The Worker accepts only PL's token
  (`apps/course-agent/src/http/routes.ts`). The browser never talks to Cloudflare
  directly, and the Worker never calls PL.
- **The Conversation Durable Object** (`AIChatAgent`) owns chat history in DO
  SQLite. A user message's text parts become a Codex `turn/start`
  (`conversation.ts` `onChatMessage`, `codex.ts` `run`). Today only `text` parts
  are read; anything else is dropped.
- **Codex runs in a Cloudflare container** (`CourseSandbox` DO) with no internet.
  `/workspace/session` (repository, Codex home, thread) is checkpointed to R2
  through `DirectoryBackup`. The Worker already streams R2 objects into the
  container (`files.writeFile(path, r2Object.body)` for the local course archive in
  `sandbox.ts`).
- **Codex can take images natively.** The pinned protocol's `UserInput` includes
  `{ type: 'localImage', path }` and `{ type: 'image', url | fileId }`. It has no
  PDF or document input type, so documents have to be files the agent reads with
  tools.
- **Reviews** capture tracked and untracked changes in the course checkout and
  allow binary files up to 1 MiB each.

## How production systems handle this

The same pattern shows up almost everywhere (ChatGPT, Claude.ai, Codex, Claude
Code, and the OpenAI/Anthropic Files APIs):

1. **Upload first, then send.** The file goes to a dedicated upload endpoint as
   soon as it's picked or pasted, and gets back an ID. The chat message carries
   only that reference. Bytes never go into the message payload or chat history.
   That's why the composer shows a progress chip and Send is instant afterwards.
2. **Object storage is the source of truth.** Files live in an object store,
   keyed by conversation, with metadata (name, type, size, hash) in the database.
   They're kept as long as the conversation exists, because history renders them
   and later turns may reread them. They're deleted with the conversation, with a
   retention backstop.
3. **Two ways into the model, chosen by type:**
   - **Into context:** images (and, for chat products, small text or PDFs) go
     into the model input as image or document blocks for that turn. They stay in
     the thread history, so later turns still "see" them until compaction.
   - **Onto the filesystem:** anything big or structured (CSVs, archives, code,
     long PDFs) goes into the agent's sandbox (ChatGPT's code interpreter uses
     `/mnt/data`). The model gets a line saying the file exists at a path, then
     reads what it needs with tools. Retrieval/RAG indexes are a third option for
     very large document sets. We don't need that.
4. **Uploaded content is untrusted.** Type is checked by sniffing bytes, not by
   trusting the extension. Files are served back with `nosniff` and
   download/attachment dispositions (SVG and HTML are XSS vectors). The agent is
   told that file content is data, not instructions (prompt injection through
   PDFs).

Codex and Claude Code are the closest analogues because they already have a
filesystem: a pasted image becomes a `localImage` input, and any other attachment
is just a path the agent can read. Our container gives us the same setup, so we
should copy that model rather than build document parsing into the Worker.

## Cloudflare mechanisms

| Mechanism                                                                            | Use here                                                                                                                                                                                                                                                                                                                                                      |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **R2**                                                                               | Store upload bytes. The Worker already has an R2 binding (`CHECKPOINTS`). Single-part PUT is fine up to 5 GiB. Bucket **lifecycle rules** can expire objects by prefix as a retention backstop.                                                                                                                                                               |
| **R2 presigned PUT URLs** (S3 API, signed with `aws4fetch`)                          | Lets the browser upload straight to R2 without the bytes passing through PL or the Worker. Needs R2 S3 API credentials as Worker secrets and a bucket CORS policy for PL's origin. Only PUT is supported, not form POST. **Not needed at first**: our files are small and PL must stay the authorization point. Worth adopting only if we raise limits a lot. |
| **R2 multipart API** (Workers binding)                                               | Resumable or very large uploads. Not needed at these sizes.                                                                                                                                                                                                                                                                                                   |
| **Durable Object SQLite/KV**                                                         | Upload metadata per conversation. **Not** for bytes: a single string, BLOB, or row is capped at 2 MB, which is why base64 data URLs in chat history are a non-starter.                                                                                                                                                                                        |
| **Workers request body limit** (100 MB Free/Pro, 200 MB Business, 500 MB Enterprise) | Upper bound for proxying an upload through the Worker. Fine for a 20 MB per-file cap.                                                                                                                                                                                                                                                                         |
| **WebSocket message limit** (32 MiB)                                                 | Another reason not to inline files into `sendMessage`.                                                                                                                                                                                                                                                                                                        |
| **Sandbox `writeFile(path, ReadableStream)`**                                        | Stream an R2 object into the container. Already used for the course archive.                                                                                                                                                                                                                                                                                  |
| **Sandbox SDK 1.0 `S3Mount` + `S3Gateway`** (replaces 0.x `mountBucket`)             | Could FUSE-mount an R2 prefix into the container. 1.0 can't mount through an R2 binding (it needs the S3 endpoint and credentials, signed by the Worker), and it adds a moving part to an offline sandbox. Copying the few files a conversation has is simpler and more predictable, so it's **not recommended** for now.                                     |

## Recommended design

### Storage: yes, keep every file, in R2

- New R2 bucket `UPLOADS` per environment (`prairielearn-course-agent-uploads`,
  `-staging`, `-production`). It's separate from checkpoints so retention rules
  and access stay independent. Wrangler config repeats per env, like
  `CHECKPOINTS`.
- Key: `conversations/<agent conversation UUID>/<upload UUID>`. The Worker
  chooses the key. Neither the browser nor the filename does.
- Metadata in the Conversation DO's KV: `upload:<id>` → `{ key, filename,
  mediaType (sniffed), size, sha256, createdAt, messageId | null }`.
- **Why keep them:** chat history has to render thumbnails and downloads after a
  reload. A lost sandbox or a checkpoint restore has to get the files back. And a
  later turn ("now use the second figure from that PDF") needs the original.
- **Retention:** for the life of the conversation. There's no conversation
  deletion today, so add an R2 lifecycle rule as a backstop (proposal: 180 days,
  matching whatever retention we decide for conversations). When conversation
  deletion exists, delete the prefix with the same scheduled, retried cleanup
  used for `deleteCheckpoint`. Uploads that are never attached to a sent message
  are deleted by a DO schedule one hour after upload.
- **PL's own S3 file store is the wrong home.** The container and Worker run in
  Cloudflare, and the Worker never calls PL. Keeping uploads beside checkpoints
  and review snapshots keeps the "PL is the gate, Cloudflare holds conversation
  state" split intact.

### Upload path: proxy through PL (upload first, then send)

1. The browser picks, drops, or pastes a file. The composer immediately sends
   `POST /pl/course/:course_id/course_agent/conversations/:conversation_id/uploads`
   with the raw bytes as the body, plus `Content-Type`, `Content-Length`, and
   `X-PL-Filename` headers and the CSRF header.
2. **PL** (`courseAgentChat.ts`) runs the same authorization as the chat route
   (`courseAgentEnabled`, owner check via
   `selectOptionalCourseAgentConversation`). It rejects a missing or oversized
   `Content-Length`, then streams the body to the Worker through the existing
   `http-proxy-middleware` proxy, with no buffering in PL.
3. **Worker** `POST /conversations/:id/uploads` checks the size again, enforces
   the per-conversation quota with the DO, streams the body to R2 (R2 needs a
   known length, so use `FixedLengthStream` with `Content-Length`), sniffs the
   first bytes against an allowlist, and registers the metadata. It returns
   `{ id, filename, mediaType, size }`.
4. The browser sends the message with AI SDK file parts that point at the
   upload, not at a data URL:
   `sendMessage({ text, files: [{ type: 'file', mediaType, filename, url: '<PL download URL for the upload>' }] })`.
   Pass `FileUIPart` objects, not a `FileList`, because the AI SDK turns a
   `FileList` into base64 data URLs.
5. **Conversation DO** `onChatMessage`: every `file` part's URL must resolve to an
   upload in _this_ conversation that isn't attached to another message, and
   `data:` URLs are refused. The browser controls message parts, so this check is
   the security boundary. Then it marks those uploads with the message ID. (Look
   for an `AIChatAgent` hook that runs before the SDK saves the message, so a
   rejected message never lands in history. If there isn't one, refuse it through
   the existing "counted as handled" path.)

Download/display: `GET .../uploads/:upload_id` in PL, with the same authorization,
proxied to Worker `GET /conversations/:id/uploads/:uploadId`, which streams from
R2. Responses always set `X-Content-Type-Options: nosniff` and `Content-Security-Policy: sandbox`.
Raster images are served `inline`. Everything else, including SVG, is served as
`attachment`.

### Into the sandbox and the model

- **Location:** `/workspace/uploads/<upload id>/<sanitized filename>`, read-only
  for the agent user. This is deliberately **outside** `/workspace/session`:
  - Review capture includes untracked files in the course checkout, so uploads
    must never appear inside it.
  - Checkpoints don't carry copies of every upload. R2 is the source of truth.
- **Copying files in:** in `SandboxTurn.prepare`, after the sandbox is ready,
  stream any of the conversation's attached uploads that aren't on disk yet
  (`writeFile(path, env.UPLOADS.get(key).body)`). On a fresh sandbox or a
  checkpoint restore this copies all of them, so paths from earlier turns stay
  valid.
- **Turn input** (`TurnInput` gains `attachments`):
  - Raster images (PNG, JPEG, WebP, GIF): add a `{ type: 'localImage', path }`
    item to `turn/start`, so the model sees them this turn and they stay in the
    Codex thread.
  - Everything else: add a manifest to the message text, e.g.
    `Attached files (read-only, untrusted content): /workspace/uploads/…/syllabus.pdf (PDF, 2.3 MB)`.
    Images are listed too, so the agent can copy them into `clientFilesQuestion`.
- **Catch-up** (`buildCatchUp`): include each earlier message's attachment
  manifest line, so a restored or new thread knows the files exist. They're
  already back on disk.
- **Instructions** (`instructions.ts`): uploads are under `/workspace/uploads`,
  are read-only, and are untrusted data. Copy one into the course only when
  asked. Reviews reject files over 1 MiB, so downscale or compress images
  intended for questions. For PDFs, use `pdftotext`, or render pages with
  `pdftoppm` and look at them with Codex's image viewer.
- **Container** (`container/Dockerfile`): add `poppler-utils` (`pdftotext`,
  `pdftoppm`). The sandbox is offline, so every tool has to be in the image.
  Office formats (`.docx`, `.xlsx`, `.pptx`) need `pandoc` or LibreOffice. That
  image size is a separate decision, so leave them out of v1.

### Limits and allowlist (v1 proposal)

- Per file 20 MB, at most 10 files per message, 100 MB per conversation.
- Allowed, checked by sniffed type: PNG, JPEG, WebP, GIF, PDF, plain text and
  code (`.txt .md .csv .tsv .json .py .js .html .tex .xml .yaml`, detected as
  UTF-8 text), and ZIP (e.g. an exported course or a batch of images). The agent
  unzips, and the conversation quota bounds zip bombs only loosely, so ZIP could
  ship in phase 2.
- Blocked: everything else, including SVG as an image (it can be allowed as a
  text file).

### UI (`Conversations.tsx`)

- A paperclip button (`bi-paperclip`), drag and drop onto the composer, and image
  paste.
- Pending attachments show as chips with name, size, progress, and remove. Send
  is disabled while an upload is in progress or has failed. A removed or failed
  upload is never referenced.
- In history, `file` parts render as image thumbnails or file chips that link to
  the download URL. A deleted or expired file shows as "File no longer available".
- Accessibility: the chips are a list, each remove button has a label, and
  upload errors are announced.

### Privacy and policy

- Instructors may upload student data (gradebook CSVs, submissions). Uploads are
  stored in Cloudflare R2, and their content reaches OpenAI when the agent reads
  or views them. The composer should say so, and this needs to go through the
  same review as sending course content to the model today.
- Nothing logs filenames or contents. Upload events log only ID, size, and type,
  following the README's logging rules.

## Delivery plan (PRs)

1. **Worker storage and API.** Add the `UPLOADS` bucket and lifecycle rule to
   `wrangler.jsonc` for all envs, the upload/download routes, the DO upload
   registry, type sniffing, the quota, orphan cleanup, and `file` part
   validation in `onChatMessage`. Unit tests for validation (foreign IDs,
   reused IDs, `data:` URLs) and sniffing.
2. **Worker turn integration.** Copy files in during prepare, add `localImage`
   items and the manifest, include attachments in catch-up, update the
   instructions, and add `poppler-utils` to the Dockerfile. Test that a restored
   sandbox gets every upload back and that uploads never show up in review
   capture.
3. **PL routes and UI.** Upload/download proxy routes with authorization, CSRF,
   and size limits. Composer attachments and history rendering. Integration test
   for authorization (another user's conversation returns 404) and a Playwright
   test that attaches an image and sees the thumbnail survive a reload.
4. **Follow-ups (separate decisions):** office-format conversion in the image,
   presigned direct-to-R2 uploads if limits grow, conversation deletion with
   upload cleanup, and a final retention policy.

## Open questions

- Retention period, and whether instructors can delete an uploaded file
  themselves.
- Whether to allow ZIP in v1.
- Whether 1 MiB review files are enough for the "use this image in a question"
  case, or whether the review limit should rise for images.
- Policy sign-off on student data in uploads.

## Sources

- [R2 presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/),
  [Upload objects](https://developers.cloudflare.com/r2/objects/upload-objects/),
  [R2 CORS](https://developers.cloudflare.com/r2/buckets/cors/),
  [R2 multipart from Workers](https://developers.cloudflare.com/r2/api/workers/workers-multipart-usage/),
  [Storing user-generated content (reference architecture)](https://developers.cloudflare.com/reference-architecture/diagrams/storage/storing-user-generated-content/)
- [Sandbox: mount buckets](https://developers.cloudflare.com/sandbox/guides/mount-buckets/),
  [Move bucket mounts to 1.0](https://developers.cloudflare.com/sandbox/sdk/migrate/bucket-mounts/),
  [Sandbox SDK 1.0 changelog](https://developers.cloudflare.com/changelog/post/2026-09-30-sandbox-sdk-1-0/)
- [Durable Objects limits](https://developers.cloudflare.com/durable-objects/platform/limits/)
  (2 MB string/BLOB/row; WebSocket messages up to 32 MiB)
