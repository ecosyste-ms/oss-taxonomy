require 'bundler/setup'
require 'yaml'
require 'json'
require 'time'

VERSION = '0.1.0'

root = './oss-taxonomy'
combined = {
  'version' => VERSION,
  'generated_at' => Time.now.utc.iso8601,
}

Dir.glob("#{root}/*").select { |entry| File.directory?(entry) }.sort.each do |facet_path|
  facet = File.basename(facet_path)
  combined[facet] = Dir.glob("#{facet_path}/*.yml").sort.map do |file|
    YAML.load_file(file).merge('name' => File.basename(file, '.yml'))
  end
end

File.write('combined-taxonomy.json', JSON.pretty_generate(combined))

# Flat term list for lightweight vendoring by downstream validators
terms = combined.flat_map do |facet, entries|
  next [] unless entries.is_a?(Array)
  entries.map { |t| "#{facet}:#{t['name']}" }
end
File.write('terms.txt', terms.sort.join("\n") + "\n")

# Copy to docs folder for GitHub Pages
require 'fileutils'
FileUtils.mkdir_p('docs')
FileUtils.cp('combined-taxonomy.json', 'docs/combined-taxonomy.json')
FileUtils.cp('schema.json', 'docs/schema.json') if File.exist?('schema.json')
FileUtils.cp('terms.txt', 'docs/terms.txt')

puts "✅ Combined JSON written to combined-taxonomy.json (v#{VERSION}, #{terms.length} terms)"
puts "✅ Flat term list written to terms.txt"
puts "✅ Files copied to docs/ for GitHub Pages"