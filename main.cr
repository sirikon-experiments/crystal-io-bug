require "http/server"

def run_http_server
  server = HTTP::Server.new do |context|
    context.response.headers.add("Content-Type", "text/plain")
    context.response.headers.add("X-Content-Type-Options", "nosniff")

    done = false
    run_ping do |bytes|
      if done
        next
      end
      begin
        context.response.write(bytes)
        context.response.flush
      rescue ex
        puts "## FAILED ##"
        done = true
      end
    end
  end
  puts "Listening on http://127.0.0.1:8080"
  server.listen(8080)
end

def run_ping(&block : Bytes -> Nil)
  output_reader, output_writer = IO.pipe()
  process = Process.new(
    command: "ping",
    args: ["8.8.8.8", "-c", "4"],
    output: output_writer,
    error: output_writer)

  spawn do
    output_reader.each_byte do |byte|
      bytes = Slice.new(1, byte)
      print String.new(bytes, encoding: "utf8")
      block.call(bytes)
    end
  end

  process.wait
end


spawn do
  run_http_server
end
sleep
