# MySQL: scripts and data shipped, performance measured at four configurations

MySQL 8.0.39 is part of the campaign at four configurations (native, stock ThreadSanitizer,
AllOpt with peeling, AllOpt with peeling and DynSTC) rather than the fourteen used for the other
applications. Reasons and costs:

- The configuration set was fixed when building MySQL with the escape analysis took about 2.2 hours
  per configuration on 56 cores with the previous compiler (`aa8a6dd8a2e8`; `sql/sql_yacc.cc` dominates:
  a 1600-way switch whose join block has 1600 predecessors). At that cost the escape-analysis
  configurations would have taken longer to build than the other four applications together. The shipped
  compiler builds the same configuration in 459 s at 56 jobs, so the cost that remains is the runs.
- A full run is five sysbench scripts at 180 s each, at 36 threads on our pinned set (84 on the
  whole machine as a second row): about 3.4 hours for the four configurations at N = 2 plus a warm-up,
  6.7 hours at N = 5.
- Its speedup intervals are 7 to 8 points wide (AllOpt with peeling 1.042 [0.985, 1.062]), so small effects
  are not resolvable on it; rows whose interval contains 1.0 are reported as no measurable change.

The workload is `harness/sql/mysql/benchmysql/run-one.sh` (server start, sysbench prepare, run, cleanup, server
shutdown, once per sysbench script): the data directory is initialised once per container run under the container's
`/tmp` (about half a gigabyte, sysbench's default one table of 10 000 rows) and reused by every configuration of the
leg, the server listens on `/tmp/mysql.sock`, and both vanish with the container, so a server ThreadSanitizer killed
cannot leave a dirty data directory for the next run.

`40-perf.sh mysql` runs the four configurations if you have the time and the disk (about 100 GB
for the installs); `ART_SMOKE=1` builds the same four configurations, runs one unwarmed run each and shortens
every sysbench script to 20 s, to show the pipeline works. Our recorded runs are under `data/perf/`, and `90-tables.sh` regenerates the MySQL table
from them.
