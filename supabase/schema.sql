-- مخطط قاعدة بيانات باتشو (Supabase / PostgreSQL)
-- نفّذه من: Supabase Dashboard > SQL Editor

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  gender text not null check (gender in ('male', 'female')),
  birth_date date not null,
  country text not null,
  city text,
  marital_status text not null
    check (marital_status in ('single', 'divorced', 'widowed')),
  goal text not null default 'zawaj'
    check (goal in ('zawaj', 'misyar', 'getting_to_know')),
  religiosity text,
  bio text,
  photo_url text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.likes (
  from_user uuid not null references public.profiles(id) on delete cascade,
  to_user uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (from_user, to_user),
  check (from_user <> to_user)
);

-- مطابقة = إعجاب متبادل
create view public.matches as
select a.from_user as user_a, a.to_user as user_b
from public.likes a
join public.likes b
  on a.from_user = b.to_user and a.to_user = b.from_user
where a.from_user < a.to_user;

create table public.messages (
  id bigint generated always as identity primary key,
  sender uuid not null references public.profiles(id) on delete cascade,
  receiver uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index messages_pair_idx on public.messages (sender, receiver, created_at);

create table public.blocks (
  blocker uuid not null references public.profiles(id) on delete cascade,
  blocked uuid not null references public.profiles(id) on delete cascade,
  primary key (blocker, blocked)
);

create table public.reports (
  id bigint generated always as identity primary key,
  reporter uuid not null references public.profiles(id) on delete cascade,
  reported uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

-- ===== الأمان (RLS) =====
alter table public.profiles enable row level security;
alter table public.likes enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;

-- الملفات الشخصية: يراها أي مستخدم مسجّل ما لم يكن بينهما حظر
create policy "profiles_read" on public.profiles for select
  using (
    auth.uid() is not null
    and not exists (
      select 1 from public.blocks
      where (blocker = auth.uid() and blocked = profiles.id)
         or (blocker = profiles.id and blocked = auth.uid())
    )
  );
create policy "profiles_insert_own" on public.profiles for insert
  with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and is_verified = (
    select p.is_verified from public.profiles p where p.id = auth.uid()
  ));

create policy "likes_read_own" on public.likes for select
  using (from_user = auth.uid() or to_user = auth.uid());
create policy "likes_insert_own" on public.likes for insert
  with check (from_user = auth.uid());
create policy "likes_delete_own" on public.likes for delete
  using (from_user = auth.uid());

-- الرسائل: فقط بين متطابقين، ولا يرسل المحظور
create policy "messages_read_own" on public.messages for select
  using (sender = auth.uid() or receiver = auth.uid());
create policy "messages_send_to_match" on public.messages for insert
  with check (
    sender = auth.uid()
    and exists (
      select 1 from public.matches m
      where (m.user_a = sender and m.user_b = receiver)
         or (m.user_b = sender and m.user_a = receiver)
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker = receiver and b.blocked = sender)
         or (b.blocker = sender and b.blocked = receiver)
    )
  );

create policy "blocks_own" on public.blocks for all
  using (blocker = auth.uid()) with check (blocker = auth.uid());

create policy "reports_insert_own" on public.reports for insert
  with check (reporter = auth.uid());

-- تفعيل الدردشة اللحظية
alter publication supabase_realtime add table public.messages;

-- مخزن الصور: أنشئ bucket باسم avatars من Storage ثم فعّل سياسات الرفع للمستخدم المسجّل
