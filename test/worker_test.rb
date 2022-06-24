require 'time'
require 'minitest/autorun'
require_relative '../lib/worker.rb'

class TestWorker < Minitest::Test 
  def test_check_id 
    e = assert_raises TypeError do 
      Worker.new('1', 'foo')
    end
    assert_equal 'id must be an integer.', e.message

    e = assert_raises TypeError do 
      Worker.new(1.0, 'foo')
    end
    assert_equal 'id must be an integer.', e.message

    e = assert_raises RangeError do 
      Worker.new(-1, 'foo')
    end
    assert_equal 'id must be non-negative.', e.message
  end

  def test_check_name
    e = assert_raises TypeError do 
      Worker.new(1, 100)
    end
    assert_equal 'name must be a string.', e.message

    e = assert_raises TypeError do 
      Worker.new(1, Date.today)
    end
    assert_equal 'name must be a string.', e.message
  end

  def test_check_work_time 
    now = Time.now
    e = assert_raises TypeError do 
      Worker.new(0, 'foo', 100)
    end
    assert_equal 'started_work_at must be nil or an instance of Time.', e.message

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, 100)
    end
    assert_equal 'finished_work_at must be nil or an instance of Time.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', nil, now)
    end
    assert_equal 'finished_work_at must be nil when started_work_at is nil.', e.message 

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now - 100)
    end
    assert_equal 'started_work_at must be before finished_work_at.', e.message
  end

  def test_start_to_finish
    # workerを作成
    worker = Worker.new(0, 'foo')
    assert worker.started_work_at.nil?
    assert worker.finished_work_at.nil?
    refute worker.working?
    assert_equal '出勤前', worker.status
    
    # 勤務開始
    worker = worker.start_work 
    assert worker.started_work_at.instance_of?(Time)
    assert worker.finished_work_at.nil?
    assert worker.working?
    assert_equal '勤務中', worker.status

    # 勤務終了
    worker = worker.finish_work
    assert worker.started_work_at.instance_of?(Time)
    assert worker.finished_work_at.instance_of?(Time)
    refute worker.working?
    assert_equal '退勤済', worker.status

    # リセット
    worker = worker.reset 
    assert worker.started_work_at.nil?
    assert worker.finished_work_at.nil?
    refute worker.working?
    assert_equal '出勤前', worker.status
  end

  def test_working_hours
    started_work_at  = Time.local(2021,  5, 20,  0, 33, 45, 0)
    finished_work_at = Time.local(2021,  5, 20,  0, 33, 52, 0)
    worker = Worker.new(0, 'foo', started_work_at, finished_work_at)
    assert_equal Timer.new(0, 0, 7), worker.working_hours

    started_work_at  = Time.local(2021, 12,  4,  0, 33, 23, 0)
    finished_work_at = Time.local(2021, 12,  4, 18, 55, 45, 0)
    worker = Worker.new(0, 'foo', started_work_at, finished_work_at)
    assert_equal Timer.new(18, 22, 22), worker.working_hours
  end
end