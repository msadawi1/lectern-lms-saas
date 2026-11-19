# API contract

Endpoint names, methods, paths and roles only. Request and response bodies, status codes and errors are filled in by the developer.

## Rules for every endpoint

- **The tenant comes from the login token, never from the path or body.** A trainer acts inside their own organisation; a student inside the one they belong to.
- **Another organisation's resource returns 404**, never 403 (invariant 1).
- **Deletes are soft:** `DELETE` sets `deleted_at`, and deleted rows are invisible to every read.
- **Roles:** `Public` needs no login. `Trainer` and `Student` need a valid login token of that role. Where a row lists both roles, they see different things, as noted.

## Health

| Method | Path | Name | Who |
| --- | --- | --- | --- |
| GET | `/health` | Health check | Public |

## Auth

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/auth/trainers/sign-up` | Trainer sign-up | Public | Creates the trainer and their organisation |
| POST | `/auth/trainers/sign-in` | Trainer sign-in | Public | |
| POST | `/auth/students/activate` | Activate student account | Public | Uses the invite token; the student sets their password here |
| POST | `/auth/students/sign-in` | Student sign-in | Public | **Open:** student emails are unique per organisation only, so the request must also identify the organisation |
| GET | `/auth/students/me` | Current profile | Student | |
| GET | `/auth/trainers/me` | Current profile | Trainer | |


## Students

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/students` | Invite student | Trainer | The only way to create a student. Calling it again for the same email is a retry or resend: same student, fresh token, new email |
| GET | `/students` | List students | Trainer | List: needs pagination |
| GET | `/students/{student_id}` | Get student | Trainer | |
| PATCH | `/students/{student_id}` | Update student | Trainer | Includes deactivation |
| DELETE | `/students/{student_id}` | Delete student | Trainer | |

## Courses

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/courses` | Create course | Trainer | |
| GET | `/courses` | List courses | Trainer, Student | Trainer: all their courses. Student: published courses only. List: needs pagination |
| GET | `/courses/{course_id}` | Get course | Trainer, Student | Student: published courses only |
| PATCH | `/courses/{course_id}` | Update course | Trainer | Includes publish, unpublish and seat limit |
| DELETE | `/courses/{course_id}` | Delete course | Trainer | |

## Lessons

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/courses/{course_id}/lessons` | Create lesson | Trainer | |
| GET | `/courses/{course_id}/lessons` | List lessons | Trainer, Student | Student: enrolled courses only. Ordered by position |
| GET | `/courses/{course_id}/lessons/{lesson_id}` | Get lesson | Trainer, Student | Student: enrolled courses only. Attachment references become fresh signed links |
| PATCH | `/courses/{course_id}/lessons/{lesson_id}` | Update lesson | Trainer | Includes content and position (reorder) |
| DELETE | `/courses/{course_id}/lessons/{lesson_id}` | Delete lesson | Trainer | |

## Attachments

Images only. Files go straight to storage; these endpoints never carry file bytes.

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/courses/{course_id}/lessons/{lesson_id}/attachments` | Start upload | Trainer | Gives the client somewhere to upload the file to |
| POST | `/courses/{course_id}/lessons/{lesson_id}/attachments/{attachment_id}/complete` | Confirm upload | Trainer | Marks the upload finished, so it can be embedded |
| DELETE | `/courses/{course_id}/lessons/{lesson_id}/attachments/{attachment_id}` | Delete attachment | Trainer | |

## Enrollments

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| POST | `/courses/{course_id}/enrollments` | Enroll | Trainer, Student | Student: enrolls themselves in a published course. Trainer: enrolls one of their students |
| GET | `/courses/{course_id}/enrollments` | List enrollments | Trainer | List: needs pagination |
| DELETE | `/courses/{course_id}/enrollments/{enrollment_id}` | Unenroll | Trainer | |

## Progress

| Method | Path | Name | Who | Notes |
| --- | --- | --- | --- | --- |
| PUT | `/courses/{course_id}/lessons/{lesson_id}/progress` | Mark lesson complete | Student | `PUT` because doing it twice has the same effect as once (invariant 6). No unmark |
| GET | `/courses/{course_id}/progress` | Course progress | Trainer, Student | Student: their own progress. Trainer: every student's progress in the course (the dashboard). Trainer view: needs pagination |