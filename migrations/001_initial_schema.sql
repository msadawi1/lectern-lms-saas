-- 001_initial_schema.sql
-- Multi-tenant LMS API: initial schema, as agreed on Nov 18.
-- Tenant = organization (one per trainer). All deletes are soft (deleted_at),
-- so unique rules apply to non-deleted rows only (partial unique indexes).

BEGIN;

-- tutors: the logins that own organizations.
CREATE TABLE tutors (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    email           text        NOT NULL,
    password        text        NOT NULL,   -- password hash only, never the plain password
    first_name      text        NOT NULL,
    last_name       text        NOT NULL,
    last_signed_in  timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz
);

CREATE UNIQUE INDEX tutors_email_unique
    ON tutors (email)
    WHERE deleted_at IS NULL;

-- Organizations: the tenant. Exactly one per trainer.
CREATE TABLE organizations (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id  uuid        NOT NULL REFERENCES tutors (id),
    name        text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    deleted_at  timestamptz
);

CREATE UNIQUE INDEX organizations_trainer_unique
    ON organizations (trainer_id)
    WHERE deleted_at IS NULL;

-- Students: belong to exactly one organization.
CREATE TABLE students (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id  uuid        NOT NULL REFERENCES organizations (id),
    email            text        NOT NULL,
    password         text,                  -- hash only; NULL until the invite is activated
    first_name       text        NOT NULL,
    last_name        text        NOT NULL,
    status           text        NOT NULL DEFAULT 'invited'
                     CHECK (status IN ('invited', 'active', 'deactivated')),
    last_signed_in   timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz
);

CREATE UNIQUE INDEX students_org_email_unique
    ON students (organization_id, email)
    WHERE deleted_at IS NULL;

-- Invitation tokens: only the hash of the token is stored.
CREATE TABLE invitation_tokens (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      uuid        NOT NULL REFERENCES students (id),
    token_hash      text        NOT NULL UNIQUE,
    expires_at      timestamptz NOT NULL,
    invalidated_at  timestamptz            -- set when used or replaced by a resend
);

-- One live (not invalidated) token per student.
CREATE UNIQUE INDEX invitation_tokens_one_live_per_student
    ON invitation_tokens (student_id)
    WHERE invalidated_at IS NULL;

-- Courses.
CREATE TABLE courses (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id  uuid        NOT NULL REFERENCES organizations (id),
    code             text        NOT NULL,
    name             text        NOT NULL,
    description      text,
    thumbnail        text,
    is_published     boolean     NOT NULL DEFAULT false,
    seat_limit       integer     NOT NULL,
    deleted_at       timestamptz
);

-- Lessons: content is a Quill Delta; embeds hold attachment:<id>, never URLs.
CREATE TABLE lessons (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id        uuid        NOT NULL REFERENCES courses (id),
    organization_id  uuid        NOT NULL REFERENCES organizations (id),
    content          jsonb       NOT NULL,
    position         smallint    NOT NULL,
    deleted_at       timestamptz
);

CREATE UNIQUE INDEX lessons_course_position_unique
    ON lessons (course_id, position)
    WHERE deleted_at IS NULL;

-- Attachments: images only. The file lives in object storage under file_key.
CREATE TABLE attachments (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id        uuid        NOT NULL REFERENCES lessons (id),
    organization_id  uuid        NOT NULL REFERENCES organizations (id),
    alt_text         text,
    file_type        text        NOT NULL,
    file_key         text        NOT NULL,
    file_size        bigint      NOT NULL,
    deleted_at       timestamptz
);

-- Enrollments: unenrolling sets deleted_at.
CREATE TABLE enrollments (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id       uuid        NOT NULL REFERENCES students (id),
    course_id        uuid        NOT NULL REFERENCES courses (id),
    organization_id  uuid        NOT NULL REFERENCES organizations (id),
    created_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz
);

CREATE UNIQUE INDEX enrollments_student_course_unique
    ON enrollments (student_id, course_id)
    WHERE deleted_at IS NULL;

-- Lesson progress: completing twice must not create a second row.
CREATE TABLE lesson_progress (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lesson_id     uuid        NOT NULL REFERENCES lessons (id),
    student_id    uuid        NOT NULL REFERENCES students (id),
    completed_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (lesson_id, student_id)
);

COMMIT;