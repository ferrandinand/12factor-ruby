CREATE DATABASE factor;
CREATE USER docker WITH PASSWORD 'docker';
GRANT ALL PRIVILEGES ON DATABASE "factor" to docker;
CREATE TABLE Countries (id int, name varchar(255));
