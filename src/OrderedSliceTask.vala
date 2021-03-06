/* OrderedSliceTask.vala
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

namespace Gpseq {
	/**
	 * A fork-join task that performs an ordered slice operation.
	 */
	internal class OrderedSliceTask<G> : SpliteratorTask<ArrayBuffer<G>,G> {
		private const long CHECK_INTERVAL = 8192; // 1 << 13

		private int64 _skip; // never changed
		private int64 _limit; // never changed
		private AtomicInt64Val _size;
		private AtomicBoolVal _completed;

		/**
		 * Creates a new ordered slice task.
		 *
		 * @param skip the number of elements to skip
		 * @param limit maximum number of elements the spliterator may contain,
		 * or a negative value if unlimited
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public OrderedSliceTask (
				int64 skip, int64 limit,
				Spliterator<G> spliterator, OrderedSliceTask<G>? parent,
				int64 threshold, int max_depth, Executor executor)
		{
			base(spliterator, parent, threshold, max_depth, executor);
			if (limit >= 0 && skip > int64.MAX - limit) {
				error("skip + limit exceeds int64.MAX");
			}
			assert(limit < 0 || skip <= int64.MAX - limit);
			_skip = skip;
			_limit = limit;
			_size = new AtomicInt64Val(0);
			_completed = new AtomicBoolVal(false);
		}

		protected override ArrayBuffer<G> empty_result {
			owned get {
				return new ArrayBuffer<G>({});
			}
		}

		protected override ArrayBuffer<G> leaf_compute () throws Error {
			ArrayBuffer<G> buffer = _limit < 0 ? copy_elements() : copy_limited_elements();
			if (is_root) {
				buffer = chop(buffer);
				shared_result.value = buffer;
			} else {
				_size.val = buffer.size;
				_completed.val = true;
				check_target_size();
			}
			return buffer;
		}

		protected override ArrayBuffer<G> merge_results (
				owned ArrayBuffer<G> left, owned ArrayBuffer<G> right) throws Error {
			ArrayBuffer<G> array;
			int64 size = left.size + right.size;
			if (size == 0 || is_cancelled) {
				_size.val = 0;
				array = new ArrayBuffer<G>({});
			} else if (left.size == 0) {
				_size.val = size;
				array = right;
			} else {
				_size.val = size;
				array = new ConcatArrayBuffer<G>(left, right);
			}

			if (is_root) {
				array = chop(array);
				shared_result.value = array;
			} else {
				_completed.val = true;
				check_target_size();
			}
			return array;
		}

		protected override SpliteratorTask<ArrayBuffer<G>,G> make_child (Spliterator<G> spliterator) {
			var task = new OrderedSliceTask<G>(
					_skip, _limit,
					spliterator, this,
					threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}

		private void check_target_size () {
			if (_limit >= 0 && is_left_completed) {
				cancel_later_nodes();
			}
		}

		private ArrayBuffer<G> copy_elements () throws Error {
			int64 estimated_remaining = int64.max(0, spliterator.estimated_size);
			int size = estimated_remaining <= MAX_ARRAY_LENGTH ? (int)estimated_remaining : MAX_ARRAY_LENGTH;
			G[] array = new G[size];
			int i = 0;
			spliterator.each(g => {
				if (i >= MAX_ARRAY_LENGTH) {
					error("OrderedSliceTask exceeds max array length");
				} else if (i >= array.length) {
					int64 next_len = next_pot(i);
					if (next_len > MAX_ARRAY_LENGTH || next_len < 0) {
						next_len = (int64)MAX_ARRAY_LENGTH;
					}
					array.resize((int) next_len);
				}
				array[i++] = g;
			});
			if (array.length != i) array.resize(i);
			return new ArrayBuffer<G>((owned) array);
		}

		private ArrayBuffer<G> copy_limited_elements () throws Error {
			int64 estimated_remaining = int64.max(0, spliterator.estimated_size);
			int size = estimated_remaining <= MAX_ARRAY_LENGTH ? (int)estimated_remaining : MAX_ARRAY_LENGTH;
			G[] array = new G[size];
			int idx = 0;
			long chk = 0;
			spliterator.each_chunk(chunk => {
				for (int i = 0; i < chunk.length; i++) {
					if (idx >= MAX_ARRAY_LENGTH) {
						error("OrderedSliceTask exceeds max array length");
					} else if (idx >= array.length) {
						int64 next_len = next_pot(idx);
						if (next_len > MAX_ARRAY_LENGTH || next_len < 0) {
							next_len = (int64)MAX_ARRAY_LENGTH;
						}
						array.resize((int) next_len);
					}
					array[idx++] = chunk[i];
				}
				_size.val = idx;
				chk += chunk.length;
				if (chk > CHECK_INTERVAL) {
					chk = 0;
					if (is_cancelled || is_left_completed) {
						return false;
					}
				}
				return true;
			});
			if (array.length != idx) array.resize(idx);
			return new ArrayBuffer<G>((owned) array);
		}

		/**
		 * Finds next power of two, which is greater than and not equal to n.
		 * @return next power of two, which is greater than and not equal to n
		 */
		private inline int64 next_pot (int64 n) {
			n |= n >> 1;
			n |= n >> 2;
			n |= n >> 4;
			n |= n >> 8;
			n |= n >> 16;
			n |= n >> 32;
			return (n > int64.MAX - 1) ? -1 : ++n;
		}

		private ArrayBuffer<G> chop (ArrayBuffer<G> array) {
			int64 start = int64.min(array.size, _skip);
			int64 stop = _limit < 0 ? array.size : int64.min(array.size, _skip + _limit);
			return array.slice(start, stop);
		}

		private bool is_left_completed {
			get {
				// assume assert(_limit >= 0);
				int64 target = _skip + _limit;
				int64 size = _completed.val ? _size.val : calc_completed_size(target);
				if (size >= target) return true;
				OrderedSliceTask<G>? p = (OrderedSliceTask<G>?) parent;
				OrderedSliceTask<G> cur = this;
				while (p != null) {
					if (cur == p.right_child) {
						int64 amount = ((OrderedSliceTask<G>) p.left_child).calc_completed_size(target);
						if (size > int64.MAX - amount || size + amount >= target) return true;
						size += amount;
					}
					cur = p;
					p = (OrderedSliceTask<G>?) p.parent;
				}
				return size >= target;
			}
		}

		private int64 calc_completed_size (int64 target) {
			if (_completed.val) {
				return _size.val;
			} else {
				OrderedSliceTask<G>? left = (OrderedSliceTask<G>?) left_child;
				OrderedSliceTask<G>? right = (OrderedSliceTask<G>?) right_child;
				if (right == null) { // leaf node
					return _size.val;
				} else {
					int64 left_size = left.calc_completed_size(target);
					if (left_size >= target) {
						return left_size;
					} else {
						int64 amount = right.calc_completed_size(target);
						if (left_size > int64.MAX - amount) {
							return target;
						}
						return left_size + amount;
					}
				}
			}
		}
	}
}
