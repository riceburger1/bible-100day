# 관리자 말씀·성경공부 저장 오류 수정

## 확인된 문제
1. 관리자 로그인은 성공해도 Supabase RLS는 쓰기 작업마다 별도로 적용됩니다.
2. `weekly_contents`, `study_questions`에 관리자용 INSERT/UPDATE/DELETE 권한 또는 RLS 정책이 없으면 저장이 거부됩니다.
3. 기존 `app.js`는 실제 Supabase 오류를 숨기고 `저장에 실패했습니다.`만 표시했습니다.
4. 기존 새 주 저장은 `upsert(... onConflict: "week_start")`에 의존해 DB의 UNIQUE 제약 상태에 따라 실패할 수 있었습니다.
5. 기존 성경공부 질문 삭제 오류를 확인하지 않고 다음 INSERT를 실행했습니다.

## 수정 내용
- `admin_weekly_save_fix.sql`: 관리자용 테이블 권한 + RLS 정책을 안전하게 추가합니다.
- `app.js`: 기존 주를 먼저 조회해 UPDATE/INSERT를 결정하여 `onConflict` 의존성을 제거했습니다.
- 실제 Supabase 오류 코드(예: `42501`)를 관리자 화면에 표시합니다.
- 질문 DELETE 실패도 확인하여 어느 단계에서 막혔는지 알려줍니다.
- `sw.js`: 캐시 버전을 올려 수정된 `app.js`가 즉시 반영되도록 했습니다.

## 적용 순서
1. Supabase `youth-worship` → SQL Editor에서 `admin_weekly_save_fix.sql` 전체를 실행합니다.
2. GitHub `youth-worship-app`에서 `app.js`, `sw.js` 두 파일을 교체합니다.
3. GitHub Pages 배포가 끝나면 Ctrl+F5로 새로고침합니다.
4. 관리자 로그인 → 말씀/성경공부 입력 → `말씀·문제 저장`을 다시 누릅니다.
5. 문제가 남으면 화면에 Supabase 오류 코드가 표시되므로 그 문구를 캡처하면 다음 원인을 바로 특정할 수 있습니다.
