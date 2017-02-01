#!/usr/bin/env ruby
require 'dotenv/load'
require 'koala'
require 'liquid'

client  = Koala::Facebook::API.new(ENV['API_KEY'])
options = { limit: 50, fields: %w(message created_time permalink_url) }

filter = ->(post) do
  minimum_lines = 2
  post['message'] &&
    post['message'].count("\n") > minimum_lines * 2
end

preprocess = ->(post) do
  post['id'] = post['permalink_url'].split('/').last
  post
end

posts = []

page = client.get_connections('me', 'posts', options)
loop do
  break unless page
  posts.concat(page.select(&filter))
  page = page.next_page
end

template = File.read(File.join(Dir.pwd, 'template.liquid'))
template = Liquid::Template.parse(template)
File.write(
  File.join(__dir__, 'posts.html'),
  template.render('posts' => posts.map(&preprocess))
)

puts "#{posts.size} posts retrieved!"
