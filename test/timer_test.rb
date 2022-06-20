require 'minitest/autorun'
require_relative '../lib/timer.rb'

class TimerTest < Minitest::Test
  def test_timer 
    assert Timer.new(0, 0, 0)
  end

  def test_create_from_sec 
    assert_equal Timer.new(0, 0, 34), Timer.create_from_sec(34)
    assert_equal Timer.new(0, 1, 34), Timer.create_from_sec(94)
    assert_equal Timer.new(3, 4, 32), Timer.create_from_sec(11072)
  end

  def test_to_sec 
    assert_equal 34, Timer.new(0, 0, 34).to_sec 
    assert_equal 94, Timer.new(0, 1, 34).to_sec 
    assert_equal 11072, Timer.new(3, 4, 32).to_sec
  end

  def test_comparable 
    assert Timer.new(2, 40, 30) > Timer.new(1, 50, 38)
    assert Timer.new(2, 3, 40) < Timer.new(2, 3, 50)
    assert Timer.new(17, 12, 8) == Timer.new(17, 12, 8)
    assert Timer.new(18, 12, 8) != Timer.new(17, 12, 8)
    assert Timer.new(10, 45, 22).between?(Timer.new(0, 0, 0), Timer.new(24, 0, 0))
  end

  def test_add 
    assert_equal Timer.new(2, 39, 3), Timer.new(1, 20, 0) + Timer.new(1, 19, 3)
    assert_equal Timer.new(0, 2, 54), Timer.new(0, 1, 20) + 94
  end

  def test_subtraction 
    assert_equal Timer.new(1, 20, 0), Timer.new(2, 39, 3) - Timer.new(1, 19, 3)
    assert_equal Timer.new(1, 19, 3), Timer.new(2, 39, 3) - Timer.new(1, 20, 0)
    assert_equal Timer.new(0, 0, 0), Timer.new(2, 39, 3) - Timer.new(4, 19, 8)
    assert_equal Timer.new(0, 1, 20), Timer.new(0, 2, 54) - 94
  end

  def test_muliplication
    assert_equal Timer.new(0, 1, 30), Timer.new(0, 0, 30) * 3
    assert_equal Timer.new(6, 17, 6), Timer.new(2, 5, 42) * 3
    assert_equal Timer.new(94, 29, 0), Timer.new(1, 34, 29) * 60
  end

  def test_to_s 
    assert_equal '00:00:00', Timer.new(0, 0, 0).to_s
    assert_equal '02:24:05', Timer.new(2, 24, 5).to_s
  end
end