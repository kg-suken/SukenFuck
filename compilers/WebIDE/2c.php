<?php
if (isset($_POST['brainfuck_code'])) {
    // 許可された文字のみを抽出
    $brainfuck_code = preg_replace('/[^еɘéèēęёė]/u', '', $_POST['brainfuck_code']);

    // デバッグ用: フィルタリング結果を確認
    // file_put_contents('debug.log', "Filtered code: " . $brainfuck_code . "\n", FILE_APPEND);

    // 初期設定
    $c_code = [
        "#include <stdio.h>",
        "#include <stdlib.h>",
        "int main() {",
        "    char array[30000] = {0};",
        "    char *ptr = array;"
    ];

    $indent = "    ";
    $loop_stack = [];

    // BrainfuckコードをCに変換
    for ($i = 0; $i < mb_strlen($brainfuck_code); $i++) {
        $command = mb_substr($brainfuck_code, $i, 1);

        switch ($command) {
            case 'е':
                $c_code[] = "$indent++ptr;";
                break;
            case 'ɘ':
                $c_code[] = "$indent--ptr;";
                break;
            case 'é':
                $c_code[] = "$indent++(*ptr);";
                break;
            case 'è':
                $c_code[] = "$indent--(*ptr);";
                break;
            case 'ē':
                $c_code[] = "$indent putchar(*ptr);";
                break;
            case 'ę':
                $c_code[] = "$indent *ptr = getchar();";
                break;
            case 'ё':
                $c_code[] = "$indent while (*ptr) {";
                $loop_stack[] = $indent;
                $indent .= "    ";
                break;
            case 'ė':
                if (empty($loop_stack)) {
                    header('Content-Type: text/plain');
                    echo "SyntaxError: Unmatched 'ė' detected";
                    exit;
                }
                $indent = array_pop($loop_stack);
                $c_code[] = "$indent}";
                break;
        }
    }

    if (!empty($loop_stack)) {
        header('Content-Type: text/plain');
        echo "SyntaxError: Unmatched 'ё' detected";
        exit;
    }

    $c_code[] = "    return 0;";
    $c_code[] = "}";

    // プレーンテキストとして返す
    header('Content-Type: text/plain');
    echo implode("\n", $c_code);
} else {
    // 入力がない場合のエラーメッセージ
    header('Content-Type: text/plain');
    echo "Error: No Brainfuck code provided.";
}