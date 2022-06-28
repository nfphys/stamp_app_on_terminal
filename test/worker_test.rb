require 'time'
require 'minitest/autorun'
require_relative '../lib/worker.rb'
require_relative '../lib/timer.rb'

class TestWorker < Minitest::Test 
  def setup
    @now = Time.now 
  end

  def test_check_id 
    e = assert_raises TypeError do 
      Worker.new(id: '1', name: 'foo')
    end
    assert_equal 'id must be an integer.', e.message

    e = assert_raises TypeError do 
      Worker.new(id: 1.0, name: 'foo')
    end
    assert_equal 'id must be an integer.', e.message

    e = assert_raises RangeError do 
      Worker.new(id: -1, name: 'foo')
    end
    assert_equal 'id must be non-negative.', e.message
  end

  def test_check_name
    e = assert_raises TypeError do 
      Worker.new(id: 1, name: 100)
    end
    assert_equal 'name must be a string.', e.message

    e = assert_raises TypeError do 
      Worker.new(id: 1, name: Date.today)
    end
    assert_equal 'name must be a string.', e.message
  end

  def test_check_started_work_at 
    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: 100)
    end
    assert_equal 'started_work_at must be nil or an instance of Time.', e.message
  end

  def test_check_finished_work_at 
    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: 100)
    end
    assert_equal 'finished_work_at must be nil or an instance of Time.', e.message
  end

  def test_check_started_and_finished_work_at 
    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: nil, finished_work_at: @now)
    end
    assert_equal 'finished_work_at must be nil when started_work_at is nil.', e.message 

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now - 100)
    end
    assert_equal 'started_work_at must be before finished_work_at.', e.message
  end

  def test_check_started_break_at 
    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: @now)
    end
    assert_equal 'started_break_at must be an array.', e.message

    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [1, nil])
    end
    assert_equal 'Each element of started_break_at must be an instance of Time.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now-10, @now+10])
    end
    assert_equal 'Each element of started_break_at must be after started_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+110])
    end
    assert_equal 'Each element of started_break_at must be before finished_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+5])
    end
    assert_equal 'started_break_at[i] must be before started_break_at[i+1].', e.message
  end

  def test_check_finished_break_at
    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now], finished_break_at: @now)
    end
    assert_equal 'finished_break_at must be an array.', e.message

    e = assert_raises TypeError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now], finished_break_at: [1, nil])
    end
    assert_equal 'Each element of finished_break_at must be an instance of Time.', e.message 

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+15, @now-12])
    end
    assert_equal 'Each element of finished_break_at must be after started_work_at.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+110, @now+25])
    end
    assert_equal 'Each element of finished_break_at must be before finished_work_at', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+15, @now+12])
    end
    assert_equal 'finished_break_at[i] must be before finished_break_at[i].', e.message
  end

  def test_check_started_and_finished_break_at
    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [])
    end
    assert_equal '(started_break_at.size - finished_break_at.size) must be 0 or 1.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+15, @now+25, @now+35])
    end
    assert_equal '(started_break_at.size - finished_break_at.size) must be 0 or 1.', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+5])
    end
    assert_equal 'started_break_at[i] must be before finished_break_at[i].', e.message

    e = assert_raises ArgumentError do 
      Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100, started_break_at: [@now+10, @now+20], finished_break_at: [@now+12, @now+18])
    end
    assert_equal 'started_break_at[i] must be before finished_break_at[i].', e.message
  end

  def test_status 
    worker = Worker.new(id: 0, name: 'foo')
    assert_equal '出勤前', worker.status 

    worker = Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: nil)
    assert_equal '勤務中', worker.status

    worker = Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100)
    assert_equal '退勤済', worker.status

    worker = Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: nil, started_break_at: [@now+10], finished_break_at: [])
    assert_equal '休憩中', worker.status

    worker = Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: nil, started_break_at: [@now+10, @now+20], finished_break_at: [@now+15])
    assert_equal '休憩中', worker.status
  end

  def test_start_work 
    worker = Worker.new(id: 0, name: 'foo')

    worker = worker.start_work
    assert_equal '勤務中', worker.status
  end

  def test_finish_work 
    worker = Worker.new(id: 0, name: 'foo')

    worker = worker.finish_work 
    assert_equal '出勤前', worker.status 

    worker = worker.start_work 
    worker = worker.finish_work 
    assert_equal '退勤済', worker.status
  end

  def test_start_break 
    worker = Worker.new(id: 0, name: 'foo')

    worker = worker.start_break
    assert_equal '出勤前', worker.status 

    worker = worker.start_work
    worker = worker.start_break 
    assert_equal '休憩中', worker.status 

    worker = worker.finish_break 
    assert_equal '勤務中', worker.status

    worker = worker.start_break 
    worker = worker.finish_work 
    assert_equal '退勤済', worker.status

    worker = worker.start_break 
    assert_equal '退勤済', worker.status
  end

  def test_finish_break 
    worker = Worker.new(id: 0, name: 'foo')

    worker = worker.finish_break 
    assert_equal '出勤前', worker.status 

    worker = worker.start_work 
    worker = worker.finish_break 
    assert_equal '勤務中', worker.status 

    worker = worker.start_break 
    worker = worker.finish_break 
    assert_equal '勤務中', worker.status 

    worker = worker.finish_work 
    worker = worker.finish_break 
    assert_equal '退勤済', worker.status 
  end

  def test_working_hours
    started_work_at  = Time.local(2021,  5, 20,  0, 33, 45, 0)
    finished_work_at = Time.local(2021,  5, 20,  0, 33, 52, 0)
    worker = Worker.new(id: 0, name: 'foo', started_work_at: started_work_at, finished_work_at: finished_work_at)
    assert_equal Timer.new(0, 0, 7), worker.working_hours

    started_work_at  = Time.local(2021, 12,  4,  0, 33, 23, 0)
    finished_work_at = Time.local(2021, 12,  4, 18, 55, 45, 0)
    worker = Worker.new(id: 0, name: 'foo', started_work_at: started_work_at, finished_work_at: finished_work_at)
    assert_equal Timer.new(18, 22, 22), worker.working_hours

    worker = Worker.new(id: 0, name: 'foo', started_work_at: @now, finished_work_at: @now+100)
    assert_equal Timer.create_from_sec(100), worker.working_hours
  end

  def test_breaking_hours 
    t = @now - 100

    worker = Worker.new(id: 0, name: 'foo', started_work_at: t, finished_work_at: nil, started_break_at: [t, t+30], finished_break_at: [t+3])
    assert_equal Timer.create_from_sec(73), worker.breaking_hours

    worker = Worker.new(id: 0, name: 'foo', started_work_at: t, finished_work_at: t+100, started_break_at: [t+10, t+30], finished_break_at: [t+13, t+45])
    assert_equal Timer.create_from_sec(18), worker.breaking_hours
  end
end
