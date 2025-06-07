program_size equ 1024               ;読み込むプログラムの最大サイズ
memory_size equ 30000               ;brainfuckの実行時に使うメモリのサイズ(最低30000個らしい)

section .data
    errormsg db "ファイルの読み込みに失敗しました", 0x0a
    errormsg_len equ $ - errormsg
    memory_err_msg db "メモリアクセス違反が発生しました", 0x0a, "プログラムを終了します", 0x0a
    memory_err_msg_len equ $ - memory_err_msg
    sigsegv_msg db "セグメンテーション違反が発生しました", 0x0a, "プログラムを終了します", 0x0a
    sigsegv_msg_len equ $ - sigsegv_msg

    sigaction_struct:
        dq sigsegv_handler
        dq 0x04000000               ;SA_RESTORER
        dq sigreturn
        dq 0

section .bss
    termios_old resb 60             ;ターミナル設定を保存するバッファ
    termios_raw resb 60             ;rawモードの設定を作るバッファ
    program resb program_size       ;brainfuckプログラムを格納するメモリ
    memory resb memory_size         ;brainfuckの実行時に使うメモリ
    memory_end:
 
section .text
    global _start
_start:
    ;コマンドライン引数の取得
    pop rdi                         ;スタックの一番上に引数の個数(argc)がある
    cmp rdi, 1
    jle input_program               ;引数が与えられなかったら標準入力からプログラムの入力を受け付ける

    pop rdi                         ;引数一つ目のポインタ
    pop rdi                         ;二つ目の引数のポインタ

    ;ファイルを開く
    mov rax, 2                      ;sys_open
    ;rdiにファイルディスクリプタ
    xor rsi, rsi                    ;read only
    syscall                         ;raxにファイルディスクリプタが入る
    mov r8, rax
    cmp rax, 0
    js load_error                   ;失敗したらraxが負になる

    ;ファイルの読み込み
    mov rdi, rax
    xor rax, rax
    mov rsi, program
    mov rdx, program_size
    syscall

    ;ファイルを閉じる
    mov rax, 3
    mov rdi, r8
    syscall

    jmp exec

input_program:
    mov rax, 0
    mov rdi, 0
    mov rsi, program
    mov rdx, program_size
    syscall

    jmp exec

exec:

    ;現在のターミナル設定を取得して保存する
    mov rax, 16                     ;sys_ioctl
    xor rdi, rdi                    ;stdin
    mov rsi, 0x5401                 ;tsgets
    mov rdx, termios_old
    syscall

    ;termios_oldをtermios_rawにコピーする
    xor rcx, rcx
    mov rsi, termios_old
    mov rdi, termios_raw
copy_loop:
    mov eax, [rsi]                  ;60バイトが8で割り切れないから4バイトずつコピーする
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    inc rcx
    cmp rcx, 15
    jl copy_loop

    ;rawモードの設定を作る
    lea rbx, [termios_raw + 12]     ;c_flag
    mov dword eax, [rbx]
    add eax, 0xfffffff5             ;ICANONとECHOを無効にする
    mov dword [rbx], eax

    ;途中でセグメンテーション違反が起こってもターミナルのモードを戻せるようにシグナルハンドラを設定する
    mov rax, 13                     ;sys_rt_sigaction
    mov rdi, 11                     ;SIGSEGV
    mov rsi, sigaction_struct       ;sigaction構造体
    mov rdx, 0                      ;oldact(不要)
    mov r10, 8                      ;sigsetsize(無視されるがとりあえず8)
    syscall

    ;rawモードの設定を適用する
    mov rax, 16                     ;sys_ioctl
    xor rdi, rdi                    ;atdin
    mov rsi, 0x5402                 ;tcsets
    mov rdx, termios_raw
    syscall

    mov r15, program
    mov r14, memory
loop:
    mov ax, [r15]
    cmp ax, "е"
    je increment_pointer
    cmp ax, "ɘ"
    je decrement_pointer
    cmp ax, "é"
    je increment_memory
    cmp ax, "è"
    je decrement_memory
    cmp ax, "ē"
    je print_char
    cmp ax, "ę"
    je get_char
    cmp ax, "ё"
    je loop_start
    cmp ax, "ė"
    je loop_end
    cmp ax, 0x00
    je end
    jmp next

increment_pointer:
    inc r14
    jmp next
decrement_pointer:
    dec r14
    jmp next
increment_memory:
    call validation_check
    inc byte [r14]
    jmp next
decrement_memory:
    call validation_check
    dec byte [r14]
    jmp next
print_char:
    mov rax, 1
    mov rdi, 1
    mov rsi, r14
    mov rdx, 1
    syscall
    jmp next
get_char:
    call validation_check
    xor rax, rax
    xor rdi, rdi
    mov rsi, r14
    mov rdx, 1
    syscall
    jmp next
loop_start:
    cmp byte [r14], 0
    je dont_enter_loop
    push r15
    jmp next
    dont_enter_loop:
    xor r13, r13
    exit_loop:
        add r15, 2
        mov ax, [r15]
        cmp ax, "ė"
        je bracket_close
        cmp ax, "ё"
        je bracket_open
        jmp exit_loop
        bracket_close:
            inc r13
            cmp r13, 1
            je next
            jmp exit_loop
        bracket_open:
            dec r13
            jmp exit_loop
loop_end:
    pop r15
    jmp loop

next:
    add r15, 2
    jmp loop

validation_check:
    cmp r14, memory
    jl memory_error
    cmp r14, memory_end
    jge memory_error
    ret

restore_terminal:
    mov rax, 16                     ; sys_ioctl
    xor rdi, rdi                    ; stdin
    mov rsi, 0x5402                 ; tcsets
    mov rdx, termios_old
    syscall
    ret

end:
    call restore_terminal
    mov rax, 60
    xor rdi, rdi
    syscall

load_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, errormsg
    mov rdx, errormsg_len
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall

memory_error:
    call restore_terminal
    mov rax, 1
    mov rdi, 1
    mov rsi, memory_err_msg
    mov rdx, memory_err_msg_len
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall

; 自前でバリデーションチェックするようにしたからもう要らないはずだけどせっかく書いたから残しておく
sigsegv_handler:
    call restore_terminal
    mov rax, 1
    mov rdi, 1
    mov rsi, sigsegv_msg
    mov rdx, sigsegv_msg_len
    syscall

    mov rax, 60                     ; sys_exit
    mov rdi, 139                    ; SIGSEGV
    syscall

sigreturn:
    mov rax, 15
    syscall
