module FileSupport

  def read_file(name)
    IO.read(File.join(__dir__, '..', 'files', name))
  end

end