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

## Notes

[Getopt::Long::Subcommand](lib/Getopt/Long/Subcommand.pm) is vendored from https://github.com/perlancar/perl-Getopt-Long-Subcommand.