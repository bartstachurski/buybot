require_relative("bh_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "parallel"
require "pry"

class BhChecker
  attr_accessor :browsers
  attr_reader :products, :thread_count

  def initialize
    @browsers = []
    @products = [
      # { 
      #   sku: "396057-USA",
      #   name: "FUJIFILM 120"
      # },
      { 
        sku: "1609755-REG",
        name: "ASUS Dual 3060 ti"
      },
      { 
        sku: "1606949-REG",
        name: "Gigabyte Eagle 3060 ti"
      },
      { 
        sku: "1606946-REG",
        name: "Gigabyte Gaming OC 3060 ti"
      },
      { 
        sku: "1609756-REG",
        name: "ASUS KO 3060 ti"
      },
      { 
        sku: "1606947-REG",
        name: "Gigabyte Gaming OC 3060 ti"
      },
      { 
        sku: "1607025-REG",
        name: "ASUS TUF Gaming 3060 ti"
      },
      { 
        sku: "1606945-REG",
        name: "Gigabyte Aorus Master 3060 ti"
      },
      { 
        sku: "1608111-REG",
        name: "Zotac Gaming Twin Edge OC 3060 ti"
      },
      { 
        sku: "1610844-REG",
        name: "MSI Ventus 2X OC 3060 ti"
      },
      { 
        sku: "1609440-REG",
        name: "PNY XLR8 3060 ti"
      },
      { 
        sku: "1602755-REG",
        name: "ASUS Dual GeForce RTX 3070"
      },
    ]
    @thread_count = 1

    url = "https://www.bhphotovideo.com/c/product/#{products.first[:sku]}"
    # url = "https://www.bhphotovideo.com/find/cart.jsp"
    Capybara.save_path = "tmp"
    thread_count.times do
      browser = CapybaraService.new(3).browser
      browser.visit(url)
      browser.restore_cookies(File.join(Capybara.save_path, 'bh.cookies.txt'))
      browser.visit(url)
      if browser.has_css?("div#px-captcha")
        puts "complete the captcha and exit pry to save cookies and continue"
        binding.pry
        browser.save_cookies('bh.cookies.txt')
      end
      browsers << browser
    end
  end

  def check
    while true
      begin
        processes = thread_count == 1 ? 0 : thread_count
        Parallel.each(products, in_processes: processes) do |product|
          sku = product[:sku]
          browser = browsers[Parallel.worker_number]
          name = product[:name]
          BhBot.new(sku, browser, name).perform
        end
      rescue => exception
        binding.pry
        retry
      end
    end
  end
end

BhChecker.new.check