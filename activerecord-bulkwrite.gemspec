Gem::Specification.new do |s|
  s.name        = 'activerecord-bulkwrite'
  s.version     = '1.0.3'
  s.date        = '2016-10-02'
  s.summary     = "Bulk write/upsert for ActiveRecord"
  s.authors     = ["Robert Zhang"]
  s.email       = 'louirobert@gmail.com'
  s.files       = ["lib/activerecord/bulkwrite.rb", "LICENSE", "README.md"]
  s.homepage    = 'https://github.com/coin8086/activerecord-bulkwrite'
  s.license     = 'MIT'

  s.add_runtime_dependency 'activerecord', '~> 4.0'
end

