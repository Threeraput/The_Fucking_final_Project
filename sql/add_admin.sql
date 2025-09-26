INSERT INTO users (user_id, username, password_hash, first_name, last_name, email, is_active, is_approved, created_at, updated_at)
VALUES (
    '35b809a4-232d-453f-b3a5-1d4a3e7a04c1',  -- แทนด้วย UUID ใหม่ที่ไม่ซ้ำกัน
    'new_admin',
    '$2b$12$PT3bDqM9yegIi1vc5EQfUeQv55dVyIEaNi3ULhCWBPQh1BFYKba4G',  -- แทนด้วย password hash ที่คัดลอกมา
    'GuyKm',
    'Admin',
    'admin@gmail.com',
    true,
    true,
    NOW(),
    NOW()
);