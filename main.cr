output_reader, output_writer = IO.pipe()

process = Process.new(
  command: "ping",
  args: ["8.8.8.8", "-c", "6"],
  output: output_writer,
  error: output_writer)

file = File.new(Path[Dir.current] / "output.txt", mode: "w")

spawn do
  loop do
    if file.closed?
      break
    end
    sleep 0.1
    file.flush
  end
end

spawn do
  sleep 3
  file.close
end

spawn do
  prevent_file_write = false
  output_reader.each_byte do |byte|
    bytes = Slice.new(1, byte)
    if !prevent_file_write
      begin
        file.write(bytes)
      rescue exception
        prevent_file_write = true
        puts "## EXCEPTION ##"
      end
    end
    print String.new(bytes, encoding: "utf8")
  end
end

process.wait
file.close
