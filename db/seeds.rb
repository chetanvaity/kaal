# content-encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Event.create!(:id => 1, :title => "Birth: Shivaji", :jd => 2316455, :source => "seed-data")
Event.create!(:id => 2, :title => "Shivaji is crowned at Raigad", :jd => 2332634, :source => "seed-data")
Event.create!(:id => 3, :title => "Battle of Surat", :jd => 2328829, :source => "seed-data")
Event.create!(:id => 4, :title => "Death - Shivaji", :jd => 2334732, :source => "seed-data")
Event.create!(:id => 5, :title => "Birth: Shivaji Sawant", :jd => 2429630, :source => "seed-data")

Tag.create!(:event_id => 1, :name => "shivaji", :source => "seed-data")
Tag.create!(:event_id => 2, :name => "shivaji", :source => "seed-data")
Tag.create!(:event_id => 3, :name => "shivaji", :source => "seed-data")
Tag.create!(:event_id => 4, :name => "shivaji", :source => "seed-data")
Tag.create!(:event_id => 1, :name => "india", :source => "seed-data")
Tag.create!(:event_id => 2, :name => "india", :source => "seed-data")
Tag.create!(:event_id => 3, :name => "india", :source => "seed-data")
Tag.create!(:event_id => 4, :name => "india", :source => "seed-data")
Tag.create!(:event_id => 3, :name => "mughal", :source => "seed-data")

Babel.create!(:id => 1, :term => "shivaji", :norm_term_id => 1)
Babel.create!(:id => 2, :term => "king_shivaji", :norm_term_id => 1)
Babel.create!(:id => 3, :term => "chatrapati_shivaji", :norm_term_id => 1)
Babel.create!(:id => 4, :term => "india", :norm_term_id => 4)
Babel.create!(:id => 5, :term => "bharat", :norm_term_id => 4)

