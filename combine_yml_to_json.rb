require 'bundler/setup'
require 'yaml'
require 'json'

root = './oss-taxonomy'
combined = {}

Dir.glob("#{root}/*").select { |entry| File.directory?(entry) }.each do |facet_path|
  facet = File.basename(facet_path)
  combined[facet] = Dir.glob("#{facet_path}/*.yml").map do |file|
    YAML.load_file(file).merge('name' => File.basename(file, '.yml'))
  end
end

File.write('combined-taxonomy.json', JSON.pretty_generate(combined))

# Copy to docs folder for GitHub Pages
require 'fileutils'
FileUtils.mkdir_p('docs')
FileUtils.cp('combined-taxonomy.json', 'docs/combined-taxonomy.json')
FileUtils.cp('schema.json', 'docs/schema.json') if File.exist?('schema.json')

puts "✅ Combined JSON written to combined-taxonomy.json"
puts "✅ Files copied to docs/ for GitHub Pages"