/*
 *  Copyright © 2013 Luca Bruno
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

// Runtime system functions for Vade
namespace Vanubi.Vade {
	// Concatenate two or more strings
	public class NativeConcat : Function {
		public override async Value eval (Scope scope, Value[]? arguments, out Value? error, Cancellable cancellable) {
			var b = new StringBuilder ();
			foreach (var val in arguments) {
				b.append (val.str);
			}
			return new StringValue ((owned) b.str);
		}
		
		public override string to_string () {
			return "concat(s1, ...)";
		}
	}
	
	public class NativeLower : Function {
		public override async Value eval (Scope scope, Value[]? arguments, out Value? error, Cancellable cancellable) {
			error = null;
			if (arguments.length > 0) {
				return new StringValue (arguments[0].str.down ());
			} else {
				error = new StringValue ("1 argument required");
				return NullValue.instance;
			}
		}
		
		public override string to_string () {
			return "lower(s)";
		}
	}
	
	public class NativeUpper : Function {
		public override async Value eval (Scope scope, Value[]? arguments, out Value? error, Cancellable cancellable) {
			if (arguments.length > 0) {
				return new StringValue (arguments[0].str.up ());
			} else {
				error = new StringValue ("1 argument required");
				return NullValue.instance;
			}
		}
		
		public override string to_string () {
			return "upper(s)";
		}
	}
	
	public Scope create_base_scope () {
		// create a scope with native functions and constants
		var scope = new Scope (null);
		
		scope["concat"] = new FunctionValue (new NativeConcat (), scope);
		scope["lower"] = new FunctionValue (new NativeLower (), scope);
		scope["upper"] = new FunctionValue (new NativeUpper (), scope);
		
		return scope;
	}
}