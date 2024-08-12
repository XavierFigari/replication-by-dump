-- Drop the database if it exists
# DROP DATABASE IF EXISTS mydb;
# CREATE DATABASE mydb;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    age INT NOT NULL
);

CREATE TABLE IF NOT EXISTS fruits (
    id SERIAL PRIMARY KEY,
    fruitname VARCHAR(255) NOT NULL,
    weight INT NOT NULL
);

INSERT INTO users (username, age) VALUES ('Bob', 30);
INSERT INTO users (username, age) VALUES ('Johanna', 43);
INSERT INTO users (username, age) VALUES ('Tom', 20);

INSERT INTO fruits (fruitname, weight) VALUES ('Apple', 100);
INSERT INTO fruits (fruitname, weight) VALUES ('Banana', 200);
INSERT INTO fruits (fruitname, weight) VALUES ('Cherry', 50);


SELECT * FROM users;
SELECT * FROM fruits;