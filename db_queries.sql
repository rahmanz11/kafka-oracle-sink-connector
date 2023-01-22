CREATE TABLE books (
  id      NUMBER(10)    NOT NULL,
  title   VARCHAR2(100) NOT NULL
);

ALTER TABLE books
  ADD (
    CONSTRAINT books_pk PRIMARY KEY (id)
  );

CREATE SEQUENCE books_sequence;

CREATE OR REPLACE TRIGGER books_on_insert
  BEFORE INSERT ON books
  FOR EACH ROW
BEGIN
  SELECT books_sequence.nextval
  INTO :new.id
  FROM dual;
END;