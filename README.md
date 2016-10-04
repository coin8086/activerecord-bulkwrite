中文文档请看这里：http://ask.githuber.cn/t/activerecord-bulk-write/1723
---

# activerecord-bulkwrite
Bulk insert/upsert for ActiveRecord! 

ActiveRecord has no native support for bulk insert and it's very inefficient to insert bulk of rows into database by loops of `Model#create`, even with a transaction outside the loops. The best way to do bulk insert is to build a SQL statement:
```sql
INSERT INTO table_name (col1, col2, col3, ...) VALUES (v11, v12, v13, ...), (v21, v22, v23, ...), ...
```
It's about 100 times faster than loops of `Model#create`! This Gem is a helper for you to build such a sql statement - it takes care of type conversion and quoting for database. What's more, it also suppports *upsert*, that is to try to insert first, and if that fails, then do update.

# Requirement
PostgreSQL 9.5 and higher, since it depends on PostgreSQL 9.5's upsert feature.

# Installation

```
gem install activerecord-bulkwrite
```

# Usage

Suppose a table definition:

```ruby
create table users (
  id integer primary key,
  name text,
  hireable bool,
  created_at date_time,
  foo text,
  bar text,
)
```

## Bulk Insert

```ruby
require "activerecord/bulkwrite"

fields = %w(id name hireable created_at)
rows = [
  [1, "Bob's", true, Time.now.utc],
  [2, nil, "false", Time.now.utc.iso8601],
  # ...
]

# The result is the effected(inserted) rows.
result = User.bulk_write(fields, rows)
```

The values of rows are sent to database as-is, and their to_s method is called when necessary. So here you need to *pay attention to datetime values: it must be in UTC time, not in local time*, since there's no time zone conversion.

## Bulk Upsert

```ruby
result = User.bulk_write(fields, rows, :conflict => [:id])
```

The statement above reinserted `rows` and thus failed on unique violation. But this time we specified an `:conflict` option meaning when the given fields conflict then do update with the rest fields. We can also explicitly specify the fields to update:

```ruby
result = User.bulk_write(fields, rows, :conflict => [:id],  :update => %w(name created_at))
```

We can even specify conditions under which to do update:

```ruby
result = User.bulk_write(fields, rows, :conflict => [:id],  :where => "users.hireable = TRUE"))
```

In fact, activerecord-bulkwrite's upsert depends on [PostgreSQL 9.5's upsert](https://www.postgresql.org/docs/9.5/static/sql-insert.html#SQL-ON-CONFLICT):

```sql
INSERT INTO table_name (col1, col2, col3, ...) VALUES (v11, v12, v13), (v21, v22, v23), ...
ON CONFLICT (colX, colY, ...) DO UPDATE
SET colA = ..., colB = ..., ...
WHERE ...
```

# Compatible Rails Versions and Test
It's tested against ActiveRecord 4.2, but should also work on 4.x as well as 5.
