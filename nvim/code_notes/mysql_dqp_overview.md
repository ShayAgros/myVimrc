## [src/OscarMysql80/sql/handler.h:302 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/handler.h#L302)
<!-- git:HEAD -->

The file which defines the storage interface between mysql and internal (e.g. innodb) and extrenal (e.g. kermit) communication

---

## [src/OscarMysql80/sql/dd/dd_table.h:100 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/dd/dd_table.h#L100)
<!-- git:HEAD -->

dd (data dectionary) is mysql term for the metadata (information on where to map table + row to partition).
partitions represent a logical partition of the data (in mysql 5.7 it maps to files but it doesn't have to).

from kermit perspective the partition can map to an external shard

---

## [src/OscarMysql80/sql/dd/dd_table.cc:1659 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/dd/dd_table.cc#L1659)
<!-- git:HEAD -->

Creating the metadata information for kermit

---

## [src/OscarMysql80/sql/sql_union.cc:1009 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_union.cc#L1009)
<!-- git:HEAD -->

Goes over the request strucutre and creates an execution plan
E.g. for the request `SELECT (COUNT(*)) FROM T1 JOIN (SELECT * FROM T2)`
```
        (aggregate)
        |
    (join)
     /      \
    /           \
(filter result)     \
    |                \
(table scan T1)     (table scan T2)

Each node is associated an iterator which encapsulates the logic required to implement it

---

## [src/OscarMysql80/sql/sql_union.cc:1816 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_union.cc#L1816)
<!-- git:HEAD -->

An example of an iterator implementation for union

---

## [src/OscarMysql80/sql/sql_union.cc:1009 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_union.cc#L1009)
<!-- git:HEAD -->



---

## [src/OscarMysql80/sql/sql_select.cc:2212 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_select.cc#L2212)
<!-- git:HEAD -->

Join holds an intermediate state for the optimized tree which is later used to create the optimized plan

---

## [src/OscarMysql80/sql/sql_optimizer.cc:3175 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc#L3175)
<!-- git:HEAD -->

This function is the one that tries to check how many shards (/partitions) are needed to be used to process a sql command, and the one based on
which it's decided whether it's a single-shard pushdown (SSP) command

---

## [src/OscarMysql80/sql/sql_optimizer.cc:610 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc#L610)
<!-- git:HEAD -->

Check whether the query can be sent as a whole to the shard (single-shard pushdown)

---

## [src/OscarMysql80/sql/sql_optimizer.cc:614 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc#L614)
<!-- git:HEAD -->

Early exit in case of single shard pushdown

---

## [src/OscarMysql80/sql/sql_update.cc:493 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_update.cc#L493)
<!-- git:HEAD -->

table pruning operation (deciding whether it can go to single shard pushdown) for update operation

---

