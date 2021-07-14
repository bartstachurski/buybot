require "capybara"
require "selenium-webdriver"

class CapybaraService
  def initialize(default_max_wait_time = 2)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument("--disable-blink-features")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.binary='/usr/bin/google-chrome-stable'
    # "--disable-blink-features=AutomationControlled" hides the "navigator.webdriver" flag.
    
    Capybara.configure do |config|
      config.default_max_wait_time = default_max_wait_time
      config.default_selector = :css
    end

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
  end

  def browser
    Capybara::Session.new(:chrome)
  end
end
