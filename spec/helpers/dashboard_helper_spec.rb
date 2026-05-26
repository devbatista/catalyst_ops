require "rails_helper"

RSpec.describe DashboardHelper, type: :helper do
  describe "#status_color_for" do
    it "retorna a cor do status da OS" do
      expect(helper.status_color_for("atrasada")).to eq("dark")
    end
  end

  describe "#weekly_change_indicator" do
    it "retorna traço quando valor anterior é zero" do
      expect(helper.weekly_change_indicator(10, 0)).to include("—", "mb-0 font-13")
    end

    it "renderiza crescimento positivo" do
      html = helper.weekly_change_indicator(15, 10)

      aggregate_failures do
        expect(html).to include("text-success")
        expect(html).to include("bx-up-arrow-alt")
        expect(html).to include("50.0%")
      end
    end

    it "renderiza queda negativa" do
      html = helper.weekly_change_indicator(5, 10)

      aggregate_failures do
        expect(html).to include("text-danger")
        expect(html).to include("bx-down-arrow-alt")
        expect(html).to include("50.0%")
      end
    end
  end
end
