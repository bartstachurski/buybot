require_relative("amazon_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "parallel"
require "pry"

class AmazonChecker
  attr_accessor :browsers
  attr_reader :products, :thread_count

  def initialize
    @browsers = []
    @products = [
      
      # { 
      #   asin: "B08NW5HNYW",
      #   name: "PNY 3060 ti"
      # },
      # { 
      #   asin: "B08P3V572B",
      #   name: "Zotac 3060 ti Twin Edge OC"
      # },
      { 
        asin: "B083Z5P6TX",
        name: "ASUS 3060 ti TUF"
      },
      # { 
      #   asin: "B08NYPLXPJ",
      #   name: "Gigabyte 3060 ti gaming oc" 
      # },
      { 
        asin: "B08P2HBBLX",
        name: "ASUS 3060 ti dual" 
      },
      # { 
      #   asin: "B08HR7SV3M",
      #   name: "MSI 3080 Gaming X Trio"
      # },
      # { 
      #   asin: "B08HR5SXPS",
      #   name: "MSI 3080 Ventus 3x OC"
      # },
      # { 
      #   asin: "B08FC5L3RG",
      #   name: "PS5"
      # },
      { 
        asin: "B08J6F174Z",
        name: "ASUS ROG Strix 3080"
      },
      { 
        asin: "B08HHDP9DW",
        name: "ASUS TUF 3080 Gaming"
      },
      { 
        asin: "B08HH5WF97",
        name: "ASUS TUF 3080 Gaming OC"
      },
      # { 
      #   asin: "B08KGZVKXM",
      #   name: "Gigabyte VISION OC 3080"
      # },
      # { 
      #   asin: "B08P2D3JSG",
      #   name: "MSI 3060 ti Gaming X Trio"
      # },
      { 
        asin: "B08P2D1JZZ",
        name: "ASUS 3060 ti KO"
      },
      # { 
      #   asin: "B08P2H5LW2",
      #   name: "evga ftw3 3060 ti"
      # },
      # { 
      #   asin: "B08HR3Y5GQ",
      #   name: "EVGA 3080 FTW3 Ultra"
      # },
      # { 
      #   asin: "B08HR55YB5",
      #   name: "EVGA 3080 Ultra"
      # },
      # { 
      #   asin: "B08KY266MG",
      #   name: "Gigabyte 3070 Gaming OC"
      # },
      { 
        asin: "B08L8JNTXQ",
        name: "ASUS ROG STRIX 3070"
      },
      { 
        asin: "B08L8LG4M3",
        name: "ASUS Dual 3070 OC Edition"
      },
      { 
        asin: "B08MT6B58K",
        name: "ASUS Dual 3070 KO"
      },
      # { 
      #   asin: "B08L8L71SM",
      #   name: "EVGA 3070 XC3 Ultra Gaming"
      # },
      # { 
      #   asin: "B08LF1CWT2",
      #   name: "ZOTAC 3070 OC"
      # },
      # { 
      #   asin: "B08M13DXSZ",
      #   name: "Gigabyte 3070 Vision OC"
      # },
      { 
        asin: "B08L8KC1J7",
        name: "ASUS 3070 TUF OC"
      },
    ]
    @thread_count = 1

    url = "https://www.amazon.com/dp/#{products.first[:asin]}?ref_=ast_sto_dp"
    Capybara.save_path = "tmp"
    thread_count.times do
      browser = CapybaraService.new(0.25).browser
      browser.visit(url)
      browser.restore_cookies(File.join(Capybara.save_path, 'user1.cookies.txt'))
      browser.visit(url)
      if browser.has_css?("form[action='/errors/validateCaptcha']")
        puts "complete the captcha and exit pry to save cookies and continue"
        binding.pry
        browser.save_cookies('user1.cookies.txt')
      end
      browsers << browser
    end
  end

  def check
    while true
      begin
        processes = thread_count == 1 ? 0 : thread_count
        Parallel.each(products, in_processes: processes) do |product|
          asin = product[:asin]
          browser = browsers[Parallel.worker_number]
          name = product[:name]
          AmazonBot.new(asin, browser, name).perform
        end
      rescue => exception
        # binding.pry
        retry
      end
    end
  end
end

AmazonChecker.new.check