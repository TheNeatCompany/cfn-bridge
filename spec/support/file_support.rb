require 'json'

module FileSupport

  def read_file(name)
    IO.read(File.join(File.dirname(__FILE__), '..', 'files', name))
  end

  def parse_json(name)
    JSON.parse(read_file("#{name}.json"), symbolize_names: true)
  end

end