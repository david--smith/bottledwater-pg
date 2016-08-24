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
* after modifying the schemas, we need to use these schemas when writing out the data.
* if specified, we need to create and write to the new `_pg_transactions` Kafka topic as well.



