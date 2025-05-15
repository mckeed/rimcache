# frozen_string_literal: true

require_relative "config"
require "active_support/all"

module Rimcache
  # The core of Rimcache. Stores frozen objects in a Hash while tracking when
  # they were last stored and when they were last updated by any process connected
  # to the same cross-process expiry cache.
  #
  # Access this via Rimcache.store for a singleton instance.
  #
  class Store
    attr_accessor :config, :cached

    def initialize
      @config = Config.new
      @cached = {}
      @written_at = {}
      @last_check = Time.current

      # @expiry_cache is set on first demand to give the best chance
      # that Rails.cache is loaded when we try to access it
      @expiry_cache = nil
      @expiry = nil
    end

    # Returns the value cached under +key+
    def read(key)
      cached[key]
    end

    # Returns true if no value has been cached for +key+ yet, if +expire+ has been
    # called from any process with access to the same +expiry_cache+
    # @return [Boolean] Whether the value under +key+ needs to be refreshed.
    def expired?(key)
      last_update = @written_at[key]
      return true if !cached[key] || needs_refresh?(last_update)

      # Check if another process has changed the value since we read it
      expired_at = reload_expiry[key]
      !!expired_at && expired_at > last_update
    end

    # Update the expiry_cache to notify other processes that the
    # rimcached object at this key has changed and must be refreshed.
    def expire(key)
      cached[key] = nil
      reload_expiry(force: true)
      @expiry[key] = Time.current
      expiry_cache.write(config.expiry_cache_key, @expiry, expires_in: nil)
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
    def fetch(key, for_update: false)
      raise(ArgumentError, "Rimcache: tried to store to cache with nil key") if key.nil?

      if for_update
        cached[key] = nil
        yield
      elsif expired?(key) || !cached[key]
        write(key, yield.freeze) if block_given?
      else
        read(key)
      end
    end

    # Expires the rimcache for this key and saves a frozen clone of +value+
    # as the new value.
    def update(key, value)
      expire(key)
      write(key, value.clone.freeze)
    end

    private

    def needs_refresh?(last_update)
      return true if last_update.nil?

      !config.refresh_interval.nil? && Time.current - last_update > config.refresh_interval
    end

    def reload_expiry(force: false)
      # Only check expiry_cache every few seconds for excessive efficiency
      now = Time.current
      return @expiry unless force || @expiry.nil? || now - @last_check > config.check_frequency

      @last_check = now
      @expiry = expiry_cache.read(config.expiry_cache_key) || {}
    end

    def write(key, value)
      @written_at[key] = Time.current
      cached[key] = value # must return value
    end

    # @return [ActiveSupport::Cache::Store]
    def expiry_cache
      @expiry_cache ||= config.expiry_cache || rails_cache || fallback_cache
    end

    def rails_cache
      require "rails"
      Rails.cache
    rescue LoadError, NoMethodError
      # return nil if there's no rails or no Rails.cache
    end

    def fallback_cache
      puts "[Rimcache] Warning: no expiry cache found. Rimcache will not be invalidated across multiple processes."
      ActiveSupport::Cache::MemoryStore.new
    end
  end
end
