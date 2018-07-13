require "spectre_client/version"
require "rest_client"
require "json"

module SpectreClient
  class Client
    attr_reader :run_id

    def initialize(project_name, suite_name, url_base, external_id = nil)
      @url_base = url_base
      @project_name = project_name
      @suite_name = suite_name
      @run_id = create_or_get_test_run(external_id)
    end

    def submit_test(options = {})
      source_url = options[:source_url] || ''
      fuzz_level = options[:fuzz_level] || ''
      highlight_colour = options[:highlight_colour] || ''

      payload = {
        test: {
          run_id: @run_id,
          name: options[:name],
          browser: options[:browser],
          size: options[:size],
          screenshot: options[:screenshot],
          source_url: source_url,
          fuzz_level: fuzz_level,
          highlight_colour: highlight_colour,
          diff_threshold: options[:diff_threshold]
        }
      }
      payload[:test][:crop_area] = options[:crop_area] if options[:crop_area]

      request = RestClient::Request.execute(
        method: :post,
        url: "#{@url_base}/tests",
        timeout: 120,
        multipart: true,
        payload: payload
      )
      JSON.parse(request.to_str, symbolize_names: true)
    end

    private

    def create_or_get_test_run(external_id = nil)
      payload = {
        project: @project_name,
        suite: @suite_name
      }
      payload[:external_id] = external_id if external_id

      lock_file = File.join(Dir.tmpdir, "specte_client#{external_id}.lock")
      response = with_global_lock(lock_file) do
        request = RestClient::Request.execute(
          method: :post,
          url: "#{@url_base}/runs",
          timeout: 120,
          payload: payload
        )
        JSON.parse(request.to_str)
      end
      @run_id = response['id']
    end

    def with_global_lock(file_path)
      fh = File.open(file_path, File::CREAT)
      fh.flock(File::LOCK_EX)
      yield
    ensure
      fh.flock(File::LOCK_UN)
      fh.close
    end
  end
end
