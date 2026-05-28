class CreateGeolocations < ActiveRecord::Migration[8.1]
  def change
    create_table :geolocations do |t|
      t.string :host, null: false
      t.string :ip, null: false

      t.string :country_code
      t.string :country_name
      t.string :region_name
      t.string :city
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      t.timestamps
    end

    add_index :geolocations, :host, unique: true
    add_index :geolocations, :ip
  end
end
