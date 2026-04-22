## [src/OscarMysql80/storage/perfschema/pfs_instr.cc:1520 - create_socket](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/storage/perfschema/pfs_instr.cc#L1520)
<!-- git:HEAD -->

Create the socket for new connection and initialize its instrumentation

---

## [src/OscarMysql80/storage/perfschema/table_events_waits_summary.cc:332 - make_socket_row](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/storage/perfschema/table_events_waits_summary.cc#L332)
<!-- git:HEAD -->

Connection number aggregation before outputting it to the query
```mysql
select * from performance_schema.events_waits_summary_global_by_event_name   where event_name like "%client_connection%"
```

---

## [src/OscarMysql80/storage/perfschema/pfs.cc:8052 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/storage/perfschema/pfs.cc#L8052)
<!-- git:HEAD -->

The point where the connection counter is being incremented

---

## [src/OscarMysql80/include/mysql/psi/mysql_socket.h:232 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/include/mysql/psi/mysql_socket.h#L232)
<!-- git:HEAD -->

The code that checks whether the instrumentation is enabled and it is the locker variable is initialized with the instrumentation start

---

