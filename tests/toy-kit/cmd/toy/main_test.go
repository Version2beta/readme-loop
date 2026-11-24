package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	cases := []struct {
		args       []string
		in, out    string
		code       int
		errContain string
	}{
		{[]string{"slug"}, "Hello World\nGo!\n", "hello-world\ngo\n", 0, ""},
		{[]string{"wrap", "5"}, "aa bb cc", "aa bb\ncc\n", 0, ""},
		{[]string{"wrap", "x"}, "", "", 2, "toy: width must be a positive integer"},
		{nil, "", "", 2, "usage: toy slug | toy wrap N"},
	}
	for _, c := range cases {
		var o, e bytes.Buffer
		code := run(c.args, strings.NewReader(c.in), &o, &e)
		if code != c.code || o.String() != c.out || !strings.Contains(e.String(), c.errContain) {
			t.Errorf("run(%v) = %d, out %q, err %q; want %d, %q, containing %q", c.args, code, o.String(), e.String(), c.code, c.out, c.errContain)
		}
	}
}
