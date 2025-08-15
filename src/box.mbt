///| A Box represents a rectangular area of text data.
/// Each box has a consistent width across all rows.
struct Box {
  data : Array[String]
}

///| Vertical alignment options for box positioning.
pub(all) enum Vertical {
  Top // Align to top edge
  Center // Align to vertical center
  Bottom // Align to bottom edge
}

///| Horizontal alignment options for box positioning.
pub(all) enum Horizontal {
  Left // Align to left edge
  Center // Align to horizontal center
  Right // Align to right edge
}

///| Get the height (number of rows) of a box.
/// 
/// Returns the number of rows in the box.
pub fn height(self : Box) -> Int {
  self.data.length()
}

///| Get the width (number of columns) of a box.
/// Returns 0 for empty boxes.
pub fn width(self : Box) -> Int {
  if self.height() == 0 {
    0
  } else {
    self.data[0].length()
  }
}

///| Get both dimensions of a box as (height, width).
/// 
/// Returns a tuple containing (height, width).
pub fn dimensions(self : Box) -> (Int, Int) {
  (self.height(), self.width())
}

///| Convert a box to a string for display.
/// 
/// Returns a string representation of the box suitable for printing.
impl Show for Box with to_string(self) {
  let buf = @buffer.new()
  self.output(buf)
  buf.to_string()
}

///| Output a box's content to a logger.
/// 
/// Sends the box content to the provided logger.
impl Show for Box with output(self, logger) {
  logger.write_string(self.data.join("\n"))
}

///| Create a box filled with the specified character.
/// 
/// # Parameters
/// - `c`: The character to fill the box with
/// - `h`: Height (number of rows)
/// - `w`: Width (number of columns)
pub fn fill(c : Char, h : Int, w : Int) -> Box {
  { data: Array::make(h, String::repeat(c.to_string(), w)) }
}

///| Create a 1×1 box containing a single character.
pub fn singleton(c : Char) -> Box {
  fill(c, 1, 1)
}

///| Create a box filled with spaces.
/// 
/// # Parameters
/// - `h`: Height (number of rows)
/// - `w`: Width (number of columns)
pub fn space(h : Int, w : Int) -> Box {
  fill(' ', h, w)
}

///| Create an empty box with zero dimensions.
/// Useful as an identity element for box combinations.
pub fn empty() -> Box {
  fill(' ', 0, 0)
}

///| Place two boxes side by side horizontally.
/// 
/// # Parameters
/// - `r`: The box to place to the right
/// - `align`: Vertical alignment (default: Center)
pub fn beside(self : Box, r : Box, align~ : Vertical = Center) -> Box {
  guard self.width() != 0 else { r }
  guard r.width() != 0 else { self }
  let hl = self.heighten(r.height(), align~)
  let hr = r.heighten(self.height(), align~)
  { data: hl.data.zip(hr.data).map(fn(s) { s.0 + s.1 }) }
}

///| Stack two boxes vertically.
/// 
/// # Parameters
/// - `b`: The box to place below
/// - `align`: Horizontal alignment (default: Center)
pub fn above(self : Box, b : Box, align~ : Horizontal = Center) -> Box {
  guard self.height() != 0 else { b }
  guard b.height() != 0 else { self }
  let wl = self.widen(b.width(), align~)
  let wr = b.widen(self.width(), align~)
  { data: wl.data + wr.data }
}

///| Expand a box to the specified width by adding padding.
/// 
/// # Parameters
/// - `w`: Target width
/// - `align`: Horizontal alignment of original content (default: Center)
pub fn widen(self : Box, w : Int, align~ : Horizontal = Center) -> Box {
  guard self.width() < w else { self }
  let (bh, bw) = self.dimensions()
  let pad = w - bw
  match align {
    Left => self.beside(space(bh, pad))
    Right => space(bh, pad).beside(self)
    Center => [space(bh, pad / 2), self, space(bh, pad - pad / 2)] |> hconcat()
  }
}

///| Expand a box to the specified height by adding padding.
/// 
/// # Parameters
/// - `h`: Target height
/// - `align`: Vertical alignment of original content (default: Center)
pub fn heighten(self : Box, h : Int, align~ : Vertical = Center) -> Box {
  guard self.height() < h else { self }
  let (bh, bw) = self.dimensions()
  let pad = h - bh
  match align {
    Top => self.above(space(pad, bw))
    Bottom => space(pad, bw).above(self)
    Center => [space(pad / 2, bw), self, space(pad - pad / 2, bw)] |> vconcat()
  }
}

///| Combine an array of boxes horizontally.
/// 
/// # Parameters
/// - `boxes`: Array of boxes to combine
/// - `align`: Vertical alignment (default: Center)
pub fn hconcat(boxes : Array[Box], align~ : Vertical = Center) -> Box {
  boxes.fold(init=empty(), fn(a, b) { a.beside(b, align~) })
}

///| Combine an array of boxes vertically.
/// 
/// # Parameters
/// - `boxes`: Array of boxes to combine
/// - `align`: Horizontal alignment (default: Center)
pub fn vconcat(boxes : Array[Box], align~ : Horizontal = Center) -> Box {
  boxes.fold(init=empty(), fn(a, b) { a.above(b, align~) })
}

///| Arrange boxes in a 2D grid layout.
/// Each sub-array represents a row of boxes.
/// 
/// # Parameters
/// - `g`: 2D array where `g[i][j]` is the box at row i, column j
pub fn grid(g : Array[Array[Box]]) -> Box {
  g.map(hconcat(_)) |> vconcat()
}

///| Add a simple ASCII frame around a box using '+', '-', and '|' characters.
pub fn framed(self : Box) -> Box {
  let (h, w) = self.dimensions()
  let v_bar = fill('|', h, 1)
  let h_bar = fill('-', 1, w)
  let corner = singleton('+')
  grid([[corner, h_bar, corner], [v_bar, self, v_bar], [corner, h_bar, corner]])
}
