docker-compose run --rm psql postgres -c "begin; insert into test (value) values('trans1'); insert into test (value) values('trans1'); insert into test (value) values('trans1'); commit;"
docker-compose run --rm psql postgres -c "begin; delete from test where id=1; commit;"
docker-compose logs bottledwater-avro
