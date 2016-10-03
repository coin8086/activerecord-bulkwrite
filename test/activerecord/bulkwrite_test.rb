require 'minitest/autorun'
require_relative '../test_helpers'
require_relative '../../lib/activerecord/bulkwrite'

class TestUser < ActiveRecord::Base
  connection.create_table(:test_users, :force => true) do |t|
    t.string    :name
    t.string    :login
    t.integer   :limit
    t.boolean   :hireable
    t.datetime  :created_at
  end

  self.record_timestamps = false
end

class BulkWriteTest < Minitest::Test
  include TestHelpers

  def test_bulk_write
    now = Time.now

    # It should bulk insert rows of data and do proper type convertion for database.
    init
    fields = %w(id name hireable created_at)
    rows = [
      [1, "Bob's", true, now - 10],
      [2, nil, "false", (now - 1).utc.iso8601], # NOTE: The string time must be in UTC.
    ]
    result = TestUser.bulk_write(fields, rows)
    assert_equal 2, result

    user = TestUser.first
    assert_equal rows[0][0], user.id
    assert_equal rows[0][1], user.name
    assert_equal rows[0][2], user.hireable
    # To be able to compare the time and ignore minor loss of accuracy,
    assert_equal rows[0][3].to_i, user.created_at.to_i

    user = TestUser.last
    assert_equal 2, user.id
    assert_equal nil, user.name
    assert_equal false, user.hireable
    assert_equal (now - 1).to_i, user.created_at.to_i

    # It should insert or update, and respect where condition on update.
    init(
      :test_users => [
        { :id => 1, :name => 'n1', :login => 'l1' },
        { :id => 2, :name => 'n2', :login => 'l2' },
        { :id => 3, :name => 'n3', :login => 'l3' },
      ],
    )
    fields = %w(id name login)
    rows = [
      [2, "n22", "l22"],
      [3, "n33", nil],
      [4, nil, "l44"],
    ]
    result = TestUser.bulk_write(
      fields, rows, { :conflict => [:id], :where => "test_users.id > 2 AND EXCLUDED.name IS NOT NULL" }
    )
    assert_equal 2, result
    users = TestUser.all.order(:id => :asc)
    assert_equal 4, users.size
    # user 1 doesn't get updated
    assert_equal 1, users[0].id
    assert_equal 'n1', users[0].name
    assert_equal 'l1', users[0].login
    # user 2 doesn't get updated
    assert_equal 2, users[1].id
    assert_equal 'n2', users[1].name
    assert_equal 'l2', users[1].login
    # user 3 gets updated
    assert_equal 3, users[2].id
    assert_equal 'n33', users[2].name
    assert_equal nil, users[2].login
    # user 4 gets inserted
    assert_equal 4, users[3].id
    assert_equal nil, users[3].name
    assert_equal 'l44', users[3].login

    # It should double qoute special field names like "limit" to avoid SQL syntax error.
    init
    fields = %w(name limit)
    rows = [['hello', 123]]
    result = TestUser.bulk_write(fields, rows)
    assert_equal 1, result
    assert_equal 123, TestUser.first.limit
  end

end
