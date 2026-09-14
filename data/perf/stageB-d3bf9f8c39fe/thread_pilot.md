# Thread-policy pilot (stock vs sound, N=3)

| app | policy | setting | SU sound/stock (geomean over tests) | stock median (first test) |
|---|---|---|---|---|
| memcached | pinned | memcached -t 48 / sysbench 36 | 1.008 | ops_sec: 2100985 |
| memcached | paper | memcached -t 112 / sysbench 84 | 1.004 | ops_sec: 1830768 |
| mysql | pinned | memcached -t 48 / sysbench 36 | 1.014 | oltp_read_only: 45696 |
| mysql | paper | memcached -t 112 / sysbench 84 | 1.014 | oltp_read_only: 45760 |
