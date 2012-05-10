namespace :data do
  desc "Copy tags from the events table to the tags table"
  task :copy_tags => :environment do
    Event.all.each do |e|
      p "Processing event # #{e.id}"
      tag_array = e.tags.split ','
      tag_array.each do |tag_str|
        # Check if the tag exists already. If not, create it
        t = Tag.find_by_name tag_str
        t ||= Tag.create!(:name => tag_str)
        # Now create a mapping entry
        Tagmap.create!(:event_id => e.id, :tag_id => t.id)
      end
    end
  end
  
  desc "Clean tags table and tagmap table"
  task :delete_tags => :environment do
    Tag.delete_all
    Tagmap.delete_all
  end
end
