require "rails_helper"

RSpec.describe PdfGenerator do
  it "encadeia métodos delegados ao Prawn" do
    prawn = instance_double(Prawn::Document)
    allow(Prawn::Document).to receive(:new).and_return(prawn)
    allow(prawn).to receive(:fill_color)
    allow(prawn).to receive(:text)
    allow(prawn).to receive(:move_down)

    generator = described_class.new

    expect(generator.fill_color("000000").text("Olá").move_down(10)).to eq(generator)
    expect(prawn).to have_received(:fill_color).with("000000")
    expect(prawn).to have_received(:text).with("Olá")
    expect(prawn).to have_received(:move_down).with(10)
  end

  it "delega render, cursor e bounds" do
    prawn = instance_double(Prawn::Document, render: "%PDF", cursor: 123, bounds: :bounds)
    allow(Prawn::Document).to receive(:new).and_return(prawn)

    generator = described_class.new

    aggregate_failures do
      expect(generator.render).to eq("%PDF")
      expect(generator.cursor).to eq(123)
      expect(generator.bounds).to eq(:bounds)
    end
  end

  it "cria documento A4 com margem padrão" do
    allow(Prawn::Document).to receive(:new).and_call_original

    described_class.new

    expect(Prawn::Document).to have_received(:new).with(page_size: "A4", margin: 20)
  end
end
