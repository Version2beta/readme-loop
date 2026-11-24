// Command toy reads stdin and prints either the slug of each line
// (`toy slug`) or the whole input wrapped (`toy wrap N`).
package main

import (
	"io"
	"os"
)

// run is the testable entry point. It returns the exit code.
func run(args []string, in io.Reader, out, errw io.Writer) int { return 0 }

func main() { os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr)) }
