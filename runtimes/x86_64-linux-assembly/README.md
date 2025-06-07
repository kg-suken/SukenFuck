# x86\_64 Linux用アセンブリ製インタプリタ

## アセンブル方法
```bash
nasm -f elf64 -o sukenfuck.o sukenfuck.asm
ld -s -o sukenfuck sukenfuck.o
```

## 実行方法
引数にプログラムのファイル名を指定するか実行後に標準入力からプログラムを入力することで実行できます
```
./sukenfuck program.sf
cat program.sf | ./sukenfuck
```

## 制作
**DETERMINATION**

---
バグなどあればissueにてご連絡ください
