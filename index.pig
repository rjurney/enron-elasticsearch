/* Avro in piggybank and its depdendencies */
register /me/pig/contrib/piggybank/java/piggybank.jar
register /me/pig/build/ivy/lib/Pig/avro-1.5.3.jar
register /me/pig/build/ivy/lib/Pig/json-simple-1.1.jar

/* A shortcut for calling AvroStorage */
define AvroStorage org.apache.pig.piggybank.storage.avro.AvroStorage();

/* First load the enron emails, available in Avro format at https://s3.amazonaws.com/rjurney.public/enron.avro */
enron_emails = LOAD '/tmp/enron.avro' USING AvroStorage();

/* Describe the emails to verify their schema */
describe enron_emails
-- emails: {message_id: chararray,orig_date: chararray,datetime: chararray,from_address: chararray,from_name: chararray,subject: chararray,body: chararray,tos: {ARRAY_ELEM: (address: chararray,name: chararray)},ccs: {ARRAY_ELEM: (address: chararray,name: chararray)},bccs: {ARRAY_ELEM: (address: chararray,name: chararray)}}

illustrate enron_emails
/*
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| emails     | message_id:chararray                         | orig_date:chararray    | datetime:chararray       | from_address:chararray    | from_name:chararray                       | subject:chararray     | body:chararray                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | tos:bag{ARRAY_ELEM:tuple(address:chararray,name:chararray)}             | ccs:bag{ARRAY_ELEM:tuple(address:chararray,name:chararray)}             | bccs:bag{ARRAY_ELEM:tuple(address:chararray,name:chararray)}             |
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|            |  | 2000-09-05 13:05:00    | 2000-09-05T13:05:00.000Z | david@ddh-pd.com          | DDH Product Design, Inc." "David Hayslett | Family Reunion Photos | Rod,\n\n It was nice to talk to you this evening. It did sound like you\n had a cold. There is no way to protect from going from air\n conditioning to the outside heat/humidity then back into\n the air conditioning. Just try to get some rest and we'll think positive\n for some cooler weather for you.\n\n Attached pls. find the photos I spoke of. There were 30 of them and I\nnarrowed them to the family I could name. I'll write more later.\n It would be great if you all came out around the holidays!\n Love,\n\n Dave........... \n - Family_Reunion_2000.zip\n | {(hayslettr@yahoo.com, )}                                               | {(rod.hayslett@enron.com, )}                                            | {(rod.hayslett@enron.com, )}                                             |
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

/* Now load Wonderdog and set configuration */
register /me/wonderdog/target/wonderdog*.jar;
register /me/elasticsearch-0.18.6/lib/*.jar; /* */

/* Nuke any previous email index, as we are about to replace it. */
sh curl -XDELETE 'http://localhost:9200/enron'

/* Create an elasticsearch index for our emails */
sh curl -XPUT 'http://localhost:9200/enron/'

/* Store our emails as JSON, remove the pig_schema information, and load 
   it as a single chararray field full of JSON data. */
rmf /tmp/enron_emails_elastic
store enron_emails into '/tmp/enron_emails_elastic' using JsonStorage();
json_emails = load '/tmp/enron_emails_elastic' AS (json_record:chararray);

/* Now we can store our email json data to elasticsearch for indexing with message_id. */
store json_emails into 'es://enron/email?json=true&size=1000' USING 
  com.infochimps.elasticsearch.pig.ElasticSearchStorage('/me/elasticsearch-0.18.6/config/elasticsearch.yml', '/me/elasticsearch-0.18.6/plugins');

/* Wallah! We've made the Enron emails searchable! */
sh curl -XGET 'http://localhost:9200/enron/email/_search?q=oil&pretty=true&size=10'
