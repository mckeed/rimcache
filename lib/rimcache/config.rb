# frozen_string_literal: true

require "logger"
require "active_support/all"

module Rimcache
  # Configuration for Rimcache
  class Config
    # An instance of ActiveSupport::Cache::Store used to coordinate Rimcache expiry and invalidation
    # across processes. If not set, defaults to Rails.cache.
    # @return [ActiveSupport::Cache::Store]
    attr_accessor :expiry_cache

    # The cache key to use in expiry_cache.
    # Defaults to "rimcache_expiry" but can be changed to avoid conflicts.
    # @return [String | Symbol]
    attr_accessor :expiry_cache_key

    # The expiry cache will only be checked if it has not been in this much time.
    # A stale cached value can keep being returned for up to this long after another
    # process invalidates it.
    # Defaults to 4 seconds
    # @return [ActiveSupport::Duration] time in seconds
    attr_accessor :check_frequency

    # If this is set, rimcached values will be refreshed after this much
    # time even if they have not been explicitly expired.
    # Default value is +nil+.
    # @return [ActiveSupport::Duration] time in seconds
    attr_accessor :refresh_interval

    def initialize
      @check_frequency = 4.seconds
      @expiry_cache_key = "rimcache_expiry"
    end
  end
end
