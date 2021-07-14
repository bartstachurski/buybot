require_relative("twilio_service")
require "pry"
require "capybara/sessionkeeper"

class ZotacBot
  attr_reader :asin, :browser, :name, :url

  def initialize(asin, browser, name)
    @asin = asin
    @browser = browser
    @name = name
    @url = "https://www.amazon.com/dp/#{asin}?ref_=ast_sto_dp"
  end

  def perform
    begin
      browser.visit(url)
      check_for_captcha
      return unless buy_now_button?
      buy_now
      twilio_confirmation
    rescue Net::ReadTimeout => error
      # twilio_timeout
      retry
    rescue EOFError => e
      twilio_end_of_file
      retry
    rescue => exception
      # twilio_bot_error
      # binding.pry
    end
  end

  private

    def add_to_cart
      current_cart_count = cart_count
      add_to_cart_button.click
      sleep 0.1 # until cart_count == current_cart_count + 1
    end

    def add_to_cart_button?
      browser.has_css?('input#add-to-cart-button')
    end
    
    def add_to_cart_button
      browser.find('input#add-to-cart-button')
    end

    def buy_now
      buy_now_button.click
      login if login_form?
      confirm_buy_now
      login if login_form?
    end

    def confirm_buy_now
      browser.within_frame('turbo-checkout-iframe') do
        browser.find("input#turbo-checkout-pyo-button").click
      end
    end

    def buy_now_button?
      browser.has_css?("input#buy-now-button")
    end

    def buy_now_button
      browser.find("input#buy-now-button")
    end

    def captcha_required?
      browser.has_css?("form[action='/errors/validateCaptcha']")
    end

    def cart_count
      browser.find("span#nav-cart-count")&.text&.to_i
    end

    def checkout_button
      browser.find("span#sc-buy-box-ptc-button")
    end

    def checkout_button?
      browser.has_css?("span#sc-buy-box-ptc-button")
    end

    def check_for_captcha
      return unless captcha_required?
      twilio_captcha_notice
      binding.pry      
      save_cookies
    end

    def confirm_logged_in
      STDOUT.puts "Please enter 'done' when login / verification / captcha finished"
      input = STDIN.gets.chomp
      if input.downcase != "done"
        abort("exiting")
      end
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
      browser.visit("https://www.amazon.com/gp/cart/view.html?ref_=nav_cart")
    end
    
    def go_to_checkout
      checkout_button.click
    end

    def last_name
      ENV["LAST_NAME"]
    end

    def login
      unless browser.all("input#ap-claim[name='email']").map(&:value).uniq == [email]
        return unless browser.has_css?("input#ap-claim[name='email']")
        browser.fill_in "email", with: email
        browser.find("input#continue").click
      end
      browser.fill_in "password", with: password
      browser.find("input#signInSubmit").click
      confirm_logged_in
      save_cookies
    end

    def login_form?
      browser.has_css?("form[name='signIn']")
    end

    def password
      ENV["AMAZON_PASSWORD"]
    end

    def place_order
      place_order_button.click
    end

    def place_order_button
      browser.find("span#submitOrderButtonId")
    end

    def restore_cookies
      browser.restore_cookies(File.join(Capybara.save_path, 'user1.cookies.txt'))
    end

    def save_cookies
      browser.save_cookies('user1.cookies.txt')
    end

    def sold_out_button?
      browser.has_css?('div#outOfStock')
    end

    def twilio_bot_error
      TwilioService.new.send("ERROR: #{name} AMAZON BOT DOWN")
    end

    def twilio_confirmation
      TwilioService.new.send("#{name} PURCHASED FROM AMAZON")
    end

    def twilio_captcha_notice
      TwilioService.new.send("AMAZON CAPTCHA REQUIRED for #{name}")
    end

    def twilio_end_of_file
      TwilioService.new.send("ERROR: #{name} Amazon BOT EOF ERROR - Retrying")
    end

    def twilio_timeout
      TwilioService.new.send("Amazon #{name} BOT TIMED OUT - Retrying")
    end
end