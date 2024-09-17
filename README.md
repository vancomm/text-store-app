# Text Store App

### 2024-09-11 

- [x] CRUD (User, id + 3 fields (int, str, date))
- date: Time::Piece (NB: DateTime)
- file-based (text)
- [x] CLI: https://perldoc.perl.org/Getopt::Long
- storage: do not use storable

### 2024-09-13

- reuse CRUD
  - [x] CLI
  - [x] HTTP API
- https://perldoc.perl.org/perlpacktut
- [x] mark as deleted instead of delete
  - [x] lineno instead of last_id + 1
- [ ] extract read/write

- [x] render HTML not JSON
- /users
  - [x] 3 inputs, "add" button
  - [x] list of users
    - [x] "delete" and "edit" buttons

### 2024-09-16

- [x] Entity -> Model
- [x] no Try::Tiny
- [x] no FindBin in .pm
- [x] extract controllers from models
- [ ] use MySQL
- read DBI docs (NB: prepare/bind/execute)
- select array of hashes (NB: Slice)
- [ ] (optionally) Docker Compose
- [ ] write schema to .sql
- use and read abt Carp
  - [ ] (die -> croak where needed)
- read abt caller

### 2024-09-17

- [ ] debug [Project::Util](./lib/Project/Util.pm)::try_parse_timestamp weird eval {} behaviour