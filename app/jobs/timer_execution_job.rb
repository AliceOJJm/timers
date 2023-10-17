require 'net/http'

class TimerExecutionJob < ::ApplicationJob
  def perform(timer)
    timer.with_lock do
      return if timer.status.in?(%w[executing executed])

      timer.update!(status: :executing)
    end
    uri = URI(timer.url)
    uri.path = uri.path.concat("/#{timer.id.to_s}").squeeze('/')
    begin
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.request(Net::HTTP::Post.new(uri))
    rescue *HTTP_ERRORS => e
      # TODO: Report the error or update timer status to :error
      # => Alternatively propagate and let the job rerun if we need the positive response
    ensure
      timer.update!(status: :executed)
    end
  end

  HTTP_ERRORS = [
    Errno::EADDRNOTAVAIL,
    Errno::ECONNABORTED,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::EINVAL,
    Errno::ENETUNREACH,
    Errno::EPIPE,
    IOError,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::OpenTimeout,
    Net::ProtocolError,
    Net::ReadTimeout,
    OpenSSL::SSL::SSLError,
    SocketError
  ].freeze
end
