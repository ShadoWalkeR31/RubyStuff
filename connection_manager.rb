class Connector
  attr_reader :thread
  def initialize(&block)
      @thread = nil
      @connector = yield
  end

  def set_dummy_lock(lock)
    @thread = Thread.new { sleep lock }
  end

  def set_lock
    @thread = Thread.current
  end

  def release_lock
    @thread = nil
  end

  def locked?
    if @thread and @thread.alive?
      return true
    else
      return false
    end
  end

  def connector
    if @thread == Thread.current 
      @connector
    end
  end
end

class ConnectionManager
  def initialize(size, dummy_lock = 0.5, &block)
    if not size
      raise ArgumentError, "No pool size given!"
    end
    @pool = Array.new
    @dummy_lock = dummy_lock
    size.times do
      @pool << Connector.new(&block)
    end
  end

  def get_connector
    if idx = @pool.index { |connector| not connector.locked? }
      @pool[idx].set_dummy_lock
      return @pool[idx]
    else
      return false
    end
  end

  def get_connector_via_cycle(pause = 0.1)
    idx = @pool.index { |connector| not connector.locked? }
    while not idx
      sleep pause
      idx = @pool.index { |connector| not connector.locked? }
    end
    @pool[idx].set_dummy_lock(dummy_lock)
    return @pool[idx]
  end

  def get_info
    @pool.each_index do |idx|
      puts "Connection ##{idx}: #{@pool[idx].thread} "
    end
  end

end
