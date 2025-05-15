# Rimcache

Note: still in development, not ready to use yet

A right-in-memory "cache" for Ruby on Rails.

Does your Rails app have individual records that most or all of your requests use?
They rarely change but it's still handy to have them in the database?

With Rimcache, you can keep a frozen ActiveRecord object or set of objects in
memory and it will automatically refresh from the database when any server worker
invalidates it. It avoids the serialization required for caching in Redis/Memcache,
so it is usable for situations where Rails low-level caching is not.
Associations on a record will stay loaded, so it can save more than one query per
cached record.


## Usage

Say you have an app where every request is processed in the context one of just a few `Site` records.
You could avoid loading it from the database every time like this:

```ruby
class Site < ActiveRecord::Base
  has_many :features

  after_update :expire_rimcache

  def self.find_cached(slug)
    Rimcache.fetch("site_#{slug}") do
      # This will only be called if site is not already in cache or was expired
      Site.eager_load(:features).find_by(slug:)
    end
  end

  def expire_rimcache
    Rimcache.expire("site_#{slug}")
  end
end
```


<!--
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
-->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mckeed/rimcache.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
