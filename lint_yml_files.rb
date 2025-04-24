require 'bundler/setup'
require 'yaml'
require 'fileutils'

required_fields = ['name', 'description', 'examples']
optional_fields = ['aliases', 'notable_projects', 'ecosystems', 'tags']

facet_directories = Dir.glob('oss-taxonomy/*').select { |entry| File.directory?(entry) }

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
        puts "  ERROR: Missing required fields: #{missing_fields.join(', ')}"
      end

      extra_fields = content.keys.reject { |key| required_fields.include?(key) || optional_fields.include?(key) }

      unless extra_fields.empty?
        puts "  ERROR: Extra fields found: #{extra_fields.join(', ')}"
      end

      if seen_names.include?(content['name'])
        puts "  ERROR: Duplicate name found: #{content['name']}"
      else
        seen_names << content['name']
      end

      filename = File.basename(file)
      if filename != filename.downcase
        puts "  ERROR: Filename is not lowercase: #{filename}"
      end

    rescue => e
      puts "  ERROR: Could not parse YAML file #{file}: #{e.message}"
    end
  end
end