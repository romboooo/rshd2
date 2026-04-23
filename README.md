# РСХД Лабораторная работа №2

## Вариант 62212
## Задание:

```
Цель работы - настроить процедуру периодического резервного копирования базы данных, сконфигурированной в ходе выполнения лабораторной работы №2, а также разработать и отладить сценарии восстановления в случае сбоев.

Узел из предыдущей лабораторной работы используется в качестве основного. Новый узел используется в качестве резервного. Учётные данные для подключения к новому узлу выдаёт преподаватель. В сценариях восстановления необходимо использовать копию данных, полученную на первом этапе данной лабораторной работы.

Этап 1. Резервное копирование

    Настроить резервное копирование с основного узла на резервный следующим образом:

    Периодические полные копии + непрерывное архивирование.
    Включить для СУБД режим архивирования WAL; настроить копирование WAL (scp) на резервный узел; настроить полное резервное копирование (pg_basebackup) по расписанию (cron) раз в неделю. Созданные полные копии должны сразу копироваться (scp) на резервный хост. Срок хранения копий на основной системе - 1 неделя, на резервной - 4 недели. По истечении срока хранения, старые архивы и неактуальные WAL должны автоматически уничтожаться.
    Подсчитать, каков будет объем резервных копий спустя месяц работы системы, исходя из следующих условий:
        Средний объем новых данных в БД за сутки: 100МБ.
        Средний объем измененных данных за сутки: 900МБ.
    Проанализировать результаты.

Этап 2. Потеря основного узла

Этот сценарий подразумевает полную недоступность основного узла. Необходимо восстановить работу СУБД на РЕЗЕРВНОМ узле, продемонстрировать успешный запуск СУБД и доступность данных.
Этап 3. Повреждение файлов БД

Этот сценарий подразумевает потерю данных (например, в результате сбоя диска или файловой системы) при сохранении доступности основного узла. Необходимо выполнить полное восстановление данных из резервной копии и перезапустить СУБД на ОСНОВНОМ узле.

Ход работы:

    Симулировать сбой:
        удалить с диска директорию WAL со всем содержимым.
    Проверить работу СУБД, доступность данных, перезапустить СУБД, проанализировать результаты.
    Выполнить восстановление данных из резервной копии, учитывая следующее условие:
        исходное расположение директории PGDATA недоступно - разместить данные в другой директории и скорректировать конфигурацию.
    Запустить СУБД, проверить работу и доступность данных, проанализировать результаты.

Этап 4. Логическое повреждение данных

Этот сценарий подразумевает частичную потерю данных (в результате нежелательной или ошибочной операции) при сохранении доступности основного узла. Необходимо выполнить восстановление данных на ОСНОВНОМ узле следующим способом:

    Генерация файла на резервном узле с помощью pg_dump и последующее применение файла на основном узле.

Ход работы:

    В каждую таблицу базы добавить 2-3 новые строки, зафиксировать результат.
    Зафиксировать время и симулировать ошибку:
        перезаписать строки любой таблицы “мусором” (INSERT, UPDATE)
    Продемонстрировать результат.
    Выполнить восстановление данных указанным способом.
    Продемонстрировать и проанализировать результат.
```

## Этап 1

### cгенерируем ssh ключи чтобы отпралвять файлы по scp на pg104 без пароля

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "postgres2@pg101 for backup"
```

### вывод

```

[postgres2@pg101 ~]$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "postgres2@pg101 for backup"
Generating public/private ed25519 key pair.
Your identification has been saved in /var/db/postgres2/.ssh/id_ed25519
Your public key has been saved in /var/db/postgres2/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:w4jDBCraUfRYM5BXPygKfK03r17X7hDNFzN2g34ss/k postgres2@pg101 for backup
The key's randomart image is:
+--[ED25519 256]--+
|  ..+o+..        |
| o o.=.o o    .  |
|o + +.+ . o  .=..|
|o. * + +   +...=.|
|. . * + S . o+.o |
|     o o . o .*  |
|        o o .o   |
|       o . o  .  |
|     .o    .o  E |
+----[SHA256]-----+
[postgres2@pg101 ~]$

[postgres2@pg101 ~]$ ls -l ~/.ssh/
total 14
-rw-------  1 postgres2 postgres 201 17 апр.  11:59 authorized_keys
-rw-------  1 postgres2 postgres 419 17 апр.  13:55 id_ed25519
-rw-r--r--  1 postgres2 postgres 108 17 апр.  13:55 id_ed25519.pub
[postgres2@pg101 ~]$ 
```

### скопируем ключ на pg104 и теперт можно заходить на pg104 без пароля
```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub postgres1@pg104
```

### пруф
```
[postgres2@pg101 ~]$ ssh postgres1@pg104
Last login: Thu Apr 23 17:45:58 2026 from helios.cs.ifmo.ru
[postgres1@pg104 ~]$ 
```

### добавим в pg_hba.conf запись

```
host    replication     postgres2   127.0.0.1/32    password
```

### добавим в postgres.conf запись

```sh
archive_mode = on
archive_command = 'scp %p postgres1@pg104:/var/db/postgres1/backup/wal_archive/%f'
```

### добавим запись в pgpass

```sh
echo "127.0.0.1:9867:replication:postgres2:PASSWORD" > ~/.pgpass
```

### создадим окружение для бэкапов

```sh
mkdir -p /var/db/postgres2/backup/full
ssh postgres1@pg104 "mkdir -p /var/db/postgres1/backup/full"
```

### создадим backup.sh

```sh
set -e
DATE=$(date +%Y-%m-%d-%H-%M-%S)
TEMP_DIR="/tmp/backup.$DATE"
mkdir -p "$TEMP_DIR"

pg_basebackup \
-h "127.0.0.1" \
-D $TEMP_DIR \
-F tar \
-p 9867 \
-U "postgres2" \
-P \
-z \
-v 

ssh postgres1@pg104 "mkdir -p /var/db/postgres1/backup/full/$DATE"

scp -r "$TEMP_DIR"/* postgres1@pg104:/var/db/postgres1/backup/full/$DATE

mkdir -p /var/db/postgres2/backup/full/$DATE
cp -r "$TEMP_DIR"/* "/var/db/postgres2/backup/full/$DATE/"
rm -rf "$TEMP_DIR"

echo "ok!"
```

```
[postgres2@pg101 ~]$ ./backup.sh
pg_basebackup: начинается базовое резервное копирование, ожидается завершение контрольной точки
pg_basebackup: контрольная точка завершена
pg_basebackup: стартовая точка в журнале предзаписи: 0/90000028 на линии времени 2
pg_basebackup: запуск фонового процесса считывания WAL
pg_basebackup: создан временный слот репликации "pg_basebackup_32002"
374485/374485 КБ (100%), табличное пространство 1/2 (....2026-04-23-16-40-29/base.tar.gz374485/374485 КБ (100%), табличное пространство 2/2                                         
pg_basebackup: конечная точка в журнале предзаписи: 0/90000138
pg_basebackup: ожидание завершения потоковой передачи фоновым процессом...
pg_basebackup: сохранение данных на диске...
pg_basebackup: переименование backup_manifest.tmp в backup_manifest
pg_basebackup: базовое резервное копирование завершено
16392.tar.gz                                          100%  932     3.9MB/s   00:00    
backup_manifest                                       100%  290KB  91.7MB/s   00:00    
base.tar.gz                                           100%   29MB 110.9MB/s   00:00    
pg_wal.tar.gz                                         100%   18KB  43.0MB/s   00:00    
ok!

```

### а также сдалем скрипт очистки cleanUpBackups.sh

```sh
find /var/db/postgres2/backup/full -maxdepth 1 -type d -name "20*" -mtime +7 -exec rm -rf {} \;
```

### и закинем в крон

```sh
crontab -e
```

либо (если нормальный человек без псих. расстройств)

```sh
EDITOR=ee crontab -e
```

### с конфигурацией

```
0 0 * * 0 /var/db/postgres2/backup.sh >> /var/db/postgres2/backup/cron.log 2>&1
0 1 * * 0 /var/db/postgres2/cleanUpBackups.sh >> /var/db/postgres2/backup/cron.log 2>&1
```

***пишем бэкап раз в неделю через час удаляем старый бэкап***

### а также добавим скрипт удаления бэкапов на резервном узле

```sh
find /var/db/postgres1/backup/full -maxdepth 1 -type d -name "20*" -mtime +28 -exec rm -rf {} \; -print
find /var/db/postgres1/backup/wal_archive -type f -mtime +28 -delete -print
```

### и закинем в крон каждый день на 5 часов дня
```
[postgres1@pg104 ~]$  crontab -l
0 5 * * * /var/db/postgres1/bin/cleanUpBackups.sh >> /var/db/postgres1/backup/cleanup.log 2>&1
[postgres1@pg104 ~]$ 
```

### каков будет объем резервных копий спустя месяц работы ? при среднем коэффициенте сжатия base‑данных 4x и wal 3x

```sh
echo $(( (70*100/4) + (30*900/3) ))
```

в Мб
```
10750
```

```
oсновной объём занимают архивы wal (даже со сжатием). при росте изменений нужно следить за очисткой и рассмотреть сжатие wal в archive_command
```

## этап 2

### главный узел не работает

```
[postgres2@pg101 ~]$ pg_ctl -D /var/db/postgres2/wzo28 status
pg_ctl: сервер не работает
[postgres2@pg101 ~]$ 
```

### восстановим из бэкапа на резервном узле

### распакуем тарники

```
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -tzf 16392.tar.gz 
PG_16_202307071/
PG_16_202307071/16390/
PG_16_202307071/16390/16415
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ 

[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ mkdir -p /var/db/postgres1/tbs_16392

tar -xzf 16392.tar.gz -C /var/db/postgres1/tbs_16392

[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf base.tar.gz -C /var/db/postgres1
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf pg_wal.tar.gz -C /var/db/postgres1/pg_wal
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$

```

### создадим символическую ссылку для табличного пространства
```sh
ln -s /var/db/postgres1/tbs_16392 /var/db/postgres1/pg_tblspc/16392
```

### распаковываем wal файьы
``` 
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf base.tar.gz -C /var/db/postgres1
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$ tar -xzf pg_wal.tar.gz -C /var/db/postgres1/pg_wal
[postgres1@pg104 ~/backup/full/2026-04-21-21-22-45]$
```

### создаем signal файл (чтобы перевести сервер в ремим REPLICA)

```sh
touch /var/db/postgres1/standby.signal
```

### пробуем запустить

```
postgres1@pg104 ~]$ pg_ctl start -D /var/db/postgres1
ожидание запуска сервера....2026-04-21 18:42:26.164 GMT [45] СООБЩЕНИЕ:  передача вывода в протокол процессу сбора протоколов
2026-04-21 18:42:26.164 GMT [45] ПОДСКАЗКА:  В дальнейшем протоколы будут выводиться в каталог "log".
 готово
сервер запущен
[postgres1@pg104 ~]$ pg_ctl status -D /var/db/postgres1
pg_ctl: сервер работает (PID: 45)
/usr/local/bin/postgres "-D" "/var/db/postgres1"
```
 
### переводим сервер в режим (master) чтобы позволить ему принимать запросы на запись

```
[postgres1@pg104 ~]$ pg_ctl promote -D /var/db/postgres1
ожидание повышения сервера.... готово
сервер повышен
[postgres1@pg104 ~]$ 
```

### проверяем 

```
[postgres1@pg104 ~]$ psql -h localhost -U postgres2 -p 9867 -d postgres -c "SELECT pg_is_in_recovery();"
Пароль пользователя postgres2: 
 pg_is_in_recovery 
-------------------
 f
(1 строка)
```

### проверим что все бд на месте

```
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
```

## этап 3

### останавливаем бд на основном узле
```
[postgres2@pg101 ~]$ pg_ctl stop -D /var/db/postgres2/wzo28 -m immediate
ожидание завершения работы сервера.... готово
сервер остановлен
[postgres2@pg101 ~]$ 
```

### "удаляем" wal

```sh
mv /var/db/postgres2/wzo28/pg_wal /var/db/postgres2/wzo28/pg_wal.broken
```

### сервер РЕАЛЬНО не доступен
```
[postgres2@pg101 ~]$ pg_ctl start -D /var/db/postgres2/wzo28
ожидание запуска сервера....2026-04-21 18:55:09.078 GMT [3306] СООБЩЕНИЕ:  передача вывода в протокол процессу сбора протоколов
2026-04-21 18:55:09.078 GMT [3306] ПОДСКАЗКА:  В дальнейшем протоколы будут выводиться в каталог "log".
 прекращение ожидания
pg_ctl: не удалось запустить сервер
Изучите протокол выполнения.
[postgres2@pg101 ~]$ 
```

### подготавливаем окружение
```sh
NEW_DATA="/var/db/postgres2/wzo28_new"
mkdir -p $NEW_DATA
chmod 0700 $NEW_DATA
cd /var/db/postgres2/backup/full/2026-04-21-21-22-45
```

### распаковываемся

```sh
tar -xzf base.tar.gz -C $NEW_DATA
mkdir -p $NEW_DATA/pg_wal
tar -xzf pg_wal.tar.gz -C $NEW_DATA/pg_wal

tar -xzf 16392.tar.gz -C /var/db/postgres2/tbs_16392
```


### ccылка на табличное пространство
```sh
ln -s /var/db/postgres2/tbs_16392 $NEW_DATA/pg_tblspc/16392
```

### создаем signal файл (чтобы перевести сервер в ремим REPLICA)

```sh
touch /var/db/postgres2/wzo28_new/standby.signal
```

### пробуем запустить

```
[postgres2@pg101 ~]$ pg_ctl -D /var/db/postgres2/wzo28_new start
ожидание запуска сервера....2026-04-23 16:57:02.491 GMT [70327] СООБЩЕНИЕ:  передача вывода в протокол процессу сбора протоколов
2026-04-23 16:57:02.491 GMT [70327] ПОДСКАЗКА:  В дальнейшем протоколы будут выводиться в каталог "log".
 готово
сервер запущен
[postgres2@pg101 ~]$ 
```
 
### проверка

```
[postgres2@pg101 ~]$ psql -h 127.0.0.1 -p 9867 -U postgres2 -d postgres -c "SELECT pg_is_in_recovery();"
Пароль пользователя postgres2: 
 pg_is_in_recovery 
-------------------
 f
(1 строка)

[postgres2@pg101 ~]$ psql -h 127.0.0.1 -p 9867 -U postgres2 -l
psql -h 127.0.0.1 -p 9867 -U rmb -d illgreennews -c "SELECT * FROM articles LIMIT 3;"
Пароль пользователя postgres2: 
                                                             Список баз данных
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

Пароль пользователя rmb: 
 id |   title   | content |         created_at         
----+-----------+---------+----------------------------
  1 | Article X | Text X  | 2026-04-23 13:27:04.192007
  2 | Article Y | Text Y  | 2026-04-23 13:27:04.192007
  3 | Article Z | Text Z  | 2026-04-23 13:27:04.192007
(3 строки)

[postgres2@pg101 ~]$ 

```


## этап 4

### немного подготовим таблицы 

```sql
INSERT INTO articles (title, content) VALUES
  ('Article X', 'Text X'),
  ('Article Y', 'Text Y'),
  ('Article Z', 'Text Z');

INSERT INTO comments (article_id, author, body) VALUES
  (1, 'UserX', 'Comment to X'),
  (2, 'UserY', 'Comment to Y'),
  (3, 'UserZ', 'Comment to Z');
  ```

```
INSERT 0 3
INSERT 0 3
```

### сделаем бэкап
```sh
./backup.sh
```

```
g_basebackup: начинается базовое резервное копирование, ожидается завершение контрольной точки
pg_basebackup: контрольная точка завершена
pg_basebackup: стартовая точка в журнале предзаписи: 0/90000028 на линии времени 2
pg_basebackup: запуск фонового процесса считывания WAL
pg_basebackup: создан временный слот репликации "pg_basebackup_32002"
374485/374485 КБ (100%), табличное пространство 1/2 (....2026-04-23-16-40-29/base.tar.gz374485/374485 КБ (100%), табличное пространство 2/2                                         
pg_basebackup: конечная точка в журнале предзаписи: 0/90000138
pg_basebackup: ожидание завершения потоковой передачи фоновым процессом...
pg_basebackup: сохранение данных на диске...
pg_basebackup: переименование backup_manifest.tmp в backup_manifest
pg_basebackup: базовое резервное копирование завершено
16392.tar.gz                                          100%  932     3.9MB/s   00:00    
backup_manifest                                       100%  290KB  91.7MB/s   00:00    
base.tar.gz                                           100%   29MB 110.9MB/s   00:00    
pg_wal.tar.gz                                         100%   18KB  43.0MB/s   00:00    
ok!
```

### проверим что бэкапы создались

```
[postgres2@pg101 ~]$ ls /var/db/postgres2/backup/full
2026-04-17-19-23-41	2026-04-21-21-22-45
2026-04-19-15-02-29	2026-04-23-16-40-29
[postgres2@pg101 ~]$ ssh postgres1@pg104 "ls /var/db/postgres1/backup/full"
2026-04-17-19-23-41
2026-04-19-15-02-29
2026-04-21-21-22-45
2026-04-23-16-40-29
```

### засидим бд грязными данными

```
[postgres2@pg101 ~]$ psql -h localhost -U postgres2 -p 9867 -d illgreennews
Пароль пользователя postgres2: 
psql (16.4)
Введите "help", чтобы получить справку.

illgreennews=# SELECT now();   
UPDATE articles SET title = 'TRASH', content = 'GARBAGE';
SELECT * FROM articles;   

              now              
-------------------------------
 2026-04-23 13:41:52.489713+00
(1 строка)

UPDATE 3
 id | title | content |         created_at         
----+-------+---------+----------------------------
  1 | TRASH | GARBAGE | 2026-04-23 13:27:04.192007
  2 | TRASH | GARBAGE | 2026-04-23 13:27:04.192007
  3 | TRASH | GARBAGE | 2026-04-23 13:27:04.192007
(3 строки)

illgreennews=# 
```


### подключаемся к pg104

### создаем рк на резервном узле

```sh
BACKUP_DIR=/var/db/postgres1/backup/full/2026-04-23-16-40-29
TMP_PGDATA=/var/db/postgres1/tmp_pgdata

mkdir -p $TMP_PGDATA
chmod 0700 $TMP_PGDATA

cd $BACKUP_DIR

tar -xzf base.tar.gz -C $TMP_PGDATA
mkdir -p $TMP_PGDATA/pg_wal

tar -xzf pg_wal.tar.gz -C $TMP_PGDATA/pg_wal
mkdir -p /var/db/postgres1/tmp_tbs

tar -xzf 16392.tar.gz -C /var/db/postgres1/tmp_tbs
rm -f $TMP_PGDATA/pg_tblspc/16392

ln -s /var/db/postgres1/tmp_tbs $TMP_PGDATA/pg_tblspc/16392
echo "port = 9868" >> $TMP_PGDATA/postgresql.conf
```


### делаем дамп и отправляем его на основной узел

```sh
pg_dump -h localhost -U postgres2 -p 9868 -d illgreennews \
  -t articles -t comments --data-only --column-inserts \
  > /tmp/illgreennews_clean.sql

pg_ctl -D $TMP_PGDATA stop
rm -rf $TMP_PGDATA /var/db/postgres1/tmp_tbs

scp /tmp/illgreennews_clean.sql postgres2@pg101:/tmp/
```


### обратно на pg101

### восстанавливаем данные на основном узле

```
[postgres2@pg101 ~]$ psql -h localhost -U postgres2 -p 9867 -d illgreennews -c "DELETE FROM comments; DELETE FROM articles;"
Пароль пользователя postgres2: 
DELETE 3
DELETE 3
[postgres2@pg101 ~]$ psql -h localhost -U postgres2 -p 9867 -d illgreennews -f /tmp/illgreennews_clean.sql
Пароль пользователя postgres2: 
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 строка)

SET
SET
SET
SET
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
 setval 
--------
      3
(1 строка)

 setval 
--------
      3
(1 строка)
```

### проверим
```
[postgres2@pg101 ~]$ psql -h localhost -U postgres2 -p 9867 -d illgreennews -c "select * FROM comments; select * FROM articles;"
Пароль пользователя postgres2: 
 id | article_id | author |     body     
----+------------+--------+--------------
  1 |          1 | UserX  | Comment to X
  2 |          2 | UserY  | Comment to Y
  3 |          3 | UserZ  | Comment to Z
(3 строки)

 id |   title   | content |         created_at         
----+-----------+---------+----------------------------
  1 | Article X | Text X  | 2026-04-23 13:27:04.192007
  2 | Article Y | Text Y  | 2026-04-23 13:27:04.192007
  3 | Article Z | Text Z  | 2026-04-23 13:27:04.192007
(3 строки)

[postgres2@pg101 ~]$
```

### данные восстановлены!

```
вывод
в ходе лабораторной работы я настроил процедуру периодического резервного копирования базы данных, сконфигурированной в ходе выполнения лабораторной работы 2, а также разработал и отладил сценарии восстановления в случае сбоев. ыполнил физический и логические бэкапы.
```
