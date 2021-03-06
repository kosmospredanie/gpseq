/* CollectorFeatures.vala
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

namespace Gpseq {
	/**
	 * Hints that can be used to optimize collect operations.
	 */
	[Flags]
	public enum CollectorFeatures {
		/**
		 * Indicates that the accumulator returned by create_accumulator() can
		 * be accumulated concurrently from multiple threads.
		 */
		CONCURRENT,
		/**
		 * Indicates that the collector doesn't commit to preserving the
		 * encounter order of input elements. e.g. Set
		 */
		UNORDERED
	}
}
