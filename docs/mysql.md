# MySQL: scripts and data shipped, performance measured at four configurations

MySQL 8.0.39 is part of the campaign at four configurations (native, stock ThreadSanitizer,
AllOpt with peeling, AllOpt with peeling and DynSTC) rather than the fourteen used for the other
applications. Reasons and costs:

- Building MySQL with the escape analysis took about 2.2 hours per configuration on 56 cores with the
  previous compiler (`aa8a6dd8a2e8`; the shipped one builds it in 459 s at 56 jobs)
  (`sql/sql_yacc.cc` dominates: a 1600-way switch whose join block has 1600 predecessors), on
  top of about an hour for an uninstrumented build. Seven escape-analysis configurations would
  have cost more than the other four applications together.
- A full run is five sysbench scripts at 180 s each, at 36 threads on our pinned set (84 on the
  whole machine as a second row), N = 5 plus a warm-up: about six hours per pass.
- Its speedup interval is about 14 points wide, so small effects are not resolvable on it in any
  case; the paper's MySQL rows are reported as nulls where the interval contains 1.0.

`40-perf.sh mysql` runs the four configurations if you have the time and the disk (about 100 GB
for the installs); `ART_SMOKE=1` builds the same four configurations, runs one unwarmed run each and shortens
every sysbench script to 20 s, to show the pipeline works. Our recorded runs are under `data/perf/`, and `90-tables.sh` regenerates the MySQL table
from them.
