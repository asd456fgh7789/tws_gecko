require 'tws_gecko/file'

class TwsGecko::CompanyList
  extend TwsGecko::File

  RAWFILE ||= (TwsGecko::File::RAWDIR + 'company_list.html').freeze
  FILENAME ||= (TwsGecko::File::STATDIR + 'company_list.csv').freeze

  URL = 'http://isin.twse.com.tw/isin/C_public.jsp?strMode=2'.freeze

  def self.company(symbol)
    row = list.find {|i| i[0] == symbol.to_s}
    row[1]
  end

  def self.symbols
    list.map { |i| i[0] }
  end

  def self.listed_date(symbol)
    row = list.find {|i| i[0] == symbol.to_s}
    Date.parse(row[3])
  end

  def self.list
    update unless File.exist? FILENAME
    data = []
    CSV.foreach(FILENAME) do |row|
      data << row
    end
    data
  end
  
  def self.update
    raw unless File.exist? RAWFILE
    msg = parse(File.read(RAWFILE))
    writer(msg)
  end

  class << self
    private
    def raw
      res = HTTPClient.get_content(URL).encode(Encoding::UTF_8, Encoding::BIG5)
      file_check RAWFILE
      File.open(RAWFILE, 'a') { |file| file.write res }
      res
    end

    def parse(src)
      html = Nokogiri::HTML(src)
      table = html.css('.h4').xpath('tr')
      list_arr = []
      table[2..-1].each do |row|
        break if row.xpath('td')[0].content == ' 上市認購(售)權證  '
        list_arr << row.xpath('td').map { |col| col.content }
      end
      list_arr.each do |i|
        str = i.shift
        a, b = str.split('　')  # fullwidth space
        i.unshift(a.to_i, b)  # 4128 has mistake on raw file
      end
    end

    def writer(msg)
      file_check FILENAME
      CSV.open(FILENAME, 'w') do |csv|
        msg.each do |item|
          csv << item
        end
      end
    end

  end
end