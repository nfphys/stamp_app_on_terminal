require 'minitest/autorun'
require_relative '../lib/stamp/worker.rb'

class TimerTest < Minitest::Test
  def test_timer 
    assert Worker::Timer.new(0, 0, 0)
  end

  def test_create_from_sec 
    assert_equal Worker::Timer.new(0, 0, 34), Worker::Timer.create_from_sec(34)
    assert_equal Worker::Timer.new(0, 1, 34), Worker::Timer.create_from_sec(94)
    assert_equal Worker::Timer.new(3, 4, 32), Worker::Timer.create_from_sec(11072)
  end

  def test_to_sec 
    assert_equal 34, Worker::Timer.new(0, 0, 34).to_sec 
    assert_equal 94, Worker::Timer.new(0, 1, 34).to_sec 
    assert_equal 11072, Worker::Timer.new(3, 4, 32).to_sec
  end

  def test_comparable 
    assert Worker::Timer.new(2, 40, 30) > Worker::Timer.new(1, 50, 38)
    assert Worker::Timer.new(2, 3, 40) < Worker::Timer.new(2, 3, 50)
    assert Worker::Timer.new(17, 12, 8) == Worker::Timer.new(17, 12, 8)
    assert Worker::Timer.new(18, 12, 8) != Worker::Timer.new(17, 12, 8)
    assert Worker::Timer.new(10, 45, 22).between?(Worker::Timer.new(0, 0, 0), Worker::Timer.new(24, 0, 0))
  end

  def test_add 
    assert_equal Worker::Timer.new(2, 39, 3), Worker::Timer.new(1, 20, 0) + Worker::Timer.new(1, 19, 3)
    assert_equal Worker::Timer.new(0, 2, 54), Worker::Timer.new(0, 1, 20) + 94
  end

  def test_subtraction 
    assert_equal Worker::Timer.new(1, 20, 0), Worker::Timer.new(2, 39, 3) - Worker::Timer.new(1, 19, 3)
    assert_equal Worker::Timer.new(1, 19, 3), Worker::Timer.new(2, 39, 3) - Worker::Timer.new(1, 20, 0)
    assert_equal Worker::Timer.new(0, 0, 0), Worker::Timer.new(2, 39, 3) - Worker::Timer.new(4, 19, 8)
    assert_equal Worker::Timer.new(0, 1, 20), Worker::Timer.new(0, 2, 54) - 94
  end

  def test_muliplication
    assert_equal Worker::Timer.new(0, 1, 30), Worker::Timer.new(0, 0, 30) * 3
    assert_equal Worker::Timer.new(6, 17, 6), Worker::Timer.new(2, 5, 42) * 3
    assert_equal Worker::Timer.new(94, 29, 0), Worker::Timer.new(1, 34, 29) * 60
  end

  def test_to_s 
    assert_equal '00:00:00', Worker::Timer.new(0, 0, 0).to_s
    assert_equal '02:24:05', Worker::Timer.new(2, 24, 5).to_s
  end
end
