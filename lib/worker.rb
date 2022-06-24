require 'date'
require 'time'
require_relative './timer.rb'

class Worker
  attr_reader :id, :name, :started_work_at, :finished_work_at, :started_break_at, :finished_break_at

  def self.check_id(id)
    unless id.instance_of?(Integer)
      raise TypeError, 'id must be an integer.'
    end

    if id.negative?
      raise RangeError, 'id must be non-negative.'
    end
  end
  
  def self.check_name(name)
    unless name.instance_of?(String)
      raise TypeError, 'name must be a string.'
    end
  end

  def self.check_started_work_at(started_work_at)
    unless started_work_at.nil? || started_work_at.instance_of?(Time)
      raise TypeError, 'started_work_at must be nil or an instance of Time.'
    end
  end

  def self.check_finished_work_at(finished_work_at)
    unless finished_work_at.nil? || finished_work_at.instance_of?(Time)
      raise TypeError, 'finished_work_at must be nil or an instance of Time.'
    end
  end

  def self.check_started_and_finished_work_at(started_work_at, finished_work_at)
    if started_work_at.nil? && !finished_work_at.nil?
      raise ArgumentError, 'finished_work_at must be nil when started_work_at is nil.'
    end

    if !started_work_at.nil? && !finished_work_at.nil? && (finished_work_at - started_work_at).negative?
      raise ArgumentError, 'started_work_at must be before finished_work_at.'
    end
  end

  def self.check_started_break_at(started_work_at, finished_work_at, started_break_at)
    unless started_break_at.instance_of?(Array)
      raise TypeError, 'started_break_at must be an array.'
    end

    started_break_at.each do |e|
      unless e.instance_of?(Time)
        raise TypeError, 'Each element of started_break_at must be an instance of Time.'
      end

      if e < started_work_at 
        raise ArgumentError, 'Each element of started_break_at must be after started_work_at.'
      end

      if !finished_work_at.nil? && e > finished_work_at 
        raise ArgumentError, 'Each element of started_break_at must be before finished_work_at.'
      end
    end

    (0...(started_break_at.size - 1)).each do |i|
      unless started_break_at[i] < started_break_at[i+1]
        raise ArgumentError, 'started_break_at[i] must be before started_break_at[i+1].'
      end
    end
  end

  def self.check_finished_break_at(started_work_at, finished_work_at, finished_break_at)
    unless finished_break_at.instance_of?(Array)
      raise TypeError, 'finished_break_at must be an array.'
    end

    finished_break_at.each do |e|
      unless e.instance_of?(Time)
        raise TypeError, 'Each element of finished_break_at must be an instance of Time.'
      end

      if e < started_work_at
        raise ArgumentError, 'Each element of finished_break_at must be after started_work_at.'
      end

      if !finished_work_at.nil? && e > finished_work_at
        raise ArgumentError, 'Each element of finished_break_at must be before finished_work_at'
      end
    end

    (0...(finished_break_at.size - 1)).each do |i|
      unless finished_break_at[i] < finished_break_at[i+1]
        raise ArgumentError, 'finished_break_at[i] must be before finished_break_at[i].'
      end
    end
  end

  def self.check_started_and_finished_break_at(started_break_at, finished_break_at)
    unless (started_break_at.size - finished_break_at.size).between?(0, 1)
      raise ArgumentError, '(started_break_at.size - finished_break_at.size) must be 0 or 1.'
    end

    (0...started_break_at.size).each do |i|
      if !finished_break_at[i].nil? && started_break_at[i] > finished_break_at[i]
        raise ArgumentError, 'started_break_at[i] must be before finished_break_at[i].'
      end
    end
  end

  def initialize(id, name, started_work_at=nil, finished_work_at=nil, started_break_at=[], finished_break_at=[])
    Worker.check_id(id)
    Worker.check_name(name)

    Worker.check_started_work_at(started_work_at)
    Worker.check_finished_work_at(finished_work_at)
    Worker.check_started_and_finished_work_at(started_work_at, finished_work_at)

    Worker.check_started_break_at(started_work_at, finished_work_at, started_break_at)
    Worker.check_finished_break_at(started_work_at, finished_work_at, finished_break_at)
    Worker.check_started_and_finished_break_at(started_break_at, finished_break_at)

    @id = id
    @name = name 
    @started_work_at = started_work_at
    @finished_work_at = finished_work_at
    @started_break_at = started_break_at
    @finished_break_at = finished_break_at
    self.freeze
  end

  def status 
    if started_work_at.nil?
      return "出勤前"
    end

    if !finished_work_at.nil?
      return "退勤済"
    end

    if started_break_at.size == finished_break_at.size + 1
      return "休憩中"
    end

    "勤務中"
  end

  def start_work 
    if status != "出勤前" 
      # puts "既に出勤しています。"
      return self 
    end

    started_work_at = Time.now 
    Worker.new(id, name, started_work_at)
  end

  def finish_work 
    if status == "出勤前"
      # puts "まだ出勤していません。"
      return self 
    end

    if status == "退勤済" 
      # puts "既に退勤しています。"
      return self 
    end
    
    now = Time.now 
    finished_work_at = now

    if status == "休憩中"
      finished_break_at = @finished_break_at + [now]
      return Worker.new(
        id, name, started_work_at, finished_work_at, 
        started_break_at, finished_break_at
      )
    end

    Worker.new(id, name, started_work_at, finished_work_at)
  end

  def start_break 
    if status != "勤務中"
      return self 
    end

    started_break_at = @started_break_at + [Time.now]
    Worker.new(id, name, started_work_at, finished_work_at, started_break_at)
  end

  def finish_break 
    if status != "休憩中"
      return self 
    end

    finished_break_at = @finished_break_at + [Time.now]
    Worker.new(
      id, name, started_work_at, finished_work_at, 
      started_break_at, finished_break_at
    )
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

