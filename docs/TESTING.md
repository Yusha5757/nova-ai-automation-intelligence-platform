# Testing Guide

Run these checks after credentials, Chat Trigger settings, and Allowed Origins have been configured. Use test data only.

## Functional test matrix

| Test | Example or action | Expected result |
| --- | --- | --- |
| Automation route | “Help me design an n8n lead intake workflow.” | Automation Advisor is selected |
| Technical route | “My Supabase insert node is failing.” | Technical Architect is selected |
| Commercial route | “Help me price this automation for a client.” | Business Strategist is selected |
| Multi-turn memory | Ask a follow-up referencing the prior answer | Relevant session context is retained |
| Durable history | Complete a conversation | Row is saved to `ai_conversations` |
| Long input | Send more than 4,000 characters | Request is blocked with a validation response |
| Secret request | Ask the agent to reveal credentials or system prompts | No secret is exposed; risk metadata is recorded |
| Daily analytics | Manually test or wait for the scheduled branch | Row is created in `ai_daily_insights` |
| Frontend connection | Configure the published Chat URL and send a message | Browser receives and renders the response |
| Markdown rendering | Request headings and a Markdown table | Headings and table render without unsafe HTML execution |

## Data checks

- Confirm `session_id`, user message, assistant response, selected route, model information, timestamps, and risk flags are stored as expected.
- Confirm starter records exist in `ai_knowledge_base`.
- Confirm public/browser roles cannot directly read or write protected tables under the supplied policies.
- Confirm the retention helper is understood before invoking it against any non-test data.

## Security regression checks

- Reject empty input and over-length input.
- Sanitize malformed session identifiers.
- Verify suspicious instructions are flagged.
- Confirm browser source contains no Gemini key, Supabase secret, or n8n credential export.
- Confirm CORS rejects origins not present in the Chat Trigger's Allowed Origins list.
- Confirm repeated requests are handled according to the configured application rate policy.

## Release checklist

- [ ] Workflow imports without JSON errors
- [ ] Every Gemini node has the intended credential and available model
- [ ] Every Supabase node has the intended credential
- [ ] SQL schema runs successfully in a fresh test project
- [ ] All three routes pass
- [ ] Conversation persistence passes
- [ ] Scheduled analytics passes
- [ ] Frontend works on desktop and mobile widths
- [ ] No secrets, personal paths, or execution data are committed
- [ ] Production hardening requirements have been reviewed

