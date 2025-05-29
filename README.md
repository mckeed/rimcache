# Rimcache

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


## Configuration

If the record is rarely updated and you'd rather not bother with expiration,
you can set a TTL with `Rimcache.config.refresh_interval`:

```ruby
Rimcache.config.refresh_interval = 15.minutes
```

This will cause the cache to be refreshed every 15 minutes, even if it has not been explicitly expired.
That way, any changes to the record will be reflected by other processes in at most 15 minutes.
Keep in mind, however, that using this strategy will lead to inconsistency between processes as they
won't all reflect the changes at the same time.

When you want to edit the record, you can call `Rimcache.fetch` with the `for_update` keyword argument:

```ruby
class Site < ActiveRecord::Base
  has_many :features

  after_update :expire_rimcache

  def self.fetch_by_slug(slug, for_update: false)
    Rimcache.fetch("site_#{slug}", for_update:) do
      # This will only be called if site is not already in cache or was expired
      Site.eager_load(:features).find_by(slug:)
    end
  end

  def expire_rimcache
    Rimcache.expire("site_#{slug}")
  end
end
```

Then a Site can be updated like this:

```ruby
site = Site.fetch_by_slug(:example, for_update: true)
site.update!(name: "New Name") # after_update callback expires the rimcache
```

Note that `for_update` does not handle expiration, it just ensures the record is refreshed
from the database and not frozen.


### Expiry cache

Rimcache by default uses Rails' low-level caching to coordinate expiration across processes.
If you want to use a different cache store, you can set `Rimcache.config.expiry_cache` to an instance of
`ActiveSupport::Cache::Store`.

```ruby
Rimcache.config.expiry_cache # defaults to Rails.cache
Rimcache.config.expiry_cache = ActiveSupport::Cache::MemoryStore.new
```

If you want to use the same cache store as Rails but avoid conflicts, such as with
another instance of `Rimcache::Store`, you can change `Rimcache.config.expiry_cache_key`:

```ruby
alt_rimcache = Rimcache::Store.new
alt_rimcache.config.expiry_cache_key = "alt_rimcache"
```

In order to reduce the number of hits to the expiry cache, Rimcache only checks it
every 4 seconds by default. This can be changed with `Rimcache.config.check_frequency`:

```ruby
Rimcache.config.check_frequency = 30.seconds
Rimcache.config.check_frequency = nil # always check the expiry cache
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
