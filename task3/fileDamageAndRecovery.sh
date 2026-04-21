[postgres2@pg101 ~]$ pg_ctl stop -D /var/db/postgres2/wzo28 -m immediate
ожидание завершения работы сервера.... готово
сервер остановлен
[postgres2@pg101 ~]$ 

mv /var/db/postgres2/wzo28/pg_wal /var/db/postgres2/wzo28/pg_wal.broken


[postgres2@pg101 ~]$ pg_ctl start -D /var/db/postgres2/wzo28
ожидание запуска сервера....2026-04-21 18:55:09.078 GMT [3306] СООБЩЕНИЕ:  передача вывода в протокол процессу сбора протоколов
2026-04-21 18:55:09.078 GMT [3306] ПОДСКАЗКА:  В дальнейшем протоколы будут выводиться в каталог "log".
 прекращение ожидания
pg_ctl: не удалось запустить сервер
Изучите протокол выполнения.
[postgres2@pg101 ~]$ 

[postgres2@pg101 ~]$ NEW_DATA="/var/db/postgres2/wzo28_new"
mkdir -p $NEW_DATA
chmod 0700 $NEW_DATA
cd /var/db/postgres2/backup/full/2026-04-21-21-22-45
tar -xzf base.tar.gz -C $NEW_DATA
mkdir -p $NEW_DATA/pg_wal
tar -xzf pg_wal.tar.gz -C $NEW_DATA/pg_wal
[postgres2@pg101 ~/backup/full/2026-04-21-21-22-45]$ 

[postgres2@pg101 ~/backup/full/2026-04-21-21-22-45]$ mkdir -p /var/db/postgres2/tbs_16392
tar -xzf 16392.tar.gz -C /var/db/postgres2/tbs_16392
[postgres2@pg101 ~/backup/full/2026-04-21-21-22-45]$ 

[postgres2@pg101 ~/backup/full/2026-04-21-21-22-45]$ mkdir -p $NEW_DATA/pg_tblspc
ln -s /var/db/postgres2/tbs_16392 $NEW_DATA/pg_tblspc/16392
[postgres2@pg101 ~/backup/full/2026-04-21-21-22-45]$ 
touch /var/db/postgres2/wzo28_new/standby.signal