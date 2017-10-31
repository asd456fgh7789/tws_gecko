require 'tws_gecko/file'

module TwsGecko::Analysis
  extend TwsGecko::File

  ANLYDIR = (TwsGecko::File::ANLYDIR).freeze
  SMADIR = (ANLYDIR + 'sma/').freeze
  EMADIR = (ANLYDIR + 'ema/').freeze
  KDDIR = (ANLYDIR + 'kd/').freeze
  
  def self.sma_file(symbol, days = 5, h = {})
    queue = []
    array = []
    CSV.foreach(file(symbol)) do |line|
      next if line[6].to_f == 0
      queue.push(line[6].to_f)
      if queue.size > days
        queue.shift
        array << [line[0], (queue.reduce(&:+) / days).round(3)]
      end
    end
    save(symbol, days, array, SMADIR) if h[:save]
    array
  end

  def self.ema_file(symbol, days = 5, h = {})
    alpha = 2.0 / (days + 1)
    array = []
    CSV.foreach(file(symbol)) do |line|
      close = line[6].to_f
      next if close == 0
      array <<
        if array.size == 0
          [line[0], close]
        else
          [line[0], (alpha * close + (1 - alpha) * array.last[1]).round(3)]
        end
    end
    save(symbol, days, array, EMADIR) if h[:save]
    array
  end

  def self.kd_file(symbol, days = 9, h = {})
    queue = []
    array = []
    kd = [50, 50]
    CSV.foreach(file(symbol)) do |line|
      next if line[6].to_f == 0
      queue.push(line[4..6].map(&:to_f))
      if queue.size > days
        queue.shift
        minmax = [queue.min_by { |i| i[1] }[1], queue.max_by { |i| i[0] }[0]]
        rsv = ((queue.last.last - minmax[0]) / (minmax[1] - minmax[0])) * 100
        kd[0] = 0.3333 * rsv + 0.6666 * kd[0]
        kd[1] = 0.3333 * kd[0] + 0.6666 * kd[1]
        array << [line[0], rsv.round(3), kd.map { |i| i.round(3) }].flatten
      end
    end
    save(symbol, days, array, KDDIR) if h[:save]
    array
  end

  def self.rsi_file(symbol, h = {})
    
  end

  class << self
    private
    def file(symbol)
      TwsGecko::File::HISDIR + symbol.to_s + '.csv'
    end

    def save(symbol, days, data, dest_dir)
      file = dest_dir + symbol.to_s + '_' + days.to_s + '.csv'
      file_check(file)
      CSV.open(file, 'w') { |csv| data.each { |i| csv << i } }
    end

    def rsv(symbol)
    end
  end
end