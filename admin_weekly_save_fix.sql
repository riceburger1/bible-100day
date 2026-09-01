-- youth-worship 관리자 말씀/성경공부 저장 권한 수정
-- 기존 테이블/데이터는 삭제하지 않습니다.
-- 여러 번 실행해도 같은 정책을 중복 생성하지 않도록 작성했습니다.

begin;

-- Data API에서 필요한 테이블 권한
-- 학생은 SELECT만, 관리자 로그인 사용자는 RLS를 통과할 때만 쓰기가 가능합니다.
grant select on table public.weekly_contents to anon, authenticated;
grant select on table public.study_questions to anon, authenticated;
grant insert, update, delete on table public.weekly_contents to authenticated;
grant insert, update, delete on table public.study_questions to authenticated;
grant select on table public.admin_users to authenticated;

alter table public.weekly_contents enable row level security;
alter table public.study_questions enable row level security;
alter table public.admin_users enable row level security;

-- admin_users: 로그인한 관리자가 자기 관리자 등록 행을 확인할 수 있어야
-- 다른 테이블의 관리자 정책(EXISTS)이 정상적으로 평가됩니다.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='admin_users'
      and policyname='admin_users_self_select'
  ) then
    create policy admin_users_self_select
      on public.admin_users
      for select
      to authenticated
      using ((select auth.uid()) = user_id);
  end if;
end
$$;

-- 학생/일반 사용자: 공개된 주간 말씀만 읽기
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='weekly_contents'
      and policyname='weekly_contents_public_select_v2'
  ) then
    create policy weekly_contents_public_select_v2
      on public.weekly_contents
      for select
      to anon, authenticated
      using (published = true);
  end if;
end
$$;

-- 관리자: 공개 여부와 관계없이 말씀 조회/등록/수정/삭제
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='weekly_contents'
      and policyname='weekly_contents_admin_select_v2'
  ) then
    create policy weekly_contents_admin_select_v2
      on public.weekly_contents
      for select
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='weekly_contents'
      and policyname='weekly_contents_admin_insert_v2'
  ) then
    create policy weekly_contents_admin_insert_v2
      on public.weekly_contents
      for insert
      to authenticated
      with check (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='weekly_contents'
      and policyname='weekly_contents_admin_update_v2'
  ) then
    create policy weekly_contents_admin_update_v2
      on public.weekly_contents
      for update
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
      with check (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='weekly_contents'
      and policyname='weekly_contents_admin_delete_v2'
  ) then
    create policy weekly_contents_admin_delete_v2
      on public.weekly_contents
      for delete
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;
end
$$;

-- 학생/일반 사용자: 공개된 주간 말씀에 연결된 성경공부 질문만 읽기
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='study_questions'
      and policyname='study_questions_public_select_v2'
  ) then
    create policy study_questions_public_select_v2
      on public.study_questions
      for select
      to anon, authenticated
      using (
        exists (
          select 1
          from public.weekly_contents w
          where w.id = study_questions.weekly_content_id
            and w.published = true
        )
      );
  end if;
end
$$;

-- 관리자: 성경공부 질문 조회/등록/수정/삭제
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='study_questions'
      and policyname='study_questions_admin_select_v2'
  ) then
    create policy study_questions_admin_select_v2
      on public.study_questions
      for select
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='study_questions'
      and policyname='study_questions_admin_insert_v2'
  ) then
    create policy study_questions_admin_insert_v2
      on public.study_questions
      for insert
      to authenticated
      with check (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='study_questions'
      and policyname='study_questions_admin_update_v2'
  ) then
    create policy study_questions_admin_update_v2
      on public.study_questions
      for update
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      )
      with check (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='study_questions'
      and policyname='study_questions_admin_delete_v2'
  ) then
    create policy study_questions_admin_delete_v2
      on public.study_questions
      for delete
      to authenticated
      using (
        exists (
          select 1 from public.admin_users a
          where a.user_id = (select auth.uid())
        )
      );
  end if;
end
$$;

commit;

-- 실행 후 아래 결과에서 관리자 정책이 보이면 정상입니다.
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname='public'
  and tablename in ('admin_users','weekly_contents','study_questions')
order by tablename, cmd, policyname;
