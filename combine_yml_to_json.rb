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

puts "✅ Combined JSON written to combined-taxonomy.json"