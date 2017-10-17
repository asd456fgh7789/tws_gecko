require 'tws_gecko/file'
require 'tws_gecko/time'

module TwsGecko::Log
  def self.logging(exception, *var)
    puts exception, var
    File.open(TwsGecko::File::LOGFILE, 'a') do |file|
      file.puts TwsGecko::Time.now.strftime('[%F %T]')
      file.print "\t", exception.message, "\n"
      backtrace = exception.backtrace.map { |level| "\t" + level }
      file.puts backtrace
      var.each { |i |file.print "\t", i, "\n" }
    end
  end
end