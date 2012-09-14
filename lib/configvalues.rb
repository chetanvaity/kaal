class Configvalues
  include Singleton

  def initialize
    @value_store = Hash.new # Empty hash
      
    #Read from DB and cach it once.
    Configvalue.all.each { |config_item|
      @value_store[config_item.paramname] = config_item.paramvalue
      Rails.logger.debug("Config item -> param=" + config_item.paramname + "  value=" + config_item.paramvalue)
    }
  end
  
  def get_value(given_param_name)
    return @value_store[given_param_name]
  end
  
  def set_value(given_param_name, given_param_val)
    #TBD .....need to test and add exception handling ...TBD TBD
    config_items = Configvalue.where("paramname=?",given_param_name)
    if config_items.nil? || config_items.length() == 0
      #Item does not exist. Add it.
      config_item = Configvalue.new
      config_item.paramname = given_param_name
      config_item.paramvalue = given_param_val
      config_item.save
      @value_store[given_param_name] = given_param_val
    end
  end
end