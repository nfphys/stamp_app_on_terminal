require 'time'
require 'minitest/autorun'
require_relative '../lib/worker.rb'

class TestWorker < Minitest::Test 
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