namespace :geoip do

  desc 'Download GeoLiteCity database from MaxMind'
  task :download do

    require 'csv'
    require 'zip/zip'

    download_dir = "#{Rails.root}/tmp"
    extract_to_dir = "#{Rails.root}/tmp"
    city_ip_file="#{download_dir}/GeoLiteCity.zip"

    url = URI.parse("http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity_20110705.zip")
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) { |http|
      http.request(req)
    }
    res


    requested_file_name=city_ip_file
    open("#{requested_file_name}", "wb") { |file|
      file.write(res.body)
    }

    Zip::ZipFile.foreach(requested_file_name) { |zipfile|
      name = "#{extract_to_dir}/#{zipfile.to_s}"
      dir = File.dirname(name)
      unless File.exist?(dir)
        Dir.mkdir(dir)
      end
      zipfile.extract(name)
      puts "extracted #{name}"
    }

    @blocks_file = Dir["#{extract_to_dir}/**/GeoLiteCity-Blocks.csv"].last
    @location_file = Dir["#{extract_to_dir}/**/GeoLiteCity-Location.csv"].last

    CSV.foreach(@location_file) do |row|
      Geoip::Location.create(
          :id=>row[0],
          :country=>row[1],
          :region=>row[2],
          :city=>row[3],
          :postal_code=>row[4],
          :latitude=>row[5],
          :longitude=>row[6],
          :metro_code=>row[7],
          :area_code=>row[8]
      )
    end


  end

  desc 'Update database'
  task :updatedb do
    puts 'Update database stub'
  end
end
