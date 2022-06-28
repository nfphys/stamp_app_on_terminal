class Worker::Timer 
  include Comparable

  attr_reader :hour, :min, :sec 

  def self.create_from_sec(t)
    t = t.floor

    sec = t % 60
    t /= 60

    min = t % 60
    t /= 60

    hour = t 

    Worker::Timer.new(hour, min, sec)
  end

  def initialize(hour, min, sec)
    unless hour.instance_of?(Integer)
      raise TypeError, 'hour must be an integer.'
    end

    if hour.negative?
      raise RangeError, 'hour must be non-negative.'
    end

    unless min.instance_of?(Integer)
      raise TypeError, 'min must be an integer.'
    end

    unless min.between?(0, 59)
      raise RangeError, 'min must be between 0 and 59.'
    end

    unless sec.instance_of?(Integer)
      raise TypeError, 'sec must be an integer.'
    end

    unless sec.between?(0, 59)
      raise RangeError, 'sec must be between 0 and 59.'
    end

    @hour = hour 
    @min = min 
    @sec = sec 
    self.freeze
  end

  def to_sec 
    hour * 3600 + min * 60 + sec
  end

  def <=>(other)
    self.to_sec <=> other.to_sec
  end

  def +(other)
    if other.is_a?(Worker::Timer)
      return Worker::Timer.create_from_sec(self.to_sec + other.to_sec)
    end

    if other.is_a?(Integer)
      return Worker::Timer.create_from_sec(self.to_sec + other)
    end

    raise TypeError, 'other must be an instance of Timer or Integer.'
  end

  def -(other)
    if other.is_a?(Worker::Timer)
      t = self.to_sec - other.to_sec
      return Worker::Timer.create_from_sec(t.negative? ? 0 : t)
    end

    if other.is_a?(Integer)
      t = self.to_sec - other 
      return Worker::Timer.create_from_sec(t.negative? ? 0 : t)
    end

    raise TypeError, 'other must be an instance of Timer or Integer.'
  end

  def *(other)
    if other.is_a?(Integer)
      return Worker::Timer.create_from_sec(self.to_sec * other)
    end

    raise TypeError, 'other must be an instance of Integer.'
  end

  def to_s 
    "#{hour.to_s.rjust(2, '0')}:#{min.to_s.rjust(2, '0')}:#{sec.to_s.rjust(2, '0')}"
  end

  def inspect 
    to_s 
  end
end
