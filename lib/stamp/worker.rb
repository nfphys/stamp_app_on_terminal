require 'mysql2'

class Worker
  DATETIME_REGEXP = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/

  attr_reader :id, :name, 
  :work_data_id, :started_work_at, :finished_work_at, 
  :break_data_ids, :started_break_at, :finished_break_at

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

  def initialize(
    id:, 
    name:, 
    work_data_id: nil,
    started_work_at: nil, 
    finished_work_at: nil, 
    break_data_ids: [],
    started_break_at: [], 
    finished_break_at: []
  )
    Worker.check_id(id)
    Worker.check_name(name)

    Worker.check_id(work_data_id) if work_data_id

    Worker.check_started_work_at(started_work_at)
    Worker.check_finished_work_at(finished_work_at)
    Worker.check_started_and_finished_work_at(started_work_at, finished_work_at)

    break_data_ids.each do |break_data_id|
      Worker.check_id(break_data_id)
    end

    Worker.check_started_break_at(started_work_at, finished_work_at, started_break_at)
    Worker.check_finished_break_at(started_work_at, finished_work_at, finished_break_at)
    Worker.check_started_and_finished_break_at(started_break_at, finished_break_at)

    @id = id
    @name = name 

    @work_data_id = work_data_id
    @started_work_at = started_work_at
    @finished_work_at = finished_work_at

    @break_data_ids = break_data_ids
    @started_break_at = started_break_at
    @finished_break_at = finished_break_at

    self.freeze
  end

  def self.load_from_database(client, name)
    client.query('USE stamp_app_on_terminal;')

    users_results = 
      client.query(
        <<~TEXT
        SELECT * 
        FROM users
        WHERE name = "#{name}"
        ;
        TEXT
      )

    if users_results.size.zero?
      raise 'ユーザが見つかりませんでした'
    end

    user_id = users_results.first['id']

    work_data_results = 
      client.query(
        <<~TEXT 
        SELECT * 
        FROM work_data
        WHERE user_id = '#{user_id}'
        ORDER BY started_work_at DESC
        LIMIT 1
        ;
        TEXT
      )

    if work_data_results.size.zero?
      return Worker.new(id: user_id, name: name)
    end

    work_data_id = work_data_results.first['id']
    started_work_at = work_data_results.first['started_work_at']
    finished_work_at = work_data_results.first['finished_work_at']

    if finished_work_at
      return Worker.new(id: user_id, name: name)
    end

    break_data_results = 
      client.query(
        <<~TEXT
        SELECT * 
        FROM break_data
        WHERE user_id = #{user_id} AND work_data_id = #{work_data_id}
        ORDER BY started_break_at ASC
        ;
        TEXT
      )

    break_data_ids = []
    started_break_at = []
    finished_break_at = []

    break_data_results.each do |result|
      break_data_ids << result['id']
      started_break_at << result['started_break_at']
      if result['finished_break_at']
        finished_break_at << result['finished_break_at']
      end
    end

    return Worker.new(
      id: user_id, 
      name: name, 
      work_data_id: work_data_id,
      started_work_at: started_work_at, 
      finished_work_at: finished_work_at, 
      break_data_ids: break_data_ids, 
      started_break_at: started_break_at, 
      finished_break_at: finished_break_at
    )
  end

  def started_work?
    !!started_work_at
  end

  def finished_work?
    !!finished_work_at 
  end

  def breaking?
    started_break_at.size == finished_break_at.size + 1
  end

  def working?
    return false unless started_work?
    return false if finished_work?
    !breaking?
  end

  def status 
    unless started_work?
      return "出勤前"
    end

    if finished_work?
      return "退勤済"
    end

    if breaking?
      return "休憩中"
    end

    "勤務中"
  end

  def start_work(client = nil)
    return self if started_work?

    started_work_at = Time.now 

    if client
      client.query('USE stamp_app_on_terminal;')
      client.query(
        <<~TEXT
        INSERT INTO work_data(started_work_at, user_id) 
        VALUES (
          '#{started_work_at.to_s.scan(DATETIME_REGEXP).first}', 
          '#{id}'
        )
        TEXT
      )
      results = 
        client.query(
          <<~TEXT
          SELECT *
          FROM work_data
          ORDER BY id DESC
          LIMIT 1
          TEXT
        )
      work_data_id = results.first['id']
      return Worker.new(
        id: id, 
        name: name, 
        work_data_id: work_data_id,
        started_work_at: started_work_at
      )
    end

    Worker.new(id: id, name: name, started_work_at: started_work_at)
  end

  def finish_work(client = nil)
    return self unless started_work?
    return self if finished_work?
    
    now = Time.now 
    finished_work_at = now

    if client 
      client.query('USE stamp_app_on_terminal;')
      client.query(
        <<~TEXT
        UPDATE work_data
        SET finished_work_at = '#{finished_work_at.to_s.scan(DATETIME_REGEXP).first}'
        WHERE id = '#{work_data_id}'
        TEXT
      )
    end

    if breaking?
      finished_break_at = self.finished_break_at + [now]

      if client
        client.query(
          <<~TEXT
          UPDATE break_data
          SET finished_break_at = '#{finished_break_at.last.to_s.scan(DATETIME_REGEXP).first}'
          WHERE id = '#{break_data_ids.last}'
          TEXT
        )
      end

      return Worker.new(
        id: id, 
        name: name, 
        work_data_id: work_data_id,
        started_work_at: started_work_at, 
        finished_work_at: finished_work_at, 
        break_data_ids: break_data_ids, 
        started_break_at: started_break_at, 
        finished_break_at: finished_break_at
      )
    end

    Worker.new(
      id: id, 
      name: name, 
      work_data_id: work_data_id,
      started_work_at: started_work_at, 
      finished_work_at: finished_work_at
    )
  end

  def start_break(client = nil)
    return self unless working?

    started_break_at = self.started_break_at + [Time.now]

    if client 
      client.query('USE stamp_app_on_terminal;')
      client.query(
        <<~TEXT
        INSERT INTO break_data(started_break_at, user_id, work_data_id)
        VALUES (
          '#{started_break_at.last.to_s.scan(DATETIME_REGEXP).first}', 
          '#{id}', 
          '#{work_data_id}'
        )
        TEXT
      )
      break_data_results = 
        client.query(
          <<~TEXT
          SELECT *
          FROM break_data 
          ORDER BY id DESC
          LIMIT 1
          TEXT
        )
      break_data_ids = self.break_data_ids + [break_data_results.first['id']]
      return Worker.new(
        id: id, 
        name: name, 
        work_data_id: work_data_id,
        started_work_at: started_work_at, 
        finished_work_at: finished_work_at, 
        break_data_ids: break_data_ids,
        started_break_at: started_break_at, 
        finished_break_at: finished_break_at
      )
    end

    Worker.new(
      id: id, 
      name: name, 
      started_work_at: started_work_at, 
      finished_work_at: finished_work_at, 
      started_break_at: started_break_at, 
      finished_break_at: finished_break_at
    )
  end

  def finish_break(client = nil)
    return self unless breaking?

    finished_break_at = self.finished_break_at + [Time.now]

    if client 
      client.query(
        <<~TEXT
        UPDATE break_data
        SET finished_break_at = '#{finished_break_at.last.to_s.scan(DATETIME_REGEXP).first}'
        WHERE id = '#{break_data_ids.last}'
        TEXT
      )
      return Worker.new(
        id: id, 
        name: name, 
        work_data_id: work_data_id,
        started_work_at: started_work_at, 
        finished_work_at: finished_work_at, 
        break_data_ids: break_data_ids,
        started_break_at: started_break_at, 
        finished_break_at: finished_break_at
      )
    end

    Worker.new(
      id: id, 
      name: name, 
      started_work_at: started_work_at, 
      finished_work_at: finished_work_at, 
      started_break_at: started_break_at, 
      finished_break_at: finished_break_at
    )
  end

  def working_hours 
    unless started_work?
      return Timer.create_from_sec(0)
    end

    unless finished_work?
      return Timer.create_from_sec(Time.now - started_work_at)
    end

    Timer.create_from_sec(finished_work_at - started_work_at)
  end

  def breaking_hours 
    sum_sec = 0
    (0...started_break_at.size).each do |i|
      if finished_break_at[i]
        sum_sec += finished_break_at[i] - started_break_at[i]
      else 
        sum_sec += Time.now - started_break_at[i]
      end
    end
    Timer.create_from_sec(sum_sec)
  end
end

require_relative './timer.rb'
