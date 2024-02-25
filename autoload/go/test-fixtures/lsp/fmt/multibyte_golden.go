package main

import "fmt"

func main() {
	fmt.Println("vim-go") // 中      asdfasdf
	fmt.Println("vim-go") // 中
	fmt.Println("vim-go") // 中a
	fmt.Println("vim-go") // 中 	a
	fmt.Println("vim-go") // 中

	fmt.Println("vim-go") // ⌘      asdfasdf
	fmt.Println("vim-go") // ⌘
	fmt.Println("vim-go") // ⌘ a
	fmt.Println("vim-go") // ⌘  	a
	fmt.Println("vim-go") // ⌘

	fmt.Println("vim-go") // é      asdfasdf
	fmt.Println("vim-go") // é
	fmt.Println("vim-go") // é a
	fmt.Println("vim-go") // é  	a
	fmt.Println("vim-go") // é

}
