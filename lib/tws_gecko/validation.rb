require 'tws_gecko/file'
require 'tws_gecko/listed'

module TwsGecko::Validation
  extend TwsGecko::File
  HISDIR = TwsGecko::File::HISDIR

  class << self
    def history(symbol)
      return false unless d0 = TwsGecko::CompanyList.listed_date(symbol)
      filepath = HISDIR + symbol.to_s + '.csv'
      file_check filepath
      arr = CSV.read(filepath)
      d0 = d0 < Date.new(1992, 1, 4) ? Date.new(1992, 1, 4) : d0
      arr.uniq! {|i| i.first}
      return nil if arr.empty?
      d1 = arr.first.first.split('/').map(&:to_i)
      d1 = Date.new(d1[0] + 1911, d1[1], d1[2])
      data_arr = []
      if(d1 > d0)
        date_arr = (d0...d1).map {|d| Date.new(d.year, d.month, 1) }.uniq
        
        date_arr.each do |d|
          c = TwsGecko::History.new(symbol, d)
          next if c.monthly.nil?
          data_arr << c.data.flatten(1)
          sleep rand * 10 
        end
      end
      data_arr.flatten(1).reverse_each {|d| arr.unshift d }
      CSV.open(filepath, 'w') do |csv|
        arr.each {|i| csv << i}
      end
    end
  end
end