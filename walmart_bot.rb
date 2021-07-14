require_relative("twilio_service")
require "http"
require "pry"
require "capybara/sessionkeeper"

class WalmartBot
  attr_reader :browser, :sku, :url
  attr_accessor :name

  def initialize(browser, name, sku, url)
    @browser = browser
    @name = name
    @sku = sku
    @url = url
  end

  def perform
    begin
      browser.visit(url)
      check_for_captcha
      return unless checkout_button?
      twilio_added_to_cart
      go_to_checkout
      login if login_container?
      place_order
      twilio_confirmation
    rescue Net::ReadTimeout => error
      # twilio_timeout
      retry
    rescue EOFError => e
      twilio_end_of_file
      retry
    rescue => exception
      twilio_bot_error
    end
  end

  private
    def captcha_required?
      browser.has_css?("div#px-captcha")
    end

    def check_for_captcha
      return unless captcha_required?
      twilio_captcha_notice
      binding.pry      
      save_cookies
    end

    def checkout_button?
      browser.has_css?("button[data-automation-id='cart-pos-proceed-to-checkout']")
    end

    def email
      ENV["EMAIL"]
    end
    
    def go_to_checkout
      browser.visit("https://www.walmart.com/checkout/#/payment")
    end
    
    def input_security_code
      browser.fill_in "credit-card-cvv", with: ENV["CREDIT_CARD_CVV"]
    end

    def login
      browser.fill_in "email", with: email
      browser.fill_in "password", with: password
      browser.find("button[data-automation-id='signin-submit-btn']").click
      save_cookies
    end

    def login_container?
      browser.has_css?("div.SignIn-container")
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
      browser.find("div.place-order button[data-automation-id='summary-place-holder']")
    end

    def save_cookies
      browser.save_cookies('walmart.cookies.txt')
    end
   
    def twilio_added_to_cart
      TwilioService.new.send("ADDING #{name} TO CART from WALMART")
    end

    def twilio_bot_error
      TwilioService.new.send("ERROR: #{name} WALMART BOT DOWN")
    end

    def twilio_end_of_file
      TwilioService.new.send("ERROR: #{name} WALMART BOT EOF ERROR - Retrying")
    end

    def twilio_captcha_notice
      TwilioService.new.send("WALMART CAPTCHA REQUIRED for #{name}")
    end

    def twilio_confirmation
      TwilioService.new.send("#{name} PURCHASED FROM WALMART")
    end

    def twilio_timeout
      TwilioService.new.send("#{name} WALMART BOT TIMED OUT - Retrying")
    end

    def twilio_waiting
      TwilioService.new.send("#{name} WALMART WAITING")
    end
end