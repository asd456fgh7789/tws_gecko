require 'faker'

module TwsGecko::Crawler
  TWSE_HOST = 'www.twse.com.tw'.freeze
  MIS_HOST = 'mis.twse.com.tw'.freeze

  USERAGENT = Faker::Internet.user_agent.freeze

    def timestamp
      Time.now.to_i * 1000
    end

    def header(*args)
      h = { 'Host' => self.class::HOST,
            'User-Agent' => USERAGENT,
            'Accept' => 'application/json, text/javascript, */*; q=0.01',
            'Accept-Language' => 'zh-TW,zh;q=0.8,en-US;q=0.5,en;q=0.3' }
      args.each do |index|
        index.each_pair { |k, v| h[k] = v } if index.respond_to? :each_pair
      end
      h
    end
end
