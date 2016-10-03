require 'active_record'
require 'active_record/tasks/database_tasks'

module TestHelpers
  def db_clear
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.descendants.each do |model|
        model.delete_all
      end
    end
  end

  def db_table_to_model
    pairs = ActiveRecord::Base.descendants.map {|klass| [klass.table_name, klass] }
    Hash[pairs].with_indifferent_access
  end

  def db_init(spec)
    models = db_table_to_model
    ActiveRecord::Base.transaction do
      spec.each do |table, docs|
        model = models[table]
        docs.each do |doc|
          model.create! doc
        end
      end
    end
  end

  def init(spec = nil)
    db_clear
    return if spec.nil?
    db_init(spec)
  end

  # It must be string-keyed.
  DB_CONFIG = {
    "adapter" =>  "postgresql",
    "database" => "activerecord-bulkwrite-test",
    "encoding" => "utf8",
  }

  # Establish database connection and create database.
  begin
    ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(DB_CONFIG).create
  rescue ActiveRecord::Tasks::DatabaseAlreadyExists
    # Ignore DatabaseAlreadyExists.
  end
end

