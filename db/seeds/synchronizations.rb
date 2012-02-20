if defined?(User)
  User.all.each do |user|
    if user.plugins.where(:name => 'synchronizations').blank?
      user.plugins.create(:name => 'synchronizations',
                          :position => (user.plugins.maximum(:position) || -1) +1)
    end
  end
end

if defined?(Page)
  page = Page.create(
    :title => 'Synchronizations',
    :link_url => '/synchronizations',
    :deletable => false,
    :position => ((Page.maximum(:position, :conditions => {:parent_id => nil}) || -1)+1),
    :menu_match => '^/synchronizations(\/|\/.+?|)$'
  )
  Page.default_parts.each do |default_page_part|
    page.parts.create(:title => default_page_part, :body => nil)
  end
end