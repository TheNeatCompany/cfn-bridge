require 'json'

module FileSupport

  def read_file(name)
    IO.read(File.join(File.dirname(__FILE__), '..', 'files', name))
  end

  def parse_json(name, symbolize_names = true)
    JSON.parse(read_file("#{name}.json"), symbolize_names: symbolize_names)
  end

end