/* UtilsTests.vala
 *
 * Copyright (C) 2019  Космос Преда́ние (kosmospredanie@yandex.ru)
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

using Gpseq;
using Gpseq.Overflow;
using TestUtils;

public class UtilsTests : Gpseq.TestSuite {
	private const int MANY_SORT_LENGTH = 32768;

	public UtilsTests () {
		base("gpseq-utils");
		add_test("parallel_sort<int>:few", test_parallel_sort_ints_few);
		add_test("parallel_sort<int?>:few", test_parallel_sort_nullable_ints_few);
		add_test("parallel_sort<int>:many", test_parallel_sort_ints_many);
		add_test("parallel_sort<int?>:many", test_parallel_sort_nullable_ints_many);
		add_test("parallel_sort<string>:few", test_parallel_sort_strings_few);
		add_test("parallel_sort<string?>:few", test_parallel_sort_nullable_strings_few);
		add_test("parallel_sort<unowned string>:few", test_parallel_sort_unowned_strings_few);
		add_test("parallel_sort:check-stable", test_parallel_sort_stable);
		add_test("task", test_task);
		add_test("overflow:int", test_overflow_int);
		add_test("overflow:long", test_overflow_long);
		add_test("overflow:int32", test_overflow_int32);
		add_test("overflow:int64", test_overflow_int64);
	}

	private void test_parallel_sort_ints_few () {
		GenericArray<int> array = new GenericArray<int>(11);
		array.add(1010);
		array.add(99);
		array.add(88);
		array.add(77);
		array.add(66);
		array.add(55);
		array.add(44);
		array.add(33);
		array.add(22);
		array.add(11);
		array.add(0);

		parallel_sort<int>(array.data).value;

		assert( array[0] == 0 );
		assert( array[1] == 11 );
		assert( array[2] == 22 );
		assert( array[3] == 33 );
		assert( array[4] == 44 );
		assert( array[5] == 55 );
		assert( array[6] == 66 );
		assert( array[7] == 77 );
		assert( array[8] == 88 );
		assert( array[9] == 99 );
		assert( array[10] == 1010 );
	}

	private void test_parallel_sort_nullable_ints_few () {
		int?[] array = {null, 1010, 99, 88, 77, 66, 55, 44, 33, 22, 11, 0, null};
		parallel_sort<int?>(array, (a, b) => compare_nullable_int(a, b)).value;

		assert( array[0] == null );
		assert( array[1] == null );
		assert( array[2] == 0 );
		assert( array[3] == 11 );
		assert( array[4] == 22 );
		assert( array[5] == 33 );
		assert( array[6] == 44 );
		assert( array[7] == 55 );
		assert( array[8] == 66 );
		assert( array[9] == 77 );
		assert( array[10] == 88 );
		assert( array[11] == 99 );
		assert( array[12] == 1010 );
	}

	private void test_parallel_sort_ints_many () {
		GenericArray<int> array = new GenericArray<int>(MANY_SORT_LENGTH);
		for (int i = 0; i < MANY_SORT_LENGTH; i++) {
			array.add( Random.int_range(0, MANY_SORT_LENGTH) );
		}
		parallel_sort<int>(array.data).value;
		assert_sorted<int>(array.data);
		assert_all_elements<int>(array.data, g => (0 <= g < MANY_SORT_LENGTH));
	}

	private void test_parallel_sort_nullable_ints_many () {
		int?[] array = new int?[MANY_SORT_LENGTH];
		for (int i = 0; i < MANY_SORT_LENGTH; i++) {
			array[i] = Random.int_range(0, MANY_SORT_LENGTH);
		}
		parallel_sort<int?>(array, (a, b) => compare_nullable_int(a, b)).value;
		assert_sorted<int?>(array, compare_nullable_int);
		assert_all_elements<int?>(array, g => (0 <= g < MANY_SORT_LENGTH));
	}

	private void test_parallel_sort_strings_few () {
		string[] array = {
			"one", "two", "three", "four", "five",
			"six", "seven", "eight", "nine", "ten",
			"eleven", "twelve", "0", "1", "10"
		};
		parallel_sort<string>(array).value;

		assert(array[0] == "0");
		assert(array[1] == "1");
		assert(array[2] == "10");
		assert(array[3] == "eight");
		assert(array[4] == "eleven");
		assert(array[5] == "five");
		assert(array[6] == "four");
		assert(array[7] == "nine");
		assert(array[8] == "one");
		assert(array[9] == "seven");
		assert(array[10] == "six");
		assert(array[11] == "ten");
		assert(array[12] == "three");
		assert(array[13] == "twelve");
		assert(array[14] == "two");
	}

	private void test_parallel_sort_nullable_strings_few () {
		string?[] array = {
			null, "one", "two", "three", "four", "five",
			"six", "seven", "eight", "nine", "ten",
			"eleven", "twelve", "0", "1", "10", null
		};
		parallel_sort<string?>(array).value;

		assert(array[0] == null);
		assert(array[1] == null);
		assert(array[2] == "0");
		assert(array[3] == "1");
		assert(array[4] == "10");
		assert(array[5] == "eight");
		assert(array[6] == "eleven");
		assert(array[7] == "five");
		assert(array[8] == "four");
		assert(array[9] == "nine");
		assert(array[10] == "one");
		assert(array[11] == "seven");
		assert(array[12] == "six");
		assert(array[13] == "ten");
		assert(array[14] == "three");
		assert(array[15] == "twelve");
		assert(array[16] == "two");
	}

	private void test_parallel_sort_unowned_strings_few () {
		(unowned string)[] array = {
			"one", "two", "three", "four", "five",
			"six", "seven", "eight", "nine", "ten",
			"eleven", "twelve", "0", "1", "10"
		};
		parallel_sort<unowned string>(array).value;

		assert(array[0] == "0");
		assert(array[1] == "1");
		assert(array[2] == "10");
		assert(array[3] == "eight");
		assert(array[4] == "eleven");
		assert(array[5] == "five");
		assert(array[6] == "four");
		assert(array[7] == "nine");
		assert(array[8] == "one");
		assert(array[9] == "seven");
		assert(array[10] == "six");
		assert(array[11] == "ten");
		assert(array[12] == "three");
		assert(array[13] == "twelve");
		assert(array[14] == "two");
	}

	private void test_parallel_sort_stable () {
		var array = new GenericArray<Wrapper<int>>(MANY_SORT_LENGTH * 2);
		var validation = new GenericArray<Wrapper<int>>(MANY_SORT_LENGTH * 2);
		for (int i = 0; i < MANY_SORT_LENGTH; i++) {
			var obj = new Wrapper<int>(0);
			array.add(obj);
			validation.add(obj);
			obj = new Wrapper<int>((int) Random.next_int());
			array.add(obj);
			validation.add(obj);
		}
		CompareDataFunc<Wrapper<int>> cmp = (a, b) => {
			int v0 = a.value;
			int v1 = b.value;
			return v0 < v1 ? -1 : (v0 == v1 ? 0 : 1);
		};
		parallel_sort<Wrapper<int>>(array.data, (a, b) => cmp(a, b)).value;
		// g_ptr_array_sort_with_data is guaranteed to be a stable sort since glib 2.32
		validation.sort_with_data((a, b) => cmp(a, b));
		assert_array_equals<Wrapper<int>>(array.data, validation.data, (a, b) => a == b);
	}

	private void test_task () {
		var future = Gpseq.task<int>(() => 726);
		assert(future.value == 726);
		assert(future.exception == null);
	}

	private void test_overflow_int () {
		int val;
		assert( !int_add(1, 2, out val) );
		assert(val == 3);
		assert( int_add(int.MAX, 1, out val) );
		assert(val == int.MIN);

		assert( !int_sub(1, 2, out val) );
		assert(val == -1);
		assert( int_sub(int.MIN, 1, out val) );
		assert(val == int.MAX);

		assert( !int_mul(1, 2, out val) );
		assert(val == 2);
		assert( !int_mul(int.MAX, -1, out val) );
		assert(val == -int.MAX);
		assert( int_mul(int.MAX, 2, out val) );
		assert(val == -2);
		assert( int_mul(int.MAX, int.MAX, out val) );
		assert( int_mul(int.MAX, -int.MAX, out val) );
		assert( int_mul(-int.MAX, int.MAX, out val) );
		assert( int_mul(-int.MAX, -int.MAX, out val) );
	}

	private void test_overflow_long () {
		long val;
		assert( !long_add(1, 2, out val) );
		assert(val == 3);
		assert( long_add(long.MAX, 1, out val) );
		assert(val == long.MIN);

		assert( !long_sub(1, 2, out val) );
		assert(val == -1);
		assert( long_sub(long.MIN, 1, out val) );
		assert(val == long.MAX);

		assert( !long_mul(1, 2, out val) );
		assert(val == 2);
		assert( !long_mul(long.MAX, -1, out val) );
		assert(val == -long.MAX);
		assert( long_mul(long.MAX, 2, out val) );
		assert(val == -2);
		assert( long_mul(long.MAX, long.MAX, out val) );
		assert( long_mul(long.MAX, -long.MAX, out val) );
		assert( long_mul(-long.MAX, long.MAX, out val) );
		assert( long_mul(-long.MAX, -long.MAX, out val) );
	}

	private void test_overflow_int32 () {
		int32 val;
		assert( !int32_add(1, 2, out val) );
		assert(val == 3);
		assert( int32_add(int32.MAX, 1, out val) );
		assert(val == int32.MIN);

		assert( !int32_sub(1, 2, out val) );
		assert(val == -1);
		assert( int32_sub(int32.MIN, 1, out val) );
		assert(val == int32.MAX);

		assert( !int32_mul(1, 2, out val) );
		assert(val == 2);
		assert( !int32_mul(int32.MAX, -1, out val) );
		assert(val == -int32.MAX);
		assert( int32_mul(int32.MAX, 2, out val) );
		assert(val == -2);
		assert( int32_mul(int32.MAX, int32.MAX, out val) );
		assert( int32_mul(int32.MAX, -int32.MAX, out val) );
		assert( int32_mul(-int32.MAX, int32.MAX, out val) );
		assert( int32_mul(-int32.MAX, -int32.MAX, out val) );
	}

	private void test_overflow_int64 () {
		int64 val;
		assert( !int64_add(1, 2, out val) );
		assert(val == 3);
		assert( int64_add(int64.MAX, 1, out val) );
		assert(val == int64.MIN);

		assert( !int64_sub(1, 2, out val) );
		assert(val == -1);
		assert( int64_sub(int64.MIN, 1, out val) );
		assert(val == int64.MAX);

		assert( !int64_mul(1, 2, out val) );
		assert(val == 2);
		assert( !int64_mul(int64.MAX, -1, out val) );
		assert(val == -int64.MAX);
		assert( int64_mul(int64.MAX, 2, out val) );
		assert(val == -2);
		assert( int64_mul(int64.MAX, int64.MAX, out val) );
		assert( int64_mul(int64.MAX, -int64.MAX, out val) );
		assert( int64_mul(-int64.MAX, int64.MAX, out val) );
		assert( int64_mul(-int64.MAX, -int64.MAX, out val) );
	}
}
