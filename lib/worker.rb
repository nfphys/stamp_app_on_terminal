require 'date'
require 'time'
require_relative './timer.rb'

class Worker
  attr_reader :id, :name, :started_work_at, :finished_work_at

  def initialize(id, name, started_work_at=nil, finished_work_at=nil)
    unless id.instance_of?(Integer)
      raise TypeError, 'id must be an integer.'
    end

    if id.negative?
      raise RangeError, 'id must be non-negative.'
    end

    unless name.instance_of?(String)
      raise TypeError, 'name must be a string.'
    end

    unless started_work_at.nil? || started_work_at.instance_of?(Time)
      raise TypeError, 'started_work_at must be an integer or nil.'
    end

    unless finished_work_at.nil? || finished_work_at.instance_of?(Time)
      raise TypeError, 'finished_work_at must be an integer or nil.'
    end

    if started_work_at.nil? && !finished_work_at.nil?
      raise ArgumentError, 'finished_work_at must be nil when started_work_at is nil.'
    end

    if !started_work_at.nil? && !finished_work_at.nil? && (finished_work_at - started_work_at).negative?
      raise ArgumentError, 'started_work_at must be before finished_work_at.'
    end

    @id = id
    @name = name 
    @started_work_at = started_work_at
    @finished_work_at = finished_work_at
    self.freeze
  end

  def start_work 
    if started_work_at 
      puts "既に出勤しています。"
      return self 
    end

    started_work_at = Time.now 
    Worker.new(id, name, started_work_at)
  end

  def finish_work 
    if started_work_at.nil?
      puts "まだ出勤していません。"
      return self 
    end

    if finished_work_at 
      puts "既に退勤しています。"
      return self 
    end
    
    finished_work_at = Time.now 
    Worker.new(id, name, started_work_at, finished_work_at)
  end

  def working?
    return false if started_work_at.nil?
    finished_work_at.nil?
  end

  def status 
    if started_work_at.nil?
      return "出勤前"
    end

    if finished_work_at.nil?
      return "勤務中"
    end

    "退勤済"
  end

  def reset 
    Worker.new(id, name)
  end

  def working_hours 
    if started_work_at.nil?
      return Timer.create_from_sec(0)
    end

    if finished_work_at.nil?
      return Timer.create_from_sec(Time.now - started_work_at)
    end

    Timer.create_from_sec(finished_work_at - started_work_at)
  end
end

