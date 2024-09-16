# Text Store App

### 2024-09-11 

- CRUD (User, id + 3 fields (int, str, date))
- date: Time::Piece (NB: DateTime)
- file-based (text)
- CLI: https://perldoc.perl.org/Getopt::Long
- storage: do not use storable

### 2024-09-13

- reuse CRUD
  - CLI
  - HTTP API
- https://perldoc.perl.org/perlpacktut
- mark as deleted instead of delete
  - lineno instead of last_id + 1
- extract read/write

- render HTML not JSON
- /users
  - 3 inputs, "add" button
  - list of users
    - "delete" and "edit" buttons

### 2024-09-16

- Entity -> Model
- no Try::Tiny
- no FindBin in .pm
- extract controllers from models
- use MySQL
- read DBI docs (NB: prepare/bind/execute)
- select array of hashes (NB: Slice)
- optionally Docker Compose
- write schema to .sql
- read abt Carp (die -> croak)
- read abt caller