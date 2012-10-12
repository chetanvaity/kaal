class ConfigCache
  include Singleton

  def initialize
    @value_store = Hash.new # Empty hash
    refresh
  end

  # Read from DB
  def refresh
    Configvalue.all.each do |config_item|
      @value_store[config_item.paramname] = config_item.paramvalue
      Rails.logger.debug("Config item -> param=" + config_item.paramname + ", value=" + config_item.paramvalue)
    end
  end
  
  def get_value(given_param_name)
    return @value_store[given_param_name]
  end
  
end
