create table if not exists `user` (
    id int primary key auto_increment,
    name varchar(255) not null,
    funds decimal not null,
    birthday date not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp on update current_timestamp,
    deleted_at timestamp null
);