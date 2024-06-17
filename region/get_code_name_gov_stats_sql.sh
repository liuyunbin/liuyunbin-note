#!/bin/bash

set -ueo pipefail

function log_info() { echo -e "$(date +'%Y-%m-%d %H:%M:%S %z') $@";          }
function log_warn() { echo -e "$(date +'%Y-%m-%d %H:%M:%S %z') $@";          }
function log_erro() { echo -e "$(date +'%Y-%m-%d %H:%M:%S %z') $@"; exit -1; }

path_gcov_stats_sql=$(pwd)/code-name-gov-stats-sql/
mkdir -p $path_gcov_stats_sql

cd code-name-gov-stats-csv

for file_name_csv in *; do
    log_info "handle $file_name_csv"
    year=${file_name_csv::-4}
    file_name_sql=${path_gcov_stats_sql}${year}.sql

    cat > $file_name_sql <<'EOF'
drop table if exists `gov_stats`;
create table `gov_stats` (
  `code`  bigint      not null comment '区划代码',
  `name`  varchar(40) not null comment '名称',
  `level` tinyint     not null comment '级别1-5,省市县镇村',
  `pcode` bigint      not null comment '父级区划代码',
   primary key (`code`),
   index `name`  (`name`),
   index `level` (`level`),
   index `pcode` (`pcode`)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_unicode_ci;

lock tables `gov_stats` write;
EOF

    awk -F, '
        BEGIN {
            str = "insert into `gov_stats` values "
        }

        {
            if (NR % 1000 == 0) {
                print(str)
                str = "insert into `gov_stats` values "
            }

            str = str"("$1",'\''"$2"'\'',"$3","$4"),"
        }
        END {
            print(str)
        }
        ' $file_name_csv | sed 's/,$/;/' >> $file_name_sql
    sed -i "s/gov_stats/gov_stats_$year/g" $file_name_sql

    mysql -D testdb < $file_name_sql
    mysqldump testdb gov_stats_$year > $file_name_sql
done

