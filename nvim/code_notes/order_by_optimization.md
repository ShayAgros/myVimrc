## [src/OscarMysql80/sql/sql_optimizer.cc:1899 - global scope](file:///local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc#L1899)
<!-- git:HEAD -->

Checks whether we can skip the ordering. For example in case we're ordering with the same key as the index in which case the results would already
come sorted

---

