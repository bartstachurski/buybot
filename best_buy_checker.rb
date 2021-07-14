require_relative("best_buy_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "http"
require "parallel"
require "pry"

class BestBuyChecker
  attr_accessor :browser
  attr_reader :products, :thread_count

  def initialize
    @browser = CapybaraService.new(2).browser
    @products = [
      # {
      #   sku: "6356983",
      #   url: "https://www.bestbuy.com/site/asus-tuf-gaming-x570-plus-wi-fi-socket-am4-usb-c-gen2-amd-motherboard-with-led-lighting/6356983.p?skuId=6356983"
      # },
      # { 
      #   sku: "6426149",
      #   url: "https://www.bestbuy.com/site/sony-playstation-5-console/6426149.p?skuId=6426149" 
      # },
      # { 
      #   sku: "6438942",
      #   url: "https://www.bestbuy.com/site/amd-ryzen-9-5900x-4th-gen-12-core-24-threads-unlocked-desktop-processor-without-cooler/6438942.p?skuId=6438942"
      # },
      # { 
      #   sku: "6438941",
      #   url: "https://www.bestbuy.com/site/amd-ryzen-9-5950x-4th-gen-16-core-32-threads-unlocked-desktop-processor-without-cooler/6438941.p?skuId=6438941"
      # },
      # { 
      #   sku: "6440913",
      #   url: "https://www.bestbuy.com/site/msi-radeon-rx-6800-xt-16g-16gb-gddr6-pci-express-4-0-graphics-card-black-black/6440913.p?skuId=6440913"
      # },
      # { 
      #   sku: "6441226",
      #   url: "https://www.bestbuy.com/site/xfx-amd-radeon-rx-6800xt-16gb-gddr6-pci-express-4-0-gaming-graphics-card-black/6441226.p?skuId=6441226"
      # },
      { 
        sku: "6429440",
        url: "https://www.bestbuy.com/site/nvidia-geforce-rtx-3080-10gb-gddr6x-pci-express-4-0-graphics-card-titanium-and-black/6429440.p?skuId=6429440"
      },
      { 
        sku: "6439402",
        url: "https://www.bestbuy.com/site/nvidia-geforce-rtx-3060-ti-8gb-gddr6-pci-express-4-0-graphics-card-steel-and-black/6439402.p?skuId=6439402"
      },
      { 
        sku: "6429442",
        url: "https://www.bestbuy.com/site/nvidia-geforce-rtx-3070-8gb-gddr6-pci-express-4-0-graphics-card-dark-platinum-and-black/6429442.p?skuId=6429442"
      },
      { 
        sku: "6444445",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3060-ti-xc-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6444445.p?skuId=6444445"
      },

      { 
        sku: "6444449",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3060-ti-ftw3-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6444449.p?skuId=6444449"
      },
      { 
        sku: "6439300",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3070-xc3-black-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6439300.p?skuId=6439300"
      },
      { 
        sku: "6444444",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3060-ti-ftw3-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6444444.p?skuId=6444444"
      },


      # { 
      #   sku: "6446660",
      #   url: "https://www.bestbuy.com/site/pny-geforce-rtx-3060ti8gb-uprising-dual-fan-graphics-card/6446660.p?skuId=6446660"
      # },
      # { 
      #   sku: "6442485",
      #   url: "https://www.bestbuy.com/site/gigabyte-nvidia-geforce-rtx-3060-ti-eagle-oc-8g-gddr6-pci-express-4-0-graphics-card-black/6442485.p?skuId=6442485"
      # },

      # { 
      #   sku: "6442484",
      #   url: "https://www.bestbuy.com/site/gigabyte-nvidia-geforce-rtx-3060-ti-gaming-oc-8g-gddr6-pci-express-4-0-graphics-card-black/6442484.p?skuId=6442484"
      # },

      { 
        sku: "6439301",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3070-ftw3-ultra-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6439301.p?skuId=6439301"
      },
      { 
        sku: "6439299",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3070-xc3-ultra-gaming-8gb-gddr6-pci-express-4-0-graphics-card/6439299.p?skuId=6439299"
      },

      # { 
      #   sku: "6437909",
      #   url: "https://www.bestbuy.com/site/gigabyte-geforce-rtx-3070-gaming-oc-8g-gddr6-pci-express-4-0-graphics-card-black/6437909.p?skuId=6437909"
      # },
      # { 
      #   sku: "6437912",
      #   url: "https://www.bestbuy.com/site/gigabyte-geforce-rtx-3070-eagle-8g-gddr6-pci-express-4-0-graphics-card-black/6437912.p?skuId=6437912"
      # },
      # { 
      #   sku: "6432653",
      #   url: "https://www.bestbuy.com/site/pny-geforce-rtx-3070-8gb-xlr8-gaming-epic-x-rgb-triple-fan-graphics-card/6432653.p?skuId=6432653"
      # },
      # { 
      #   sku: "6432654",
      #   url: "https://www.bestbuy.com/site/pny-geforce-rtx-3070-8gb-dual-fan-graphics-card/6432654.p?skuId=6432654"
      # },
      



      # { 
      #   sku: "6430621",
      #   url: "https://www.bestbuy.com/site/gigabyte-geforce-rtx-3080-10g-gddr6x-pci-express-4-0-graphics-card-black/6430621.p?skuId=6430621"
      # },
      # { 
      #   sku: "6430175",
      #   url: "https://www.bestbuy.com/site/msi-geforce-rtx-3080-ventus-3x-10g-oc-bv-gddr6x-pci-express-4-0-graphic-card-black-silver/6430175.p?skuId=6430175"
      # },
      { 
        sku: "6436194",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3080-xc3-gaming-10gb-gddr6x-pci-express-4-0-graphics-card/6436194.p?skuId=6436194"
      },
      # { 
      #   sku: "6432400",
      #   url: "https://www.bestbuy.com/site/evga-geforce-rtx-3080-xc3-ultra-gaming-10gb-gddr6x-pci-express-4-0-graphics-card/6432400.p?skuId=6432400"
      # },
      # { 
      #   sku: "6436195",
      #   url: "https://www.bestbuy.com/site/evga-geforce-rtx-3080-xc3-ultra-gaming-10gb-gddr6x-pci-express-4-0-graphics-card/6436195.p?skuId=6436195"
      # },
      { 
        sku: "6436191",
        url: "https://www.bestbuy.com/site/evga-geforce-rtx-3080-ftw3-gaming-10gb-gddr6x-pci-express-4-0-graphics-card/6436191.p?skuId=6436191"
      },
      # { 
      #   sku: "6430161",
      #   url: "https://www.bestbuy.com/site/sony-playstation-5-digital-edition-console/6430161.p?skuId=6430161"
      # }
    ]
    url = products.first[:url]
    Capybara.save_path = "tmp"
    browser.visit(url)
    browser.restore_cookies(File.join(Capybara.save_path, 'bb_ps5.cookies.txt'))
    browser.visit(url)
  end

  def check
    while true
      begin
        products.each do |product|
          url = product[:url]
          sku = product[:sku]
          BestBuyBot.new(browser, sku, url).perform
        end
      rescue => exception
        binding.pry
        retry
      end
    end
  end
end

BestBuyChecker.new.check
