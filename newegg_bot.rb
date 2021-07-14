require_relative("twilio_service")
require "http"
require "pry"
require "capybara/sessionkeeper"

class NeweggBot
  attr_reader :browser
  attr_accessor :combo, :name, :url, :item_number

  def initialize(browser, combo, name, url)
    @browser = browser
    @combo = combo
    @name = name
    @url = url
    @item_number = url.rpartition("/p/").last
  end

  def perform
    begin
      browser.visit(url)
      puts name
      check_for_captcha
      return unless add_to_cart_button?
      add_to_cart
      go_to_checkout
      login if login_container?
      next_step
      input_security_code
      next_step
      confirm_card_number
      binding.pry
      place_order
      twilio_confirmation
      return
    rescue Net::ReadTimeout => error
      twilio_timeout
      retry
    rescue EOFError => e
      twilio_end_of_file
      retry
    rescue Twilio::REST::RestError
      # binding.pry
    rescue => exception
      twilio_bot_error
      binding.pry
      return
    end
  end

  private

    def add_to_cart
      browser.visit("https://secure.newegg.com/Shopping/AddtoCart.aspx?Submit=ADD&ItemList=#{item_number}")
      # add_to_cart_button.click
      twilio_added_to_cart
      decline_masks if mask_ad?
      return unless warranty_ad?
      decline_warranty_button.click
    end
  
    def add_to_cart_button?
      if combo
        browser.has_css?("a[title='Add Combo to Cart'].atnPrimary")
      else
        browser.has_css?("div#ProductBuy button.btn-primary")
      end
    end
  
    def add_to_cart_button
      if combo
        browser.find("a[title='Add Combo to Cart'].atnPrimary")
      else
        browser.find("div#ProductBuy button.btn-primary")
      end
    end

    def auto_notify_button?
      browser.has_css?("button[title='Auto Notify ']")
    end

    def captcha_required?
      browser.find("h1", match: :first)&.text == "Human?"
    end

    def credit_card_number
      ENV["CREDIT_CARD_NUMBER"]
    end

    def check_for_captcha
      return unless captcha_required?
      twilio_captcha_notice
      binding.pry
      save_cookies
    end

    def checkout_button
      browser.find("button.btn-primary[type='button']")
    end

    def confirm_card_number
      return unless browser.has_css?("body.modal-open")
      iframe = browser.find("iframe iframe")
      browser.within_frame(iframe) do
        browser.find("input").fill_in with: credit_card_number
        browser.find("button.btn-primary[type='button']").click
      end
    end

    def confirm_card_number?
      browser.within_frame(0) do
        find("div.modal-content div.modal-header h5.modal-title")&.text == "Retype Card Number"
      end
    end

    def decline_masks
      checkbox = browser.find("div.modal-content span.form-checkbox-title")
      checkbox.click
      decline_masks_button.click
    end

    def decline_masks_button
      browser.find("div.modal-footer button[data-dismiss='modal']")
    end

    def decline_warranty_button
      browser.find("div#modal-intermediary button[data-dismiss='modal']")
    end

    def next_step
      next_step_button.click
    end

    def next_step_button
      browser.find("div.checkout-step div.checkout-step-action button.btn-primary")
    end

    def email
      ENV["EMAIL"]
    end
    
    def go_to_cart
      browser.visit("https://secure.newegg.com/shop/cart")
      return unless mask_ad?
      decline_masks
      # go_to_cart_button.click
    end
    
    def go_to_cart_button
      browser.find("div#modal-intermediary button[title='View Cart & Checkout']")
    end

    def go_to_checkout
      decline_masks if mask_ad?
      checkout_button.click
    end

    def input_security_code
      input_box = browser.find("div.retype-security-code input.form-text.mask-cvv-4")
      input_box.fill_in with: "025"
    end

    def last_name
      ENV["LAST_NAME"]
    end

    def login
      browser.fill_in "signEmail", with: email
      sign_in_button.click
      browser.fill_in "password", with: password
      sign_in_button.click
      save_cookies
    end

    def login_container?
      browser.has_css?("div.signin-steps")
    end

    def mask_ad?
      browser.has_css?("div.modal-content")
    end

    def password
      ENV["AMAZON_PASSWORD"]
    end

    def place_order
      browser.scroll_to(place_order_button)
      place_order_button.click
      sleep 0.1 until browser.has_css?("div.message.message-success")
    end

    def place_order_button
      browser.find("div.summary-actions button#btnCreditCard")
    end

    def save_cookies
      browser.save_cookies('newegg.cookies.txt')
    end

    def sign_in_button
      browser.find("button#signInSubmit")
    end

    def sold_out_button?
      browser.has_css?('button.btn.btn-lg.btn-disabled.btn-block.add-to-cart-button')
    end
    
    def twilio_added_to_cart
      TwilioService.new.send("ADDING #{name} TO CART from NEWEGG")
    end

    def twilio_bot_error
      TwilioService.new.send("ERROR: #{name} NEWEGG BOT DOWN")
    end

    def twilio_captcha_notice
      TwilioService.new.send("NEWEGG CAPTCHA REQUIRED for #{name}")
    end

    def twilio_end_of_file
      TwilioService.new.send("ERROR: #{name} NEWEGG BOT EOF ERROR - Retrying")
    end

    def twilio_confirmation
      TwilioService.new.send("#{name} PURCHASED FROM NEWEGG")
    end

    def twilio_timeout
      TwilioService.new.send("#{name} NEWEGG BOT TIMED OUT - Retrying")
    end

    def twilio_waiting
      TwilioService.new.send("#{name} NEWEGG WAITING")
    end

    def warranty_ad?
      browser.has_css?("div#modal-intermediary")
    end
end