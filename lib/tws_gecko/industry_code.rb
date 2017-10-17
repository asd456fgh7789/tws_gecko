require 'tws_gecko/crawler'
require 'tws_gecko/file'

class TwsGecko::IndustryCode
  extend TwsGecko::File

  FILENAME ||= (TwsGecko::File::STATDIR + 'industry_code.csv').freeze
  URL = 'http://isin.twse.com.tw/isin/class_i.jsp?kind=1'

  def self.industry(code)
    generate unless File.exist? FILENAME
    CSV.foreach(FILENAME) do |row|
      return row[1] if row[0] == "%02d" % code
    end
  end

  class << self
    private
    def generate
      writer(raw)
    end

    def raw
      res = HTTPClient.get_content(URL)
      html = Nokogiri::HTML(res.encode(Encoding::UTF_8, Encoding::BIG5))
      arr = []
      html.xpath('//select[@name="industry_code"]/option').each do |element|
        next if element.content.empty?
        arr << [element.content[0..1], element.content[3..-1]]
      end
      arr
    end

    def writer(msg)
      file_check FILENAME
      CSV.open(FILENAME, 'w') { |csv| msg.each { |item| csv << item } }
    end

  end
end