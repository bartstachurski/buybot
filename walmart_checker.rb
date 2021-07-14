require_relative("walmart_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "http"
require "parallel"
require "pry"

class WalmartChecker
  attr_accessor :browser
  attr_reader :products, :thread_count

  def initialize
    @browser = CapybaraService.new.browser
    @products = [
      { 
        sku: "647899167",
        name: "Ryzen 5900x"
      },
      { 
        sku: "182785024",
        name: "Ryzen 5600x"
      },
      { 
        sku: "159710953",
        name: "Ryzen 5950x"
      },
      # { 
      #   sku: "493824815",
      #   name: "PS5 Digital"
      # }
    ]
    url = "https://www.walmart.com/account/wmpurchasehistory"
    Capybara.save_path = "tmp"
    browser.visit(url)
    browser.restore_cookies(File.join(Capybara.save_path, 'walmart.cookies.txt'))
    browser.visit(url)
  end

  def check
    while true
      begin
        products.each do |product|
          name = product[:name]
          sku = product[:sku]
          url = "https://affil.walmart.com/cart/buynow?items=#{sku}"
          WalmartBot.new(browser, name, sku, url).perform
        end
      rescue => exception
        binding.pry
        retry
      end
    end
  end
end

WalmartChecker.new.check
