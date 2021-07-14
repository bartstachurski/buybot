require_relative("twilio_service")
require "pry"
require "capybara/sessionkeeper"


class BhBot
  attr_reader :sku, :browser, :name, :url

  def initialize(sku, browser, name)
    @sku = sku
    @browser = browser
    @name = name
    @url = "https://www.bhphotovideo.com/c/product/#{sku}"
    # @url = "https://www.bhphotovideo.com/find/cart.jsp"
  end

  def perform
    browser.visit(url)
    captcha_check
    return unless add_to_cart_button?
    twilio_can_add
    # binding.pry
    add_to_cart
    go_to_cart
    login if login_container?
    go_to_checkout
    login if login_container?
    # input_pickup_details
    # check amount?
    place_order
    twilio_confirmation
    sleep(10)
  end

  private
    
    def add_to_cart_button?
      browser.has_css?("button[data-selenium='addToCartButton']")
    end
    
    def add_to_cart
      add_to_cart_button.click
    end
    
    def add_to_cart_button
      browser.find(:css, "button[data-selenium='addToCartButton']")
    end

    def captcha_required?
      browser.has_css?("div#px-captcha")
    end

    def captcha_check
      return unless captcha_required?
      twilio_captcha_required
      puts "complete the captcha and exit pry to save cookies and continue"
      binding.pry
      browser.save_cookies('bh.cookies.txt')
    end

    def checkout_button
      browser.find(:css, "button[data-selenium='itemLayerViewCartBtn']")
    end

    def continue_to_payment
      # maybe check that the total is right and the pickup location is right before proceeding?
      continue_to_payment_button.click
    end

    def continue_to_payment_button
      browser.find(:css, "div.button--continue")
    end

    def email
      ENV["EMAIL"]
    end
    
    def go_to_cart
      browser.visit("https://www.bhphotovideo.com/find/cart.jsp")
      # go_to_cart_button.click
    end
    
    def go_to_cart_button
      browser.find(:css, "a[data-selenium='itemLayerViewCartBtn']")
    end

    def go_to_checkout
      if Parallel.worker_number.zero?
        browser.visit("https://www.bhphotovideo.com/find/checkout.jsp")
      else
        checkout_button.click
      end
    end

    def last_name
      ENV["LAST_NAME"]
    end

    def login
      browser.find(:css, "a.logInRel.blue_btn_cart.openInOnePopupLayer").click
      browser.fill_in "user-input", with: email
      browser.fill_in "password-input", with: password
      browser.find(:css, "div.lf-section.lf-login-section input[type='submit'].lf-primaryBtn").click
      save_cookies
    end

    def login_container?
      browser.has_css?("div.cia-signin")
    end

    def password
      ENV["BH_PASSWORD"]
    end

    def place_order
      browser.scroll_to(place_order_button)
      browser.check("text-updates")
      # place_order_button.click
    end

    def place_order_button
      browser.find(:css, "button.button__fast-track")
    end

    def save_cookies
      browser.save_cookies('bh.cookies.txt')
    end

    def twilio_confirmation
      TwilioService.new.send("#{name} PURCHASED FROM B&H")
    end

    def twilio_can_add
      TwilioService.new.send("#{name} AVAILABLE TO ADD TO CART ON B&H")
    end

    def twilio_captcha_required
      TwilioService.new.send("Captcha requried for #{name} from B&H")
    end
end