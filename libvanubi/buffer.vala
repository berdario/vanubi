/*
 *  Copyright © 2011-2014 Luca Bruno
 *
 *  This file is part of Vanubi.
 *
 *  Vanubi is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Vanubi is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Vanubi.  If not, see <http://www.gnu.org/licenses/>.
 */
namespace Vanubi {
	public abstract class Buffer {
		public abstract int tab_width { get; set; }
		public virtual IndentMode indent_mode { get; set; default = IndentMode.TABS; }
		public abstract BufferIter line_start (int line);
		public abstract BufferIter line_end (int line);
		public abstract BufferIter line_at_char (int line, int line_offset);
		public abstract BufferIter line_at_byte (int line, int line_offset);
		public abstract void insert (BufferIter iter, string text);
		public abstract void delete (BufferIter start, BufferIter end);
		public abstract string line_text (int line);

		public virtual bool empty_line (int line) {
			return line_text(line).strip()[0] == '\0';
		}

		public virtual void set_indent (int line, int indent) {
			indent = int.max (indent, 0);
			if (get_indent (line) == indent) {
				// avoid adding unfriendly undo actions
				return;
			}

			var start = line_start (line);
			var iter = start.copy ();
			while (iter.char.isspace() && !iter.eol) {
				iter.forward_char ();
			}

			@delete (start, iter);
			var tab_width = tab_width;
			// mixed tab + spaces, TODO: handle indent_mode
			insert (start, string.nfill(indent/tab_width, '\t')+string.nfill(indent-(indent/tab_width)*tab_width, ' '));
		}

		public virtual int get_indent (int line) {
			var tab_width = tab_width;
			int indent = 0;
			var iter = line_start (line);
			while (!iter.eol && iter.char.isspace ()) {
				if (iter.char == '\t') {
					indent += tab_width;
				} else {
					indent++;
				}
				iter.forward_char ();
			}
			return indent;
		}
	}

	public abstract class BufferIter : Object {
		public unowned Buffer buffer { get; set; }

		public BufferIter (Buffer buffer) {
			this.buffer = buffer;
		}

		public abstract BufferIter forward_char ();
		public abstract BufferIter backward_char ();
		public abstract BufferIter forward_line ();
		public abstract BufferIter backward_line ();
		public abstract bool is_in_code { get; }
		public abstract bool is_in_comment { get; }
		public abstract int line_offset { get; }
		public abstract int line { get; }
		public abstract bool eol { get; }
		public abstract bool eof { get; }
		public abstract bool sol { get; }
		public abstract unichar char { get; }
		public abstract BufferIter copy ();

		/* Forwards a copy of the iter until the whole string is consumed, otherwise returns the original iter.
		 * Works on a line only */
		public virtual BufferIter forward_string (string str) {
			var cp = copy ();
			var cnt = str.length;
			for (var i=0; i < cnt; i++) {
				if (cp.eol) {
					return this;
				}
				if (cp.char != str[i]) {
					return this;
				}
				cp.forward_char ();
			}
			return cp;
		}
		
		/* Backwards a copy of the iter until the whole reverse string is consumed, otherwise returns the original iter
		 * Works on a line only */
		public virtual BufferIter backward_string (string str) {
			var cp = copy ();
			var cnt = str.length;
			for (var i=cnt-1; i >= 0; i--) {
				if (cp.sol) {
					return this;
				}
				cp.backward_char ();
				if (cp.char != str[i]) {
					return this;
				}
			}
			return cp;
		}
		
		public virtual BufferIter forward_spaces () {
			while (!eol && char.isspace()) forward_char ();
			return this;
		}																					

		public virtual BufferIter backward_spaces () {
			while (!sol && char.isspace()) backward_char ();
			return this;
		}

		public virtual int effective_line_offset {
			get {
				var iter = copy ();
				var off = 0;
				do {
					if (iter.char == '\t') {
						off += buffer.tab_width;
					} else {
						off++;
					}
					if (iter.line_offset == 0) {
						break;
					}
					iter.backward_char ();
				} while (true);
				return off;
			}
		}
	}

	/*****************
	 * STRING BUFFER
	 *****************/

	public class StringBuffer : Buffer {
		internal string[] lines;
		internal int timestamp;
		public bool force_in_comment;

		public StringBuffer (owned string[] lines) {
			this.lines = (owned) lines;
		}

		public StringBuffer.from_text (string text) {
			var lines = text.split ("\n");
			foreach (unowned string line in lines) {
				this.lines += line+"\n";
			}
			unowned string last = this.lines[this.lines.length-1];
			last.data[last.length-1] = '\0';
		}

		public string text {
			owned get {
				return string.joinv ("", lines);
			}
		}

		public override int tab_width { get; set; default = 4; }

		public override string line_text (int line) {
			return lines[line];
		}

		public override BufferIter line_start (int line) {
			line = int.min (line, lines.length-1);
			return new StringBufferIter (this, line, 0);
		}

		public override BufferIter line_end (int line) {
			line = int.max (0, line);
			unowned string l = lines[line];
			return new StringBufferIter (this, line, l.length-1);
		}
		
		// assume latin1
		public override BufferIter line_at_char (int line, int line_offset) {
			return new StringBufferIter (this, line, line_offset);
		}
		
		// assume latin1
		public override BufferIter line_at_byte (int line, int line_offset) {
			return new StringBufferIter (this, line, line_offset);
		}

		// only on a single line
		public override void insert (BufferIter iter, string text) requires (((StringBufferIter) iter).valid && text.index_of ("\n") < 0) {
			unowned string l = lines[iter.line];
			lines[iter.line] = l.substring(0, iter.line_offset) + text + l.substring (iter.line_offset);
			// update the iter
			var siter = (StringBufferIter) iter;
			siter._line_offset += text.length;
			siter.timestamp = ++timestamp;
		}

		// only on a single line
		public override void delete (BufferIter start, BufferIter end) requires (((StringBufferIter)start).valid && ((StringBufferIter)end).valid && start.line == end.line) {
			unowned string l = lines[start.line];
			lines[start.line] = l.substring(0, start.line_offset) + l.substring (end.line_offset);
			// update the iter
			var sstart = (StringBufferIter) start;
			var send = (StringBufferIter) end;
			send._line_offset = sstart.line_offset;
			sstart.timestamp = send.timestamp = ++timestamp;
		}
	}

	/* ASCII string buffer iter */
	public class StringBufferIter : BufferIter {
		internal int _line;
		internal int _line_offset;
		internal int timestamp;
		StringBuffer buf;

		public StringBufferIter (StringBuffer buffer, int line, int line_offset) {
			base (buffer);
			buf = buffer;
			_line = line;
			_line_offset = line_offset;
			timestamp = buf.timestamp;
		}

		public bool valid {
			get {
				return timestamp == buf.timestamp;
			}
		}

		public override BufferIter forward_char () requires (valid) {
			if (eol) {
				if (_line >= buf.lines.length-1) {
					return this;
				}
				_line++;
				_line_offset = 0;
			} else {
				_line_offset++;
			}
			return this;
		}

		public override BufferIter backward_char () requires (valid) {
			if (_line_offset == 0) {
				if (_line == 0) {
					return this;
				}
				_line--;
				unowned string l = buf.lines[_line];
				_line_offset = l.length-1;
			} else {
				_line_offset--;
			}
			return this;
		}

		public override BufferIter forward_line () requires (valid) {
			_line = int.min (buf.lines.length-1, _line+1);
			return this;
		}
		
		public override BufferIter backward_line () requires (valid) {
			_line = int.max (0, _line-1);
			return this;
		}
		
		public override bool is_in_code {
			get {
				// assume no strings and no comments for the tests
				return !buf.force_in_comment;
			}
		}
		
		public override bool is_in_comment {
			get {
				// assume no comments for the tests
				return buf.force_in_comment;
			}
		}

		public override int line_offset {
			get {
				warn_if_fail (valid);
				return _line_offset;
			}
		}

		public override int line {
			get {
				warn_if_fail (valid);
				return _line;
			}
		}

		public override bool eol {
			get {
				warn_if_fail (valid);
				unowned string l = buf.lines[line];
				return line_offset >= l.length-1;
			}
		}
		
		public override bool eof {
			get {
				warn_if_fail (valid);
				unowned string l = buf.lines[line];
				return line == buf.lines.length-1 && line_offset >= l.length-1;
			}
		}

		public override bool sol {
			get {
				warn_if_fail (valid);
				return line_offset == 0;
			}
		}

		public override unichar char {
			get {
				warn_if_fail (valid);
				unowned string l = buf.lines[line];
				return l[line_offset];
			}
		}

		public override BufferIter copy () requires (valid) {
			var it = new StringBufferIter (buf, _line, _line_offset);
			it.timestamp = timestamp;
			return it;
		}
	}
}
