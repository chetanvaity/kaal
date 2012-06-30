class StaticController < ApplicationController
  caches_page :home, :about_us,

  def credits
  end

end
