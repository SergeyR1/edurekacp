--register required jars
register org.apache.pig.piggybank;
register customudf.jar;

--load the data into pig

SMS = load './smsall.xml' using org.apache.pig.piggybank.storage.XMLLoader('sms') as (x:chararray);

--extract data from chararray after the XMLLoader usin regular expression
SMS2  = foreach SMS GENERATE FLATTEN(REGEX_EXTRACT_ALL(x,'<sms>\\s*<protocol>(.*)</protocol>\\s*<address>(.*)</address>\\s*<date>(.*)</date>\\s*<type>(.*)</type>\\s*<subject>(.*)</subject>\\s*<body>(.*)</body>\\s*<toa>(.*)</toa>\\s*<sc_toa>(.*)</sc_toa>\\s*<service_center>(.*)</service_center>\\s*<read>(.*)</read>\\s*<status>(.*)</status>\\s*<locked>(.*)</locked>\\s*<date_sent>(.*)</date_sent>\\s*<readable_date>(.*)</readable_date>\\s*<contact_name>(.*)</contact_name>\\s*</sms>')) AS (protocol:chararray, address:chararray, date:long, type:int, subject:chararray, body:chararray, toa:int, sc_toa:int, service_center:chararray, read:int, status:int, locked:int, date_sent:int, readable_date:chararray, contact_name:chararray); 

--project the data and apply our udf
SMS3 = foreach SMS2 generate customudf.fromunixtime(date) as date:chararray, type, body, customudf.lovecounter(body) as lovecount:int, customudf.kisscounter(body) as kisscount:int, customudf.thankscounter(body) as thankscount:int;

--store the data to hdfs
store SMS3 into './smses' using PigStorage(';');

