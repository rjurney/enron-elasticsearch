register /me/wonderdog/target/wonderdog*.jar;
register /me/elasticsearch-0.18.6/lib/*.jar; /* */

/* All emails from a sender with the name "Tim Belden".
   Note the use of url encoded values for ' ' (%20) and '"' (%22) */
tim_emails = LOAD 'es://enron/email?q=from.name:%22Tim%20Belden%22' USING com.infochimps.elasticsearch.pig.ElasticSearchStorage('/me/elasticsearch-0.18.6/config/elasticsearch.yml', '/me/elasticsearch-0.18.6/plugins') AS (doc_id:chararray, contents:chararray);
store tim_emails INTO '/tmp/tim.json' USING JsonStorage();

