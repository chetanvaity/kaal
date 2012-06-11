# encoding: UTF-8
require 'test/unit'
require './util.rb'

class TestUtil < Test::Unit::TestCase
  def setup
    @e_title = "Battle of Surat: The Maratha Chhatrapati Shivaji defeats Inayat Khan of Mughal"
    @e2_title = "Birth - Pedro Calderón de la Barca, Spanish playwright (d. 1681)"
    @e3_title = "A massive wave sweeps along the Bristol Channel, possibly a tsunami, killing 2,000 people."
    @e262_title = "Susenyos defeats the combined armies of Yaqob and Abuna Petros II at the Battle of Gol in Gojjam, which makes him Emperor of Ethiopia."
    @para = "Battle of Surat was a land battle that took place on January 5, 1664 near the city of Surat, Gujarat, India between Chhatrapati Shivaji Maharaj and Inayat Khan, a Mughal captain.
The Marathas defeated the small Mughal force. Here are some non-ASCII characters - Y with a bar - Ȳ, A with a bar - Ā"
  end
  
  # def test_get_first_sentence
  #   uu = Util.instance
  #   s = uu.get_first_sentence(@e_title)
  #   assert_equal "Battle of Surat", s
  # end

  # def test_get_relevant_wiki_link
  #   uu = Util.instance
  #   link = uu.get_relevant_wiki_link("Battle of Surat")
  #   assert_equal "http://en.wikipedia.org/wiki/Battle_of_Surat", link
  # end

  def test_get_NLP_response
    uu = Util.instance
    p uu.get_NLP_response(@para)
  end

  # def test_init_babel
  #   uu = Util.instance
  #   uu.init_babel("/usr/local/share/mod-babel-synsets.txt")
  #   assert_equal 13, uu.get_synset("Shivaji").length
  # end

  # def test_get_more_tags()
  #   uu = Util.instance
  #   p uu.get_more_tags(@e262_title)
  # end

  # #def test_mod_babelnet
  # #  uu = Util.new
  # #  uu.mod_babelnet("/usr/local/share/babel-synsets.txt","/tmp/mod-babel-synsets.txt")
  # #end

end
