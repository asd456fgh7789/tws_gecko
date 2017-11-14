require 'tws_gecko/crawler'
require 'tws_gecko/file'
require 'tws_gecko/exception'
require 'tws_gecko/log'

class TwsGecko::RealTime
  include TwsGecko::Crawler
  include TwsGecko::File

  # urls of mis.twse.com.tw
  HOST = TwsGecko::Crawler::MIS_HOST.freeze
  HOMEURL = "http://#{HOST}/stock/fibest.jsp?lang=zh_tw".freeze
  STOCKURL = "http://#{HOST}/stock/api/getStockInfo.jsp?".freeze
  PASSQUERY = 'ex_ch=tse_t00.tw|otc_o00.tw|tse_FRMSA.tw&'\
              "json=1&delay=0&_=#{Time.now.to_i * 100}".freeze
  MAX_SYM = 50

  DATADIR = TwsGecko::File::DATADIR.freeze

  attr_reader :data, :raw, :date

  @@cookie ||= nil
  @@update_time ||= Time.at(0)

  def initialize(symbols)
    @symbols ||= Array(symbols)
    @raw ||= []
    @data ||= []
    @date ||= Date.today
    @worker_size ||= (@symbols.size + MAX_SYM - 1) / MAX_SYM
  end

  def recent
    raw_array = req_raw
    return false if raw_array.nil?
    raw_array.each do |json|
      next if json['msgArray'].nil?
      json['msgArray'].each do |i|
        @data << [i['c'], i['t'], i['z'], i['tv'], i['v'], i['a'], i['f'], i['b'], i['g']]
      end
    end
    true
  end

  # making request to json file
  def req_raw
    queue = Queue.new
    @worker_size.times { |i| queue << query(@symbols[(i * MAX_SYM)..(i * MAX_SYM + MAX_SYM - 1)]) }
    thread_max = @worker_size <= 10 ? @worker_size : 10
    worker = (0...thread_max).map do
      Thread.new do
        until queue.empty?
          res = process(queue.pop(true))
          @raw << res
        end
      end
    end
    worker.map(&:join)
    worker.map(&:kill)
    @raw.delete_if {|i| i.is_a? Array || i.nil? }
    @date = Date.parse(@raw[0]['msgArray'][0]['d']) if @raw
    @raw
  rescue ThreadError, 
         TwsGecko::ServerDatabaseError, 
         TwsGecko::ServerNoResponseError => e
    TwsGecko::Log.logging(e)
  end

  def save
    return false if @data.nil?
    folderpath = DATADIR + @date.to_s
    @data.each do |row|
      next if row.empty?
      symbol = row.shift
      filepath = "#{folderpath}/#{symbol}.csv"
      file_check filepath
      line = lastline filepath
      CSV.open(filepath, 'a') { |csv| csv << row } if line[0] != row[0]
    end
    true
  end

  private
    def query(symbols)
      channel = Array(symbols).map { |s| "tse_#{s}.tw" }.join('|')
      "_=#{timestamp}&ex_ch=#{channel}&delay=0&json=1"
    end

    def json(msg)
      json = JSON.parse(msg)
      if json['rtcode'] != '0000' || json['rtmessage'] != 'OK'
        raise TwsGecko::ServerDatabaseError.new(json)
      end
      json
    end

    def process(query)
      begin
        clnt = HTTPClient.new
        update_cookie(clnt) if @@update_time - Time.now < -60
        custom_header = {
          'Cookie' => @@cookie, 
          'X-Requested-With' => 'XMLHttpRequest', 
          'Referer' => HOMEURL
        }
        clnt.get(STOCKURL, PASSQUERY, header(custom_header))
        res = clnt.get_content(STOCKURL, query, header(custom_header))
        json(res)
      rescue Errno::ENETUNREACH
        raise TwsGecko::ServerNoResponseError
      end
    end

    def update_cookie(http)
      @@cookie = http.get(HOMEURL).header['Set-Cookie'][0].split(';')[0]
      @@update_time = Time.now
    end
end
