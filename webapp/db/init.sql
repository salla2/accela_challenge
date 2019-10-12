CREATE DATABASE users;
use users;

CREATE TABLE active_users (
  name VARCHAR(20),
  user_id INT(10)
);

INSERT INTO active_users
  (name, user_id)
VALUES
  ('Satya', 1),
  ('Ram', 2),
  ('Sai', 3);

