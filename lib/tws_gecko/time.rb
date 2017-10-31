require 'tws_gecko/date'

module TwsGecko::Time
  # ZONE_OFFSET: UTC+08:00(Asia/Taipei)
  ZONE_OFFSET ||= 28_800
  OPEN ||= '09:00'.freeze
  CLOSE ||= '13:30'.freeze

  # String Constant of After-Hour Fixed-Price time
  AFHP ||= '14:30'.freeze
  def self.now
    Time.now.utc + ZONE_OFFSET
  end

  def self.open_now?
    return false unless TwsGecko::Date.open?(Date.parse(now.to_s))
    time = now.strftime("%H:%M")
    ((OPEN..CLOSE).cover? time) || (AFHP == time)
  end
end