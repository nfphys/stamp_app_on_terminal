# 時間を hh:mm:ss の形式で管理する。
class Worker::Timer 
  include Comparable

  # 時を0以上の任意の整数で指定する。
  attr_reader :hour 

  # 分を0から59の整数で指定する。
  attr_reader :min 

  # 秒を0から59の整数で指定する。
  attr_reader :sec

  # 秒単位で表された時間からインスタンスを作成
  # 
  # Example: 
  #   >> Worker::Timer.create_from_sec(94)
  #   => 00:01:34
  # 
  # Arguments: 
  #   t: (Int)
  #
  def self.create_from_sec(t)
    t = t.floor

    sec = t % 60
    t /= 60

    min = t % 60
    t /= 60

    hour = t 

    Worker::Timer.new(hour, min, sec)
  end

  # Worker::Timerクラスのオブジェクトを作成
  #
  # Example:
  #   >> Worker.new(0, 1, 34)
  #   => 00:01:34
  # 
  # Arguments: 
  #   hour: (Int)
  #   min: (Int)
  #   sec: (Int)
  #
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

  # 秒単位で表された時間を整数値で返す
  # 
  # Example: 
  #   >> Worker::Timer.new(0, 1, 34).to_sec 
  #   => 94
  #
  def to_sec 
    hour * 3600 + min * 60 + sec
  end

  # selfとotherの時間を比較する。selfの方が大きい場合は1を、等しい場合は0を、
  # 小さい場合は-1を返す。
  #
  # Example:
  #   >> Worker::Timer.new(2, 40, 30) <=> Worker::Timer.new(1, 50, 38)
  #   => 1
  #
  #   >> Worker::Timer.new(1, 40, 30) <=> Worker::Timer.new(1, 50, 38)
  #   => -1
  #
  def <=>(other) 
    self.to_sec <=> other.to_sec
  end

  def +(other) # :nodoc:
    if other.is_a?(Worker::Timer)
      return Worker::Timer.create_from_sec(self.to_sec + other.to_sec)
    end

    if other.is_a?(Integer)
      return Worker::Timer.create_from_sec(self.to_sec + other)
    end

    raise TypeError, 'other must be an instance of Timer or Integer.'
  end

  def -(other) # :nodoc:
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

  def *(other) # :nodoc:
    if other.is_a?(Integer)
      return Worker::Timer.create_from_sec(self.to_sec * other)
    end

    raise TypeError, 'other must be an instance of Integer.'
  end

  # 時間を文字列に変換した結果を返す。
  #
  # Example: 
  #   >> Worker.new(2, 24, 5).to_s 
  #   => 02:24:05
  #
  def to_s 
    "#{hour.to_s.rjust(2, '0')}:#{min.to_s.rjust(2, '0')}:#{sec.to_s.rjust(2, '0')}"
  end

  # 時間を文字列に変換した結果を返す。
  #
  # Example: 
  #   >> Worker.new(2, 24, 5).to_s 
  #   => 02:24:05
  #
  def inspect 
    to_s 
  end
end
