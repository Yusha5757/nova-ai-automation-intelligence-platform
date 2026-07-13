# Setup Guide

## Prerequisites

- An n8n instance that supports native AI Agent and Google Gemini nodes
- A Google Gemini API credential
- A Supabase project and API credential
- Python 3 or another static-file server for the frontend

Only Google Gemini API and Supabase API credentials are required. Never place real keys in this repository or in frontend JavaScript.

## 1. Prepare Supabase

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Run [`database/supabase_setup.sql`](../database/supabase_setup.sql).
4. Confirm that these tables exist:
   - `ai_conversations`
   - `ai_knowledge_base`
   - `ai_daily_insights`
5. Confirm that starter rows exist in `ai_knowledge_base`.
6. Keep the service-role credential server-side in n8n.

## 2. Import and configure n8n

1. In n8n, import [`workflow/NOVA_Commercial_AI_Automation_Platform_GEMINI_NATIVE_CLEAN.json`](../workflow/NOVA_Commercial_AI_Automation_Platform_GEMINI_NATIVE_CLEAN.json).
2. Create or select a native **Google Gemini API** credential.
3. Create or select a native **Supabase API** credential.
4. Assign the Gemini credential to every Google Gemini Chat Model node.
5. Assign the Supabase credential to every Supabase node.
6. Review the selected Gemini model against the models currently available to your account.
7. Open the Chat Trigger and enable public availability.
8. Select **Embedded Chat** mode.
9. Set **Allowed Origins** to the exact origin used by the frontend, such as `http://localhost:5500` during local development.
10. Publish the workflow and copy its production Chat URL.

The imported workflow is inactive by default. It must be configured and published before the frontend can use it.

## 3. Run the frontend

The frontend accepts the Chat URL through its connection modal. You may instead set `DEFAULT_WEBHOOK_URL` in `frontend/index.html` for your own deployment, but never add credentials.

```bash
cd frontend
python -m http.server 5500
```

Open `http://localhost:5500`, paste the published n8n Chat URL, and save the connection. Keep both n8n and the static server running.

You can also provide a valid URL through the `webhook` query parameter for local testing. Treat any deployed Chat URL as configuration and apply suitable access controls.

## 4. Verify the installation

1. Send a general n8n design question and verify the Automation Advisor route.
2. Send a Supabase debugging question and verify the Technical Architect route.
3. Send a pricing question and verify the Business Strategist route.
4. Confirm a new row appears in `ai_conversations`.
5. Verify that multi-turn context is retained for the same session.
6. Test the scheduled analytics branch and confirm a row appears in `ai_daily_insights`.

For a complete checklist, see [TESTING.md](TESTING.md).

