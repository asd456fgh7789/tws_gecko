require 'tws_gecko/crawler'
require 'tws_gecko/file'
require 'tws_gecko/log'

class TwsGecko::MiIndex
  include TwsGecko::Crawler
  include TwsGecko::File

  HOST ||= TwsGecko::Crawler::TWSE_HOST.freeze
  MIURL ||= "http://#{HOST}/exchangeReport/MI_INDEX?".freeze

  DATADIR ||= TwsGecko::File::DATADIR.freeze
  HISDIR ||= TwsGecko::File::HISDIR.freeze
  attr_reader :data, :raw, :date

  def initialize(date)
    @date = date
    @raw = []
    @data = []
    @filepath = DATADIR + @date.to_s + '/mi_index.csv'
  end

  def daily
    raw_data if @raw.empty?
    @data = @raw['data5'].map { |r| r.map { |i| i.delete(',') } }
  end

  def raw_data
    content = HTTPClient.get_content(MIURL, query, header)
    @raw = json(content)
  rescue StandardError => e
    TwsGecko::Log.logging(e)
  end

  def save
    return false if @data.empty?
    file_check(@filepath)
    @data.each do |row|
      CSV.open(@filepath, 'a') { |csv| csv << row }
    end
    true
  end

  def each_save(h = {})
    data_ary = @data
    return false if data_ary.empty?
    data_ary.each do |row|
      next if h[:listed] && (row[0].size > 4 || row[0][0] == '0')
      row = row_to_history(row)
      filename = "#{HISDIR}/#{row[0]}.csv"
      file_check filename
      CSV.open(filename, 'a') { |csv| csv << row[1] }
    end
    true
  end

  def data
    if File.exist? @filepath
      CSV.read(@filepath)
    else
      daily
    end
  end

  private
  def query
    date = @date.strftime("%Y%m%d")
    "date=#{date}&response=json&type=ALL"
  end

  def json(msg)
    json = JSON.parse(msg)
    raise "stat: #{json['stat']}" if json['stat'] != 'OK'
    json
  end

  # given a row to Array [[symbol], [data]]
  def row_to_history(ary)
    [ ary[0], 
      ["%03d/%s" % [@date.year - 1911, @date.strftime("%m/%d")], 
        ary[2],
        ary[4..8],
        ary[10],
        ary[3]
      ].flatten
    ]
  end
end