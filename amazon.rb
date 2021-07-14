require_relative("twilio_service")
require "kimurai"
require "pry"
require "capybara/sessionkeeper"


class SimpleSpider < Kimurai::Base
  @name = "simple_spider"
  @engine = :selenium_chrome
  # @start_urls = ["https://www.amazon.com/gp/sign-in.html"]
  @start_urls = ["https://www.amazon.com/PlayStation-5-Console/dp/B08FC5L3RG?ref_=ast_sto_dp"]
  @config = {}

  def parse(response, url:, data: {})
    browser.config.default_max_wait_time = 200
    browser.config.default_selector = :css
    begin
      restore_cookies
      browser.visit(ps5_url)
      wait_for_stock
      check_for_captcha
      add_to_cart
      go_to_cart
      go_to_checkout
      login if login_form?
      place_order
      twilio_confirmation
    rescue Net::ReadTimeout => error
      twilio_timeout
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

    def add_to_cart
      add_to_cart_button.click
      current_cart_count = cart_count
      sleep 0.1 until cart_count == current_cart_count + 1
    end

    def add_to_cart_button?
      browser.has_css?('input#add-to-cart-button')
    end
    
    def add_to_cart_button
      browser.find('input#add-to-cart-button')
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

    def check_for_captcha
      return unless captcha_required?
      twilio_captcha_notice
      confirm_logged_in
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

    def ps5_url
      "https://www.amazon.com/PlayStation-5-Console/dp/B08FC5L3RG?ref_=ast_sto_dp"
    end

    def ps5_controller_url
      "https://www.amazon.com/Xbox-Wireless-Controller-Shock-Blue-one/dp/B08DFB488B/ref=sr_1_7?dchild=1&keywords=xbox&qid=1605709257&sr=8-7"
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
      TwilioService.new.send("ERROR: PS5 AMAZON BOT DOWN")
    end

    def twilio_confirmation
      TwilioService.new.send("PS5 PURCHASED FROM AMAZON")
    end

    def twilio_captcha_notice
      TwilioService.new.send("AMAZON CAPTCHA REQUIRED")
    end

    def twilio_end_of_file
      TwilioService.new.send("ERROR: PS5 BEST BUY BOT EOF ERROR - Retrying")
    end

    def twilio_timeout
      TwilioService.new.send("Amazon PS5 BOT TIMED OUT - Retrying")
    end

    def wait_for_stock
      until add_to_cart_button?
        browser.refresh
        sleep(rand(5..15))
      end
  
    end
end

SimpleSpider.crawl!