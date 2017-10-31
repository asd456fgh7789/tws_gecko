require 'tws_gecko/crawler'
require 'tws_gecko/file'
require 'tws_gecko/exception'
require 'tws_gecko/log'

# 0	"日期"
# 1	"成交股數"
# 2	"成交金額"
# 3	"開盤價"
# 4	"最高價"
# 5	"最低價"
# 6	"收盤價"
# 7	"漲跌價差"
# 8	"成交筆數"

class TwsGecko::History
  include TwsGecko::Crawler
  include TwsGecko::File

  attr_accessor :date, :symbol
  attr_reader :raw, :data

  HOST ||= TwsGecko::Crawler::TWSE_HOST.freeze
  STOCKURL ||= "http://#{HOST}/exchangeReport/STOCK_DAY?".freeze

  HISDIR = TwsGecko::File::HISDIR.freeze

  def initialize(symbol, date = nil)
    @symbol = symbol
    @date = date
    @raw = []
    @data = []
  end

  def monthly(month = @date.month)
    content = HTTPClient.get_content(STOCKURL, query(month), header)
    @raw = json(content)
    @data << @raw['data'].map { |r| r.map { |i| i.delete(',') } }
  rescue TwsGecko::ServerNoResponseError => e
    TwsGecko::Log.logging(e)
  end

  def daily
    monthly.select do |row|
      row[0] == "%3d/#{@date.strftime("%m/%d")}" % [@date.year - 1911]
    end
  end

  def yearly
    (1..12).each do |i|
      monthly(i)
      sleep 1
    end
    @data = @data.flatten(1)
  end

  def save
    return false if @data.nil?
    filename = HISDIR + "#{@symbol}.csv"
    file_check filename
    line = lastline filename
    if line[0] != @data[-1][0]
      CSV.open(filename, 'a') { |csv| @data.each { |i| csv << i } }
    end
    true
  end

  private
  def query(month = @date.month)
    date = "%d%02d%02d" % [@date.year, month, @date.day]
    "date=#{date}&response=json&stockNo=#{@symbol}"
  end

  def json(msg)
    json = JSON.parse(msg)
    raise TwsGecko::ServerNoResponseError.new(json) if json['stat'] != 'OK'
    json
  end

end