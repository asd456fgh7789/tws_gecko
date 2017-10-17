require 'tws_gecko/file'
require 'date'

module TwsGecko::TradeDate
  extend TwsGecko::File

  def self.open?(date)
    @year = date.year if date.respond_to? :year
    convert
    if open_listed?(date)
      true
    elsif close_listed?(date)
      false
    else
      date.wday % 6 != 0
    end
  end

  class << self
    private
    STATDIR = TwsGecko::File::STATDIR
    RAWDIR = TwsGecko::File::RAWDIR

    def close_listed?(date)
      File.read(close_file).include? date.to_s
    end
  
    def open_listed?(date)
      File.read(open_file).include? date.to_s
    end

    def close_file
      "#{STATDIR}close/#{@year}.csv"
    end

    def open_file
      "#{STATDIR}open/#{@year}.csv"
    end

    def csv_file
      "#{RAWDIR}trade_#{@year}.csv"
    end

    def raw
      url = 'http://www.twse.com.tw/holidaySchedule/holidaySchedule.csv?'\
            "queryYear=#{@year - 1911}"
      res = HTTPClient.get_content(url)
      res = res.force_encoding(Encoding::BIG5).encode(Encoding::UTF_8)
      file_check csv_file
      File.open(csv_file, 'w') { |file| file.print res }
    end

    def convert
      return true if ((File.exist? close_file) && (File.exist? open_file))
      raw unless File.exist? csv_file
      closedates = []
      opendates = []
      CSV.foreach(csv_file) do |row|
         next if row[0] == '農曆春節後開始交易日' || row.length < 4
         if row[0] == '農曆春節前最後交易日'
           scan_date(row[3], closedates)
         else
           scan_date(row[1], closedates)    
           scan_open(row[3], opendates)
         end
      end
      writer(close:closedates, open:opendates)
    end

    def scan_date(str, arr)
      result = str.scan(/\d+/)
      unless result.empty?
        (result.length / 2).times do |i|
          arr << Date.new(@year, result[i * 2].to_i, result[i * 2 + 1].to_i)
        end
      end
    end

    def scan_open(str, arr)
      result = str.scan(/\d+月\d+日.....補行/)
      scan_date(result[0], arr) unless result.empty?
    end

    def writer(args)
      args.each do |key, value|
        folderpath = STATDIR + key.to_s
        Dir.mkdir folderpath unless File.exist? folderpath
        filepath = "#{folderpath}/#{@year}.csv"
        CSV.open(filepath, 'w') do |csv|
          value.each do |item|
            csv << [item.to_s]
          end
        end
      end
    end

  end
end