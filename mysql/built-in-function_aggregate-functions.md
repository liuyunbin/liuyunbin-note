
## 聚合函数
```
* 不能嵌套

USE  test;
DROP TABLE IF EXISTS student;
CREATE TABLE student (
    id int,
    name VARCHAR(20),
    score DECIMAL
);

INSERT INTO student VALUES(1, '张三', 100);
INSERT INTO student VALUES(2, '李四', 70);
INSERT INTO student VALUES(3, '王五', 80);
INSERT INTO student VALUES(4, '赵六', NULL);
INSERT INTO student VALUES(5, '田七', 70);

SELECT max(score)              FROM student;   # 任意类型 跳过 NULL 行
SELECT min(score)              FROM student;   # 任意类型 跳过 NULL 行
SELECT avg(score)              FROM student;   # 数值类 跳过 NULL 行
SELECT sum(score)/count(score) FROM student;   # 数值类 跳过 NULL 行
SELECT sum(score)/count(*)     FROM student;   # 数值类 包含 NULL 行
SELECT sum(score) FROM student;                # 数值类 跳过 NULL 行
SELECT count(score) FROM student;              # 任意类型 跳过 NULL 行
SELECT count(*) FROM student;                  # 任意类型 包含 NULL 行
```