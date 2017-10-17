require 'tws_gecko/crawler'
require 'tws_gecko/file'
require 'tws_gecko/exception'
require 'tws_gecko/log'

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

  def monthly
    content = HTTPClient.get_content(STOCKURL, query, header)
    @raw = json(content)
    @data = @raw['data'].map { |r| r.map { |i| i.delete(',') } }
  rescue TwsGecko::ServerNoResponseError => e
    TwsGecko::Log.logging(e)
  end

  def daily
    monthly.select do |row|
      row[0] == "%3d/#{@date.strftime("%m/%d")}" % [@date.year - 1911]
    end
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
  def query
    date = @date.strftime("%Y%m%d")
    "date=#{date}&response=json&_=#{timestamp}&stockNo=#{@symbol}"
  end

  def json(msg)
    json = JSON.parse(msg)
    raise TwsGecko::ServerNoResponseError.new(json) if json['stat'] != 'OK'
    json
  end

end