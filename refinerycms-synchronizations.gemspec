Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-synchronizations'
  s.version           = '1.0'
  s.description       = 'Ruby on Rails Synchronizations engine for Refinery CMS'
  s.date              = '2012-02-06'
  s.authors           = 'Just Brilliant Solutions'
  s.email             = 'gems@jbsolutions.hu'
  s.homepage          = 'http://jbsolutions.hu/'
  s.summary           = 'Synchronizations engine for Refinery CMS'
  s.require_paths     = %w(lib)
  s.files             = Dir['lib/**/*', 'config/**/*', 'app/**/*']
end
