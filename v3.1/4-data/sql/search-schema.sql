CREATE TABLE PatentSearchDocuments (
  DocumentId STRING(64) NOT NULL,
  PublicationNumber STRING(128) NOT NULL,
  Title STRING(MAX) NOT NULL,
  SearchText ARRAY<STRING(MAX)>,
  SourceUri STRING(MAX) NOT NULL,
  SourceGeneration STRING(32) NOT NULL,
  ProjectionVersion INT64 NOT NULL,
  IndexedAt TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true),
  SearchTokens TOKENLIST AS (TOKENIZE_FULLTEXT(SearchText)) HIDDEN
) PRIMARY KEY (DocumentId);
CREATE SEARCH INDEX PatentFullText ON PatentSearchDocuments(SearchTokens);
CREATE INDEX PatentPublicationNumber ON PatentSearchDocuments(PublicationNumber);
CREATE ROLE indexer;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE PatentSearchDocuments TO ROLE indexer
