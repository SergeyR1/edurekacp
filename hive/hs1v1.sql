-- Preparing database
set hive.cli.print.current.db = true;
create database if not exists messages;
use messages;

-- Creating external table
create external table if not exists smses (
date TIMESTAMP,
type INT,
body STRING,
lovecount INT,
kisscount INT,
thankscount INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
LOCATION '/user/edureka/smses';

-- Aggregation table for words
create table if not exists smses_agg_all as select e.monthnum, e.daynum, e.dayhour, e.type, sum(e.lovecount), sum(e.kisscount), sum(e.thankscount)
from (select month(date) as monthnum, from_unixtime(unix_timestamp(date, 'yyyyMMdd'),'u') as daynum, hour(date) as dayhour, type, lovecount, kisscount, thankscount from smses) e
group by e.monthnum, e.daynum, e.dayhour, e.type;

--Aggregation table for amount of smses
create table if not exists smses_amount_day as select e.date,e.type,e.sms_type, count(*), sum(e.sms_amount)
from (select date,type,(cast(length(body)/70 as INT) + 1) as sms_amount , if(cast(length(body) as FLOAT)/70 > 5,2,1) as sms_type from smses) e
group by e.date,e.type,e.sms_type;
