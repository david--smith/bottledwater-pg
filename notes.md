# Fork description

This fork intends to augment Bottled Water to include transaction and write-ahead log information when writing to Kafka.

The ideal feature(s) would be:

* user can specify whether Bottled Water should output transaction information (transaction ID `xid` and write-ahead log position `wal_pos`) for each commit. 
* user can specify whether to include the above transaction information in either or both:

    - the existing table-specific Kafka topics. Proposed Kafka-msg format:
    ```
        xid: 123456,
        wal_pos: "123BD222/6737DCA2",
        record: {
            ...
        }
    ```

    - a new `_pg_transactions` table. Proposed Kafka-msg format:
    ```
        rel: "my_table",
        xid: 123456,
        wal_pos: "123BD222/6737DCA2",
        record: {
            ...
        }
    ```


# New scripts for automating building/testing

On my Mac, exitsing Bottled Water tests would largely fail. Further, in order to "integration" test code changes, I found it always safest to rebuild/relaunch the Docker containers from a clean state.

In [./scripts](scripts), you'll find scripts to help automate the integration-test process, including these main ones:

* `rebuild-all.sh`: stops and removes ALL running containers (NOT just the ones related to Bottled Water), re-builds the containers, launches the containers, writes some data to the database, and displays the logs from Bottled Water.
* `populate-db.sh`: performs adds, updates, and deletes against the database, then displays the logs from Bottled Water.
* `plsql.sh`: opens a PL/SQL session against the database.


# Progress

This fork's differences from the upstream project's master branch can be [seen here by initiating a pull request](https://github.com/confluentinc/bottledwater-pg/compare/master...david--smith:feature/transactions?expand=1) -- but do NOT submit the request!

The code has been adapted to pass the `xid` all the way through to the Kafka writer. 

# TODO

* the code needs to pass along the `wal_pos` the same way that it passed along the `xid`. 
* the code needs to modify the Avro schema(s) (built on the fly; stored in schema registry) to handle the writing of `xid`, `wal_pos`, and `record` instead of writing just the naked `record`.
    - the code where the schemas get generated per table (called `Relation`s) [is in `oid2avro.schema_for_table_row()`](https://github.com/david--smith/bottledwater-pg/blob/master/ext/oid2avro.c#L122) -- specifically [iterating through the columns here](https://github.com/david--smith/bottledwater-pg/blob/master/ext/oid2avro.c#L165-L178).
    - attempted code changes to this class to add one attribute, which fails due to memory corruption (*NOTE: for simplicity, new attr `__wal_pos` is set as a `long` but in reality it will need to be a string; it is a `uint64_t`, for which there is no Avro data type*):

```
        index affeaf9..89cb543 100644
        --- a/ext/oid2avro.c
        +++ b/ext/oid2avro.c
        @@ -126,6 +126,8 @@ int schema_for_table_row(Relation rel, avro_schema_t *schema_out) {
             avro_schema_t record_schema, column_schema;
             TupleDesc tupdesc;
             predef_schema predef;
        -    avro_schema_t wal_pos_schema = avro_schema_long();
        -    char* wal_pos_att_name = make_avro_safe("__wal_pos");
             int err = 0;

             memset(&predef, 0, sizeof(predef_schema));
        @@ -177,6 +179,10 @@ int schema_for_table_row(Relation rel, avro_schema_t *schema_out) {
                 if (err) break;
             }

        -    avro_schema_record_field_append(record_schema, wal_pos_att_name, wal_pos_schema);
        -    avro_schema_decref(wal_pos_schema);
        -    free(wal_pos_att_name);
        +
             *schema_out = record_schema;
             return err;
         }
        @@ -186,6 +192,12 @@ int schema_for_table_row(Relation rel, avro_schema_t *schema_out) {
          + by schema_for_table_row(). */
         int tuple_to_avro_row(avro_value_t *output_val, TupleDesc tupdesc, HeapTuple tuple) {
             int err = 0, field = 0;
        +
        -    // avro_schema_t wal_pos_schema = avro_schema_string();
        -    // avro_value_iface_t  *wal_pos_iface = avro_generic_class_from_schema(wal_pos_schema);
        -    avro_value_t *wal_pos_value;
        -    avro_value_t wal_pos_branch_val;
        +
             check(err, avro_value_reset(output_val));

             for (int i = 0; i < tupdesc->natts; i++) {
        @@ -209,6 +221,13 @@ int tuple_to_avro_row(avro_value_t *output_val, TupleDesc tupdesc, HeapTuple tup
                 field++;
             }

        -    check(err, avro_value_set_branch(wal_pos_value, 1, &wal_pos_branch_val));
        -    check(err, avro_value_set_long(&wal_pos_branch_val, 379379));
        +
        -    // the index (if we need it) where to insert is: tupdesc->natts
        -    // check(err, update_avro_with_datum(&field_val, attr->atttypid, datum));
        -    // avro_value_set_string("__wal_pos", wal_pos_datum);
        +
             return err;
         }
```


* after modifying the schemas, we need to use these schemas when writing out the data and reading back the data.
* if specified, we need to create and write to the new `_pg_transactions` Kafka topic as well.
    - when writing the data to Kafka, the producer is telling the producer to [free the memory associated with the message via `RD_KAFKA_MSG_F_FREE`](https://github.com/david--smith/bottledwater-pg/blob/master/kafka/bottledwater.c#L563). We CANNOT do it this way if the same record is also to be written to the `_pg_transactions` Kafka topic; we need to free the record only AFTER writing it to both topics -- [we need to use `RD_KAFKA_MSG_F_COPY` the first time we write](http://docs.confluent.io/2.0.1/clients/producer.html#asynchronous-writes).



