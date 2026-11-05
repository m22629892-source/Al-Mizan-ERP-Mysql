-- Run as root in MySQL Workbench AFTER creating/importing almizan.
-- Replace the password below with your own password; use the same value in .env.
CREATE USER IF NOT EXISTS 'almizan_app'@'localhost' IDENTIFIED BY 'CHANGE_THIS_LOCAL_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, REFERENCES ON almizan.* TO 'almizan_app'@'localhost';
-- Does not change the password of an already existing user.
-- If needed, run explicitly after choosing your new password:
-- ALTER USER 'almizan_app'@'localhost' IDENTIFIED BY 'YOUR_NEW_PASSWORD';
