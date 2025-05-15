# frozen_string_literal: true

require_relative "rimcache/store"
require_relative "rimcache/version"

# The main entry point to Rimcache.
# "Caches" commonly-used objects by just storing them frozen in a global hash.
# Expiration is handled via Rails low-level caching or a configurable ActiveSupport::Cache::Store.
#
module Rimcache
  # A singleton instance of +Rimcache::Store+.
  def self.store
    @store ||= Store.include(Singleton).instance
  end

  # The +Rimcache::Config+ object associated with the singleton +store+
  def self.config
    store.config
  end

  # Fetches or updates data from the rimcache at the given key.
  # If there's an unexpired stored value it is returned. Otherwise,
  # the block is called and the result is frozen, stored in the rimcache
  # under this key, and returned.
  #
  # The keyword argument +for_update+ can be set to +true+ to call the block
  # and return the result unfrozen instead of caching it. You must still call
  # +expire(key)+ or +update(key, value)+ after updating the record in the database.
  #
  def self.fetch(...)
    store.fetch(...)
  end

  def self.expire(...)
    store.expire(...)
  end

  module_function

  # You can include +Rimcache+ in your model to use +rimcache+ instead of +Rimcache.fetch+
  def rimcache(...)
    Rimcache.fetch(...)
  end

  # You can include +Rimcache+ in your model to use +rimcache_expire+ instead of +Rimcache.expire+
  def rimcache_expire(...)
    Rimcache.expire(...)
  end
end
