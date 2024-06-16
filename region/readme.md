
## 获取和更新 1980-至今 民政部的 省 市 区县 数据
* 官网: https://www.mca.gov.cn/n156/n186/index.html
* 编码: UTF-8
* 说明:
    * 1980-2011 有 省 市 区县 的区划代码
    * 2012-2013 有 省 市 区县 乡镇 的区划代码
    * 2014-2020 有 省 市 区县 的区划代码, 有 乡镇 的区划代码的变更情况
    * 2021 有 省 市 区县 乡镇 的区划代码的变更情况 -- 已处理 省 市 区县 变更, 并存储变更后的结果
    * 2022-至今 有 省 市 区县 的区划代码, 有 乡镇 的区划代码的变更情况
* 从数据源获取 CSV 文件
    * 执行: [./get_code_name_gov_mca_csv.py](./get_code_name_gov_mca_csv.py)
    * 目录: [code-name-gov-mca-csv](code-name-gov-mca-csv)
* 由 CSV 文件生成 SQL 文件
    * 执行: [./get_code_name_gov_mca_sql.sh](./get_code_name_gov_mca_sql.sh)
    * 目录: [code-name-gov-mca-sql](code-name-gov-mca-sql)

## 获取和更新 2009-至今 统计局的 省 市 区县 数据
* 官网: https://www.stats.gov.cn/sj/tjbz/qhdm/
* 编码: 2020 及其之前的网页使用 GBK, 2020 之后的网页使用 UTF-8
* 说明:
    * 有些市的下一级直接就是乡镇, 没有区县这一级, 比如: 2023-东莞市
    * 除了直辖市, 其他市的直辖区没有下一级, 比如: 2023-太原市-市辖区
    * 有些市没有下一级, 比如: 2023-雄安新区
    * 有些乡镇没有村, 比如: 2015-天津-红桥区-大胡同街道(网页为空)
* 从数据源获取 JSON 文件
    * 执行: [./get_code_name_gov_stats_json.py](./get_code_name_gov_stats_json.py)
    * 目录: [code-name-gov-stats-json](code-name-gov-stats-json)
* 由 JSON 文件生成 CSV 文件
    * 执行: [get_code_name_gov_stats_csv.py](./get_code_name_gov_stats_csv.py)
    * 目录: [code-name-gov-stats-csv](code-name-gov-stats-csv)
* 由 CSV 文件生成 SQL 文件
    * 执行: [./get_code_name_gov_stats_sql.sh](./get_code_name_gov_stats_sql.sh)
    * 目录: [code-name-gov-stats-sql](code-name-gov-stats-sql)

## 获取和更新 2009-至今 统计局的 省 市 区县 乡镇 村 数据
* 从数据源获取 JSON 文件
    * 执行: [./get_code_name_gov_stats_json_all.sh](./get_code_name_gov_stats_json_all.sh)
    * 目录: [code-name-gov-stats-json-all](code-name-gov-stats-json-all)
    * 注意: 执行脚本前, 先将该目录下的 tgz 文件解压, 避免重复下载
* 由 JSON 文件生成 CSV 文件
    * 执行: [get_code_name_gov_stats_csv_all.sh](./get_code_name_gov_stats_csv_all.sh)
    * 目录: [code-name-gov-stats-csv-all](code-name-gov-stats-csv-all)
* 其他部分同上一节

## 获取和更新 1949-2006 中国政府网 县级及以上行政区划变更情况
* 官网: http://www.gov.cn/test/2006-02/27/content_212020.htm
* 说明: 2003 2005 2006 的数据暂时缺失, 使用的是之前的数据
* 从数据源获取相关文件
    * 执行: [./get_desc_gov.py](./get_desc_gov.py)
    * 目录: [desc-gov](desc-gov)

## 获取和更新 1999-至今 民政部 县级及以上行政区划变更情况
* 官网: http://xzqh.mca.gov.cn/description?dcpid=1
* 说明: 2022 的数据暂时缺失, 使用的是之前的数据
* 从数据源获取相关文件
    * 执行: [./get_desc_gov_mca.py](./get_desc_gov_mca.py)
    * 目录: [desc-gov-mca](desc-gov-mca)

## 代码说明
* 民政统计代码编制规则: https://www.mca.gov.cn/n156/n186/c110788/content.html
* 统计上使用的县以下行政区划代码编制规则: https://www.mca.gov.cn/n156/n186/c110787/content.html
* 维基百科: https://zh.wikipedia.org/wiki/%E4%B8%AD%E5%8D%8E%E4%BA%BA%E6%B0%91%E5%85%B1%E5%92%8C%E5%9B%BD%E8%A1%8C%E6%94%BF%E5%8C%BA%E5%88%92%E4%BB%A3%E7%A0%81

* 第一位: 省: 1-华北 2-东北 3-华东 4-中南 5-西南 6-西北 7-台湾 8-港澳台 9-外国人永久居留身份证
* 第二位:
* 第三位: 市
* 第四位:
* 第五位: 区县
* 第六位:
* 第七位: 乡镇: 0-街道 1-镇 2和3-乡 4和5-政企合一的单位
* 第八位:
* 第九位:
* 第十位: 村: 0和1-居民委员会 2和3-村民委员会
* 第十一位:
* 第十二位:
