require 'active_record'

module ActiveRecord
  class Base
    # Insert or update a batch of rows.
    # When upsert is nil, insert only. Otherwise insert or update on conflict.
    #
    # Parameters:
    # fields: an array of field names to insert value
    # rows:   an array of array of values to insert. The element, values array,
    #         must correspond with the fields parameter.
    # upsert:
    #   A hash with the following keys::
    #   conflict: an array of field names on which a unique constrain may fail the
    #             insert
    #   update:   an array of field names to update when conflict happens. If
    #             omitted, it will be "fields - upsert[:conflict]".
    #   where:    where clause to determine if a row will be updated when
    #             conflict happens. "EXCLUDED" is used for referencing the row
    #             that failed in insert. If omitted, update all rows that have
    #             conflict.
    #
    # Return:
    # The number of affected rows
    def self.bulk_write(fields, rows, upsert = nil)
      return 0 if rows.empty?

      columns = fields.map {|name| column_for_attribute(name) }
      rows = rows.map do |row|
        values = row.map.with_index do |val, i|
          # NOTE: Here quote method treats val as a Ruby value from
          # Value#type_cast_from_user, and thus won't convert a String time to
          # Time object before passing the string time to database.
          # That's OK for a time string in UTC, but NOT FOR LOCAL TIME, since
          # ActiveRecord saves time as type "DATETIME WITHOUT TIMEZONE" in database!
          connection.quote(val, columns[i])
        end.join ', '
        "(#{ values })"
      end
      field_list = fields.map{|e| %Q("#{e}") }.join ', '
      sql = "INSERT INTO #{ table_name } (#{ field_list }) VALUES #{ rows.join ', ' }"
      if upsert
        if !upsert[:update]
          update = fields.map(&:to_s) - upsert[:conflict].map(&:to_s)
        else
          update = upsert[:update]
        end
        update = update.map {|field| "#{ field } = EXCLUDED.#{ field }" }
        sql += " ON CONFLICT (#{ upsert[:conflict].join ', ' }) DO UPDATE SET #{ update.join ', ' }"
        if upsert[:where]
          sql += " WHERE #{ upsert[:where] }"
        end
      end
      # res is a PG::Result object. See
      # https://deveiate.org/code/pg/PG/Result.html
      # for its details.
      res = connection.execute(sql)
      res.cmd_tuples
    end

  end
end

