cd ~/backup/full/2026-04-21-21-22-45 


[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -tzf 16392.tar.gz 
PG_16_202307071/
PG_16_202307071/16390/
PG_16_202307071/16390/16415
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ 

[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ mkdir -p /var/db/postgres1/tbs_16392

tar -xzf 16392.tar.gz -C /var/db/postgres1/tbs_16392

ln -s /var/db/postgres1/tbs_16392 /var/db/postgres1/pg_tblspc/16392

[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf base.tar.gz -C /var/db/postgres1
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf pg_wal.tar.gz -C /var/db/postgres1/pg_wal
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$

touch /var/db/postgres1/standby.signal

pg_ctl start -D /var/db/postgres1

[postgres1@pg104 ~]$ touch /var/db/postgres1/standby.signal
[postgres1@pg104 ~]$ pg_ctl start -D /var/db/postgres1
ожидание запуска сервера....2026-04-21 18:42:26.164 GMT [45] СООБЩЕНИЕ:  передача вывода в протокол процессу сбора протоколов
2026-04-21 18:42:26.164 GMT [45] ПОДСКАЗКА:  В дальнейшем протоколы будут выводиться в каталог "log".
 готово
сервер запущен
[postgres1@pg104 ~]$ pg_ctl status -D /var/db/postgres1
pg_ctl: сервер работает (PID: 45)
/usr/local/bin/postgres "-D" "/var/db/postgres1"
[postgres1@pg104 ~]$ pg_ctl promote -D /var/db/postgres1
ожидание повышения сервера.... готово
сервер повышен
[postgres1@pg104 ~]$ 

[postgres1@pg104 ~]$ psql -h localhost -U postgres2 -p 9867 -d postgres -c "SELECT pg_is_in_recovery();"
Пароль пользователя postgres2: 
 pg_is_in_recovery 
-------------------
 f
(1 строка)

[postgres1@pg104 ~]$ 

stgres1@pg104 ~]$ psql -h localhost -U postgres2 -p 9867 -l
Пароль пользователя postgres2: 
                   postgres1@pg104                                          Список баз данных
     Имя      | Владелец  | Кодировка | Провайдер локали |  LC_COLLATE  |   LC_CTYPE   | локаль ICU | Правила ICU |      Права доступа      
--------------+-----------+-----------+------------------+--------------+--------------+------------+-------------+-------------------------
 bench_test   | postgres2 | SQL_ASCII | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | 
 bench_test2  | postgres2 | SQL_ASCII | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | 
 illgreennews | rmb       | WIN1251   | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | =Tc/rmb                +
              |           |           |                  |              |              |            |             | rmb=CTc/rmb
 postgres     | postgres2 | WIN1251   | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | 
 template0    | postgres2 | WIN1251   | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | =c/postgres2           +
              |           |           |                  |              |              |            |             | postgres2=CTc/postgres2
 template1    | postgres2 | WIN1251   | libc             | ru_RU.CP1251 | ru_RU.CP1251 |            |             | =c/postgres2           +
              |           |           |                  |              |              |            |             | postgres2=CTc/postgres2
(6 строк)

[postgres1@pg104 ~]$  