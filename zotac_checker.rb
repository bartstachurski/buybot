require_relative("zotac_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "pry"

class ZotacChecker
  attr_accessor :browser
  attr_reader :url

  def initialize
    Capybara.save_path = "tmp"
    @browser = CapybaraService.new(0.25).browser
    @url = "https://www.zotacstore.com/us/graphics-cards/geforce-rtx-30-series?limit=36"
    browser.visit(url)
    sleep(10)
    binding.pry
    browser.restore_cookies(File.join(Capybara.save_path, 'zotac.cookies.txt'))
    browser.visit(url)
    if browser.has_css?("form[action='/errors/validateCaptcha']")
      puts "complete the captcha and exit pry to save cookies and continue"
      binding.pry
      browser.save_cookies('zotac.cookies.txt')
    end
  end

  def check
    while true
      begin
        ZotacBot.new(browser, url).perform
      rescue => exception
        binding.pry
        retry
      end
    end
  end
end

ZotacChecker.new.check