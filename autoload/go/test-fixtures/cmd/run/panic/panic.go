package main

import (
	"errors"
	"fmt"
)

func quux() {
	panic(errors.New("quux"))
}

func main() {
	quux()
	fmt.Println("vim-go")
}
