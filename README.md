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
- [x] use MySQL
- read DBI docs (NB: prepare/bind/execute)
- select array of hashes (NB: Slice)
- [x] (optionally) Docker Compose
- [x] write schema to .sql
- use and read abt Carp
  - [ ] (die -> croak where needed)
- read abt caller

### 2024-09-17

- [x] debug [Project::Util](./lib/Project/Util.pm)::try_parse_timestamp weird eval {} behaviour

- [x] lowercase all SQL
- [x] set PrintError => 0
- [ ] try RaiseError => 0
- [x] checkout `map` and `grep`
- [x] mutate in-place array of hashes using `foreach`
- [x] DB::User->update: add query builder

### 2024-09-20

- [x] [Store](./lib/Store.pm): store interface
  - `sub some_method { die 'abstract method invoked'; }`
- Model:
  - [x] [Model](./lib/Model.pm) - define connection logic (reuse? cache?)
  - [x] [Model::User](./lib/Model/User.pm) - define User CRUD
  - NB: DBI::connect_cached
  - [x] test `select sleep(400);`, kill, ~~terminate,~~ destroy connection, network disconnect
  - [ ] add application name to DSN

### 2024-09-23

- [ ] remove `use Exporter` and `@EXPORT_OK`
- [ ] rename User->sleep -> User->test_long_op
- [ ] return error instead of `die` in Model::User
- [ ] modes (develoment/production)
- [ ] figure out error codes (objects?)
- NB: testing:
  - Perl Tests (book)
  - `prove` (CLI utility)
  - Test::More
  - [Test::Most (yt)](https://www.youtube.com/watch?v=Gwg4cn3IxNI&list=PLvHhdy-GnNXCjZHNkOk4_tkH4b1PW7z8x)
- [ ] unit tests
- [ ] functional tests
  - NB: LWP (HTTP client)
  - NB: Mojo::UserAgent + [Mojo::Promise](https://docs.mojolicious.org/Mojo/Promise)
  - NB: AnyEvent, [AE](https://metacpan.org/pod/AE)
  - NB: [Coro](https://metacpan.org/pod/Coro)
