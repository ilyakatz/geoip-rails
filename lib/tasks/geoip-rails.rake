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
      if File.exists?(name)
        puts "#{name} already exists ... taking backup"
        File.rename(name, "#{name}.bkp")
      end
      dir = File.dirname(name)
      unless File.exist?(dir)
        Dir.mkdir(dir)
      end
      zipfile.extract(name)
      puts "extracted #{name}"
    }

    @blocks_file = Dir["#{extract_to_dir}/**/GeoLiteCity-Blocks.csv"].last
    @location_file = Dir["#{extract_to_dir}/**/GeoLiteCity-Location.csv"].last

    CreateGeoLocationsTemp.up
    ActiveRecord::Base.connection.execute(load_data_infile(@location_file))
    ActiveRecord::Base.connection.execute(copy_table)

  end

  desc 'Update database'
  task :updatedb do
    puts 'Update database stub'
  end
end


def load_data_infile(temp_path)
  <<-EOF

LOAD DATA LOCAL INFILE "#{temp_path}"
INTO TABLE #{TestGeoip.table_name}
FIELDS
  TERMINATED BY ","
  ENCLOSED BY '\"'
IGNORE 2 LINES
(
  @id, @country, @region, @city, @postal_code, @latitude, @longitude, @metro_code, @area_code
)
SET
  id          := @id,
  country     := @country,
  region      := @region,
  city        := @city,
  postal_code := @postal_code,
  latitude    := @latitude,
  longitude   := @longitude,
  metro_code  := @metro_code,
  area_code   := @area_code
;

  EOF
end

def copy_table
  <<-EOF
  INSERT INTO #{Geoip::Location.table_name}
  SELECT *
  FROM #{TestGeoip.table_name};
  EOF
end


class CreateGeoLocationsTemp < ActiveRecord::Migration
  def self.up
    create_table :geoip_locations_new do |t|
      t.string :country
      t.string :region
      t.string :city, :index=>true
      t.integer :postal_code, :index=>true
      t.float :latitude
      t.float :longitude
      t.integer :metro_code
      t.integer :area_code
    end
  end

  def self.down
    drop_table :geoip_locations_new
  end
end

class TestGeoip < ActiveRecord::Base
  set_table_name "geoip_locations_new"
end