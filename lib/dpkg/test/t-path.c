/*
 * libdpkg - Debian packaging suite library routines
 * t-path.c - test path handling code
 *
 * Copyright © 2009 Guillem Jover <guillem@debian.org>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <config.h>
#include <compat.h>

#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>

#include <dpkg/test.h>
#include <dpkg/path.h>

/* Use the test_trim_eq_ref macro to avoid leaking the string and to get
 * meaningful line numbers from assert. */
#define test_trim_eq_ref(p, ref) \
do { \
	char *t = strdup((p)); \
	path_rtrim_slash_slashdot(t); \
	test_str(t, ==, (ref)); \
	free(t); \
} while (0)

static void
test_path_rtrim(void)
{
	test_trim_eq_ref("./././.", ".");
	test_trim_eq_ref("./././", ".");
	test_trim_eq_ref("./.", ".");
	test_trim_eq_ref("./", ".");
	test_trim_eq_ref("/./././.", "/");
	test_trim_eq_ref("/./", "/");
	test_trim_eq_ref("/.", "/");
	test_trim_eq_ref("/", "/");
	test_trim_eq_ref("", "");
	test_trim_eq_ref("/./../.", "/./..");
	test_trim_eq_ref("/foo/bar/./", "/foo/bar");
	test_trim_eq_ref("./foo/bar/./", "./foo/bar");
	test_trim_eq_ref("/./foo/bar/./", "/./foo/bar");
}

static void
test_path_skip(void)
{
	test_str(path_skip_slash_dotslash("./././."), ==, ".");
	test_str(path_skip_slash_dotslash("./././"), ==, "");
	test_str(path_skip_slash_dotslash("./."), ==, ".");
	test_str(path_skip_slash_dotslash("./"), ==, "");
	test_str(path_skip_slash_dotslash("/./././."), ==, ".");
	test_str(path_skip_slash_dotslash("/./"), ==, "");
	test_str(path_skip_slash_dotslash("/."), ==, ".");
	test_str(path_skip_slash_dotslash("/"), ==, "");
	test_str(path_skip_slash_dotslash("/./../."), ==, "../.");
	test_str(path_skip_slash_dotslash("/foo/bar/./"), ==, "foo/bar/./");
	test_str(path_skip_slash_dotslash("./foo/bar/./"), ==, "foo/bar/./");
	test_str(path_skip_slash_dotslash("/./foo/bar/./"), ==, "foo/bar/./");
}

static void
test_path_temp(void)
{
	char *template;

	template = path_make_temp_template("test");

	test_pass(strstr(template, "test") != NULL);
	test_pass(strstr(template, "XXXXXX") != NULL);

	free(template);
}

static bool
string_is_ascii(const char *str)
{
	while (*str) {
		if (!isascii(*str))
			return false;

		str++;
	}

	return true;
}

static void
test_path_quote(void)
{
	const char src_7_bit[] = "string with 7-bit chars only";
	const char src_7_bit_trim[] = "string with 7-bit chars";
	const char src_8_bit[] = "text w/ 8-bit chars: \\ \370 \300 \342 end";
	const char src_8_bit_end[] = "text \370";
	const char src_bs_end[] = "text \\";
	char *dst;
	size_t len;

	/* Test no quoting. */
	len = strlen(src_7_bit) + 1;
	dst = malloc(len);
	test_fail(dst == NULL);

	path_quote_filename(dst, src_7_bit, len);
	test_str(dst, ==, src_7_bit);
	free(dst);

	/* Test no quoting with limit. */
	len = strlen(src_7_bit_trim) + 1;
	dst = malloc(len);
	test_fail(dst == NULL);

	path_quote_filename(dst, src_7_bit, len);
	test_str(dst, ==, src_7_bit_trim);
	free(dst);

	/* Test normal quoting. */
	len = strlen(src_8_bit) * 2 + 1;
	dst = malloc(len);
	test_fail(dst == NULL);

	path_quote_filename(dst, src_8_bit, len);
	test_pass(strstr(dst, "end") != NULL);
	test_pass(string_is_ascii(dst));
	free(dst);

	/* Test normal quoting with limit. */
	len = strlen(src_8_bit_end) + 1 + 2;
	dst = malloc(len);
	test_fail(dst == NULL);

	path_quote_filename(dst, src_8_bit_end, len);
	test_str(dst, ==, "text ");
	free(dst);

	/* Test backslash quoting with limit. */
	len = strlen(src_bs_end) + 1;
	dst = malloc(len);
	test_fail(dst == NULL);

	path_quote_filename(dst, src_bs_end, len);
	test_str(dst, ==, "text ");
	free(dst);
}

static void
test(void)
{
	test_path_rtrim();
	test_path_skip();
	test_path_temp();
	test_path_quote();
}

