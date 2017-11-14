class TwsGecko::ServerDatabaseError < StandardError
  attr_reader :raw
  def initialize(raw)
    @raw = raw
    super "No response from database of server"
  end
end

class TwsGecko::ServerNoResponseError < StandardError
  def initialize(raw = nil)
    @raw = raw
    super "#{@raw['stat']}"
  end
end