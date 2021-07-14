require_relative("newegg_bot")
require_relative("capybara_service")
require "capybara/sessionkeeper"
require "http"
require "parallel"
require "pry"

class NeweggChecker
  attr_accessor :browsers
  attr_reader :products, :thread_count

  def initialize
    @browsers = []
    @products = [
      # { 
      #   combo: false,
      #   name: "AMD 5900x",
      #   url: "https://www.newegg.com/amd-ryzen-9-5900x/p/N82E16819113664"
      # },
      # { 
      #   combo: false,
      #   name: "EVGA 3060ti",
      #   url: "https://www.newegg.com/evga-geforce-rtx-3060-ti-08g-p5-3663-kr/p/N82E16814487535"
      # },
      # { 
      #   combo: false,
      #   name: "GIGABYTE 3060ti",
      #   url: "https://www.newegg.com/gigabyte-geforce-rtx-3060-ti-gv-n306teagle-8gd/p/N82E16814932379"
      # },
      # { 
      #   combo: false,
      #   name: "MSI Ventus 2x oc 3060ti",
      #   url: "https://www.newegg.com/msi-geforce-rtx-3060-ti-rtx-3060-ti-ventus-2x-oc/p/N82E16814137612"
      # },
      # { 
      #   combo: false,
      #   name: "EVGA big 3060ti",
      #   url: "https://www.newegg.com/evga-geforce-rtx-3060-ti-08g-p5-3667-kr/p/N82E16814487537"
      # },
      # { 
      #   combo: false,
      #   name: "EVGA 3060 ti FTW ULTRA Gaming",
      #   url: "https://www.newegg.com/evga-geforce-rtx-3060-ti-08g-p5-3667-kr/p/N82E16814487537"
      # },
      # { 
      #   combo: false,
      #   name: "Gigabyte 3060 ti Eagle OC",
      #   url: "https://www.newegg.com/gigabyte-geforce-rtx-3060-ti-gv-n306teagle-oc-8gd/p/N82E16814932378"
      # },
      # { 
      #   combo: false,
      #   name: "ASUS 3060 ti DUAL",
      #   url: "https://www.newegg.com/asus-geforce-rtx-3060-ti-dual-rtx3060ti-8g/p/N82E16814126480"
      # },
      # { 
      #   combo: false,
      #   name: "GIGABYTE GeForce RTX 3060 Ti Gaming OC",
      #   url: "https://www.newegg.com/gigabyte-geforce-rtx-3060-ti-gv-n306tgaming-oc-8gd/p/N82E16814932377"
      # },
      { 
        combo: false,
        name: "MSI 3080 Ventus 3x",
        url: "https://www.newegg.com/msi-geforce-rtx-3080-rtx-3080-ventus-3x-10g/p/N82E16814137600"
      },
      { 
        combo: false,
        name: "Gigabyte 3080 Eagle",
        url: "https://www.newegg.com/gigabyte-geforce-rtx-3080-gv-n3080eagle-10gd/p/N82E16814932367"
      },
      { 
        combo: false,
        name: "Gigabyte 3080 Eagle OC",
        url: "https://www.newegg.com/gigabyte-geforce-rtx-3080-gv-n3080eagle-oc-10gd/p/N82E16814932330"
      },
      { 
        combo: false,
        name: "EVGA 3080 XC3 Black Gaming",
        url: "https://www.newegg.com/evga-geforce-rtx-3080-10g-p5-3881-kr/p/N82E16814487522"
      },
      { 
        combo: false,
        name: "Gigabyte 3080 Gaming OC",
        url: "https://www.newegg.com/gigabyte-geforce-rtx-3080-gv-n3080gaming-oc-10gd/p/N82E16814932329"
      },
      { 
        combo: false,
        name: "EVGA 3080 XC3 Gaming",
        url: "https://www.newegg.com/evga-geforce-rtx-3080-10g-p5-3883-kr/p/N82E16814487521"
      },
      { 
        combo: false,
        name: "EVGA 3080 XC3 Ultra Gaming",
        url: "https://www.newegg.com/evga-geforce-rtx-3080-10g-p5-3885-kr/p/N82E16814487520"
      },
      { 
        combo: false,
        name: "EVGA 3080 Vision OC",
        url: "https://www.newegg.com/gigabyte-geforce-rtx-3080-gv-n3080vision-oc-10gd/p/N82E16814932337"
      },
      { 
        combo: false,
        name: "EVGA 3080 FTW 3 Gaming",
        url: "https://www.newegg.com/evga-geforce-rtx-3080-10g-p5-3895-kr/p/N82E16814487519"
      },
      { 
        combo: false,
        name: "Gigabyte Aorus 3080",
        url: "https://www.newegg.com/gigabyte-geforce-rtx-3080-gv-n3080aorus-m-10gd/p/N82E16814932336"
      },
    ]

    @thread_count = 1

    url = products.first[:url]
    Capybara.save_path = "tmp"
    thread_count.times do
      browser = CapybaraService.new(1).browser
      browser.visit(url)
      browser.restore_cookies(File.join(Capybara.save_path, 'newegg.cookies.txt'))
      browser.visit(url)
      browsers << browser
    end
  end

  def check
    while true
      begin
        processes = thread_count == 1 ? 0 : thread_count
        Parallel.each(products, in_processes: processes) do |product|
          browser = browsers[Parallel.worker_number]
          combo = product[:combo]
          name = product[:name]
          url = product[:url]
          NeweggBot.new(browser, combo, name, url).perform
        end
      rescue => exception
        binding.pry
        retry
      end
    end
  end
end

NeweggChecker.new.check
