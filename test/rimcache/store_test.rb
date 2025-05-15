# frozen_string_literal: true

require_relative "../test_helper"

module Rimcache
  class TestStore < ::Minitest::Test
    def setup
      @store = Store.new
      @store.config.expiry_cache = ActiveSupport::Cache::MemoryStore.new if @store.config.expiry_cache.nil?
      @key = "key#{rand(2 << 31)}"
    end

    def test_read
      assert_nil @store.read(@key)
      @store.fetch(@key) { "read value" } # rubocop:disable Style/RedundantFetchBlock

      assert_equal "read value", @store.read(@key)
    end

    def test_fetch_stores_and_retrieves
      cached_value = @store.fetch("key1") { Object.new }

      refute_nil cached_value
      assert_equal cached_value, @store.fetch("key1")
    end

    def test_fetch_clones_and_freezes_stored_object
      orig_value = ["value"]
      cached_value = @store.fetch("key2") { ["value"] }

      orig_value << "more"

      assert_equal orig_value, @store.fetch("key2") + ["more"]
      refute_equal cached_value, orig_value

      assert_predicate @store.fetch("key2"), :frozen?
      assert_raises(FrozenError) { cached_value << "more" }
    end

    def test_fetch_for_update
      orig_value = @store.fetch("key3") { ["value1"] }
      new_value = @store.fetch("key3", for_update: true) { ["value2"] }

      refute_equal orig_value, new_value
      assert_equal ["value2"], new_value
      assert_equal ["value3"], @store.fetch("key3") { ["value3"] }
    end

    def test_fetch_nil_key_raises_error
      assert_raises(ArgumentError) { @store.fetch(nil) }
      assert_raises(ArgumentError) { @store.fetch }
    end

    def test_fetch_expired_value
      @store.fetch(@key) { ["value4"] }

      # Expire directly in expiry_cache to simulate it being expired from another process
      @store.config.check_frequency = 0
      @store.send(:expiry_cache).stub(:read, { @key => Time.now }) do
        sleep 0.1

        new_value = @store.fetch(@key) { ["value5"] }

        assert_equal ["value5"], new_value
        assert_equal ["value5"], @store.fetch(@key) { raise "fetch's block should not be called" }
      end
    end

    def test_expire
      @store.config.check_frequency = 10.seconds
      orig_value = @store.fetch(@key) { ["value6"] }
      @store.expire(@key)

      refute_nil @store.send(:reload_expiry)[@key]
      refute_nil @store.send(:expiry_cache).read(@store.config.expiry_cache_key)[@key]

      new_value = @store.fetch(@key) { ["value7"] }

      assert_equal ["value7"], new_value
      refute_equal orig_value, new_value
    end

    def test_update
      orig_value = @store.fetch(@key) { { value: 7 } }
      new_value = @store.update(@key, "value8")

      refute_equal orig_value, new_value
      assert_equal "value8", @store.read(@key)
    end

    def test_expiry_cache_config
      @store2 = Store.new
      @store2.config.expiry_cache = @store.send(:expiry_cache)

      orig_value = @store.fetch(@key) { ["value6"] }

      # Expire via @store2 to test that config.expiry_cache= worked
      @store2.expire(@key)

      new_value = @store.fetch(@key) { ["value7"] }

      assert_equal ["value7"], new_value
      refute_equal orig_value, new_value
    end

    def test_expiry_cache_key_config
      @store2 = Store.new
      @store2.config.expiry_cache = @store.send(:expiry_cache)

      orig_value = @store.fetch(@key) { ["value6"] }

      # Now expiring @store2 should not expire @store
      @store2.config.expiry_cache_key = "new cache #{@key}"
      @store2.expire(@key)

      new_value = @store.fetch(@key) { ["value7"] }

      assert_equal orig_value, new_value
    end
  end
end
