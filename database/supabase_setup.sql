-- NOVA Commercial AI Automation Platform
-- Run this entire file once in Supabase SQL Editor.
-- The frontend never receives the service-role key. Only n8n uses it.

begin;

create extension if not exists pgcrypto;

-- =========================================================
-- 1. DURABLE CONVERSATION LOG
-- =========================================================
create table if not exists public.ai_conversations (
    id uuid primary key default gen_random_uuid(),
    session_id text not null,
    request_id text not null unique,
    user_message text not null,
    assistant_message text not null,
    route text not null
        check (route in ('general', 'technical', 'strategy', 'blocked')),
    model text not null default 'openai/gpt-4.1-mini via OpenRouter',
    response_status text not null default 'completed'
        check (response_status in ('completed', 'blocked', 'failed')),
    risk_flags text[] not null default '{}'::text[],
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),

    constraint ai_conversations_session_length
        check (char_length(session_id) between 8 and 128),
    constraint ai_conversations_user_message_length
        check (char_length(user_message) between 1 and 4000),
    constraint ai_conversations_assistant_message_length
        check (char_length(assistant_message) between 1 and 20000)
);

create index if not exists ai_conversations_session_created_idx
    on public.ai_conversations (session_id, created_at desc);

create index if not exists ai_conversations_created_idx
    on public.ai_conversations (created_at desc);

create index if not exists ai_conversations_route_created_idx
    on public.ai_conversations (route, created_at desc);

create index if not exists ai_conversations_risk_flags_gin_idx
    on public.ai_conversations using gin (risk_flags);

-- =========================================================
-- 2. CURATED KNOWLEDGE BASE
-- Deterministic retrieval in n8n; no additional vector credential.
-- =========================================================
create table if not exists public.ai_knowledge_base (
    id uuid primary key default gen_random_uuid(),
    slug text not null unique,
    title text not null,
    category text not null
        check (category in ('general', 'technical', 'strategy', 'security')),
    content text not null,
    tags text[] not null default '{}'::text[],
    priority integer not null default 10
        check (priority between 0 and 100),
    active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint ai_knowledge_base_title_length
        check (char_length(title) between 3 and 180),
    constraint ai_knowledge_base_content_length
        check (char_length(content) between 20 and 12000)
);

create index if not exists ai_knowledge_base_active_priority_idx
    on public.ai_knowledge_base (active, priority desc, updated_at desc);

create index if not exists ai_knowledge_base_tags_gin_idx
    on public.ai_knowledge_base using gin (tags);

-- =========================================================
-- 3. DAILY PRODUCT INTELLIGENCE
-- =========================================================
create table if not exists public.ai_daily_insights (
    id uuid primary key default gen_random_uuid(),
    report_date date not null,
    content text not null,
    metrics jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),

    constraint ai_daily_insights_content_length
        check (char_length(content) between 20 and 30000)
);

create index if not exists ai_daily_insights_date_idx
    on public.ai_daily_insights (report_date desc);

-- =========================================================
-- 4. UPDATED_AT TRIGGER
-- =========================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_ai_knowledge_base_updated_at
    on public.ai_knowledge_base;

create trigger trg_ai_knowledge_base_updated_at
before update on public.ai_knowledge_base
for each row
execute function public.set_updated_at();

-- =========================================================
-- 5. ROW LEVEL SECURITY
-- No public/browser access. n8n uses the service-role credential.
-- =========================================================
alter table public.ai_conversations enable row level security;
alter table public.ai_knowledge_base enable row level security;
alter table public.ai_daily_insights enable row level security;

revoke all on table public.ai_conversations from anon, authenticated;
revoke all on table public.ai_knowledge_base from anon, authenticated;
revoke all on table public.ai_daily_insights from anon, authenticated;

grant all on table public.ai_conversations to service_role;
grant all on table public.ai_knowledge_base to service_role;
grant all on table public.ai_daily_insights to service_role;

-- =========================================================
-- 6. SAFE DATA-RETENTION FUNCTION
-- Run manually from SQL Editor, for example:
-- select public.cleanup_nova_data(90);
-- =========================================================
create or replace function public.cleanup_nova_data(retention_days integer default 90)
returns table (
    deleted_conversations bigint,
    deleted_insights bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
    conversation_count bigint;
    insight_count bigint;
begin
    if retention_days < 7 or retention_days > 3650 then
        raise exception 'retention_days must be between 7 and 3650';
    end if;

    delete from public.ai_conversations
    where created_at < now() - make_interval(days => retention_days);
    get diagnostics conversation_count = row_count;

    delete from public.ai_daily_insights
    where report_date < current_date - retention_days;
    get diagnostics insight_count = row_count;

    return query select conversation_count, insight_count;
end;
$$;

revoke all on function public.cleanup_nova_data(integer) from public, anon, authenticated;
grant execute on function public.cleanup_nova_data(integer) to service_role;

-- =========================================================
-- 7. STARTER KNOWLEDGE BASE
-- Edit these rows for the niche/client before selling or deploying.
-- =========================================================
insert into public.ai_knowledge_base
    (slug, title, category, content, tags, priority, active)
values
(
    'native-node-principle',
    'Prefer Native n8n Nodes',
    'technical',
    'Use a native n8n integration node when it supports the required operation and authentication. Native nodes are usually easier to understand, maintain, test and hand over than custom HTTP calls. Use an HTTP Request only when a native node cannot perform the required operation.',
    array['n8n', 'native nodes', 'maintainability', 'integration'],
    90,
    true
),
(
    'production-workflow-checklist',
    'Production Workflow Checklist',
    'technical',
    'A production workflow should validate inputs, define idempotency behavior, use explicit status values, separate retryable and non-retryable failures, log important decisions, protect secrets through credentials, include a rollback or recovery path and have a repeatable end-to-end test.',
    array['production', 'testing', 'idempotency', 'errors', 'observability'],
    95,
    true
),
(
    'supabase-security',
    'Supabase Security Boundary',
    'security',
    'The Supabase service-role key is a server-side secret and must never be placed in HTML, frontend JavaScript, screenshots, public repositories or client-side environment variables. Frontend access should use tightly scoped public credentials and RLS policies. This product keeps the service-role key only in the n8n Supabase credential.',
    array['supabase', 'security', 'service role', 'rls', 'secrets'],
    100,
    true
),
(
    'discovery-framework',
    'Automation Discovery Framework',
    'strategy',
    'Before proposing an automation, identify the trigger, current manual steps, decision points, systems involved, data sensitivity, volume, failure cost, human approval requirements, desired response time and measurable business outcome. Scope the first release around one reliable end-to-end business result.',
    array['discovery', 'client', 'scope', 'requirements', 'sales'],
    90,
    true
),
(
    'pricing-framework',
    'Value-Based Packaging Framework',
    'strategy',
    'Package commercial automations around business outcomes rather than node count. Separate discovery, build, testing, deployment, documentation and ongoing support. Price estimates should account for complexity, integrations, data risk, expected support load and the financial value or time saved for the client.',
    array['pricing', 'proposal', 'package', 'roi', 'client'],
    85,
    true
),
(
    'safe-answering',
    'Safe and Honest Answering',
    'general',
    'The assistant should distinguish confirmed facts from assumptions, avoid claiming that it performed actions it did not perform, never fabricate live information and give staged validation steps before production changes. Sensitive values must be redacted rather than repeated.',
    array['safety', 'honesty', 'validation', 'secrets'],
    100,
    true
)
on conflict (slug) do update
set
    title = excluded.title,
    category = excluded.category,
    content = excluded.content,
    tags = excluded.tags,
    priority = excluded.priority,
    active = excluded.active,
    updated_at = now();

commit;

-- Expected result: "Success. No rows returned."
