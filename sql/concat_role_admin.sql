INSERT INTO user_roles (user_id, role_id)
VALUES (
    '35b809a4-232d-453f-b3a5-1d4a3e7a04c1', -- user_id ของ Admin คนใหม่
    (SELECT id FROM roles WHERE name = 'admin') -- ค้นหา role_id ของ 'admin' โดยอัตโนมัติ
);