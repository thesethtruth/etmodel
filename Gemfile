source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.0.8'
gem 'jquery-rails'
gem 'haml', '~>3.1.1'
gem 'sass', '~>3.1.1'
gem 'authlogic', :git => 'git://github.com/odorcicd/authlogic.git', :branch => 'rails3'
gem 'bluecloth'
gem 'formtastic'
gem 'http_status_exceptions', :git => 'git://github.com/japetheape/http_status_exceptions.git' 
gem 'paper_trail', '~>2.2.4'
gem 'default_value_for'
gem 'acts_as_list'
gem 'ancestry', '~> 1.2.3'
gem 'httparty', '~> 0.7.4'
gem 'tabs_on_rails', '~>2.0.1'

# javascript
gem 'sprockets' # CHECK
gem 'sprockets-rails' # CHECK
gem 'rack-sprockets' # CHECK
gem 'yui-compressor'
gem 'i18n-js'

# supporting gems
gem 'hoptoad_notifier', '2.4.2'

# system gems
gem 'thinking-sphinx', '>=2.0.1'
gem 'mysql2', '~>0.2.6'
gem 'memcache-client'
gem 'mongrel', '1.2.0.pre2'

group :development do
  gem 'yard', '0.5.4'
  gem 'annotate', :require => false
  gem 'jslint_on_rails'
end

group :test, :development do
  # It needs to be in the :development group to expose generators and rake tasks without having to type RAILS_ENV=test.
  gem "rspec-rails", "~> 2.6.1"
  gem 'ruby-debug19'
  gem 'hirb'
  gem 'wirble'
  gem 'awesome_print', :require => 'ap'
  gem 'watchr'
  gem 'spork'
end

group :test do
  gem 'factory_girl_rails', :require => false
  gem 'shoulda-matchers'
  gem 'webrat'
  gem 'simplecov'
end
