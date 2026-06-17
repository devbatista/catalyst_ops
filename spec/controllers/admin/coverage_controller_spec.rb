require "rails_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Admin::CoverageController, type: :controller do
  describe "#coverage_report" do
    before do
      @tmp_dir = Dir.mktmpdir
      @tmp_root = Pathname.new(@tmp_dir)
      FileUtils.mkdir_p(@tmp_root.join("coverage"))
      allow(Rails).to receive(:root).and_return(@tmp_root)
    end

    after do
      FileUtils.remove_entry(@tmp_dir) if @tmp_dir
    end

    it "calcula percentuais a partir do resultset do SimpleCov" do
      write_last_run(line: 10.0, branch: 20.0)
      write_resultset(
        "app/models/user.rb" => {
          "lines" => [1, nil, 0, 2],
          "branches" => {
            "branch" => {
              "then" => 1,
              "else" => 0
            }
          }
        }
      )
      File.write(@tmp_root.join("coverage/index.html"), "<html></html>")

      report = controller.send(:coverage_report)

      aggregate_failures do
        expect(report[:line]).to eq(66.67)
        expect(report[:branch]).to eq(50.0)
        expect(report[:lines_covered]).to eq(2)
        expect(report[:lines_total]).to eq(3)
        expect(report[:branches_covered]).to eq(1)
        expect(report[:branches_total]).to eq(2)
        expect(report[:resultset_exists]).to be(true)
        expect(report[:report_exists]).to be(true)
      end
    end

    it "usa o last_run como fallback quando nao existe resultset" do
      write_last_run(line: 77.2, branch: 56.63)

      report = controller.send(:coverage_report)

      aggregate_failures do
        expect(report[:line]).to eq(77.2)
        expect(report[:branch]).to eq(56.63)
        expect(report[:resultset_exists]).to be(false)
        expect(report[:report_exists]).to be(false)
      end
    end

    it "retorna nil quando o last_run nao existe" do
      expect(controller.send(:coverage_report)).to be_nil
    end

    it "retorna nil quando o JSON esta invalido" do
      File.write(@tmp_root.join("coverage/.last_run.json"), "{")

      expect(controller.send(:coverage_report)).to be_nil
    end
  end

  def write_last_run(line:, branch:)
    File.write(
      @tmp_root.join("coverage/.last_run.json"),
      {
        result: {
          line: line,
          branch: branch
        }
      }.to_json
    )
  end

  def write_resultset(coverage)
    File.write(
      @tmp_root.join("coverage/.resultset.json"),
      {
        RSpec: {
          coverage: coverage,
          timestamp: Time.current.to_i
        }
      }.to_json
    )
  end
end
