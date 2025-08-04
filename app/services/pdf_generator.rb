class PdfGenerator
  def initialize
    @pdf = Prawn::Document.new(page_size: "A4", margin: 20)
  end

  def fill_color(color)
    @pdf.fill_color color
    self
  end

  def fill_rectangle(point, width, height)
    @pdf.fill_rectangle(point, width, height)
    self
  end

  def font_size(size, &block)
    @pdf.font_size(size, &block)
    self
  end

  def text_box(*args)
    @pdf.text_box(*args)
    self
  end

  def move_down(val)
    @pdf.move_down(val)
    self
  end

  def table(data, opts = {})
    @pdf.table(data, opts)
    self
  end

  def render
    @pdf.render
  end

  def cursor
    @pdf.cursor
  end

  def bounds
    @pdf.bounds
  end

  def text(*args)
    @pdf.text(*args)
    self
  end

  def stroke_horizontal_line(*args)
    @pdf.stroke_horizontal_line(*args)
    self
  end

  def bounding_box(*args, &block)
    @pdf.bounding_box(*args, &block)
  end

  def stroke_rectangle(*args)
    @pdf.stroke_rectangle(*args)
    self
  end
end
