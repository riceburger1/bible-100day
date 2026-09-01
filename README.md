# 주의울림 관리자 콘텐츠 편집 V8

## 변경사항
- 공지사항: 등록된 공지를 드롭다운에서 선택해 수정 가능
- 공지사항: 새 공지 작성 버튼으로 새 등록 모드 전환
- 공지사항: 공개/비공개, 배너 여부를 수정 가능
- 말씀·성경공부: 기존 주차 목록을 선택해 말씀/질문을 불러온 뒤 수정 가능
- 말씀·성경공부: 새 주차 작성 버튼으로 새 등록 가능
- 말씀·성경공부: `youth_admin_save_weekly` RPC로 말씀과 질문을 한 번의 트랜잭션으로 저장
- RPC가 아직 없는 경우 기존 Data API 저장 방식으로 자동 fallback
- 오류가 나면 Supabase 오류 코드/메시지를 관리자 화면에 표시
- 감사기도 달력, 🔥/✅ 기록, 7일·30일 배지는 그대로 유지
- PWA 캐시 버전 `주의울림-v8-admin-content-editor`

## 적용순서
1. Supabase `youth-worship` 프로젝트 SQL Editor에서 `admin_content_editor_v5.sql` 전체 실행
2. GitHub `youth-worship-app` 저장소에서 `index.html`, `app.js`, `styles.css`, `sw.js` 교체
3. GitHub Pages 배포 후 Ctrl+F5
4. 관리자 로그인 후 화면에 `관리자 콘텐츠 편집 v8 준비 완료.` 문구 확인
5. 기존 주차/공지를 선택해 수정 저장, 또는 새 작성 버튼으로 신규 등록 테스트
