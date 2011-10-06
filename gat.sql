BEGIN;

CREATE TABLE asset (
	id       INTEGER   PRIMARY KEY,
	size     INTEGER   NOT NULL,
	mtime    TIMESTAMP NOT NULL,
	checksum TEXT      NOT NULL UNIQUE,
	content_type TEXT  NOT NULL DEFAULT 'application/octet-stream'
);

CREATE TABLE label (
	id       INTEGER PRIMARY KEY,
	asset    INTEGER NOT NULL REFERENCES asset (id),
	filename TEXT NOT NULL UNIQUE
);

CREATE TABLE attribute (
	id    INTEGER PRIMARY KEY,
	asset INTEGER NOT NULL REFERENCES asset (id),
	name  TEXT NOT NULL,
	value TEXT,
	UNIQUE (asset, name)
);

COMMIT;
