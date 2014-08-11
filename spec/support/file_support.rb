module FileSupport

  def read_file(name)
    IO.read(File.join(File.dirname(__FILE__), '..', 'files', name))
  end

end