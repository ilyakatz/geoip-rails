class CreateGeoLocations < ActiveRecord::Migration
  def self.up
    create_table :geo_locations do |t|
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
    drop_table :geo_locations
  end
end
