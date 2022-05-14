# MyST markdown

Manuel was originally written for reStructuredText.
Starting with the {mod}`manuel.codeblock` module, Manuel will successively be extended for MyST, a Markdown flavor.
[Read about `MyST`](https://myst-parser.readthedocs.io/en/latest/).

## Code Blocks

Sphinx and other docutils extensions provide a `code-block` directive, which allows inlined snippets of code in MyST documents.

Several plug-ins are included that provide new test syntax (see
{ref}`functionality`).
You can also create your own plug-ins.

For example, if you've ever wanted to include a large chunk of Python in a
doctest but were irritated by all the `>>>` and `...` prompts required, you'd
like the {mod}`manuel.myst.codeblock` module.
It lets you execute code using MyST-style code block directives containing unpolluted Python code.
The markup looks like this:

    ```python
    import foo

    def my_func(bar):
        return foo.baz(bar)
    ```


To get Manuel wired up, see {ref}`getting-started`.
To run doctests in MyST, use {mod}`manuel.myst.codeblock`.

The scope of variables spans across the complete document.

```python
a = 3

# another variable
b = 2 * 3
```

The variables `a` and `b` can be used in the subsequent code block.

```python
assert b == 6
```

For better test feedback, you can use the methods of [`unittest.TestCase`](https://docs.python.org/3/library/unittest.html#unittest.TestCase.assertEqual). 

```python
self.assertEqual(b, 6)
```

The output of `self.assertEqual(b, 9999)` would be the following.

```console
AssertionError: 6 != 9999
```

You can even write code in invisible code blocks.
Invisible code blocks do not show up in the rendered documentation.
Using MyST syntax, lines that start with `%` are comments.
The markup looks like this:

    % invisible-code-block: python
    %
    % self.assertEqual(a+b, 9)
    %
    % self.assertEqual(7 * a, 21)


% invisible-code-block: python
%
% self.assertEqual(a+b, 9)
%
% self.assertEqual(7 * a, 21)

Invisible code blocks are tested like normal code blocks.

Happy hacking!
