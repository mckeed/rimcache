# frozen_string_literal: true

require_relative "test_helper"

class TestRimcache < Minitest::Test
  def setup
    Rimcache.config.expiry_cache = ActiveSupport::Cache::MemoryStore.new if Rimcache.config.expiry_cache.nil?
    @key = "key#{rand(2 << 31)}"
  end

  def test_that_it_has_a_version_number
    refute_nil ::Rimcache::VERSION
  end

  def test_fetch_stores_and_retrieves
    cached_value = Rimcache.fetch("key1") { Object.new }

    refute_nil cached_value
    assert_equal cached_value, Rimcache.fetch("key1")
  end

  def test_fetch_clones_and_freezes_stored_object
    orig_value = ["value"]
    cached_value = Rimcache.fetch("key2") { ["value"] }

    orig_value << "more"

    assert_equal orig_value, Rimcache.fetch("key2") + ["more"]
    refute_equal cached_value, orig_value

    assert_predicate Rimcache.fetch("key2"), :frozen?
    assert_raises(FrozenError) { cached_value << "more" }
  end

  def test_fetch_for_update
    orig_value = Rimcache.fetch("key3") { ["value1"] }
    new_value = Rimcache.fetch("key3", for_update: true) { ["value2"] }

    refute_equal orig_value, new_value
    assert_equal ["value2"], new_value
    assert_equal ["value3"], Rimcache.fetch("key3") { ["value3"] }
  end

  def test_fetch_nil_key_raises_error
    assert_raises(ArgumentError) { Rimcache.fetch(nil) }
    assert_raises(ArgumentError) { Rimcache.fetch }
  end

  def test_fetch_expired_value
    config = Rimcache.config
    Rimcache.fetch(@key) { ["value4"] }

    # Expire directly in expiry_cache to simulate it being expired from another process
    config.check_frequency = 0
    config.expiry_cache.stub(:read, { @key => Time.now }) do
      sleep 0.1

      new_value = Rimcache.fetch(@key) { ["value5"] }

      assert_equal ["value5"], new_value
      assert_equal ["value5"], Rimcache.fetch(@key) { raise "fetch's block should not be called" }
    end
  end

  def test_expire
    Rimcache.config.check_frequency = 10.seconds
    orig_value = Rimcache.fetch(@key) { ["value6"] }
    Rimcache.expire(@key)

    refute_nil Rimcache.store.send(:reload_expiry)[@key]
    refute_nil Rimcache.config.expiry_cache.read(Rimcache.config.expiry_cache_key)[@key]

    new_value = Rimcache.fetch(@key) { ["value7"] }

    assert_equal ["value7"], new_value
    refute_equal orig_value, new_value
  end

  def test_check_frequency_config
    Rimcache.config.check_frequency = 0.1.seconds
    orig_value = Rimcache.fetch(@key) { ["value8"] }

    assert_equal orig_value, Rimcache.fetch(@key) { ["value9"] }

    sleep 0.12
  end
end
