# Concepts
- PK, FK (Primary key, Foreign Key).

## My understanding
- Primary Key is an attribute to identify a single record. It cannot contain NULL values, and all values must be unique.
- Foreing Key is column in one table that refers to the Primary Key in another table. It describes the relationship between the two tables

## Why it matters
Primary Key ensures that every row in a table can be identified, preventing duplicate records and allowing for efficient data retrieval.

Foreign Key establishes links between tables, allowing us to combine data across them (using JOINs). It also prevents actions that would break these links (e.g., deleting a customer record that still has active orders).

## Example
Imagine a database for a library:

Table: Authors

- AuthorID (PK)

- AuthorName

Table: Books

- BookID (PK)

- Title

AuthorID (FK) -> References Authors(AuthorID)

Here, the AuthorID in the Books table connects a specific book to its creator in the Authors table.