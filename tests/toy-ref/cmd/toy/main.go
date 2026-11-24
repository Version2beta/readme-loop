// Command toy reads stdin and prints either the slug of each line
// (`toy slug`) or the whole input wrapped (`toy wrap N`).
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strconv"

	"example.com/toy/slug"
	"example.com/toy/wrap"
)

// run is the testable entry point. It returns the exit code.
func run(args []string, in io.Reader, out, errw io.Writer) int {
	switch {
	case len(args) == 1 && args[0] == "slug":
		sc := bufio.NewScanner(in)
		for sc.Scan() {
			fmt.Fprintln(out, slug.Slugify(sc.Text()))
		}
		return 0
	case len(args) == 2 && args[0] == "wrap":
		n, err := strconv.Atoi(args[1])
		if err != nil || n < 1 {
			fmt.Fprintln(errw, "toy: width must be a positive integer")
			return 2
		}
		b, _ := io.ReadAll(in)
		s, _ := wrap.Wrap(string(b), n)
		fmt.Fprintln(out, s)
		return 0
	}
	fmt.Fprintln(errw, "usage: toy slug | toy wrap N")
	return 2
}

func main() { os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr)) }
