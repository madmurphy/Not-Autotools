dnl  **************************************************************************
dnl         _   _       _      ___        _        _              _     
dnl        | \ | |     | |    / _ \      | |      | |            | |    
dnl        |  \| | ___ | |_  / /_\ \_   _| |_ ___ | |_ ___   ___ | |___ 
dnl        | . ` |/ _ \| __| |  _  | | | | __/ _ \| __/ _ \ / _ \| / __|
dnl        | |\  | (_) | |_  | | | | |_| | || (_) | || (_) | (_) | \__ \
dnl        \_| \_/\___/ \__| \_| |_/\__,_|\__\___/ \__\___/ \___/|_|___/
dnl
dnl            A collection of useful m4-ish macros for GNU Autotools
dnl
dnl                                               -- Released under GNU GPL3 --
dnl
dnl                                  https://github.com/madmurphy/not-autotools
dnl  **************************************************************************



dnl  **************************************************************************
dnl  M 4 S U G A R   E X T E N S I O N S
dnl  **************************************************************************



dnl  n4_lambda(macro_body)
dnl  **************************************************************************
dnl
dnl  Creates an anonymous macro on the fly, able to be passed as a callback
dnl  argument
dnl
dnl  For example,
dnl
dnl      n4_lambda([Hi there! Here it's $1!])([Rose])
dnl
dnl  will print
dnl
dnl      Hi there! Here it's Rose!
dnl
dnl  Or, for instance, in the following code a lambda macro instead of a named
dnl  one is passed to `m4_map()`:
dnl
dnl      AC_DEFUN([MISSING_PROGRAMS], [[find], [xargs], [sed]])
dnl      AC_MSG_ERROR([Install first m4_map([n4_lambda(["$1", ])], [MISSING_PROGRAMS])then proceed.])
dnl
dnl  The code above will print:
dnl
dnl      Install first "find", "xargs", "sed", then proceed.
dnl
dnl  By using the `n4_anon` keyword, a lambda macro can invoke itself
dnl  repeatedly (recursion). For example,
dnl
dnl      AC_MSG_NOTICE([n4_lambda([m4_if(m4_eval([$2 > 0]), [1], [$1[]n4_anon([$1], m4_decr([$2]))])])([Repeat me!], 4)])
dnl
dnl  will print
dnl
dnl      Repeat me!Repeat me!Repeat me!Repeat me!
dnl
dnl  Alternatively you can use the `$0` shortcut, which expands to `n4_anon`:
dnl
dnl      AC_MSG_NOTICE([n4_lambda([m4_if(m4_eval([$2 > 0]), [1], [$1[]$0([$1], m4_decr([$2]))])])([Repeat me!], 4)])
dnl
dnl  The `n4_anon` keyword is available only from within the lambda macro body,
dnl  works in a stack-like fashion and is fully reentrant. Do not attempt to
dnl  redefine it yourself.
dnl
dnl  Lambda macros can be nested within each other:
dnl
dnl      n4_lambda([Hi there! n4_lambda([This is a nested lambda macro!])])
dnl
dnl  However, as with any other type of macro, reading the arguments of a
dnl  nested lambda macro might be difficult. Consider for example the following
dnl  code snippet:
dnl
dnl      n4_lambda([Hi there! Here it's $1! n4_lambda([And here it's $1!])([Charlie])])([Rose])
dnl
dnl  It will print:
dnl
dnl      Hi there! Here it's Rose! And here it's Rose!
dnl
dnl  This is because `$1` gets replaced with `Rose` before the nested macro's
dnl  arguments can expand. The only way to prevent this is to delay the
dnl  composition of `$` and `1`, so that the expansion of the argument happens
dnl  at a later time. Hence,
dnl
dnl      n4_lambda([Hi there! Here it's $1! n4_lambda([And here it's ][$][1][!])([Charlie])])([Rose])
dnl
dnl  will finally print:
dnl
dnl      Hi there! Here it's Rose! And here it's Charlie!
dnl
dnl  This applies also to other argument notations, such as `$#`, `$*` and
dnl  `#@`.
dnl
dnl  There is no particular limit in the level of nesting reachable, except
dnl  good coding practices. As an extreme example, consider the following
dnl  snippet, consisting of three lambda macros nested within each other, whose
dnl  innermost one is also recursive (the atypical M4 indentation is only for
dnl  clarity):
dnl
dnl      # Let's use `L()` as a shortcut for `n4_lambda()`...
dnl      m4_define([L], m4_defn([n4_lambda]))
dnl
dnl      L([
dnl          This is $1 L([
dnl              This is ][$][1][ L([
dnl                  {][$][1][}m4_if(m4_eval(][$][#][ > 1), [1],
dnl                      [n4_anon(m4_shift(]m4_quote(][$][@][)[))])
dnl                  ])([internal-1], [internal-2], [internal-3], [internal-4])
dnl              ])([central])
dnl      ])([external])
dnl
dnl  The example above will print something like this (plus some trailing
dnl  spaces due to the atypical indentation):
dnl
dnl      This is external 
dnl          This is central 
dnl              {internal-1}
dnl              {internal-2}
dnl              {internal-3}
dnl              {internal-4}
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl  Further reading: https://www.gnu.org/software/m4/manual/m4-1.4.18/html_node/Composition.html
dnl
dnl  **************************************************************************
m4_define([n4_lambda],
	[m4_pushdef([n4_anon], [$1])[]m4_pushdef([n4_anon], [m4_popdef([n4_anon])[]$1[]m4_popdef([n4_anon])])[]n4_anon])


dnl  n4_with(expand-val, expression)
dnl  **************************************************************************
dnl
dnl  Expands every occurrence of `n4_this` in `expression` with the computed
dnl  expansion of `expand-val`, ensuring that the latter is computed only once
dnl  regardless of the number of internal calls
dnl
dnl  For example:
dnl
dnl      n4_with([m4_eval(10 ** 3)],
dnl          [n4_this... n4_this...])
dnl
dnl          => 1000... 1000...
dnl
dnl  The `n4_this` keyword is fully reentrant and allows nested invocations of
dnl  `n4_with()`
dnl
dnl      n4_with([m4_eval(10 ** 3)],
dnl          [n4_this... n4_with([m4_eval(9 ** 3)], [n4_this... n4_this])... n4_this...])
dnl
dnl          => 1000... 729... 729... 1000...
dnl
dnl  From a quotation perspective, doing
dnl
dnl     n4_with([some text here],
dnl         [n4_this... n4_this...])
dnl
dnl  is exactly the same thing as doing
dnl
dnl     m4_unquote(m4_expand([some text here]))... m4_unquote(m4_expand([some text here]))...
dnl
dnl  The only difference is that the first example will be more efficient,
dnl  because `m4_unquote(m4_expand([some text here]))` is invoked only once and
dnl  stored in `n4_this` as a literal.
dnl
dnl  This macro is useful for expensive operations that would need otherwise to
dnl  be invoked repeatedly.
dnl
dnl  The keyword `n4_this` optionally supports the usage of temporary
dnl  arguments:
dnl
dnl      n4_with([text $1], [n4_this([a])... n4_this([b])...])
dnl          => text a... text b...
dnl
dnl  However, as these are expanded at a later stage, they cannot be used for
dnl  the purpose of creating a fully computed literal.
dnl
dnl      n4_with([m4_eval($1 + 5)], [n4_this(3)])
dnl          => m4:test.m4: bad expression in eval: $1 + 5
dnl
dnl  If, as a workaround, you tried to double quote `m4_eval()` in the example
dnl  above, the code _would_ work, but it would be computed on every invocation
dnl  of `n4_this`, loosing the efficiency advantage provided by this macro. The
dnl  following examples illustrate the different behavior of single and double
dnl  quotes in `n4_with()`.
dnl
dnl  Single quoting:
dnl
dnl      m4_define([counter], [0])
dnl
dnl      n4_with([m4_define([counter], m4_incr(counter))Hi!],
dnl          [n4_this n4_this n4_this n4_this n4_this n4_this])... counter
dnl
dnl          => Hi! Hi! Hi! Hi! Hi! Hi!... 1
dnl
dnl  Double quoting:
dnl
dnl      m4_define([counter], [0])
dnl
dnl      n4_with([[m4_define([counter], m4_incr(counter))Hi!]],
dnl          [n4_this n4_this n4_this n4_this n4_this n4_this])... counter
dnl
dnl          => Hi! Hi! Hi! Hi! Hi! Hi!... 6
dnl
dnl  If you need to store more than one value at a time, use `n4_let()` or
dnl  `n4_qlet()` instead of `n4_with()`
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_with],
	[m4_pushdef([n4_this], m4_expand([$1]))$2[]m4_popdef([n4_this])])


dnl  n4_let(macro-name1, expand-val1[, ... macro-nameN, expand-valN], expression)
dnl  **************************************************************************
dnl
dnl  Exactly like `n4_with()`, but allows to use infinite computed expansions
dnl  and give them names
dnl
dnl  This macro in fact creates a complete M4 scoping mechanism. See the
dnl  documentation of `n4_with()` for more information.
dnl
dnl  For example,
dnl
dnl      n4_let([AUTHOR],    [madmurphy],
dnl             [DATE],      [m4_esyscmd_s([date +%d/%m/%Y])],
dnl          [This text has been created by AUTHOR on DATE.])
dnl
dnl  will print:
dnl  
dnl      This text has been created by madmurphy on 25/09/2019.
dnl
dnl  In the example above the system call `date` will be invoked only once,
dnl  regardless of how many times the keyword `DATE` appears in `expression`.
dnl
dnl  As with `n4_with()`, scope nesting is fully supported. For example,
dnl
dnl      n4_let([AUTHOR],    [madmurphy],
dnl             [DATE],      [m4_esyscmd_s([date +%d/%m/%Y])],
dnl          [This text has been created by AUTHOR on DATE.
dnl
dnl          n4_let([AUTHOR],    [charlie],
dnl              [...Don't forget to write an email to the real author, AUTHOR!])
dnl
dnl              The real author is AUTHOR.])
dnl
dnl  will print:
dnl
dnl      This text has been created by madmurphy on 25/09/2019.
dnl
dnl          ...Don't forget to write an email to the real author, charlie!
dnl
dnl              The real author is madmurphy.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_let],
	[m4_if([$#], [1], [$1], [m4_pushdef([$1], m4_expand([$2]))n4_let(m4_shift2($@))[]m4_popdef([$1])])])


dnl  n4_qlet([name-val-pair1][, ... [name-val-pairN]], expression)
dnl  **************************************************************************
dnl
dnl  Exactly like `n4_let()`, but optionally tolerates each `name-valN` pair to
dnl  be surrounded by quotes (this macro is only for clarity)
dnl
dnl  For example,
dnl
dnl      n4_qlet([[AUTHOR],  [madmurphy]],
dnl              [[DATE],    [m4_esyscmd_s([date +%d/%m/%Y])]],
dnl          [This text has been created by AUTHOR on DATE.])
dnl
dnl  will print:
dnl
dnl      This text has been created by madmurphy on 25/09/2019.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: `n4_let()`
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_qlet],
	[n4_let(m4_reverse(m4_shift(m4_reverse($*))), m4_argn($#, $@))])


dnl  n4_case_in(text, list1, if-found1[, ... listN, if-foundN], [if-not-found])
dnl  **************************************************************************
dnl
dnl  Searches for the first occurence of `text` in each comma-separated list
dnl  `listN`
dnl
dnl  For example,
dnl
dnl      n4_case_in(NM_GET_AM_VAR([USER]),
dnl          [[rose], [madmurphy], [charlie]],
dnl              [Official release],
dnl              [Unofficial release])
dnl
dnl  will print "Official release" if the user who generated the `configure`
dnl  script was in the list above, or it will print "Unofficial release"
dnl  otherwise (for the `NM_GET_AM_VAR()` macro, see `not-automake.m4`).
dnl
dnl  This macro works exactly like `m4_case()`, but instead of looking for the
dnl  equality of a target string with one or more other strings, it checks
dnl  whether a target string is present in one or more given lists.
dnl
dnl  Here is a more articulated example:
dnl
dnl      n4_case_in(NM_GET_AM_VAR([USER]),
dnl          [[rose], [madmurphy], [lili], [frank]],
dnl              [Official release],
dnl          [[rick], [karl], [matilde]],
dnl              [Semi-official release],
dnl          [[jack], [charlie]],
dnl              [Offensive release],
dnl              [Unofficial release])
dnl
dnl  `n4_case_in()` has been designed to behave like `m4_case()` when a simple
dnl  string is passed instead of a list.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: Autoconf >= 2.62: for the `m4_cond()` macro -- see:
dnl  https://www.gnu.org/software/autoconf/manual/autoconf-2.62/html_node/Conditional-constructs.html
dnl  Author: madmurphy
dnl  Further reading: https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Conditional-constructs.html#index-m4_005fcase-1363
dnl
dnl  **************************************************************************
m4_define([n4_case_in],
	[m4_cond([m4_eval([$# < 2])], [1],
			[],
		[m4_argn([1], $2)], [$1],
			[$3],
		[m4_eval(m4_count($2)[ > 1])], [1],
			[n4_case_in([$1], m4_dquote(m4_shift($2)), m4_shift2($@))],
		[m4_eval([$# > 4])], [1],
			[n4_case_in([$1], m4_shift3($@))],
			[$4])])


dnl  n4_list_index(list, target, [add-to-return-value], [if-not-found])
dnl  **************************************************************************
dnl
dnl  Searches for the first occurence of `target` in the comma-separated list
dnl  `list` and returns its position, or `-1` if `target` has not been found
dnl
dnl  For example,
dnl
dnl      n4_list_index([[foo], [bar], [hello]],
dnl          [bar])
dnl
dnl  expands to `1`.
dnl
dnl  If the `add-to-return-value` argument is expressed (this accepts only
dnl  numbers, both positive and negative), it will be added to the returned
dnl  index -- if `target` has not been found and the `if-not-found` argument is
dnl  omitted, it will be added to `-1`.
dnl
dnl  If the `if-not-found` argument is expressed, it will be returned every
dnl  time `target` is not found. This argument accepts both numerical and
dnl  non-numerical values.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: Autoconf >= 2.62: for the `m4_cond()` macro -- see:
dnl  https://www.gnu.org/software/autoconf/manual/autoconf-2.62/html_node/Conditional-constructs.html
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_list_index],
	[m4_cond([m4_eval([$# < 2])], [1],
			[-1],
		[m4_argn(1, $1)], [$2],
			[m4_eval([$3 + 0])],
		[m4_eval(m4_count($1)[ > 1])], [1],
			[n4_list_index(m4_dquote(m4_shift($1)), [$2], m4_eval([$3 + 1]), m4_if(m4_eval([$# > 3]), [1], [$4], [m4_eval([$3 - 1])]))],
		[m4_eval([$# > 3])], [1],
			[$4],
			[m4_eval([$3 - 1])])])


dnl  n4_define_substrings_as(string, regexp, macro0[, macro1[, ... macroN ]])
dnl  **************************************************************************
dnl
dnl  Searches for the first match of `regexp` in `string` and defines custom
dnl  macros accordingly
dnl
dnl  For both the entire regular expression `regexp` (`\0`) and each
dnl  sub-expression within capturing parentheses (`\1`, `\2`, `\3`, ... , `\N`)
dnl  a macro expanding to the corresponding matching text will be created,
dnl  named according to the argument `macroN` passed. If a `macroN` argument is
dnl  omitted or empty, the corresponding parentheses in the regular expression
dnl  will be considered as non-capturing. If `regexp` cannot be found in
dnl  `string` no macro will be defined. If `regexp` can be found but some of
dnl  its capturing parentheses cannot, the macro(s) corresponding to the latter
dnl  will be defined as empty strings.
dnl
dnl  Example -- Get the current version string from a file named `VERSION`:
dnl
dnl      n4_define_substrings_as(
dnl          m4_quote(m4_include([VERSION])),
dnl          [\([0-9]+\)\.\([0-9]+\)\.\([0-9]+\)],
dnl          [VERSION_STR], [VERSION_MAJ], [VERSION_MIN], [VERSION_REV]      
dnl      )
dnl      AC_INIT([foo], VERSION_MAJ[.]VERSION_MIN[.]VERSION_REV)
dnl
dnl  Due to limitations of M4's native implementation of regular expressions
dnl  it is not possible to define more than 10 macros at a time.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal (void)
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_define_substrings_as],
	[m4_bregexp([$1], [$2],
		m4_if([$3], [], [],
			[[m4_define(m4_normalize([$3]), [m4_quote(\&)])]])[]m4_if(m4_eval([$# > 3]), [1],
			[m4_for([_idx_], [1], [$# - 3], [1],
				[m4_if(m4_normalize(m4_argn(_idx_, m4_shift3($@))), [], [],
					[[m4_define(m4_normalize(m4_argn(]_idx_[, m4_shift3($@))), m4_quote(\]_idx_[))]])])]))])


dnl  n4_repeat(n_times, text)
dnl  **************************************************************************
dnl
dnl  Repeats `text` `n_times`
dnl
dnl  Every occurrence of `$#` within `text` will be replaced with the current
dnl  index. For example,
dnl
dnl      n4_repeat([4], [foo $#...])
dnl
dnl  will expand to
dnl
dnl      foo 1...foo 2...foo 3...foo 4...
dnl
dnl  If `n4_repeat()` is invoked from within a macro body, `$#` will be
dnl  replaced with higher priority with the current macro's number of
dnl  arguments. For instance,
dnl
dnl      m4_define([print_foo], [n4_repeat([4], [foo $#...])])
dnl      print_foo
dnl
dnl  will expand to
dnl
dnl      foo 0...foo 0...foo 0...foo 0...
dnl
dnl  Therefore, in order to inhibit the immediate expansion of `$#` it is
dnl  necessary temporarily to break its components, as in the following
dnl  example,
dnl
dnl      m4_define([print_foo], [n4_repeat([4], [foo ][$][#][...])])
dnl      print_foo
dnl
dnl  which will finally expand to
dnl
dnl      foo 1...foo 2...foo 3...foo 4...
dnl
dnl  This applies also to macro calls. For example,
dnl
dnl      m4_define([even_numbers],
dnl          [(0)n4_repeat([$1], [, m4_eval(][$][#][ * 2)])])
dnl
dnl      Even numbers: even_numbers([10]) ...
dnl
dnl  will expand to
dnl
dnl      Even numbers: (0), 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 ...
dnl
dnl  However, for complex cases it is suggested to use `m4_for()`.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_repeat],
	[m4_if(m4_eval([$1 > 0]), [1],
		[n4_repeat(m4_decr([$1]), [$2])[]m4_bpatsubst([$2], [\$][#], [$1])])])


dnl  n4_redepth(regexp)
dnl  **************************************************************************
dnl
dnl  Examines a regular expression and returns the number of capturing
dnl  parentheses present
dnl
dnl  The returned number is the highest available sub-match that can be written
dnl  as `\[number]` during a replacement
dnl
dnl  For example,
dnl
dnl      n4_redepth([\([0-9]+\)\.\([0-9]+\)\.\([0-9]+\)])
dnl
dnl  expands to `3`.
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_redepth],
	[m4_len(m4_bpatsubst(m4_bpatsubst([$1], [\(\\\|)\|\([^\\]\|^\)\(\\\\\)*(\)\|\(\\\)(\|,], [\4]), [[^\\]], []))])


dnl  n4_for_each_match(string, regexp, macro)
dnl  **************************************************************************
dnl
dnl  Calls the custom macro `macro` for every occurrence of `regexp` in
dnl  `string`
dnl
dnl  The text that matches the entire `regexp` and all the sub-strings that
dnl  match its capturing parentheses will be passed to `macro` as arguments.
dnl
dnl  For example,
dnl
dnl      AC_DEFUN([custom_macro], [...foo $1|$2|$3|$4 bar])
dnl      AC_MSG_NOTICE([n4_for_each_match([blaablabblac], [\(b\(l\)\)\(a\)], [custom_macro])])
dnl
dnl  will print:
dnl
dnl      ...foo bla|bl|l|a bar...foo bla|bl|l|a bar...foo bla|bl|l|a bar
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: `n4_redepth()`
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_for_each_match],
	[m4_if(m4_bregexp([$1], [$2]), [-1], [],
		[m4_bregexp([$1], [$2], [[]$3([\&]]m4_quote(m4_for([_idx_], [1], n4_redepth([$2]), [1], [, \_idx_]))[)])[]n4_for_each_match(m4_substr([$1], m4_eval(m4_bregexp([$1], [$2]) + m4_len(m4_bregexp([$1], [$2], [\&])))), [$2], [$3])])])


dnl  n4_get_replacements(string, regexp, macro)
dnl  **************************************************************************
dnl
dnl  Replaces every occurrence of `regexp` in `string` with the text returned
dnl  by the custom macro `macro`, invoked for each match
dnl
dnl  The text that matches the entire `regexp` and all the sub-strings that
dnl  match its capturing parentheses will be passed to `macro` as arguments.
dnl
dnl  For example,
dnl
dnl      AC_DEFUN([custom_macro], [XX$3])
dnl      AC_MSG_NOTICE([n4_get_replacements([hello you world!!], [\(l\|w\)+\(o\)], [custom_macro])])
dnl
dnl  will print:
dnl
dnl      heXXo you XXorld!!
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: `n4_redepth()`
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_get_replacements],
	[m4_if(m4_bregexp([$1], [$2]), [-1], [$1],
		[m4_bpatsubst([$1], [$2], [[]$3([\&]]m4_quote(m4_for([_idx_], [1], n4_redepth([$2]), [1], [, \_idx_]))[)])])])


dnl  n4_burn_out(string1[, string2[, ... stringN]])
dnl  **************************************************************************
dnl
dnl  Recursive and variadic version of `m4_expand()`
dnl
dnl  The strings passed as arguments will be expanded and stripped of all their
dnl  quotes until there will be no more expansions left.
dnl
dnl  For example,
dnl
dnl      m4_define([WTF], [a test])
dnl      n4_burn_out([[[[[This is [[[WTF]]]. Bye!]]]]])
dnl
dnl  expands to:
dnl
dnl      This is a test. Bye!
dnl
dnl  As with `m4_expand()`, in order to preserve the spaces that follow a
dnl  comma, after all possible expansions have been burned out a layer of
dnl  quotes is added to the final string returned. If you want to remove it,
dnl  please use `m4_unquote()`. The following examples illustrate it:
dnl
dnl      n4_burn_out([Hi, how [[[[are]]]] [[you]]?])
dnl          => Hi, how are you?
dnl
dnl      m4_count(n4_burn_out([Hi, how [[[[are]]]] [[you]]?]))
dnl          => 1
dnl
dnl      m4_count(m4_unquote(n4_burn_out([Hi, how [[[[are]]]] [[you]]?])))
dnl          => 2
dnl
dnl  This macro can be invoked before `AC_INIT()`.
dnl
dnl  Expansion type: literal
dnl  Requires: nothing
dnl  Author: madmurphy
dnl
dnl  **************************************************************************
m4_define([n4_burn_out],
	[m4_pushdef([_tmp_], m4_dquote(m4_expand(m4_expand([$*]))))[]m4_if(($*), (_tmp_), [_tmp_[]m4_popdef([_tmp_])], [n4_burn_out(_tmp_[]m4_popdef([_tmp_]))])])



dnl  **************************************************************************
dnl  Note:  The `n4_` prefix (which stands for "Not m4sugar") is used with the
dnl         purpose of avoiding collisions with the default Autotools prefix
dnl         `m4_`.
dnl  **************************************************************************



dnl  EOF

