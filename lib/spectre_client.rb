require "spectre_client/version"
require "rest_client"
require "json"

module SpectreClient
  class Client
    attr_reader :run_id

    def initialize(url_base, project_name, suite_name, existing_run_id = nil)
      @url_base = url_base
      @project_name = project_name
      @suite_name = suite_name
      @run_id = existing_run_id || create_test_run
    end

    def submit_test(options = {})
      source_url =  options[:source_url] || ''
      fuzz_level =  options[:fuzz_level] || ''
      highlight_colour = options[:highlight_colour] || ''

      request = RestClient::Request.execute(
        method: :post,
        url: "#{@url_base}/tests",
        timeout: 120,
        multipart: true,
        payload: {
          test: {
            run_id: @run_id,
            name: options[:name],
            browser: options[:browser],
            size: options[:size],
            screenshot: options[:screenshot],
            source_url: source_url,
            fuzz_level: fuzz_level,
            highlight_colour: highlight_colour,
            crop_area: options[:crop_area],
            diff_threshold: options[:diff_threshold]
          }
        }
      )
      JSON.parse(request.to_str, symbolize_names: true)
    end

    private

    def create_test_run
      request = RestClient::Request.execute(
        method: :post,
        url: "#{@url_base}/runs",
        timeout: 120,
        payload: {
          project: @project_name,
          suite: @suite_name
        }
      )
      response = JSON.parse(request.to_str)
      @run_id = response['id']
    end
  end
end
