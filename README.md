中文文档请看这里：http://ask.githuber.cn/t/activerecord-bulk-write/1723
---
# activerecord-bulkwrite
Bulk write/upsert for ActiveRecord!

# Requirement
PostgreSQL 9.5 and higher

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

You do upsert like:

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

The upsert function depends on PostgreSQL 9.5's upsert. See here for more: https://www.postgresql.org/docs/9.5/static/sql-insert.html#SQL-ON-CONFLICT

# Compatible Rails Versions and Test
It's tested against ActiveRecord 4.2, but should also work on 4.x as well as 5.
