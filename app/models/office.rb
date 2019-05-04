class Office < ApplicationRecord
  
  validates_presence_of :name
  validates_presence_of :country
  validates_presence_of :postcode
  validates_uniqueness_of :postcode
  validates_presence_of :street_ad
  validates_presence_of :town_city
  validates_presence_of :phone_no
  
end
