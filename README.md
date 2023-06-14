# Documentarian

[![Build Status][icon]][status]

[icon]: https://github.com/pyrmont/documentarian/workflows/build/badge.svg
[status]: https://github.com/pyrmont/documentarian/actions?query=workflow%3Abuild

Documentarian is a minimal documentation generation tool for Janet projects.

Documentarian makes it easy to take the docstrings you've already written for
your code and turn them into a simple Markdown-formatted document. This document
can be included in your repository and read easily on services like GitHub.

## Requirements

Documentarian depends on your project having a `project.janet` file that
contains a `:name` key in the `declare-project` form and a `:source` key in
either the `declare-source` or `declare-native` forms. The `:source` key can be
associated with individual files or a directory containing Janet files.

Since the API document is generated in Markdown, you can include Markdown in
your docstrings. Don't forget that Janet supports `` ` ``-delimited
[long strings][ls] in addition to regular `"`-delimited strings. Long strings
preserve whitespace (including newlines) which can be used to create lists,
headings and code blocks.

[ls]: https://janet-lang.org/docs/strings.html

### Installing

To install run:

```console
$ jpm install https://github.com/pyrmont/documentarian
```

## Usage

```console
$ /path/to/documentarian
```

By default, your documentation is saved to a file called `api.md` in the
current working directory.

Documentarian includes a simple template that is used to produce the `api.md`
file. You can specify your own template file using the `-t` command-line
argument (see below). The file must be in the [Mustache templating
language][mustache]. Documentarian processes the template using [Musty][].
Please note that Musty is an incomplete implementation and does not support the
more advanced features of Mustache.

[mustache]: http://mustache.github.io
[Musty]: https://github.com/pyrmont/musty

### Command-Line Arguments

Documentarian supports the following command-line arguments:

```
 -d, --defix <prefix>       Remove prefix from all namespaces.
 -e, --echo                 Output to stdout rather than output file.
 -i, --input <path>         Use <path> as project file.
 -o, --output <path>        Use <path> as output file.
 -p, --private              Include private values in output.
 -l, --link-parent <url>    Replace project root with <url> in source code links.
 -t, --template <path>      Use template at <path> for output.
 -h, --help                 Show this help message.
```

## Development

### Preparing

Clone the repository and then run:

```console
$ jpm [-l] run dev-deps
```

### Building

```console
$ jpm [-l] build
```

### Testing

```console
$ jpm [-l] test
```

## Bugs

Found a bug? I'd love to know about it. The best way is to report your bug in
the [Issues][] section on GitHub.

[Issues]: https://github.com/pyrmont/documentarian/issues

## Licence

Documentarian is licensed under the MIT Licence. See [LICENSE][] for more
details.

[LICENSE]: https://github.com/pyrmont/documentarian/blob/master/LICENSE

## Thanks

Special thanks to Andrew Chambers ([@andrewchambers][]) and Zach Smith
([@subsetpark][]) for their feedback and suggestions.

[@andrewchambers]: https://github.com/andrewchambers
[@subsetpark]: https://github.com/subsetpark
