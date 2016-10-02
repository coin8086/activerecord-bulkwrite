# activerecord-bulkwrite
Bulk write/upsert for ActiveRecord!

# Requirements
It requires PostgreSQL 9.5 and higher for upsert, but doesn't require it for insert-only. See below for examples of upsert and insert-only.

# Installation

```
gem install activerecord-bulkwrite
```

# Usage

Suppose there's a table definition

```
create table users (
  id integer primary key,
  name text,
  hireable bool,
  created_at date_time,
  foo text,
  bar text,
)
```

## Bulk Insert-only

```
require "activerecord/bulkwrite"

fields = %w(id name hireable created_at)
rows = [
  [1, "Bob's", true, now - 10],
  [2, nil, "false", (now - 1).utc.iso8601],
  # ...
]

# The result is the effected(inserted) rows.
result = User.bulk_write(fields, rows)
```

The values of rows are sent to database as-is, and their to_s method is called when necessary. So here you need to *pay attention to datetime values: it must be in UTC time, not in local time*, since there's no time zone conversion.

## Bulk Upsert

When you do upsert, you pass the 3rd parameter `upsert`:

```
require "activerecord/bulkwrite"

upsert = { :conflict => [:id] }
result = User.bulk_write(fields, rows, :upsert => upsert)
```

The only required field of upsert is conflict. See comment in code for more of the parameter's meanings. If you know PostgreSQL 9.5's upsert syntax, you understand it even more. Here it is: https://www.postgresql.org/docs/9.5/static/sql-insert.html#SQL-ON-CONFLICT

# Compatible Rails Versions and Test
It's tested against ActiveRecord 4.2, but should work on 4.x as well as 5. See the gist for a test example: https://gist.github.com/coin8086/a66c5f1a706b3981d1bdbe2cb7ff154d.
