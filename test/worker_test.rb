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

  def test_check_started_work_at 
    now = Time.now 

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', 100)
    end
    assert_equal 'started_work_at must be nil or an instance of Time.', e.message
  end

  def test_check_finished_work_at 
    now = Time.now

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, 100)
    end
    assert_equal 'finished_work_at must be nil or an instance of Time.', e.message
  end

  def test_check_started_and_finished_work_at 
    now = Time.now

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', nil, now)
    end
    assert_equal 'finished_work_at must be nil when started_work_at is nil.', e.message 

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now - 100)
    end
    assert_equal 'started_work_at must be before finished_work_at.', e.message
  end

  def test_check_started_break_at 
    now = Time.now 

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, now+100, now)
    end
    assert_equal 'started_break_at must be an array.', e.message

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, now+100, [1, nil])
    end
    assert_equal 'Each element of started_break_at must be an instance of Time.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now-10, now+10])
    end
    assert_equal 'Each element of started_break_at must be after started_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+110])
    end
    assert_equal 'Each element of started_break_at must be before finished_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+5])
    end
    assert_equal 'started_break_at[i] must be before started_break_at[i+1].', e.message
  end

  def test_check_finished_break_at
    now = Time.now 

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, now+100, [now], now)
    end
    assert_equal 'finished_break_at must be an array.', e.message

    e = assert_raises TypeError do 
      Worker.new(0, 'foo', now, now+100, [now], [1, nil])
    end
    assert_equal 'Each element of finished_break_at must be an instance of Time.', e.message 

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+15, now-12])
    end
    assert_equal 'Each element of finished_break_at must be after started_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+110, now+25])
    end
    assert_equal 'Each element of finished_break_at must be before finished_work_at', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+15, now+12])
    end
    assert_equal 'finished_break_at[i] must be before finished_break_at[i].', e.message
  end

  def test_check_started_and_finished_break_at
    now = Time.now 

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [])
    end
    assert_equal '(started_break_at.size - finished_break_at.size) must be 0 or 1.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+15, now+25, now+35])
    end
    assert_equal '(started_break_at.size - finished_break_at.size) must be 0 or 1.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+5])
    end
    assert_equal 'started_break_at[i] must be before finished_break_at[i].', e.message

    e = assert_raises ArgumentError do 
      Worker.new(0, 'foo', now, now+100, [now+10, now+20], [now+12, now+18])
    end
    assert_equal 'started_break_at[i] must be before finished_break_at[i].', e.message
  end

  def test_status 
    now = Time.now 

    worker = Worker.new(0, 'foo')
    assert_equal '出勤前', worker.status 

    worker = Worker.new(0, 'foo', now, nil)
    assert_equal '勤務中', worker.status

    worker = Worker.new(0, 'foo', now, now+100)
    assert_equal '退勤済', worker.status

    worker = Worker.new(0, 'foo', now, nil, [now+10], [])
    assert_equal '休憩中', worker.status

    worker = Worker.new(0, 'foo', now, nil, [now+10, now+20], [now+15])
    assert_equal '休憩中', worker.status
  end

  def test_start_work 
    worker = Worker.new(0, 'foo')

    worker = worker.start_work
    assert_equal '勤務中', worker.status
  end

  def test_finish_work 
    worker = Worker.new(0, 'foo')

    worker = worker.finish_work 
    assert_equal '出勤前', worker.status 

    worker = worker.start_work 
    worker = worker.finish_work 
    assert_equal '退勤済', worker.status
  end

  def test_start_break 
    worker = Worker.new(0, 'foo')

    worker = worker.start_break
    assert_equal '出勤前', worker.status 

    worker = worker.start_work
    worker = worker.start_break 
    assert_equal '休憩中', worker.status 

    worker = worker.finish_work 
    assert_equal '退勤済', worker.status

    worker = worker.start_break 
    assert_equal '退勤済', worker.status
  end

  def test_start_to_finish
    # workerを作成
    worker = Worker.new(0, 'foo')
    assert worker.started_work_at.nil?
    assert worker.finished_work_at.nil?
    assert_equal '出勤前', worker.status
    
    # 勤務開始
    worker = worker.start_work 
    assert worker.started_work_at.instance_of?(Time)
    assert worker.finished_work_at.nil?
    assert_equal '勤務中', worker.status

    # 勤務終了
    worker = worker.finish_work
    assert worker.started_work_at.instance_of?(Time)
    assert worker.finished_work_at.instance_of?(Time)
    assert_equal '退勤済', worker.status
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