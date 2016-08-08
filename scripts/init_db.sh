docker-compose run --rm psql postgres -c "create extension bottledwater; create table test (id serial primary key, value text); insert into test (value) values('hello world');"
