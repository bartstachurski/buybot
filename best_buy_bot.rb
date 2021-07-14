require_relative("twilio_service")
require "http"
require "pry"
require "capybara/sessionkeeper"

class BestBuyBot
  attr_reader :browser, :sku, :url
  attr_accessor :name, :direct_url

  def initialize(browser, sku, url)
    @browser = browser
    @name = url.gsub("https://www.bestbuy.com/site/", "").split("/#{sku}").first
    @sku = sku
    @url = url
    @direct_url = "https://api.bestbuy.com/click/-/#{sku}/cart"
  end

  def perform
    begin
      # browser.visit(direct_url)
      browser.visit(url)
      return unless add_to_cart_button?
      add_to_cart
      go_to_cart
      return unless checkout_button?
      go_to_checkout
      # go_to_checkout
      login if login_container?
      # check amount?
      place_order
      twilio_confirmation
    rescue Net::ReadTimeout => error
      # twilio_timeout
      # binding.pry
      retry
    rescue EOFError => e
      twilio_end_of_file
      retry
    rescue => exception
      twilio_bot_error
      binding.pry
    end
  end

  private

  
    def add_to_cart_button?
      browser.has_css?("button.btn.btn-primary.add-to-cart-button:not(.btn-disabled)[data-sku-id='#{sku}']")
    end
  
    def add_to_cart
      add_to_cart_button.click
      twilio_added_to_cart
      binding.pry
      return unless wait_overlay?
      twilio_waiting
      while wait_overlay?
        sleep 0.1
      end
      add_to_cart_button.click
    end
    
    def add_to_cart_button
      # https://api.bestbuy.com/click/-/6430161/cart
      browser.find("button.btn.btn-primary.add-to-cart-button:not(.btn-disabled)[data-sku-id='#{sku}']")
    end

    def checkout_button
      browser.find("div.checkout-buttons__checkout")
    end

    def checkout_button?
      browser.has_css?("div.checkout-buttons__checkout")
    end

    def continue_to_payment
      # maybe check that the total is right and the pickup location is right before proceeding?
      continue_to_payment_button.click
    end

    def continue_to_payment_button
      browser.find("div.button--continue")
    end

    def email
      ENV["EMAIL"]
    end
    
    def go_to_cart
      browser.visit("https://www.bestbuy.com/cart")
      # "https://www.bestbuy.com/checkout/r/fast-track"
      # go_to_cart_button.click
    end
    
    def go_to_cart_button
      browser.find("div.go-to-cart-button")
    end

    def go_to_checkout
      # browser.visit("https://www.bestbuy.com/checkout/r/fast-track")
      checkout_button.click
    end

    def input_security_code
      browser.fill_in "credit-card-cvv", with: ENV["CREDIT_CARD_CVV"]
    end

    def last_name
      ENV["LAST_NAME"]
    end

    def login
      return unless browser.has_css?("label[for='fld-e']")
      browser.fill_in "fld-e", with: email
      browser.fill_in "fld-p1", with: password
      browser.find("button.cia-form__controls__submit").click
      save_cookies
    end

    def login_container?
      browser.has_css?("div.cia-signin")
    end

    def password
      ENV["BEST_BUY_PASSWORD"]
    end

    def place_order
      browser.scroll_to(place_order_button)
      place_order_button.click
      sleep 0.1 until browser.has_css?("section.thank-you-enhancement")
    end

    def place_order_button
      browser.find("button.button__fast-track")
    end

    def save_cookies
      browser.save_cookies('bb_ps5.cookies.txt')
    end

    def sold_out_button?
      browser.has_css?('button.btn.btn-lg.btn-disabled.btn-block.add-to-cart-button')
    end
    
    def twilio_added_to_cart
      TwilioService.new.send("ADDING #{name} TO CART from BEST BUY")
    end

    def twilio_bot_error
      TwilioService.new.send("ERROR: #{name} BEST BUY BOT DOWN")
    end

    def twilio_end_of_file
      TwilioService.new.send("ERROR: #{name} BEST BUY BOT EOF ERROR - Retrying")
    end

    def twilio_confirmation
      TwilioService.new.send("#{name} PURCHASED FROM BEST BUY")
    end

    def twilio_timeout
      TwilioService.new.send("#{name} BEST BUY BOT TIMED OUT - Retrying")
    end

    def twilio_waiting
      TwilioService.new.send("#{name} BEST BUY WAITING")
    end

    def wait_for_stock
      until add_to_cart_button?
        browser.refresh
        sleep(rand(5..15))
      end
    end

    def wait_overlay?
      browser.has_css?("div#wait-overlay-#{sku}")
    end
end