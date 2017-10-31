module TwsGecko::File
  STATDIR = 'static/'.freeze
  RAWDIR = 'static/raw/'.freeze
  DATADIR = 'data/'.freeze
  HISDIR = 'data/history/'.freeze
  ANLYDIR = 'data/analysis/'.freeze

  LOGFILE ||= 'tws_gecko.log'.freeze
  def file_check(filepath)
    path_arr = filepath.split('/')
    path = ''
    path_arr[0..-2].each do |dir|
      path += (dir + '/')
      Dir.mkdir path unless File.directory? path
    end
    File.new(filepath, 'w') unless File.exist? filepath
  end

  def lastline(filepath)
    return '' unless File.exist? filepath
    f = File.open(filepath, 'r')
    f.each_line do |line|
      return CSV.parse(line.delete('"')).flatten if f.eof?
    end
    ['']
  end
end