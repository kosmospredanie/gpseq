/* SumFloatCollector.vala
 *
 * Copyright (C) 2019-2020  Космическое П. (kosmospredanie@yandex.ru)
 *
 * This file is part of Gpseq.
 *
 * Gpseq is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * Gpseq is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Gpseq.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

private class Gpseq.Collectors.SumFloatCollector<G> : Object, Collector<float?,Accumulator,G> {
	private MapFunc<float?,G> _mapper;

	public SumFloatCollector (owned MapFunc<float?,G> mapper) {
		_mapper = (owned) mapper;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator create_accumulator () throws Error {
		return new Accumulator(0);
	}

	public void accumulate (G g, Accumulator a) throws Error {
		a.val += _mapper(g);
	}

	public Accumulator combine (Accumulator a, Accumulator b) throws Error {
		a.val += b.val;
		return a;
	}

	public float? finish (Accumulator a) throws Error {
		return a.val;
	}

	public class Accumulator : Object {
		public float val { get; set; }
		public Accumulator (float val) {
			_val = val;
		}
	}
}
