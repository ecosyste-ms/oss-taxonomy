require 'bundler/setup'
require 'yaml'
require 'fileutils'

required_fields = ['name', 'description']
optional_fields = ['examples', 'related', 'aliases', 'ecosystems', 'tags']

facet_directories = Dir.glob('oss-taxonomy/*').select { |entry| File.directory?(entry) }

errors = []

facet_directories.each do |facet_dir|
  seen_names = []

  Dir.glob("#{facet_dir}/*.yml").each do |file|
    puts "Checking file: #{file}"

    begin
      content = YAML.load_file(file)

      missing_fields = required_fields.reject { |field| content.key?(field) }

      if missing_fields.empty?
        puts "  ✅ File is valid"
      else
        errors << "#{file}: Missing required fields: #{missing_fields.join(', ')}"
        puts "  ERROR: #{errors.last}"
      end

      extra_fields = content.keys.reject { |key| required_fields.include?(key) || optional_fields.include?(key) }

      unless extra_fields.empty?
        errors << "#{file}: Extra fields found: #{extra_fields.join(', ')}"
        puts "  ERROR: #{errors.last}"
      end

      if seen_names.include?(content['name'])
        errors << "#{file}: Duplicate name found: #{content['name']}"
        puts "  ERROR: #{errors.last}"
      else
        seen_names << content['name']
      end

      filename = File.basename(file)
      if filename != filename.downcase
        errors << "#{file}: Filename is not lowercase: #{filename}"
        puts "  ERROR: #{errors.last}"
      end

    rescue => e
      errors << "#{file}: Could not parse YAML: #{e.message}"
      puts "  ERROR: #{errors.last}"
    end
  end
end

if errors.any?
  puts "\n#{errors.length} error(s):"
  errors.each { |e| puts "  #{e}" }
  exit 1
end

puts "\nAll files valid."